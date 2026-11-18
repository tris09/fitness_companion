import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../catalog.dart';
import '../models.dart';

/// Default model: Lite is fast, cheap and good enough for plans and lists.
/// If Google renames it, the app looks up another model on its own.
const String kDefaultCoachModel = 'gemini-flash-lite-latest';

/// What the user asks the coach for.
class CoachRequest {
  /// One or more styles. The coach combines them.
  final List<String> styles;
  final String goal;
  final String level;
  final int daysPerWeek;
  final int minutes;
  final String note;

  const CoachRequest({
    required this.styles,
    required this.goal,
    required this.level,
    required this.daysPerWeek,
    required this.minutes,
    this.note = '',
  });
}

class CoachDay {
  final String name;
  final List<PlanItem> items;

  CoachDay({required this.name, required this.items});
}

/// A training programme made by the coach. One day becomes one plan.
class CoachProgram {
  final String name;
  final List<CoachDay> days;

  /// The cleaned JSON, kept so it can be saved on the device.
  final String json;

  CoachProgram({required this.name, required this.days, required this.json});

  /// 0 = no time limit, otherwise 10 to 300 s.
  static int _limit(dynamic v) {
    final int n = v is num ? v.toInt() : (int.tryParse('$v') ?? 0);
    return n <= 0 ? 0 : (n < 10 ? 10 : (n > 300 ? 300 : n));
  }

  static int _clamp(dynamic v, int min, int max, int fallback) {
    final int n = v is num ? v.toInt() : (int.tryParse('$v') ?? fallback);
    return n < min ? min : (n > max ? max : n);
  }

  /// Reads the answer of the model. Unknown exercises are dropped, numbers are limited.
  static CoachProgram parse(String text) {
    final int a = text.indexOf('{');
    final int b = text.lastIndexOf('}');
    if (a < 0 || b <= a) {
      throw const FormatException('Keine JSON-Antwort');
    }
    return fromMap(Map<String, dynamic>.from(jsonDecode(text.substring(a, b + 1)) as Map));
  }

  /// Same as [parse] for data that is already decoded, for example the
  /// arguments of a function call.
  static CoachProgram fromMap(Map<String, dynamic> j) {
    final List<dynamic> rawDays = (j['days'] as List<dynamic>?) ?? <dynamic>[];
    final List<CoachDay> days = <CoachDay>[];
    for (final dynamic d in rawDays) {
      if (d is! Map) {
        continue;
      }
      final List<dynamic> rawItems = (d['items'] as List<dynamic>?) ?? <dynamic>[];
      final List<PlanItem> items = <PlanItem>[];
      for (final dynamic it in rawItems) {
        if (it is! Map) {
          continue;
        }
        final String id = '${it['exerciseId'] ?? ''}';
        if (!exerciseExists(id)) {
          continue;
        }
        final Exercise ex = exerciseById(id);
        items.add(PlanItem(
          exerciseId: id,
          sets: _clamp(it['sets'], 1, 10, 3),
          reps: ex.timed ? _clamp(it['reps'], 10, 600, 45) : _clamp(it['reps'], 1, 50, 10),
          // Rest 10 to 180 s. Inside a superset the next exercise follows directly anyway.
          restSec: _clamp(it['restSec'], 10, 180, 60),
          supersetWithNext: it['supersetWithNext'] == true || it['superset'] == true,
          workSec: ex.timed ? 0 : _limit(it['workSec']),
        ));
      }
      if (items.isEmpty) {
        continue;
      }
      items.last.supersetWithNext = false;
      final String dayName = '${d['name'] ?? ''}'.trim();
      days.add(CoachDay(name: dayName.isEmpty ? 'Tag ${days.length + 1}' : dayName, items: items));
    }
    if (days.isEmpty) {
      throw const FormatException('Die Antwort enthält keine nutzbaren Übungen');
    }
    final String name = '${j['name'] ?? ''}'.trim().isEmpty ? 'Programm' : '${j['name']}'.trim();
    final Map<String, dynamic> clean = <String, dynamic>{
      'name': name,
      'days': days
          .map((CoachDay d) => <String, dynamic>{
                'name': d.name,
                'items': d.items.map((PlanItem e) => e.toJson()).toList(),
              })
          .toList(),
    };
    return CoachProgram(name: name, days: days, json: jsonEncode(clean));
  }

  List<Plan> toPlans(String Function() newId) {
    final List<Plan> out = <Plan>[];
    for (int i = 0; i < days.length; i++) {
      out.add(Plan(
        id: '${newId()}_$i',
        name: '$name · ${days[i].name}',
        items: days[i].items.map((PlanItem e) => e.copy()).toList(),
      ));
    }
    return out;
  }
}

class CoachException implements Exception {
  final String message;

  CoachException(this.message);

  @override
  String toString() => message;
}

/// Connection point for the AI coach. Another provider or our own server
/// can replace [GeminiCoachService] later.
/// The answer of the coach in the chat: text and maybe a plan.
class CoachReply {
  final String text;
  final CoachProgram? program;

  /// Cleaned JSON of a shopping list, or empty.
  final String listJson;

  /// Facts the coach wants to remember.
  final List<String> remember;

  CoachReply({required this.text, this.program, this.listJson = '', List<String>? remember})
      : remember = remember ?? <String>[];
}

/// Result of the local offer search: a short text for the coach and the web sources.
class OfferInfo {
  final String text;
  final List<String> sources;

  const OfferInfo(this.text, this.sources);
}

/// One turn sent to the coach.
class ChatTurn {
  final String role;
  final String text;

  const ChatTurn(this.role, this.text);
}

abstract class CoachService {
  /// Chat with memory. [system] holds profile, body data and past workouts.
  /// The model can answer with text or call the function that creates a plan.
  Future<CoachReply> chat({
    required String apiKey,
    required String model,
    required String system,
    required List<ChatTurn> turns,
  });

  /// Looks up current supermarket offers near [place]. Returns null when nothing usable was found.
  Future<OfferInfo?> findOffers({
    required String apiKey,
    required String model,
    required String place,
    required List<String> stores,
  });

  /// Returns the programme and the model name that answered.
  Future<CoachProgram> createProgram({required String apiKey, required String model, required CoachRequest request});

  /// Model that worked last, so it can be remembered.
  String? get lastWorkingModel;
}

class GeminiCoachService implements CoachService {
  static const String _base = 'https://generativelanguage.googleapis.com/v1beta';

  String? _lastModel;

  @override
  String? get lastWorkingModel => _lastModel;

  static String buildPrompt(CoachRequest r) {
    final StringBuffer b = StringBuffer();
    b.writeln('Du bist ein erfahrener Trainingsplaner. Erstelle ein Trainingsprogramm.');
    if (r.styles.length == 1) {
      b.writeln('Trainingsstil: ${r.styles.first}');
    } else {
      b.writeln('Trainingsstile (miteinander kombinieren): ${r.styles.join(', ')}');
    }
    b.writeln('Ziel: ${r.goal}');
    b.writeln('Erfahrung: ${r.level}');
    b.writeln('Trainingstage pro Woche: ${r.daysPerWeek}');
    b.writeln('Dauer pro Einheit: etwa ${r.minutes} Minuten');
    if (r.note.trim().isNotEmpty) {
      b.writeln('Hinweis der Person: ${r.note.trim()}');
    }
    b.writeln();
    b.writeln('Regeln:');
    b.writeln('- Nutze nur Übungen aus der Liste unten und gib ihre id exakt an.');
    b.writeln('- Erstelle genau ${r.daysPerWeek} Trainingstage mit je 4 bis 8 Übungen.');
    b.writeln('- sets: 1 bis 6. reps: Wiederholungen, bei Übungen mit timed=ja Sekunden.');
    b.writeln('- restSec: Pause nach der Übung in Sekunden, 10 bis 180.');
    b.writeln('- supersetWithNext=true heißt: direkt weiter zur nächsten Übung ohne Pause.');
    b.writeln('- Bei mehreren Stilen die Stile sinnvoll mischen. Nicht jeder Stil muss an jedem Tag vorkommen, aber jeder soll im Programm vertreten sein.');
    b.writeln('- Zum Stil Supersets oder CrossFit gehört: passende Übungen mit supersetWithNext=true verbinden. Sonst false.');
    b.writeln('- Wähle Übungen passend zu den Stilen, zum Beispiel für Gerätetraining Geräte, für Calisthenics Körpergewicht, für Freie Gewichte Hanteln.');
    b.writeln('- Kraft & Power heißt: schwere Grundübungen, wenige Wiederholungen (1 bis 6) und lange Pausen (120 bis 180 s).');
    b.writeln('- Für Anfänger einfache Übungen und moderate Umfänge.');
    b.writeln('- Namen auf Deutsch und kurz.');
    b.writeln();
    b.writeln('Antworte nur mit JSON in genau diesem Format, ohne weiteren Text:');
    b.writeln('{"name":"Programmname","days":[{"name":"Tagname","items":[{"exerciseId":"squat","sets":3,"reps":10,"restSec":90,"supersetWithNext":false}]}]}');
    b.writeln();
    b.writeln('Übungen (id | Name | Kategorie | Ausrüstung | timed):');
    for (final Exercise e in exerciseCatalog) {
      b.writeln('${e.id} | ${e.name} | ${e.category} | ${e.equipment} | ${e.timed ? 'ja' : 'nein'}');
    }
    return b.toString();
  }

  static String _apiError(http.Response r) {
    String detail = '';
    try {
      final dynamic j = jsonDecode(r.body);
      if (j is Map && j['error'] is Map) {
        detail = '${(j['error'] as Map)['message'] ?? ''}';
      }
    } catch (_) {
      detail = '';
    }
    if (r.statusCode == 400 && detail.toLowerCase().contains('api key')) {
      return 'Der API-Schlüssel ist ungültig.';
    }
    if (r.statusCode == 401 || r.statusCode == 403) {
      return 'Der API-Schlüssel wurde abgelehnt (Fehler ${r.statusCode}).';
    }
    if (_busy(r.statusCode)) {
      return 'Die Gemini-Server sind gerade überlastet (Fehler ${r.statusCode}). Das liegt nicht an deinem Schlüssel. Versuch es in ein paar Minuten noch einmal.';
    }
    if (r.statusCode == 429) {
      return 'Das Kontingent deines Schlüssels ist gerade aufgebraucht. Versuch es später noch einmal.';
    }
    return 'Fehler ${r.statusCode}${detail.isEmpty ? '' : ': $detail'}';
  }

  Future<http.Response> _postBody(String apiKey, String model, Map<String, dynamic> body) {
    return http
        .post(
          Uri.parse('$_base/models/$model:generateContent'),
          headers: <String, String>{'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 90));
  }

  /// Description of the function the model may call. The exercise ids are
  /// an enum, so the model cannot invent exercises.
  static Map<String, dynamic> _planFunction() {
    return <String, dynamic>{
      'name': 'create_training_plan',
      'description': 'Erstellt einen Trainingsplan in der App. Ein Eintrag in days wird ein Plan.',
      'parameters': <String, dynamic>{
        'type': 'OBJECT',
        'properties': <String, dynamic>{
          'name': <String, dynamic>{'type': 'STRING', 'description': 'Kurzer Name des Programms'},
          'days': <String, dynamic>{
            'type': 'ARRAY',
            'items': <String, dynamic>{
              'type': 'OBJECT',
              'properties': <String, dynamic>{
                'name': <String, dynamic>{'type': 'STRING', 'description': 'Name des Trainingstags'},
                'items': <String, dynamic>{
                  'type': 'ARRAY',
                  'items': <String, dynamic>{
                    'type': 'OBJECT',
                    'properties': <String, dynamic>{
                      'exerciseId': <String, dynamic>{
                        'type': 'STRING',
                        'enum': exerciseCatalog.map((Exercise e) => e.id).toList(),
                      },
                      'sets': <String, dynamic>{'type': 'INTEGER'},
                      'reps': <String, dynamic>{'type': 'INTEGER', 'description': 'Wiederholungen, bei zeitbasierten Übungen Sekunden'},
                      'restSec': <String, dynamic>{'type': 'INTEGER'},
                      'supersetWithNext': <String, dynamic>{'type': 'BOOLEAN'},
                      'workSec': <String, dynamic>{
                        'type': 'INTEGER',
                        'description': 'Zeitlimit pro Satz in Sekunden für "so viele Wdh wie möglich", sonst 0',
                      },
                    },
                    'required': <String>['exerciseId', 'sets', 'reps', 'restSec'],
                  },
                },
              },
              'required': <String>['name', 'items'],
            },
          },
        },
        'required': <String>['name', 'days'],
      },
    };
  }

  static Map<String, dynamic> _listFunction() {
    return <String, dynamic>{
      'name': 'create_shopping_list',
      'description': 'Erstellt eine Einkaufsliste in der App. Nutze Angebote aus dem Kontext, wenn vorhanden.',
      'parameters': <String, dynamic>{
        'type': 'OBJECT',
        'properties': <String, dynamic>{
          'title': <String, dynamic>{'type': 'STRING'},
          'note': <String, dynamic>{'type': 'STRING', 'description': 'Kurz: für welche Mahlzeiten die Liste ist'},
          'items': <String, dynamic>{
            'type': 'ARRAY',
            'items': <String, dynamic>{
              'type': 'OBJECT',
              'properties': <String, dynamic>{
                'name': <String, dynamic>{'type': 'STRING'},
                'amount': <String, dynamic>{'type': 'STRING', 'description': 'z. B. 500 g, 6 Stück'},
                'category': <String, dynamic>{
                  'type': 'STRING',
                  'enum': kShoppingCategories,
                },
                'offer': <String, dynamic>{'type': 'STRING', 'description': 'Markt und Preis aus den Angeboten, sonst leer'},
              },
              'required': <String>['name', 'category'],
            },
          },
        },
        'required': <String>['title', 'items'],
      },
    };
  }

  static Map<String, dynamic> _rememberFunction() {
    return <String, dynamic>{
      'name': 'remember',
      'description': 'Merkt sich dauerhafte Vorlieben oder Einschränkungen der Person, z. B. "Knie schonen" oder "trainiert lieber morgens".',
      'parameters': <String, dynamic>{
        'type': 'OBJECT',
        'properties': <String, dynamic>{
          'facts': <String, dynamic>{
            'type': 'ARRAY',
            'items': <String, dynamic>{'type': 'STRING'},
          },
        },
        'required': <String>['facts'],
      },
    };
  }

  /// Keeps only usable lines and the known categories.
  static String _cleanList(Map<String, dynamic> args) {
    final ShoppingList list = ShoppingList.fromJson(args)..created = DateTime.now();
    for (final ShoppingItem i in list.items) {
      if (!kShoppingCategories.contains(i.category)) {
        i.category = 'Sonstiges';
      }
      i.done = false;
    }
    if (list.items.isEmpty) {
      return '';
    }
    return jsonEncode(list.toJson());
  }

  @override
  Future<OfferInfo?> findOffers({
    required String apiKey,
    required String model,
    required String place,
    required List<String> stores,
  }) async {
    if (place.trim().isEmpty) {
      return null;
    }
    final String which = stores.isEmpty ? 'Supermärkten und Discountern' : stores.join(', ');
    final String prompt = 'Suche die aktuellen Angebote dieser Woche bei $which in der Nähe von $place. '
        'Liste nur Lebensmittel, die für eine eiweißreiche, gesunde Ernährung passen, '
        'je Zeile: Markt | Produkt | Angebotspreis | gültig bis. Höchstens 25 Zeilen. '
        'Schreibe nur, was du in den Quellen gefunden hast. Wenn du nichts Sicheres findest, antworte nur mit KEINE.';
    final Map<String, dynamic> body = <String, dynamic>{
      'contents': <dynamic>[
        <String, dynamic>{
          'role': 'user',
          'parts': <dynamic>[
            <String, dynamic>{'text': prompt},
          ],
        },
      ],
      'tools': <dynamic>[
        <String, dynamic>{'google_search': <String, dynamic>{}},
      ],
    };
    try {
      final String useModel = model.trim().isEmpty ? kDefaultCoachModel : model.trim();
      final http.Response r = await _postBody(apiKey, useModel, body);
      if (r.statusCode != 200) {
        return null;
      }
      final dynamic j = jsonDecode(utf8.decode(r.bodyBytes));
      final List<dynamic> candidates = (j is Map ? j['candidates'] as List<dynamic>? : null) ?? <dynamic>[];
      if (candidates.isEmpty || candidates.first is! Map) {
        return null;
      }
      final Map<dynamic, dynamic> cand = candidates.first as Map;
      final String text = _partsText(cand['content']).trim();
      if (text.isEmpty || text.toUpperCase().startsWith('KEINE')) {
        return null;
      }
      final List<String> sources = <String>[];
      final dynamic meta = cand['groundingMetadata'];
      if (meta is Map && meta['groundingChunks'] is List) {
        for (final dynamic ch in meta['groundingChunks'] as List<dynamic>) {
          if (ch is Map && ch['web'] is Map) {
            final Map<dynamic, dynamic> w = ch['web'] as Map;
            final String title = '${w['title'] ?? ''}';
            final String uri = '${w['uri'] ?? ''}';
            if (uri.isNotEmpty && sources.length < 5) {
              sources.add(title.isEmpty ? uri : '$title|$uri');
            }
          }
        }
      }
      return OfferInfo(text, sources);
    } catch (_) {
      // Offers are a bonus. Without them the coach still writes a list.
      return null;
    }
  }

  static String _partsText(dynamic content) {
    final List<dynamic> parts = (content is Map ? content['parts'] as List<dynamic>? : null) ?? <dynamic>[];
    final StringBuffer b = StringBuffer();
    for (final dynamic p in parts) {
      if (p is Map && p['text'] != null) {
        b.write('${p['text']}');
      }
    }
    return b.toString();
  }

  @override
  Future<CoachReply> chat({
    required String apiKey,
    required String model,
    required String system,
    required List<ChatTurn> turns,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'systemInstruction': <String, dynamic>{
        'parts': <dynamic>[
          <String, dynamic>{'text': system},
        ],
      },
      'contents': <dynamic>[
        for (final ChatTurn t in turns)
          <String, dynamic>{
            'role': t.role,
            'parts': <dynamic>[
              <String, dynamic>{'text': t.text},
            ],
          },
      ],
      'tools': <dynamic>[
        <String, dynamic>{
          'functionDeclarations': <dynamic>[_planFunction(), _listFunction(), _rememberFunction()],
        },
      ],
    };
    String useModel = model.trim().isEmpty ? kDefaultCoachModel : model.trim();
    bool searchedModel = false;
    try {
      List<String>? alternatives;
      for (int attempt = 0; attempt < 6; attempt++) {
        final http.Response r = await _postBody(apiKey, useModel, body);
        if (r.statusCode == 200) {
          _lastModel = useModel;
          return _readReply(r);
        }
        if (_busy(r.statusCode)) {
          // Wait a moment, then try again. From the second miss on, switch to another model.
          await Future<void>.delayed(Duration(milliseconds: 800 * (attempt + 1)));
          if (attempt >= 1) {
            alternatives ??= await _alternatives(apiKey, useModel);
            if (alternatives.isNotEmpty) {
              useModel = alternatives.removeAt(0);
            }
          }
          continue;
        }
        if (r.statusCode == 404 && !searchedModel) {
          searchedModel = true;
          final String? found = await _findModel(apiKey);
          if (found != null && found != useModel) {
            useModel = found;
            continue;
          }
        }
        throw CoachException(_apiError(r));
      }
      throw CoachException('Die Gemini-Server sind gerade überlastet. Das liegt nicht an deinem Schlüssel. Versuch es in ein paar Minuten noch einmal.');
    } on CoachException {
      rethrow;
    } on TimeoutException {
      throw CoachException('Der Coach hat zu lange gebraucht. Prüfe deine Internetverbindung.');
    } on FormatException catch (e) {
      throw CoachException('Die Antwort war nicht lesbar: ${e.message}');
    } catch (_) {
      throw CoachException('Keine Verbindung zum Coach. Prüfe deine Internetverbindung.');
    }
  }

  /// Reads text parts and an optional function call from the answer.
  static CoachReply _readReply(http.Response r) {
    final dynamic j = jsonDecode(utf8.decode(r.bodyBytes));
    final List<dynamic> candidates = (j is Map ? j['candidates'] as List<dynamic>? : null) ?? <dynamic>[];
    if (candidates.isEmpty || candidates.first is! Map) {
      throw CoachException('Der Coach hat keine Antwort geliefert.');
    }
    final dynamic content = (candidates.first as Map)['content'];
    final List<dynamic> parts = (content is Map ? content['parts'] as List<dynamic>? : null) ?? <dynamic>[];
    final StringBuffer text = StringBuffer();
    CoachProgram? program;
    String listJson = '';
    final List<String> remember = <String>[];
    for (final dynamic p in parts) {
      if (p is! Map) {
        continue;
      }
      if (p['text'] != null) {
        text.write('${p['text']}');
      }
      final dynamic call = p['functionCall'];
      if (call is! Map || call['args'] is! Map) {
        continue;
      }
      final Map<String, dynamic> args = Map<String, dynamic>.from(call['args'] as Map);
      try {
        switch (call['name']) {
          case 'create_training_plan':
            program = CoachProgram.fromMap(args);
          case 'create_shopping_list':
            listJson = _cleanList(args);
          case 'remember':
            final List<dynamic> facts = (args['facts'] as List<dynamic>?) ?? <dynamic>[];
            remember.addAll(facts.map((dynamic e) => '$e'.trim()).where((String e) => e.isNotEmpty && e.length <= 120));
        }
      } on FormatException {
        // A broken call is dropped. The text answer still counts.
      }
    }
    String t = text.toString().trim();
    if (t.isEmpty && program != null) {
      t = 'Ich habe einen Plan für dich vorbereitet. Sieh ihn dir an und übernimm ihn, wenn er passt.';
    }
    if (t.isEmpty && listJson.isNotEmpty) {
      t = 'Hier ist deine Einkaufsliste. Übernimm sie, dann findest du sie im Tab Essen.';
    }
    if (t.isEmpty && remember.isNotEmpty) {
      t = 'Alles klar, das merke ich mir.';
    }
    if (t.isEmpty) {
      throw CoachException('Der Coach hat keine Antwort geliefert.');
    }
    return CoachReply(text: t, program: program, listJson: listJson, remember: remember);
  }

  Future<http.Response> _post(String apiKey, String model, String prompt, bool jsonMode) {
    final Map<String, dynamic> body = <String, dynamic>{
      'contents': <dynamic>[
        <String, dynamic>{
          'role': 'user',
          'parts': <dynamic>[
            <String, dynamic>{'text': prompt},
          ],
        },
      ],
    };
    if (jsonMode) {
      body['generationConfig'] = <String, dynamic>{'responseMimeType': 'application/json'};
    }
    return http
        .post(
          Uri.parse('$_base/models/$model:generateContent'),
          headers: <String, String>{'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 90));
  }

  /// Asks the API which models exist and picks a fast text model.
  Future<String?> _findModel(String apiKey) async {
    final http.Response r = await http
        .get(Uri.parse('$_base/models?pageSize=200'), headers: <String, String>{'x-goog-api-key': apiKey})
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) {
      throw CoachException(_apiError(r));
    }
    final dynamic j = jsonDecode(r.body);
    final List<dynamic> models = (j is Map ? j['models'] as List<dynamic>? : null) ?? <dynamic>[];
    final List<String> names = <String>[];
    const List<String> skip = <String>['image', 'tts', 'audio', 'live', 'embedding', 'vision'];
    for (final dynamic m in models) {
      if (m is! Map) {
        continue;
      }
      final String name = '${m['name'] ?? ''}'.replaceFirst('models/', '');
      final List<dynamic> methods = (m['supportedGenerationMethods'] as List<dynamic>?) ?? <dynamic>[];
      if (!methods.contains('generateContent') || !name.contains('flash')) {
        continue;
      }
      if (skip.any((String s) => name.contains(s))) {
        continue;
      }
      names.add(name);
    }
    if (names.isEmpty) {
      return null;
    }
    for (final String n in names) {
      if (n.contains('lite') && n.contains('latest')) {
        return n;
      }
    }
    for (final String n in names) {
      if (n.contains('lite')) {
        return n;
      }
    }
    for (final String n in names) {
      if (n.contains('latest')) {
        return n;
      }
    }
    names.sort();
    return names.last;
  }

  /// 503 = Google's servers are busy, 500 = temporary error. Not a key problem.
  static bool _busy(int code) => code == 503 || code == 500;

  /// Other fast models this key may use, lighter ones first. Used when a model is overloaded.
  Future<List<String>> _alternatives(String apiKey, String current) async {
    final List<String> out = <String>[];
    try {
      final http.Response r = await http
          .get(Uri.parse('$_base/models?pageSize=200'), headers: <String, String>{'x-goog-api-key': apiKey})
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) {
        return out;
      }
      final dynamic j = jsonDecode(r.body);
      final List<dynamic> models = (j is Map ? j['models'] as List<dynamic>? : null) ?? <dynamic>[];
      const List<String> skip = <String>['image', 'tts', 'audio', 'live', 'embedding', 'vision', 'preview', 'exp'];
      for (final dynamic m in models) {
        if (m is! Map) {
          continue;
        }
        final String name = '${m['name'] ?? ''}'.replaceFirst('models/', '');
        final List<dynamic> methods = (m['supportedGenerationMethods'] as List<dynamic>?) ?? <dynamic>[];
        if (name == current || !methods.contains('generateContent') || !name.contains('flash')) {
          continue;
        }
        if (skip.any((String x) => name.contains(x))) {
          continue;
        }
        out.add(name);
      }
      // Lite models first (usually less busy), then newest names first.
      out.sort((String a, String b) {
        final int la = a.contains('lite') ? 0 : 1;
        final int lb = b.contains('lite') ? 0 : 1;
        return la != lb ? la - lb : b.compareTo(a);
      });
    } catch (_) {
      // No list. The caller keeps retrying the same model.
    }
    return out.take(3).toList();
  }

  static String _textOf(http.Response r) {
    final dynamic j = jsonDecode(utf8.decode(r.bodyBytes));
    final List<dynamic> candidates = (j is Map ? j['candidates'] as List<dynamic>? : null) ?? <dynamic>[];
    if (candidates.isEmpty || candidates.first is! Map) {
      throw CoachException('Der Coach hat keine Antwort geliefert.');
    }
    final dynamic content = (candidates.first as Map)['content'];
    final List<dynamic> parts = (content is Map ? content['parts'] as List<dynamic>? : null) ?? <dynamic>[];
    final StringBuffer b = StringBuffer();
    for (final dynamic p in parts) {
      if (p is Map && p['text'] != null) {
        b.write('${p['text']}');
      }
    }
    return b.toString();
  }

  @override
  Future<CoachProgram> createProgram({
    required String apiKey,
    required String model,
    required CoachRequest request,
  }) async {
    final String prompt = buildPrompt(request);
    String useModel = model.trim().isEmpty ? kDefaultCoachModel : model.trim();
    bool jsonMode = true;
    bool searchedModel = false;
    try {
      List<String>? alternatives;
      for (int attempt = 0; attempt < 7; attempt++) {
        final http.Response r = await _post(apiKey, useModel, prompt, jsonMode);
        if (r.statusCode == 200) {
          _lastModel = useModel;
          return CoachProgram.parse(_textOf(r));
        }
        if (_busy(r.statusCode)) {
          await Future<void>.delayed(Duration(milliseconds: 800 * (attempt + 1)));
          if (attempt >= 1) {
            alternatives ??= await _alternatives(apiKey, useModel);
            if (alternatives.isNotEmpty) {
              useModel = alternatives.removeAt(0);
            }
          }
          continue;
        }
        if (r.statusCode == 404 && !searchedModel) {
          // The model name is unknown. Look up which models this key can use.
          searchedModel = true;
          final String? found = await _findModel(apiKey);
          if (found != null && found != useModel) {
            useModel = found;
            continue;
          }
        }
        if (r.statusCode == 400 && jsonMode && !_apiError(r).contains('ungültig')) {
          // Try once more without the JSON switch. The prompt still asks for JSON.
          jsonMode = false;
          continue;
        }
        throw CoachException(_apiError(r));
      }
      throw CoachException('Die Gemini-Server sind gerade überlastet. Das liegt nicht an deinem Schlüssel. Versuch es in ein paar Minuten noch einmal.');
    } on CoachException {
      rethrow;
    } on TimeoutException {
      throw CoachException('Der Coach hat zu lange gebraucht. Prüfe deine Internetverbindung.');
    } on FormatException catch (e) {
      throw CoachException('Die Antwort war nicht lesbar: ${e.message}');
    } catch (_) {
      throw CoachException('Keine Verbindung zum Coach. Prüfe deine Internetverbindung.');
    }
  }
}
