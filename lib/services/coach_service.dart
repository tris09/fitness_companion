import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../catalog.dart';
import '../models.dart';

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
    final Map<String, dynamic> j = Map<String, dynamic>.from(jsonDecode(text.substring(a, b + 1)) as Map);
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
          restSec: _clamp(it['restSec'], 0, 600, 60),
          supersetWithNext: it['supersetWithNext'] == true,
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
abstract class CoachService {
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
    b.writeln('- restSec: Pause nach der Übung in Sekunden, 0 bis 180.');
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
    if (r.statusCode == 429) {
      return 'Das Kontingent deines Schlüssels ist gerade aufgebraucht. Versuch es später noch einmal.';
    }
    return 'Fehler ${r.statusCode}${detail.isEmpty ? '' : ': $detail'}';
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
      if (n.contains('latest')) {
        return n;
      }
    }
    names.sort();
    return names.last;
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
    String useModel = model.trim().isEmpty ? 'gemini-flash-latest' : model.trim();
    bool jsonMode = true;
    bool searchedModel = false;
    try {
      for (int attempt = 0; attempt < 4; attempt++) {
        final http.Response r = await _post(apiKey, useModel, prompt, jsonMode);
        if (r.statusCode == 200) {
          _lastModel = useModel;
          return CoachProgram.parse(_textOf(r));
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
      throw CoachException('Der Coach konnte kein Programm erstellen.');
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
