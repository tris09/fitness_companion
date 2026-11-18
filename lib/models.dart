/// Body regions the muscle figure can highlight.
enum Muscle { neck, shoulders, chest, core, arms, hips, quads, calves }

class Exercise {
  final String id;
  final String name;
  final String muscleLabel;

  /// Filter category in the planner, e.g. 'Beine'.
  final String category;

  /// 'Körpergewicht', 'Freie Gewichte', 'Gerät' or 'CrossFit'.
  final String equipment;
  final List<Muscle> muscles;

  /// true = held for time (seconds), false = counted in repetitions.
  final bool timed;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleLabel,
    required this.category,
    required this.equipment,
    required this.muscles,
    this.timed = false,
  });
}

class PlanItem {
  String exerciseId;
  int sets;

  /// Repetitions, or seconds when the exercise is timed.
  int reps;
  int restSec;

  /// true = no rest after this item, the next item follows directly.
  bool supersetWithNext;

  PlanItem({
    required this.exerciseId,
    this.sets = 3,
    this.reps = 10,
    this.restSec = 60,
    this.supersetWithNext = false,
  });

  PlanItem copy() {
    return PlanItem(
      exerciseId: exerciseId,
      sets: sets,
      reps: reps,
      restSec: restSec,
      supersetWithNext: supersetWithNext,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
      'restSec': restSec,
      'superset': supersetWithNext,
    };
  }

  static PlanItem fromJson(Map<String, dynamic> j) {
    return PlanItem(
      exerciseId: j['exerciseId'] as String,
      sets: (j['sets'] as num?)?.toInt() ?? 3,
      reps: (j['reps'] as num?)?.toInt() ?? 10,
      restSec: (j['restSec'] as num?)?.toInt() ?? 60,
      supersetWithNext: (j['superset'] as bool?) ?? false,
    );
  }
}

class Plan {
  String id;
  String name;
  List<PlanItem> items;

  Plan({required this.id, required this.name, required this.items});

  /// Rough length of the plan in minutes.
  int get estimatedMinutes {
    int seconds = 0;
    for (final PlanItem it in items) {
      seconds += it.sets * (45 + (it.supersetWithNext ? 0 : it.restSec));
    }
    final int m = (seconds / 60).round();
    return m < 1 ? 1 : m;
  }

  Plan copy() {
    return Plan(id: id, name: name, items: items.map((PlanItem e) => e.copy()).toList());
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'items': items.map((PlanItem e) => e.toJson()).toList(),
    };
  }

  static Plan fromJson(Map<String, dynamic> j) {
    final List<dynamic> raw = (j['items'] as List<dynamic>?) ?? <dynamic>[];
    return Plan(
      id: '${j['id']}',
      name: (j['name'] as String?) ?? 'Plan',
      items: raw.map((dynamic e) => PlanItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}

class Stretch {
  final String id;
  final String name;

  /// Coverage group shown under "Heute angesprochen".
  final String group;
  final List<Muscle> muscles;
  final int seconds;
  final List<String> steps;

  const Stretch({
    required this.id,
    required this.name,
    required this.group,
    required this.muscles,
    required this.seconds,
    required this.steps,
  });
}

class StretchSettings {
  bool enabled;

  /// 1 = Monday ... 7 = Sunday.
  Set<int> weekdays;
  int startHour;
  int endHour;
  int intervalMin;

  StretchSettings({
    this.enabled = false,
    Set<int>? weekdays,
    this.startHour = 9,
    this.endHour = 17,
    this.intervalMin = 120,
  }) : weekdays = weekdays ?? <int>{1, 2, 3, 4, 5};

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enabled': enabled,
      'weekdays': weekdays.toList(),
      'startHour': startHour,
      'endHour': endHour,
      'intervalMin': intervalMin,
    };
  }

  static StretchSettings fromJson(Map<String, dynamic> j) {
    final List<dynamic> days = (j['weekdays'] as List<dynamic>?) ?? <dynamic>[1, 2, 3, 4, 5];
    return StretchSettings(
      enabled: (j['enabled'] as bool?) ?? false,
      weekdays: days.map((dynamic e) => (e as num).toInt()).toSet(),
      startHour: (j['startHour'] as num?)?.toInt() ?? 9,
      endHour: (j['endHour'] as num?)?.toInt() ?? 17,
      intervalMin: (j['intervalMin'] as num?)?.toInt() ?? 120,
    );
  }

  /// All reminder times of one calendar day, oldest first.
  List<DateTime> slotsFor(DateTime day) {
    final List<DateTime> out = <DateTime>[];
    if (!weekdays.contains(day.weekday) || intervalMin <= 0) {
      return out;
    }
    int minutes = startHour * 60;
    final int end = endHour * 60;
    while (minutes <= end) {
      out.add(DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60));
      minutes += intervalMin;
    }
    return out;
  }

  /// Upcoming reminder times within the next [days] days.
  List<DateTime> upcoming({int days = 7}) {
    final DateTime now = DateTime.now();
    final List<DateTime> out = <DateTime>[];
    if (!enabled) {
      return out;
    }
    for (int d = 0; d < days; d++) {
      final DateTime day = DateTime(now.year, now.month, now.day + d);
      for (final DateTime t in slotsFor(day)) {
        if (t.isAfter(now)) {
          out.add(t);
        }
      }
    }
    return out;
  }
}

/// What the user told the coach once. Saved so the questions are not asked again.
class CoachProfile {
  List<String> styles;
  String goal;
  String level;
  int days;
  int minutes;

  /// False until the user finished the set-up once.
  bool done;

  CoachProfile({
    List<String>? styles,
    this.goal = 'Muskelaufbau',
    this.level = 'Anfänger',
    this.days = 3,
    this.minutes = 60,
    this.done = false,
  }) : styles = styles ?? <String>['Ganzkörper'];

  CoachProfile copy() {
    return CoachProfile(
      styles: List<String>.from(styles),
      goal: goal,
      level: level,
      days: days,
      minutes: minutes,
      done: done,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'styles': styles,
        'goal': goal,
        'level': level,
        'days': days,
        'minutes': minutes,
        'done': done,
      };

  factory CoachProfile.fromJson(Map<String, dynamic> j, List<String> knownStyles) {
    final List<dynamic> raw = (j['styles'] as List<dynamic>?) ?? <dynamic>[];
    final List<String> styles = raw.map((dynamic e) => '$e').where(knownStyles.contains).toList();
    return CoachProfile(
      styles: styles.isEmpty ? null : styles,
      goal: (j['goal'] as String?) ?? 'Muskelaufbau',
      level: (j['level'] as String?) ?? 'Anfänger',
      days: (j['days'] as num?)?.toInt() ?? 3,
      minutes: (j['minutes'] as num?)?.toInt() ?? 60,
      done: j['done'] == true,
    );
  }
}
