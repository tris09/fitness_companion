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

  /// Time limit per set in seconds ("as many as you can, at most X s").
  /// 0 = normal set with fixed reps. Then [reps] is the target shown as info.
  /// Time not used is added to the following rest.
  int workSec;

  PlanItem({
    required this.exerciseId,
    this.sets = 3,
    this.reps = 10,
    this.restSec = 60,
    this.supersetWithNext = false,
    this.workSec = 0,
  });

  PlanItem copy() {
    return PlanItem(
      exerciseId: exerciseId,
      sets: sets,
      reps: reps,
      restSec: restSec,
      supersetWithNext: supersetWithNext,
      workSec: workSec,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
      'restSec': restSec,
      'superset': supersetWithNext,
      'workSec': workSec,
    };
  }

  static PlanItem fromJson(Map<String, dynamic> j) {
    return PlanItem(
      exerciseId: j['exerciseId'] as String,
      sets: (j['sets'] as num?)?.toInt() ?? 3,
      reps: (j['reps'] as num?)?.toInt() ?? 10,
      restSec: (j['restSec'] as num?)?.toInt() ?? 60,
      supersetWithNext: (j['superset'] as bool?) ?? false,
      workSec: (j['workSec'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Every storage limit of the app in one place ("Gesamtmax").
/// Everything with a date follows the same rule: kept for [keepDays] back,
/// planned at most [aheadDays] ahead. Counts are hard caps on top of that.
class DataLimits {
  /// Workouts, weights, body data, calendar entries and day plans: 6 months back.
  static const int keepDays = 183;

  /// The calendar can be planned at most 6 months ahead.
  static const int aheadDays = 183;

  /// The newest workouts stay even when older than [keepDays].
  static const int keepWorkoutsAlways = 5;

  /// Plans that belong to one calendar day (not shown under "Pläne").
  static const int maxDayPlans = 250;

  /// Calendar entries in total.
  static const int maxUnits = 500;

  /// Coach chat messages on the device (the coach itself only gets the last 8).
  static const int maxChat = 60;

  /// Facts the coach remembers.
  static const int maxMemory = 20;

  /// Shopping lists.
  static const int maxShoppingLists = 5;

  /// First and last day that may hold calendar entries, from today.
  static DateTime get firstDay {
    final DateTime n = DateTime.now();
    return DateTime(n.year, n.month, n.day - keepDays);
  }

  static DateTime get lastDay {
    final DateTime n = DateTime.now();
    return DateTime(n.year, n.month, n.day + aheadDays);
  }
}

class Plan {
  String id;
  String name;
  List<PlanItem> items;

  /// Calendar day ('yyyy-m-d') when the plan belongs to one day only.
  /// Null = template: listed under "Pläne" and usable on any day.
  String? day;

  Plan({required this.id, required this.name, required this.items, this.day});

  bool get isTemplate => day == null;

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
    return Plan(id: id, name: name, items: items.map((PlanItem e) => e.copy()).toList(), day: day);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'items': items.map((PlanItem e) => e.toJson()).toList(),
      if (day != null) 'day': day,
    };
  }

  static Plan fromJson(Map<String, dynamic> j) {
    final List<dynamic> raw = (j['items'] as List<dynamic>?) ?? <dynamic>[];
    return Plan(
      id: '${j['id']}',
      name: (j['name'] as String?) ?? 'Plan',
      items: raw.map((dynamic e) => PlanItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      day: (j['day'] as String?)?.isNotEmpty == true ? j['day'] as String : null,
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
/// Choices of the coach set-up. Shared by the set-up, the settings and the coach's proposals.
const List<String> kCoachGoals = <String>['Muskelaufbau', 'Fett verlieren', 'Fit bleiben', 'Kraft'];
const List<String> kCoachLevels = <String>['Anfänger', 'Etwas Erfahrung', 'Erfahren'];

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

  /// Real duration in minutes (start to finish). 0 for older entries.
  final int minutes;

  WorkoutLog({required this.date, required this.planName, required this.items, this.minutes = 0});

  /// Compact form: date as day number, items as [id, sets, reps].
  Map<String, dynamic> toJson() => <String, dynamic>{
        'd': dayNumber(date),
        'n': planName,
        'i': items.map((PlanItem e) => <dynamic>[e.exerciseId, e.sets, e.reps]).toList(),
        if (minutes > 0) 'm': minutes,
      };

  /// Reads the compact form and the older long form.
  factory WorkoutLog.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('d')) {
      final List<dynamic> raw = (j['i'] as List<dynamic>?) ?? <dynamic>[];
      return WorkoutLog(
        date: dateOfDayNumber((j['d'] as num).toInt()),
        planName: '${j['n'] ?? ''}',
        items: <PlanItem>[
          for (final dynamic e in raw)
            if (e is List && e.length >= 3)
              PlanItem(exerciseId: '${e[0]}', sets: (e[1] as num).toInt(), reps: (e[2] as num).toInt(), restSec: 60),
        ],
        minutes: (j['m'] as num?)?.toInt() ?? 0,
      );
    }
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

  /// Proposed change of the coach settings (JSON), or empty.
  final String settingsJson;

  /// '' = open, 'accepted' or 'declined'.
  String settingsState;

  ChatMessage({
    required this.role,
    required this.text,
    this.programJson = '',
    this.saved = false,
    this.listJson = '',
    this.listSaved = false,
    List<String>? sources,
    this.settingsJson = '',
    this.settingsState = '',
  }) : sources = sources ?? <String>[];

  Map<String, dynamic> toJson() => <String, dynamic>{
        'role': role,
        'text': text,
        'program': programJson,
        'saved': saved,
        'list': listJson,
        'listSaved': listSaved,
        'sources': sources,
        if (settingsJson.isNotEmpty) 'settings': settingsJson,
        if (settingsState.isNotEmpty) 'settingsState': settingsState,
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
      settingsJson: '${j['settings'] ?? ''}',
      settingsState: '${j['settingsState'] ?? ''}',
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

  static const List<String> _feels = <String>['', 'leicht', 'passt', 'schwer'];

  /// Compact form to keep 6 months small: [day number, kg x 10, reps, feel code].
  List<int> toJson() => <int>[dayNumber(date), (kg * 10).round(), reps, _feels.indexOf(feel).clamp(0, 3)];

  /// Reads the compact list and the older map form.
  factory WeightEntry.fromJson(dynamic j) {
    if (j is List && j.length >= 3) {
      final int f = j.length > 3 ? (j[3] as num).toInt() : 0;
      return WeightEntry(
        date: dateOfDayNumber((j[0] as num).toInt()),
        kg: (j[1] as num).toDouble() / 10,
        reps: (j[2] as num).toInt(),
        feel: _feels[f.clamp(0, 3)],
      );
    }
    final Map<String, dynamic> m = Map<String, dynamic>.from(j as Map);
    return WeightEntry(
      date: DateTime.tryParse('${m['date']}') ?? DateTime.now(),
      kg: (m['kg'] as num?)?.toDouble() ?? 0,
      reps: (m['reps'] as num?)?.toInt() ?? 0,
      feel: '${m['feel'] ?? ''}',
    );
  }
}

/// Days since 1.1.2020. Small numbers for compact storage.
int dayNumber(DateTime d) => DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2020)).inDays;
DateTime dateOfDayNumber(int n) {
  final DateTime u = DateTime.utc(2020).add(Duration(days: n));
  return DateTime(u.year, u.month, u.day);
}

/// One body measurement. Weight is required, the rest optional.
class BodyEntry {
  final DateTime date;
  final double weightKg;
  final double? fatPercent;
  final double? waistCm;

  const BodyEntry({required this.date, required this.weightKg, this.fatPercent, this.waistCm});

  /// [day number, kg x 10, fat x 10 or -1, waist x 10 or -1]
  List<int> toJson() => <int>[
        dayNumber(date),
        (weightKg * 10).round(),
        fatPercent == null ? -1 : (fatPercent! * 10).round(),
        waistCm == null ? -1 : (waistCm! * 10).round(),
      ];

  static BodyEntry? fromJson(dynamic j) {
    if (j is! List || j.length < 2) {
      return null;
    }
    double? opt(int i) => j.length > i && (j[i] as num) >= 0 ? (j[i] as num).toDouble() / 10 : null;
    return BodyEntry(
      date: dateOfDayNumber((j[0] as num).toInt()),
      weightKg: (j[1] as num).toDouble() / 10,
      fatPercent: opt(2),
      waistCm: opt(3),
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

/// One planned unit on a calendar day. A day can hold several.
class ScheduledUnit {
  final String id;

  /// Day as 'yyyy-m-d' (same format as the rest of the app).
  final String day;
  final String planId;

  /// Minutes after midnight, or null when no time was given.
  final int? minute;

  ScheduledUnit({required this.id, required this.day, required this.planId, this.minute});

  /// A reminder is sent 30 minutes before, only when a time is set.
  bool get hasTime => minute != null;

  String get timeText {
    if (minute == null) {
      return '';
    }
    final int h = minute! ~/ 60;
    final int m = minute! % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'day': day, 'planId': planId, 'minute': minute};

  static ScheduledUnit? fromJson(Map<String, dynamic> j) {
    final String day = (j['day'] as String?) ?? '';
    final String planId = '${j['planId'] ?? ''}';
    if (day.isEmpty || planId.isEmpty) {
      return null;
    }
    final dynamic m = j['minute'];
    return ScheduledUnit(
      id: '${j['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      day: day,
      planId: planId,
      minute: m is num ? m.toInt().clamp(0, 24 * 60 - 1) : null,
    );
  }
}

/// Parts of the app the user can switch on and off. Training planning is always on.
class AppFeatures {
  bool coach;
  bool tracking;
  bool stretch;
  bool food;
  bool news;

  AppFeatures({this.coach = true, this.tracking = true, this.stretch = true, this.food = true, this.news = true});

  AppFeatures copy() => AppFeatures(coach: coach, tracking: tracking, stretch: stretch, food: food, news: news);

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'coach': coach, 'tracking': tracking, 'stretch': stretch, 'food': food, 'news': news};

  static AppFeatures fromJson(Map<String, dynamic> j) => AppFeatures(
        coach: j['coach'] != false,
        tracking: j['tracking'] != false,
        stretch: j['stretch'] != false,
        food: j['food'] != false,
        news: j['news'] != false,
      );
}

/// Blocks on Home that the user can move. News is not in the list: it is always last.
const List<String> kHomeBlocks = <String>['calendar', 'ad', 'tiles'];
