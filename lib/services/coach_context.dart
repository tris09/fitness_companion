import '../catalog.dart';
import '../models.dart';
import '../state.dart';
import 'coach_service.dart';
import '../training_memory.dart';

const List<String> _weekdays = <String>['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];

String _date(DateTime d) => '${d.day}.${d.month}.${d.year}';

/// Builds the memory of the coach: profile, body data and the last workouts.
/// It is sent as the system instruction with every request.
String buildCoachSystem(AppState state, {OfferInfo? offers}) {
  final DateTime now = DateTime.now();
  final CoachProfile p = state.coachProfile;
  final BodyProfile b = state.body;
  final StringBuffer s = StringBuffer();
  s.writeln('Du bist der persönliche Fitness-Coach in einer App. Antworte auf Deutsch, kurz und konkret.');
  s.writeln('Heute ist ${_weekdays[now.weekday - 1]}, der ${_date(now)}.');
  s.writeln();
  s.writeln('Profil der Person:');
  s.writeln('- Gewicht ${b.weightKg.round()} kg, Größe ${b.heightCm} cm, Alter ${b.age}');
  if (p.aiDecides || !p.done) {
    s.writeln('- Ziel, Stil und Umfang: Die Person lässt dich entscheiden. Wähle passend zu Körperdaten und Trainingsverlauf und erkläre kurz deine Wahl.');
  } else {
    s.writeln('- Ziel: ${p.goal}; Erfahrung: ${p.level}');
    s.writeln('- Bevorzugte Trainingsstile: ${p.styles.join(', ')}');
    s.writeln('- Wunsch: ${p.days} Trainingstage pro Woche, etwa ${p.minutes} Minuten pro Einheit');
  }
  if (state.memory.isNotEmpty) {
    s.writeln('- Gemerkte Vorlieben und Einschränkungen: ${state.memory.join('; ')}');
  }
  if (state.shop.place.trim().isNotEmpty) {
    s.writeln('- Wohnort für den Einkauf: ${state.shop.place.trim()}${state.shop.stores.isEmpty ? '' : ' (bevorzugte Märkte: ${state.shop.stores.join(', ')})'}');
  }
  s.writeln();
  // The app keeps the last 2 weeks, and at least the last 5 workouts.
  final List<WorkoutLog> recent = state.history;
  if (recent.isEmpty) {
    s.writeln('Gespeicherte Trainings: noch keine.');
  } else {
    s.writeln('Gespeicherte Trainings (letzte 2 Wochen, mindestens die letzten 5; älteste zuerst):');
    for (final WorkoutLog w in recent) {
      final int days = now.difference(w.date).inDays;
      final String ago = days <= 0 ? 'heute' : (days == 1 ? 'gestern' : 'vor $days Tagen');
      final String items = w.items
          .map((PlanItem i) {
            final Exercise e = exerciseById(i.exerciseId);
            return '${e.name} ${i.sets}×${i.reps}${e.timed ? 's' : ''}';
          })
          .join(', ');
      s.writeln('- ${_date(w.date)} ($ago), ${w.planName}: $items');
    }
  }
  s.writeln();
  final Map<String, DateTime> last = state.muscleLast;
  s.writeln('Muskelgruppen, zuletzt trainiert: ${kMuscleGroups.map((String g) => '$g ${agoText(last[g])}').join(', ')}');
  final List<String> due = state.dueMuscles;
  if (due.isNotEmpty) {
    s.writeln('Länger nicht trainiert (bevorzugen, wenn es passt): ${due.join(', ')}');
  }
  if (state.weights.isEmpty) {
    s.writeln('Gewichte: noch keine eingetragen. Empfiehl für Anfänger leichte Startgewichte.');
  } else {
    s.writeln('Gewichte (letzte Einträge, Gefühl der Person; Vorschlag der App für das nächste Mal):');
    state.weights.forEach((String id, List<WeightEntry> list) {
      if (list.isEmpty) {
        return;
      }
      final List<WeightEntry> tail = list.length > 3 ? list.sublist(list.length - 3) : list;
      final String hist = tail.map((WeightEntry e) => '${formatKg(e.kg)}×${e.reps}${e.feel.isEmpty ? '' : ' (${e.feel})'}').join(', ');
      final double? next = suggestWeight(list);
      s.writeln('- ${exerciseById(id).name}: $hist${next == null ? '' : '; Vorschlag ${formatKg(next)}'}');
    });
  }
  s.writeln();
  s.writeln('Regeln:');
  s.writeln('- Wenn die Person einen Plan oder ein Training möchte, rufe die Funktion create_training_plan auf. Schreibe den Plan nicht als Text.');
  s.writeln('- Ein Training für heute ist ein Plan mit genau einem Tag. Für eine Woche so viele Tage wie gewünscht.');
  s.writeln('- Berücksichtige die letzten Trainings: Muskelgruppen, die gestern oder vorgestern dran waren, nicht gleich wieder voll belasten.');
  s.writeln('- Nutze nur Übungen aus der Funktion (exerciseId). Passe Dauer an: etwa 6 bis 8 Minuten pro Übung inklusive Pausen.');
  s.writeln('- sets 1 bis 6; reps in Wiederholungen, bei zeitbasierten Übungen in Sekunden; restSec 10 bis 180 (ohne Pause nur über supersetWithNext).');
  s.writeln('- Schreibe zusätzlich ein bis drei Sätze, warum der Plan so aufgebaut ist.');
  s.writeln('- Wenn die Person eine Einkaufsliste möchte, rufe create_shopping_list auf. Mengen für die genannte Zeit, passend zu Ziel und Körpergewicht. Ordne jede Zutat einer Kategorie zu.');
  s.writeln('- Wenn Angebote unten stehen, bevorzuge passende Angebote und trage Markt und Preis in offer ein. Erfinde keine Angebote oder Preise.');
  s.writeln('- Wenn die Person eine dauerhafte Vorliebe oder Einschränkung nennt, rufe remember auf (kurz, ein Fakt pro Eintrag).');
  s.writeln('- Nenne bei Übungen mit Gewicht das empfohlene Gewicht in deinem Text, orientiert am Vorschlag der App.');
  s.writeln('- Keine medizinischen Diagnosen. Bei Schmerzen oder Vorerkrankungen auf Ärztin oder Arzt verweisen.');
  if (offers != null) {
    s.writeln();
    s.writeln('Aktuelle Angebote in der Nähe (aus einer Websuche, können unvollständig sein):');
    s.writeln(offers.text);
  }
  s.writeln();
  s.writeln('Übungen (id | Name | Kategorie | Ausrüstung | zeitbasiert):');
  for (final Exercise e in exerciseCatalog) {
    s.writeln('${e.id} | ${e.name} | ${e.category} | ${e.equipment} | ${e.timed ? 'ja' : 'nein'}');
  }
  return s.toString();
}
