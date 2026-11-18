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

/// Settings of the stretch plan. The plan runs either on fixed weekdays,
/// or only today, or both. The stretches are spread evenly over the day.
class StretchSettings {
  /// Plan on the fixed weekdays below.
  bool enabled;

  /// 1 = Monday ... 7 = Sunday.
  Set<int> weekdays;
  int startHour;
  int endHour;

  /// Number of stretches per day.
  int perDay;

  /// Day key (y-m-d) when the plan was switched on for that single day. Empty if not.
  String todayKey;

  /// Raised by "Neu würfeln". Only counts on the day stored in [rerollKey].
  int reroll;
  String rerollKey;

  StretchSettings({
    this.enabled = false,
    Set<int>? weekdays,
    this.startHour = 9,
    this.endHour = 17,
    this.perDay = 4,
    this.todayKey = '',
    this.reroll = 0,
    this.rerollKey = '',
  }) : weekdays = weekdays ?? <int>{1, 2, 3, 4, 5};

  static String keyOf(DateTime d) => '${d.year}-${d.month}-${d.day}';

  StretchSettings copy() {
    return StretchSettings(
      enabled: enabled,
      weekdays: Set<int>.from(weekdays),
      startHour: startHour,
      endHour: endHour,
      perDay: perDay,
      todayKey: todayKey,
      reroll: reroll,
      rerollKey: rerollKey,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enabled': enabled,
      'weekdays': weekdays.toList(),
      'startHour': startHour,
      'endHour': endHour,
      'perDay': perDay,
      'todayKey': todayKey,
      'reroll': reroll,
      'rerollKey': rerollKey,
    };
  }

  static StretchSettings fromJson(Map<String, dynamic> j) {
    final List<dynamic> days = (j['weekdays'] as List<dynamic>?) ?? <dynamic>[1, 2, 3, 4, 5];
    return StretchSettings(
      enabled: (j['enabled'] as bool?) ?? false,
      weekdays: days.map((dynamic e) => (e as num).toInt()).toSet(),
      startHour: (j['startHour'] as num?)?.toInt() ?? 9,
      endHour: (j['endHour'] as num?)?.toInt() ?? 17,
      perDay: ((j['perDay'] as num?)?.toInt() ?? 4).clamp(1, 12),
      todayKey: (j['todayKey'] as String?) ?? '',
      reroll: (j['reroll'] as num?)?.toInt() ?? 0,
      rerollKey: (j['rerollKey'] as String?) ?? '',
    );
  }

  /// True when the plan runs on this day.
  bool activeOn(DateTime day) {
    return (enabled && weekdays.contains(day.weekday)) || todayKey == keyOf(day);
  }

  /// True when anything is switched on that still lies ahead.
  bool get anyActive => enabled || todayKey == keyOf(DateTime.now());

  /// Times of the plan on one day, spread evenly between start and end.
  /// Example: 9 to 17 with 4 stretches gives 10:00, 12:00, 14:00, 16:00.
  List<DateTime> slotsFor(DateTime day) {
    final List<DateTime> out = <DateTime>[];
    if (perDay <= 0) {
      return out;
    }
    final int start = startHour * 60;
    final int span = (endHour - startHour) * 60;
    for (int i = 0; i < perDay; i++) {
      final int m = start + (span * (2 * i + 1) / (2 * perDay)).round();
      out.add(DateTime(day.year, day.month, day.day, m ~/ 60, m % 60));
    }
    return out;
  }

  /// Seed for the random stretches of one day. Same day, same plan.
  int seedFor(DateTime day) {
    final int base = day.year * 10000 + day.month * 100 + day.day;
    return base * 31 + (rerollKey == keyOf(day) ? reroll : 0);
  }

  /// Upcoming push times within the next [days] days.
  List<DateTime> upcoming({int days = 7}) {
    final DateTime now = DateTime.now();
    final List<DateTime> out = <DateTime>[];
    for (int d = 0; d < days; d++) {
      final DateTime day = DateTime(now.year, now.month, now.day + d);
      if (!activeOn(day)) {
        continue;
      }
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

  /// True = the coach chooses goal, styles and volume on its own.
  bool aiDecides;

  /// False until the user finished the set-up once.
  bool done;

  CoachProfile({
    this.aiDecides = false,
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
      aiDecides: aiDecides,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'aiDecides': aiDecides,
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
      aiDecides: j['aiDecides'] == true,
    );
  }
}

/// Body data the user entered once. The coach uses it for its suggestions.
class BodyProfile {
  double weightKg;
  int heightCm;
  int age;

  /// False until the user finished the profile screen once.
  bool done;

  BodyProfile({this.weightKg = 75, this.heightCm = 175, this.age = 25, this.done = false});

  BodyProfile copy() => BodyProfile(weightKg: weightKg, heightCm: heightCm, age: age, done: done);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'weightKg': weightKg,
        'heightCm': heightCm,
        'age': age,
        'done': done,
      };

  factory BodyProfile.fromJson(Map<String, dynamic> j) {
    return BodyProfile(
      weightKg: (j['weightKg'] as num?)?.toDouble() ?? 75,
      heightCm: (j['heightCm'] as num?)?.toInt() ?? 175,
      age: (j['age'] as num?)?.toInt() ?? 25,
      done: j['done'] == true,
    );
  }
}

/// One finished workout. The coach reads the last ones as its memory.
class WorkoutLog {
  final DateTime date;
  final String planName;

  /// Exercises as done: id, sets, reps.
  final List<PlanItem> items;

  WorkoutLog({required this.date, required this.planName, required this.items});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'date': date.toIso8601String(),
        'planName': planName,
        'items': items.map((PlanItem e) => e.toJson()).toList(),
      };

  factory WorkoutLog.fromJson(Map<String, dynamic> j) {
    final List<dynamic> raw = (j['items'] as List<dynamic>?) ?? <dynamic>[];
    return WorkoutLog(
      date: DateTime.tryParse('${j['date']}') ?? DateTime.now(),
      planName: '${j['planName'] ?? ''}',
      items: raw.map((dynamic e) => PlanItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}

/// One message in the coach chat.
class ChatMessage {
  /// 'user' or 'model'.
  final String role;
  final String text;

  /// Cleaned JSON of a plan the coach created in this message. Empty if none.
  final String programJson;

  /// True once the user added the plan to the plan list.
  bool saved;

  /// Cleaned JSON of a shopping list the coach created. Empty if none.
  final String listJson;

  /// True once the user took over the shopping list.
  bool listSaved;

  /// Web sources the coach used for local offers.
  final List<String> sources;

  ChatMessage({
    required this.role,
    required this.text,
    this.programJson = '',
    this.saved = false,
    this.listJson = '',
    this.listSaved = false,
    List<String>? sources,
  }) : sources = sources ?? <String>[];

  Map<String, dynamic> toJson() => <String, dynamic>{
        'role': role,
        'text': text,
        'program': programJson,
        'saved': saved,
        'list': listJson,
        'listSaved': listSaved,
        'sources': sources,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    return ChatMessage(
      role: j['role'] == 'model' ? 'model' : 'user',
      text: '${j['text'] ?? ''}',
      programJson: '${j['program'] ?? ''}',
      saved: j['saved'] == true,
      listJson: '${j['list'] ?? ''}',
      listSaved: j['listSaved'] == true,
      sources: ((j['sources'] as List<dynamic>?) ?? <dynamic>[]).map((dynamic e) => '$e').toList(),
    );
  }
}

/// Shelf groups of the shopping list, in shop order.
const List<String> kShoppingCategories = <String>[
  'Obst & Gemüse',
  'Fleisch & Fisch',
  'Milch & Eier',
  'Brot & Getreide',
  'Vorrat',
  'Tiefkühl',
  'Getränke',
  'Sonstiges',
];

/// One line on the shopping list.
class ShoppingItem {
  String name;
  String amount;

  /// Shelf group, e.g. 'Obst & Gemüse'. Used to sort the list.
  String category;

  /// Offer info from the local search, e.g. 'Lidl, 1,29 € statt 1,79 €'. Empty if none.
  String offer;
  bool done;

  ShoppingItem({required this.name, this.amount = '', this.category = 'Sonstiges', this.offer = '', this.done = false});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'amount': amount,
        'category': category,
        'offer': offer,
        'done': done,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> j) {
    return ShoppingItem(
      name: '${j['name'] ?? ''}'.trim(),
      amount: '${j['amount'] ?? ''}'.trim(),
      category: '${j['category'] ?? ''}'.trim().isEmpty ? 'Sonstiges' : '${j['category']}'.trim(),
      offer: '${j['offer'] ?? ''}'.trim(),
      done: j['done'] == true,
    );
  }
}

class ShoppingList {
  String title;
  DateTime created;
  List<ShoppingItem> items;

  /// Short tips from the coach, e.g. which meals the list is for.
  String note;

  ShoppingList({required this.title, required this.created, required this.items, this.note = ''});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'created': created.toIso8601String(),
        'items': items.map((ShoppingItem e) => e.toJson()).toList(),
        'note': note,
      };

  factory ShoppingList.fromJson(Map<String, dynamic> j) {
    final List<dynamic> raw = (j['items'] as List<dynamic>?) ?? <dynamic>[];
    return ShoppingList(
      title: '${j['title'] ?? ''}'.trim().isEmpty ? 'Einkaufsliste' : '${j['title']}'.trim(),
      created: DateTime.tryParse('${j['created']}') ?? DateTime.now(),
      items: raw
          .whereType<Map>()
          .map((Map e) => ShoppingItem.fromJson(Map<String, dynamic>.from(e)))
          .where((ShoppingItem e) => e.name.isNotEmpty)
          .toList(),
      note: '${j['note'] ?? ''}',
    );
  }
}

/// Where the user shops. Used to look up local offers.
class ShopSettings {
  /// Postcode or town, e.g. '5020 Salzburg'.
  String place;

  /// Preferred supermarkets. Empty means: all nearby.
  List<String> stores;

  ShopSettings({this.place = '', List<String>? stores}) : stores = stores ?? <String>[];

  Map<String, dynamic> toJson() => <String, dynamic>{'place': place, 'stores': stores};

  factory ShopSettings.fromJson(Map<String, dynamic> j) {
    return ShopSettings(
      place: '${j['place'] ?? ''}',
      stores: ((j['stores'] as List<dynamic>?) ?? <dynamic>[]).map((dynamic e) => '$e').toList(),
    );
  }
}

/// One logged weight of an exercise.
class WeightEntry {
  final DateTime date;
  final double kg;
  final int reps;

  /// 'leicht', 'passt', 'schwer' or '' when the user did not say.
  final String feel;

  const WeightEntry({required this.date, required this.kg, required this.reps, this.feel = ''});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'date': date.toIso8601String(),
        'kg': kg,
        'reps': reps,
        'feel': feel,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> j) {
    return WeightEntry(
      date: DateTime.tryParse('${j['date']}') ?? DateTime.now(),
      kg: (j['kg'] as num?)?.toDouble() ?? 0,
      reps: (j['reps'] as num?)?.toInt() ?? 0,
      feel: '${j['feel'] ?? ''}',
    );
  }
}

/// Main muscle groups the app keeps track of.
const List<String> kMuscleGroups = <String>['Beine', 'Brust', 'Rücken', 'Schultern', 'Arme', 'Core'];

/// Formats kilograms the German way: 42,5 kg or 40 kg.
String formatKg(double kg) {
  final String n = kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
  return '${n.replaceAll('.', ',')} kg';
}
