import 'catalog.dart';
import 'models.dart';
import 'state.dart';
import 'training_memory.dart';

/// Statistics computed from the stored data. Nothing extra is saved:
/// everything comes from the workout history, the weights and the week counts.

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _monday(DateTime d) => _day(d).subtract(Duration(days: d.weekday - 1));

/// Estimated one-rep max (Epley). Makes sets with different reps comparable.
double estimatedMax(WeightEntry e) {
  if (e.kg <= 0) {
    return 0;
  }
  return e.reps <= 1 ? e.kg : e.kg * (1 + e.reps / 30);
}

/// Workouts in the last [days] days.
List<WorkoutLog> workoutsIn(AppState s, int days) {
  final DateTime from = _day(DateTime.now()).subtract(Duration(days: days - 1));
  return s.history.where((WorkoutLog w) => !w.date.isBefore(from)).toList();
}

/// Workouts per week for the last [weeks] weeks, oldest first. From the week
/// counts, so it reaches back further than the detailed history.
List<int> workoutsPerWeek(AppState s, int weeks) {
  final DateTime monday = _monday(DateTime.now());
  return <int>[
    for (int i = weeks - 1; i >= 0; i--) s.weeks[weekKey(monday.subtract(Duration(days: 7 * i)))] ?? 0,
  ];
}

/// Sets of [exerciseId] in the workout on the day of [date]. 3 when unknown.
int _setsOn(AppState s, String exerciseId, DateTime date) {
  final DateTime d = _day(date);
  for (final WorkoutLog w in s.history.reversed) {
    if (_day(w.date) == d) {
      for (final PlanItem it in w.items) {
        if (it.exerciseId == exerciseId) {
          return it.sets;
        }
      }
    }
  }
  return 3;
}

/// Lifted volume (kg × reps × sets) per week for the last [weeks] weeks, oldest first.
List<double> volumePerWeek(AppState s, int weeks) {
  final DateTime first = _monday(DateTime.now()).subtract(Duration(days: 7 * (weeks - 1)));
  final List<double> out = List<double>.filled(weeks, 0);
  s.weights.forEach((String id, List<WeightEntry> list) {
    for (final WeightEntry e in list) {
      final int i = _day(e.date).difference(first).inDays ~/ 7;
      if (!_day(e.date).isBefore(first) && i >= 0 && i < weeks) {
        out[i] += e.kg * e.reps * _setsOn(s, id, e.date);
      }
    }
  });
  return out;
}

/// Total volume in the last [days] days.
double volumeIn(AppState s, int days) {
  final DateTime from = _day(DateTime.now()).subtract(Duration(days: days - 1));
  double sum = 0;
  s.weights.forEach((String id, List<WeightEntry> list) {
    for (final WeightEntry e in list) {
      if (!e.date.isBefore(from)) {
        sum += e.kg * e.reps * _setsOn(s, id, e.date);
      }
    }
  });
  return sum;
}

/// Training minutes in the last [days] days. Older entries without a
/// measured time count with 0 and are left out of the average.
({int total, int counted}) minutesIn(AppState s, int days) {
  int total = 0;
  int counted = 0;
  for (final WorkoutLog w in workoutsIn(s, days)) {
    if (w.minutes > 0) {
      total += w.minutes;
      counted++;
    }
  }
  return (total: total, counted: counted);
}

/// Set of trained days in the last [weeks] weeks (for the heat map).
Set<DateTime> trainedDays(AppState s, int weeks) {
  final DateTime from = _monday(DateTime.now()).subtract(Duration(days: 7 * (weeks - 1)));
  return s.history.map((WorkoutLog w) => _day(w.date)).where((DateTime d) => !d.isBefore(from)).toSet();
}

/// Workouts per weekday (Mo..So) in the last [days] days.
List<int> perWeekday(AppState s, int days) {
  final List<int> out = List<int>.filled(7, 0);
  for (final WorkoutLog w in workoutsIn(s, days)) {
    out[w.date.weekday - 1]++;
  }
  return out;
}

/// Most frequent exercises in the last [days] days: (id, count), most first.
List<(String, int)> topExercises(AppState s, int days, {int take = 5}) {
  final Map<String, int> count = <String, int>{};
  for (final WorkoutLog w in workoutsIn(s, days)) {
    for (final String id in w.items.map((PlanItem e) => e.exerciseId).toSet()) {
      count[id] = (count[id] ?? 0) + 1;
    }
  }
  final List<(String, int)> list = count.entries.map((MapEntry<String, int> e) => (e.key, e.value)).toList()
    ..sort(((String, int) a, (String, int) b) => b.$2.compareTo(a.$2));
  return list.take(take).toList();
}

/// A new best weight within the period: beats every earlier entry of the exercise.
class NewRecord {
  final String exerciseId;
  final WeightEntry entry;
  final double previous;

  const NewRecord(this.exerciseId, this.entry, this.previous);
}

/// New best weights in the last [days] days, newest first.
List<NewRecord> recordsIn(AppState s, int days) {
  final DateTime from = _day(DateTime.now()).subtract(Duration(days: days - 1));
  final List<NewRecord> out = <NewRecord>[];
  s.weights.forEach((String id, List<WeightEntry> list) {
    double best = 0;
    for (final WeightEntry e in list) {
      if (e.kg > best && best > 0 && !e.date.isBefore(from)) {
        out.add(NewRecord(id, e, best));
      }
      if (e.kg > best) {
        best = e.kg;
      }
    }
  });
  out.sort((NewRecord a, NewRecord b) => b.entry.date.compareTo(a.entry.date));
  return out;
}

/// Change of the estimated max from the first to the last entry in the period.
class Progress {
  final String exerciseId;
  final double from;
  final double to;

  const Progress(this.exerciseId, this.from, this.to);

  double get percent => from <= 0 ? 0 : (to - from) / from * 100;
}

/// Exercises with at least two entries in the period, biggest gain first.
List<Progress> progressIn(AppState s, int days, {int take = 3}) {
  final DateTime from = _day(DateTime.now()).subtract(Duration(days: days - 1));
  final List<Progress> out = <Progress>[];
  s.weights.forEach((String id, List<WeightEntry> list) {
    final List<WeightEntry> inside = list.where((WeightEntry e) => !e.date.isBefore(from)).toList();
    if (inside.length >= 2) {
      out.add(Progress(id, estimatedMax(inside.first), estimatedMax(inside.last)));
    }
  });
  out.sort((Progress a, Progress b) => b.percent.compareTo(a.percent));
  return out.take(take).toList();
}

/// Display name of an exercise id.
String exerciseName(String id) => exerciseById(id).name;

/// '12,4 t' or '850 kg'.
String formatVolume(double kg) {
  if (kg >= 1000) {
    return '${(kg / 1000).toStringAsFixed(1).replaceAll('.', ',')} t';
  }
  return '${kg.round()} kg';
}

/// '3 h 20 min' or '45 min'.
String formatMinutes(int m) {
  if (m < 60) {
    return '$m min';
  }
  return m % 60 == 0 ? '${m ~/ 60} h' : '${m ~/ 60} h ${m % 60} min';
}
