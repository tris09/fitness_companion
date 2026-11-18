import 'catalog.dart';
import 'models.dart';

/// Rules for weights and muscle groups. Used by the app and passed to the coach.

/// Exercises where a weight makes sense.
bool usesWeight(Exercise e) {
  if (e.timed) {
    return false;
  }
  if (e.equipment == 'Freie Gewichte' || e.equipment == 'Gerät') {
    return true;
  }
  return const <String>{'swing', 'thruster', 'wallball'}.contains(e.id);
}

/// Muscle groups an exercise works. Full-body moves count for every group they touch.
Set<String> groupsOf(Exercise e) {
  final Set<String> out = <String>{};
  if (kMuscleGroups.contains(e.category)) {
    out.add(e.category);
  }
  for (final Muscle m in e.muscles) {
    switch (m) {
      case Muscle.quads:
      case Muscle.hips:
      case Muscle.calves:
        out.add('Beine');
      case Muscle.chest:
        out.add('Brust');
      case Muscle.shoulders:
        out.add('Schultern');
      case Muscle.arms:
        out.add('Arme');
      case Muscle.core:
        out.add('Core');
      case Muscle.neck:
        break;
    }
  }
  return out;
}

double _round(double kg) => (kg / 2.5).round() * 2.5;

/// Suggests the next weight from the last entries (newest last).
/// Light: about +5 %. Fits twice in a row at the same weight: +2,5 kg.
/// Heavy: about -5 %. Otherwise: stay.
double? suggestWeight(List<WeightEntry> entries) {
  if (entries.isEmpty) {
    return null;
  }
  final WeightEntry last = entries.last;
  double next = last.kg;
  if (last.feel == 'leicht') {
    next = _round(last.kg * 1.05);
    if (next <= last.kg) {
      next = last.kg + 2.5;
    }
  } else if (last.feel == 'schwer') {
    next = _round(last.kg * 0.95);
    if (next >= last.kg) {
      next = last.kg - 2.5;
    }
  } else if (last.feel == 'passt' && entries.length >= 2) {
    final WeightEntry before = entries[entries.length - 2];
    if (before.kg == last.kg && before.feel == 'passt') {
      next = last.kg + 2.5;
    }
  }
  return next < 0 ? 0 : next;
}

/// Updates [last] (group -> date) with the groups of one workout.
void markTrained(Map<String, DateTime> last, WorkoutLog w) {
  for (final PlanItem i in w.items) {
    for (final String g in groupsOf(exerciseById(i.exerciseId))) {
      final DateTime? old = last[g];
      if (old == null || w.date.isAfter(old)) {
        last[g] = w.date;
      }
    }
  }
}

/// Groups not trained for at least [days] days, longest ago first.
/// [last] is kept apart from the workout list, so it survives when old workouts are deleted.
List<String> dueGroups(Map<String, DateTime> last, {int days = 6}) {
  final DateTime now = DateTime.now();
  final List<String> due = kMuscleGroups.where((String g) {
    final DateTime? d = last[g];
    return d == null || now.difference(d).inDays >= days;
  }).toList();
  due.sort((String a, String b) {
    final DateTime? da = last[a];
    final DateTime? db = last[b];
    if (da == null) {
      return db == null ? 0 : -1;
    }
    if (db == null) {
      return 1;
    }
    return da.compareTo(db);
  });
  return due;
}

/// Short text for a date: heute, gestern, vor 5 Tagen.
String agoText(DateTime? d) {
  if (d == null) {
    return 'noch nicht erfasst';
  }
  final DateTime now = DateTime.now();
  final int days = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (days <= 0) {
    return 'heute';
  }
  return days == 1 ? 'gestern' : 'vor $days Tagen';
}
