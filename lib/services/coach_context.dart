import '../catalog.dart';
import '../models.dart';
import '../state.dart';
import 'coach_service.dart';
import '../training_memory.dart';

const List<String> _weekdays = <String>['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];

String _date(DateTime d) => '${d.day}.${d.month}.';

String _iso(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The next 14 days as "Mo=2026-11-23", so the model can turn "Montag" into a date.
String _nextDays(DateTime now) {
  const List<String> short = <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  return <String>[
    for (int i = 0; i < 14; i++)
      () {
        final DateTime d = DateTime(now.year, now.month, now.day + i);
        return '${short[d.weekday - 1]}=${_iso(d)}';
      }(),
  ].join(', ');
}

/// What a chat message is about. Decides which parts of the memory are sent.
enum CoachTopic { training, food, general }

/// Rough guess from the user's text. Training is the default, it is the main use.
CoachTopic guessTopic(String text) {
  final String t = text.toLowerCase();
  const List<String> food = <String>[
    'einkauf', 'essen', 'rezept', 'ernähr', 'kochen', 'mahlzeit', 'frühstück', 'abendessen',
    'mittagessen', 'snack', 'protein', 'kalorien', 'angebot', 'lebensmittel',
  ];
  const List<String> train = <String>[
    'training', 'plan', 'übung', 'satz', 'sätze', 'gewicht', 'kg', 'muskel', 'workout', 'woche', 'heute', 'pause',
  ];
  final bool f = food.any(t.contains);
  final bool tr = train.any(t.contains);
  if (f && !tr) {
    return CoachTopic.food;
  }
  if (!f && !tr && t.length < 60) {
    return CoachTopic.general;
  }
  return CoachTopic.training;
}

/// Body weight now and the change over 4 weeks and 6 months, in one line.
String bodyTrendLine(AppState state) {
  final List<BodyEntry> log = state.bodyLog;
  if (log.isEmpty) {
    return 'Gewicht ${formatKg(state.body.weightKg)} (keine Verlaufsdaten)';
  }
  final BodyEntry last = log.last;
  BodyEntry? at(int daysAgo) {
    final DateTime t = DateTime.now().subtract(Duration(days: daysAgo));
    BodyEntry? best;
    for (final BodyEntry e in log) {
      if (!e.date.isAfter(t)) {
        best = e;
      }
    }
    return best;
  }

  final List<String> parts = <String>['Gewicht ${formatKg(last.weightKg)} (${_date(last.date)})'];
  final BodyEntry? m1 = at(28);
  final BodyEntry? m6 = at(150) ?? (log.first == last ? null : log.first);
  if (m1 != null && m1 != last) {
    parts.add('vor 4 Wochen ${formatKg(m1.weightKg)}');
  }
  if (m6 != null && m6 != last && m6 != m1) {
    parts.add('am ${_date(m6.date)} ${formatKg(m6.weightKg)}');
  }
  if (last.fatPercent != null) {
    parts.add('Körperfett ${last.fatPercent!.toStringAsFixed(1)} %');
  }
  if (last.waistCm != null) {
    parts.add('Taille ${last.waistCm!.round()} cm');
  }
  return parts.join(', ');
}

/// Builds the system text of the coach. Kept short on purpose:
/// all values are stored for 6 months, but only a summary is sent,
/// and only the parts that fit the topic of the message.
String buildCoachSystem(AppState state, {OfferInfo? offers, CoachTopic topic = CoachTopic.training}) {
  final DateTime now = DateTime.now();
  final CoachProfile p = state.coachProfile;
  final BodyProfile b = state.body;
  final StringBuffer s = StringBuffer();
  final bool training = topic == CoachTopic.training;
  final bool food = topic == CoachTopic.food || offers != null;
  s.writeln('Du bist der persönliche Fitness-Coach in einer App. Antworte auf Deutsch, kurz und konkret.');
  s.writeln('Heute: ${_weekdays[now.weekday - 1]}, ${_date(now)}${now.year}.');
  s.writeln('Person: ${bodyTrendLine(state)}; ${b.heightCm} cm; ${b.age} Jahre.');
  if (p.aiDecides || !p.done) {
    s.writeln('Coach entscheidet: Wähle Ziel, Stil und Umfang selbst anhand des Trainingsverlaufs (Häufigkeit, Muskelgruppen, Gewichte) '
        'und der Körperdaten; Wahl kurz erklären.');
  } else {
    s.writeln('Ziel ${p.goal}; Erfahrung ${p.level}; Stile ${p.styles.join(', ')}; ${p.days} Tage/Woche à ${p.minutes} min.');
  }
  if (state.memory.isNotEmpty) {
    s.writeln('Gemerkt: ${state.memory.join('; ')}');
  }
  if (food && state.shop.place.trim().isNotEmpty) {
    s.writeln('Einkauf in ${state.shop.place.trim()}${state.shop.stores.isEmpty ? '' : ' (${state.shop.stores.join(', ')})'}');
  }

  if (training) {
    _writeTraining(s, state, now);
  } else {
    // Short hint only, so plans still fit when the topic was guessed wrong.
    final int n = state.recentWorkouts().length;
    s.writeln('Trainings letzte 2 Wochen: $n. Länger nicht trainiert: ${state.dueMuscles.join(', ')}');
  }

  s.writeln();
  s.writeln('Regeln:');
  s.writeln('- Persönliche dauerhafte Vorliebe oder Einschränkung genannt: remember aufrufen (ein kurzer Fakt pro Eintrag).');
  s.writeln('- Keine Diagnosen. Bei Schmerzen oder Vorerkrankungen auf Ärztin oder Arzt verweisen.');
  s.writeln('- Will die Person Ziele, Umfang oder Methode ändern, oder passt das Training laut Verlauf nicht mehr zu den Einstellungen: '
      'propose_coach_settings aufrufen (nur geänderte Felder, ein Satz Begründung). Nichts gilt, bevor sie bestätigt.');
  if (training) {
    s.writeln('- Plan oder Training gewünscht: create_training_plan aufrufen, den Plan nicht als Text schreiben. Für heute genau ein Tag.');
    s.writeln('- Pläne mit date trägt die App sofort in den Kalender ein (z. B. „fürs Wochenende“ = Sa und So). Sag danach kurz, an welchen Tagen sie stehen.');
    s.writeln('- Nennt die Person Tage oder Daten: pro Tag date (JJJJ-MM-TT) setzen; diese Pläne stehen nur im Kalender. '
        'Will sie eine Vorlage oder einen Plan ohne Tag: date weglassen; der Plan landet unter Pläne.');
    s.writeln('- Nächste Tage: ${_nextDays(now)}. Höchstens ${DataLimits.aheadDays} Tage im Voraus.');
    s.writeln('- Muskelgruppen von gestern/vorgestern nicht voll belasten. Etwa 6 bis 8 Minuten pro Übung inklusive Pausen.');
    s.writeln('- sets 1-6; reps = Wiederholungen bzw. Sekunden bei zeitbasierten Übungen; restSec 10-180; ohne Pause nur per supersetWithNext.');
    s.writeln('- workSec > 0 = Zeit-Satz (so viele Wdh wie möglich, höchstens workSec s; reps ist das Ziel). Nur wenn passend.');
    s.writeln('- Empfohlenes Gewicht im Text nennen, am Vorschlag der App orientiert. Ein bis drei Sätze zur Begründung.');
  }
  if (food || topic == CoachTopic.general) {
    s.writeln('- Einkaufsliste gewünscht: create_shopping_list aufrufen; Mengen passend zu Zeitraum, Ziel und Gewicht; jede Zutat einer Kategorie zuordnen.');
    s.writeln('- Angebote nur aus der Liste unten verwenden, nichts erfinden.');
  }
  if (offers != null) {
    s.writeln();
    s.writeln('Angebote in der Nähe (Websuche, evtl. unvollständig):');
    s.writeln(offers.text);
  }
  if (training) {
    s.writeln();
    s.writeln('Übungen je Kategorie (id=Name, * = zeitbasiert, [Gerät]):');
    final Map<String, List<Exercise>> byCat = <String, List<Exercise>>{};
    for (final Exercise e in exerciseCatalog) {
      byCat.putIfAbsent(e.category, () => <Exercise>[]).add(e);
    }
    byCat.forEach((String cat, List<Exercise> list) {
      final String items = list.map((Exercise e) {
        final String eq = e.equipment.isEmpty || e.equipment == 'Körpergewicht' ? '' : ' [${e.equipment}]';
        return '${e.id}=${e.name}${e.timed ? '*' : ''}$eq';
      }).join(', ');
      s.writeln('$cat: $items');
    });
  }
  return s.toString();
}

void _writeTraining(StringBuffer s, AppState state, DateTime now) {
  // Details only for the last 2 weeks (at most 8 workouts). Older months as one line.
  final List<WorkoutLog> recent = state.recentWorkouts();
  final List<WorkoutLog> shown = recent.length > 8 ? recent.sublist(recent.length - 8) : recent;
  if (shown.isEmpty) {
    s.writeln('Trainings letzte 2 Wochen: keine.');
  } else {
    s.writeln('Trainings letzte 2 Wochen (älteste zuerst):');
    for (final WorkoutLog w in shown) {
      final int days = now.difference(w.date).inDays;
      final String ago = days <= 0 ? 'heute' : (days == 1 ? 'gestern' : 'vor $days T.');
      final String items = w.items.map((PlanItem i) {
        final Exercise e = exerciseById(i.exerciseId);
        return '${e.name} ${i.sets}×${i.reps}${e.timed ? 's' : ''}';
      }).join(', ');
      s.writeln('- $ago ${w.planName}: $items');
    }
  }
  final int older = state.history.length - recent.length;
  if (older > 0) {
    final DateTime first = state.history.first.date;
    final double weeks = now.difference(first).inDays / 7;
    s.writeln('Davor seit ${_date(first)}: $older Trainings, im Schnitt ${(state.history.length / (weeks < 1 ? 1 : weeks)).toStringAsFixed(1)} pro Woche.');
  }
  final Map<String, DateTime> last = state.muscleLast;
  s.writeln('Zuletzt trainiert: ${kMuscleGroups.map((String g) => '$g ${agoText(last[g])}').join(', ')}');
  final List<String> due = state.dueMuscles;
  if (due.isNotEmpty) {
    s.writeln('Bevorzugen, wenn passend: ${due.join(', ')}');
  }
  if (state.weights.isEmpty) {
    s.writeln('Gewichte: noch keine. Leichte Startgewichte empfehlen.');
    return;
  }
  // Only exercises used in the last 8 weeks, newest first, at most 15.
  final DateTime cut = now.subtract(const Duration(days: 56));
  final List<MapEntry<String, List<WeightEntry>>> used = state.weights.entries
      .where((MapEntry<String, List<WeightEntry>> e) => e.value.isNotEmpty && e.value.last.date.isAfter(cut))
      .toList()
    ..sort((MapEntry<String, List<WeightEntry>> a, MapEntry<String, List<WeightEntry>> b) => b.value.last.date.compareTo(a.value.last.date));
  s.writeln('Gewichte (zuletzt kg×Wdh (Gefühl); Bestwert; Startwert der 6 Monate; Vorschlag):');
  for (final MapEntry<String, List<WeightEntry>> e in used.take(15)) {
    final List<WeightEntry> l = e.value;
    final WeightEntry lw = l.last;
    final double best = state.records[e.key] ?? lw.kg;
    final double? next = suggestWeight(l);
    s.writeln('- ${exerciseById(e.key).name}: ${formatKg(lw.kg)}×${lw.reps}${lw.feel.isEmpty ? '' : ' (${lw.feel})'}; '
        'best ${formatKg(best)}; start ${formatKg(l.first.kg)}${next == null ? '' : '; nächstes ${formatKg(next)}'}');
  }
  final int rest = state.weights.length - used.take(15).length;
  if (rest > 0) {
    s.writeln('($rest weitere Übungen mit älteren Gewichten nicht aufgeführt.)');
  }
}

/// Short prompt for the weekly summary on the statistics page.
String buildSummarySystem(AppState state) {
  final DateTime now = DateTime.now();
  final StringBuffer s = StringBuffer();
  s.writeln('Du schreibst eine kurze Wochen-Zusammenfassung für eine Fitness-App. Deutsch, höchstens 4 Sätze, motivierend aber ehrlich, ohne Diagnosen.');
  s.writeln('Inhalt: was gut lief, welche Muskelgruppe zu kurz kam, ein konkreter Vorschlag für nächste Woche.');
  s.writeln('Person: ${bodyTrendLine(state)}.');
  final List<WorkoutLog> week = state.recentWorkouts(days: 7);
  s.writeln('Trainings letzte 7 Tage: ${week.length} (Ziel ${state.weekGoal}).');
  for (final WorkoutLog w in week) {
    s.writeln('- ${_date(w.date)} ${w.planName}: ${w.items.map((PlanItem i) => exerciseById(i.exerciseId).name).join(', ')}');
  }
  final Map<String, DateTime> last = state.muscleLast;
  s.writeln('Zuletzt trainiert: ${kMuscleGroups.map((String g) => '$g ${agoText(last[g])}').join(', ')}');
  final DateTime cut = now.subtract(const Duration(days: 7));
  final List<String> lifts = <String>[];
  state.weights.forEach((String id, List<WeightEntry> l) {
    final List<WeightEntry> wk = l.where((WeightEntry e) => e.date.isAfter(cut)).toList();
    if (wk.isNotEmpty) {
      lifts.add('${exerciseById(id).name} ${formatKg(wk.last.kg)} (Bestwert ${formatKg(state.records[id] ?? wk.last.kg)})');
    }
  });
  if (lifts.isNotEmpty) {
    s.writeln('Gewichte diese Woche: ${lifts.join(', ')}');
  }
  return s.toString();
}
