import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog.dart';
import 'models.dart';
import 'services/auth_service.dart';
import 'services/coach_service.dart';
import 'services/google_auth.dart';
import 'services/notifications.dart';
import 'services/secrets.dart';
import 'training_memory.dart';

/// Holds all app data and saves it on the device.
class AppState extends ChangeNotifier {
  static const String _key = 'app_state_v1';

  /// Swap these two for server versions later.
  final AuthService auth = LocalAuthService();
  final CoachService coach = GeminiCoachService();

  AuthUser? user;
  List<Plan> plans = <Plan>[];
  ThemeMode themeMode = ThemeMode.system;

  /// Background style per mode: light 'stone' | 'white' | 'blue', dark 'black' | 'grey' | 'blue'.
  String lightStyle = 'white';
  String darkStyle = 'black';

  /// First name, asked on the first page after login. Shown as "Hi, Name".
  String firstName = '';

  /// Black/white, thick borders, no title bar. For low vision.
  bool highContrast = false;

  /// Text size factor: 0.9, 1.0 or 1.15.
  double textScale = 1.0;

  /// Master switch for all push messages.
  bool pushEnabled = true;

  /// Reminder 30 minutes before a planned unit with a time.
  bool trainingReminders = true;

  /// Planned units in the calendar. Several per day are allowed.
  List<ScheduledUnit> schedule = <ScheduledUnit>[];

  /// 'drag' = two lists with drag and drop, 'list' = vertical editor with buttons.
  String plannerMode = 'drag';

  /// Gemini model name. Corrected on its own when the API reports another one.
  String coachModel = kDefaultCoachModel;

  /// JSON of the last programme the coach created.
  String lastProgramJson = '';

  /// Answers of the coach set-up. Asked once, changed only on request.
  CoachProfile coachProfile = CoachProfile();
  BodyProfile body = BodyProfile();

  /// The last finished workouts, newest last. The coach reads them as memory.
  List<WorkoutLog> history = <WorkoutLog>[];

  /// Keep rule for all logged values (workouts, weights, body data, calendar,
  /// day plans): see [DataLimits]. The coach does not get all of it:
  /// coach_context.dart sends a short summary.
  static const int keepDays = DataLimits.keepDays;
  static const int _keepCount = DataLimits.keepWorkoutsAlways;

  /// Workouts per week (key = Monday of the week). Kept for the streak, not deleted with the history.
  Map<String, int> weeks = <String, int>{};

  /// Best weight per exercise ever logged. Kept even when old weight entries are dropped.
  Map<String, double> records = <String, double>{};

  /// Muscle group -> last training day. Kept on its own, so it survives the clean-up.
  Map<String, DateTime> muscleLast = <String, DateTime>{};

  /// Logged weights per exercise id, newest last. Kept for 6 months.
  Map<String, List<WeightEntry>> weights = <String, List<WeightEntry>>{};

  /// Ask for the used weights after a workout. The user can switch it off.
  bool askWeights = true;

  /// Body weight and measurements over time, oldest first. Kept for 6 months.
  List<BodyEntry> bodyLog = <BodyEntry>[];

  /// Weekly reminder to log the body weight (Monday 08:00).
  bool bodyReminder = true;

  /// Weekly summary of progress on the statistics page. Off by default.
  bool weeklySummary = false;

  /// Last weekly summary of the coach and the week it belongs to (Monday key).
  String summaryText = '';
  String summaryWeek = '';

  /// Parts of the app the user chose. Can be changed in the settings at any time.
  AppFeatures features = AppFeatures();

  /// False until the user went through the feature choice once.
  bool featuresChosen = false;

  /// Order of the movable blocks on Home. News stays below them.
  List<String> homeOrder = List<String>.of(kHomeBlocks);

  /// Two stretches before and after each workout.
  bool warmup = true;

  /// True once the welcome tips were shown.
  bool welcomeSeen = false;

  /// Short facts the coach should keep in mind, e.g. 'Knie schonen'.
  List<String> memory = <String>[];
  static const int _maxMemory = DataLimits.maxMemory;

  /// Shopping lists, newest first.
  List<ShoppingList> shopping = <ShoppingList>[];
  ShopSettings shop = ShopSettings();

  /// The coach chat, newest last.
  List<ChatMessage> chat = <ChatMessage>[];
  static const int _maxChat = DataLimits.maxChat;
  StretchSettings stretch = StretchSettings();
  String stretchDay = '';
  List<String> stretchDone = <String>[];

  final Random _random = Random();

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> j = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final List<dynamic> rawPlans = (j['plans'] as List<dynamic>?) ?? <dynamic>[];
        plans = rawPlans.map((dynamic e) => Plan.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        final String mode = (j['themeMode'] as String?) ?? 'system';
        themeMode = mode == 'light' ? ThemeMode.light : (mode == 'dark' ? ThemeMode.dark : ThemeMode.system);
        lightStyle = const <String>['stone', 'white', 'blue'].contains(j['lightStyle']) ? j['lightStyle'] as String : 'white';
        // Before v21 Stein was the default. Move everyone once to the new default Weiß.
        if (((j['styleV'] as num?) ?? 0) < 2) {
          lightStyle = 'white';
        }
        firstName = (j['firstName'] as String?) ?? '';
        darkStyle = const <String>['black', 'grey', 'blue'].contains(j['darkStyle']) ? j['darkStyle'] as String : 'black';
        highContrast = j['highContrast'] == true;
        final dynamic ts = j['textScale'];
        textScale = ts is num && <double>[0.9, 1.0, 1.15].contains(ts.toDouble()) ? ts.toDouble() : 1.0;
        pushEnabled = j['pushEnabled'] != false;
        trainingReminders = j['trainingReminders'] != false;
        schedule = <ScheduledUnit>[];
        for (final dynamic e in (j['schedule'] as List<dynamic>?) ?? <dynamic>[]) {
          if (e is Map) {
            final ScheduledUnit? u = ScheduledUnit.fromJson(Map<String, dynamic>.from(e));
            if (u != null) {
              schedule.add(u);
            }
          }
        }
        plannerMode = (j['plannerMode'] as String?) == 'list' ? 'list' : 'drag';
        coachModel = (j['coachModel'] as String?) ?? kDefaultCoachModel;
        // Version 10: switch old saved defaults to the Lite model once.
        if (j['modelV'] != 10) {
          coachModel = kDefaultCoachModel;
        }
        lastProgramJson = (j['lastProgram'] as String?) ?? '';
        if (j['coachProfile'] != null) {
          coachProfile = CoachProfile.fromJson(Map<String, dynamic>.from(j['coachProfile'] as Map), trainingStyles);
        }
        if (j['body'] != null) {
          body = BodyProfile.fromJson(Map<String, dynamic>.from(j['body'] as Map));
        }
        final List<dynamic> rawHistory = (j['history'] as List<dynamic>?) ?? <dynamic>[];
        history = rawHistory.map((dynamic e) => WorkoutLog.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        final Map<String, dynamic> rawLast = Map<String, dynamic>.from((j['muscleLast'] as Map?) ?? <String, dynamic>{});
        muscleLast = <String, DateTime>{
          for (final MapEntry<String, dynamic> e in rawLast.entries)
            if (DateTime.tryParse('${e.value}') != null) e.key: DateTime.parse('${e.value}'),
        };
        for (final WorkoutLog w in history) {
          markTrained(muscleLast, w);
        }
        weeks = Map<String, dynamic>.from((j['weeks'] as Map?) ?? <String, dynamic>{})
            .map((String k, dynamic v) => MapEntry<String, int>(k, (v as num).toInt()));
        records = Map<String, dynamic>.from((j['records'] as Map?) ?? <String, dynamic>{})
            .map((String k, dynamic v) => MapEntry<String, double>(k, (v as num).toDouble()));
        _pruneHistory();
        final Map<String, dynamic> rawW = Map<String, dynamic>.from((j['weights'] as Map?) ?? <String, dynamic>{});
        weights = rawW.map((String k, dynamic v) => MapEntry<String, List<WeightEntry>>(
              k,
              ((v as List<dynamic>?) ?? <dynamic>[]).map((dynamic e) => WeightEntry.fromJson(e)).toList(),
            ));
        _pruneValues();
        askWeights = j['askWeights'] != false;
        bodyLog = <BodyEntry>[
          for (final dynamic e in (j['bodyLog'] as List<dynamic>?) ?? <dynamic>[])
            if (BodyEntry.fromJson(e) != null) BodyEntry.fromJson(e)!,
        ];
        bodyReminder = j['bodyReminder'] != false;
        weeklySummary = j['weeklySummary'] == true;
        // Apply the data limits once at start: old calendar entries and their day plans go.
        _pruneSchedule();
        summaryText = (j['summaryText'] as String?) ?? '';
        summaryWeek = (j['summaryWeek'] as String?) ?? '';
        if (j['features'] is Map) {
          features = AppFeatures.fromJson(Map<String, dynamic>.from(j['features'] as Map));
        }
        // Users from before the feature choice already set everything up: do not ask again.
        featuresChosen = j['featuresChosen'] == true || j['features'] == null && (j['body'] != null);
        final List<String> order = ((j['homeOrder'] as List<dynamic>?) ?? <dynamic>[]).map((dynamic e) => '$e').toList();
        homeOrder = _validOrder(order);
        warmup = j['warmup'] != false;
        welcomeSeen = j['welcomeSeen'] == true;
        memory = ((j['memory'] as List<dynamic>?) ?? <dynamic>[]).map((dynamic e) => '$e').toList();
        final List<dynamic> rawShopping = (j['shopping'] as List<dynamic>?) ?? <dynamic>[];
        shopping = rawShopping.map((dynamic e) => ShoppingList.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        if (j['shop'] != null) {
          shop = ShopSettings.fromJson(Map<String, dynamic>.from(j['shop'] as Map));
        }
        final List<dynamic> rawChat = (j['chat'] as List<dynamic>?) ?? <dynamic>[];
        chat = rawChat.map((dynamic e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        if (j['stretch'] != null) {
          stretch = StretchSettings.fromJson(Map<String, dynamic>.from(j['stretch'] as Map));
        }
        stretchDay = (j['stretchDay'] as String?) ?? '';
        final List<dynamic> done = (j['stretchDone'] as List<dynamic>?) ?? <dynamic>[];
        stretchDone = done.map((dynamic e) => e as String).toList();
        final String? email = j['email'] as String?;
        if (email != null && email.isNotEmpty) {
          user = email == kTestEmail
              ? auth.testUser
              : (email == kLocalUser ? const AuthUser(email: kLocalUser, isAdmin: false) : auth.userFor(email));
        }
      } else {
        plans = <Plan>[_samplePlan()];
      }
    } catch (_) {
      plans = <Plan>[_samplePlan()];
    }
    // Older saves have no records yet: take them from the logged weights.
    weights.forEach((String id, List<WeightEntry> list) {
      final double? best = bestWeight(list);
      if (best != null && best > (records[id] ?? 0)) {
        records[id] = best;
      }
    });
    _rollDay();
  }

  Plan _samplePlan() {
    return Plan(
      id: 'sample',
      name: 'Ganzkörper A',
      items: <PlanItem>[
        PlanItem(exerciseId: 'squat', sets: 3, reps: 10, restSec: 90),
        PlanItem(exerciseId: 'bench', sets: 3, reps: 8, restSec: 90),
        PlanItem(exerciseId: 'row', sets: 3, reps: 10, restSec: 60),
        PlanItem(exerciseId: 'ohp', sets: 3, reps: 10, restSec: 60),
        PlanItem(exerciseId: 'plank', sets: 3, reps: 45, restSec: 30),
      ],
    );
  }

  /// All data of the app as one map. Used for saving and for the export.
  Map<String, dynamic> toJson() {
    final String mode = themeMode == ThemeMode.light ? 'light' : (themeMode == ThemeMode.dark ? 'dark' : 'system');
    return <String, dynamic>{
        'plans': plans.map((Plan p) => p.toJson()).toList(),
        'themeMode': mode,
        'plannerMode': plannerMode,
        'coachModel': coachModel,
        'modelV': 10,
        'lastProgram': lastProgramJson,
        'coachProfile': coachProfile.toJson(),
        'body': body.toJson(),
        'lightStyle': lightStyle,
        'styleV': 2,
        'firstName': firstName,
        'darkStyle': darkStyle,
        'highContrast': highContrast,
        'textScale': textScale,
        'pushEnabled': pushEnabled,
        'trainingReminders': trainingReminders,
        'schedule': schedule.map((ScheduledUnit u) => u.toJson()).toList(),
        'history': history.map((WorkoutLog e) => e.toJson()).toList(),
        'weeks': weeks,
        'records': records,
        'muscleLast': muscleLast.map((String k, DateTime v) => MapEntry<String, String>(k, v.toIso8601String())),
        'memory': memory,
        'weights': weights.map((String k, List<WeightEntry> v) => MapEntry<String, dynamic>(k, v.map((WeightEntry e) => e.toJson()).toList())),
        'askWeights': askWeights,
        'bodyLog': bodyLog.map((BodyEntry e) => e.toJson()).toList(),
        'bodyReminder': bodyReminder,
        'weeklySummary': weeklySummary,
        'summaryText': summaryText,
        'summaryWeek': summaryWeek,
        'features': features.toJson(),
        'featuresChosen': featuresChosen,
        'homeOrder': homeOrder,
        'warmup': warmup,
        'welcomeSeen': welcomeSeen,
        'shopping': shopping.map((ShoppingList e) => e.toJson()).toList(),
        'shop': shop.toJson(),
        'chat': chat.map((ChatMessage e) => e.toJson()).toList(),
        'stretch': stretch.toJson(),
        'stretchDay': stretchDay,
        'stretchDone': stretchDone,
        'email': user?.email ?? '',
      };
  }

  /// Readable export of all data, e.g. to copy it somewhere safe.
  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  Future<void> _save() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> j = toJson();
      await prefs.setString(_key, jsonEncode(j));
    } catch (_) {
      // Saving failed. The app keeps working with the data in memory.
    }
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  // ---- Account ----

  /// Each of these returns null when it worked, otherwise a message for the user.
  Future<String?> register(String email, String password) async {
    try {
      user = await auth.register(email, password);
      _changed();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Die Registrierung hat nicht geklappt.';
    }
  }

  Future<String?> signInWithPassword(String email, String password) async {
    try {
      user = await auth.signInWithPassword(email, password);
      _changed();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Die Anmeldung hat nicht geklappt.';
    }
  }

  /// Test login: skips the profile screens. Only works in debug builds.
  void signInAsTest() {
    if (!kDebugMode) {
      return;
    }
    user = auth.testUser;
    body = BodyProfile(weightKg: 75, heightCm: 178, age: 25, done: true);
    coachProfile = CoachProfile(
      styles: <String>['Ganzkörper', 'Calisthenics'],
      goal: 'Muskelaufbau',
      level: 'Etwas Erfahrung',
      days: 3,
      minutes: 45,
      done: true,
    );
    _changed();
  }

  /// Returns null when it worked, otherwise a message for the user.
  Future<String?> signInWithGoogle() async {
    if (!GoogleAuth.isConfigured) {
      return 'Die Google-Anmeldung ist noch nicht eingerichtet.';
    }
    try {
      final String email = await GoogleAuth.signIn();
      user = auth.userFor(email);
      _changed();
      return null;
    } catch (_) {
      return 'Die Google-Anmeldung wurde abgebrochen oder ist fehlgeschlagen.';
    }
  }

  Future<void> signOut() async {
    await GoogleAuth.signOut();
    await auth.signOut();
    user = null;
    _changed();
  }

  /// Local mode: no account, no password. Everything stays on this device.
  void startLocal() {
    user = const AuthUser(email: kLocalUser, isAdmin: false);
    _changed();
  }

  /// Deletes all data of the app on this device, including the API key and local accounts.
  Future<void> deleteEverything() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {
      // Continue with the rest.
    }
    await Secrets.deleteAll();
    resetData();
    themeMode = ThemeMode.system;
    lightStyle = 'white';
    darkStyle = 'black';
    firstName = '';
    highContrast = false;
    textScale = 1.0;
    pushEnabled = true;
    trainingReminders = true;
    plannerMode = 'drag';
    lastProgramJson = '';
    askWeights = true;
    bodyReminder = true;
    weeklySummary = false;
    features = AppFeatures();
    featuresChosen = false;
    homeOrder = List<String>.of(kHomeBlocks);
    warmup = true;
    await signOut();
  }

  /// Admin tool: back to the sample plan and default settings. The login stays.
  void resetData() {
    plans = <Plan>[_samplePlan()];
    stretch = StretchSettings();
    stretchDone = <String>[];
    coachProfile = CoachProfile();
    body = BodyProfile();
    history = <WorkoutLog>[];
    muscleLast = <String, DateTime>{};
    weeks = <String, int>{};
    records = <String, double>{};
    chat = <ChatMessage>[];
    memory = <String>[];
    weights = <String, List<WeightEntry>>{};
    shopping = <ShoppingList>[];
    shop = ShopSettings();
    schedule = <ScheduledUnit>[];
    bodyLog = <BodyEntry>[];
    summaryText = '';
    summaryWeek = '';
    _changed();
    rescheduleReminders();
  }

  // ---- Plans ----

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Plans under "Pläne": templates that can be put on any day.
  List<Plan> get templates => plans.where((Plan p) => p.isTemplate).toList();

  void savePlan(Plan plan) {
    final int i = plans.indexWhere((Plan p) => p.id == plan.id);
    if (i >= 0) {
      plans[i] = plan;
    } else {
      plans.add(plan);
    }
    _changed();
  }

  void deletePlan(String id) {
    plans.removeWhere((Plan p) => p.id == id);
    _pruneSchedule();
    _changed();
    rescheduleReminders();
  }

  void addPlans(List<Plan> list) {
    plans.addAll(list);
    _changed();
  }

  /// Creates a plan that belongs to [day] only and puts it in the calendar.
  /// It is not listed under "Pläne" and is removed with its calendar entry.
  void addDayPlan(DateTime day, Plan plan, {int? minute}) {
    plan.day = _dayKey(day);
    plans.add(plan);
    addUnit(day, plan.id, minute: minute);
  }

  /// True when [day] may hold calendar entries (6 months back to 6 months ahead).
  static bool canPlan(DateTime day) {
    final DateTime d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(DataLimits.firstDay) && !d.isAfter(DataLimits.lastDay);
  }

  // ---- Coach ----

  /// Stores the set-up answers and marks the set-up as finished.
  void saveCoachProfile(CoachProfile profile) {
    coachProfile = profile.copy()..done = true;
    _changed();
  }

  void saveBody(BodyProfile b) {
    final bool changed = (b.weightKg - body.weightKg).abs() > 0.01 || bodyLog.isEmpty;
    body = b.copy()..done = true;
    if (changed) {
      _addBody(BodyEntry(date: DateTime.now(), weightKg: b.weightKg));
    }
    _changed();
  }

  // ---- Body tracking ----

  /// Saves a measurement. One entry per day: a second one the same day replaces the first.
  void logBody(BodyEntry e) {
    _addBody(e);
    body.weightKg = e.weightKg;
    _changed();
  }

  void _addBody(BodyEntry e) {
    bodyLog.removeWhere((BodyEntry x) => dayNumber(x.date) == dayNumber(e.date));
    bodyLog.add(e);
    bodyLog.sort((BodyEntry a, BodyEntry b) => a.date.compareTo(b.date));
    _pruneValues();
  }

  void removeBody(BodyEntry e) {
    bodyLog.remove(e);
    _changed();
  }

  BodyEntry? get lastBody => bodyLog.isEmpty ? null : bodyLog.last;

  /// True when the last body entry is 7 days old or older.
  bool get bodyDue {
    final BodyEntry? l = lastBody;
    return l == null || DateTime.now().difference(l.date).inDays >= 7;
  }

  void setBodyReminder(bool v) {
    bodyReminder = v;
    _changed();
    rescheduleReminders();
  }

  void setWeeklySummary(bool v) {
    weeklySummary = v;
    _changed();
  }

  /// The summary is due from Sunday on, once per week.
  bool get summaryDue {
    final DateTime now = DateTime.now();
    return weeklySummary && now.weekday == DateTime.sunday && summaryWeek != weekKey(now) ||
        weeklySummary && summaryText.isEmpty;
  }

  void saveSummary(String text) {
    summaryText = text.trim();
    summaryWeek = weekKey(DateTime.now());
    _changed();
  }

  // ---- Features and Home layout ----

  void setFeatures(AppFeatures f) {
    features = f.copy();
    featuresChosen = true;
    _changed();
    rescheduleReminders();
  }

  static List<String> _validOrder(List<String> o) {
    final List<String> out = o.where((String e) => kHomeBlocks.contains(e)).toSet().toList();
    for (final String b in kHomeBlocks) {
      if (!out.contains(b)) {
        out.add(b);
      }
    }
    return out;
  }

  void setHomeOrder(List<String> order) {
    homeOrder = _validOrder(order);
    _changed();
  }

  void resetHome() {
    homeOrder = List<String>.of(kHomeBlocks);
    _changed();
  }

  /// Drops values older than 6 months: weights, body data and calendar entries.
  void _pruneValues() {
    final DateTime limit = DateTime.now().subtract(const Duration(days: keepDays));
    weights.forEach((String _, List<WeightEntry> l) => l.removeWhere((WeightEntry e) => e.date.isBefore(limit)));
    weights.removeWhere((String _, List<WeightEntry> l) => l.isEmpty);
    bodyLog.removeWhere((BodyEntry e) => e.date.isBefore(limit));
  }

  /// Remembers a finished workout for the coach.
  void logWorkout(Plan plan) {
    final WorkoutLog w = WorkoutLog(
      date: DateTime.now(),
      planName: plan.name,
      items: plan.items.map((PlanItem e) => e.copy()).toList(),
    );
    history.add(w);
    markTrained(muscleLast, w);
    final String wk = weekKey(w.date);
    weeks[wk] = (weeks[wk] ?? 0) + 1;
    _pruneHistory();
    _changed();
  }

  /// Applies the keep rule (see [keepDays] and [_keepCount]).
  void _pruneHistory() {
    history.sort((WorkoutLog a, WorkoutLog b) => a.date.compareTo(b.date));
    final DateTime limit = DateTime.now().subtract(const Duration(days: keepDays));
    final List<WorkoutLog> kept = <WorkoutLog>[];
    for (int i = 0; i < history.length; i++) {
      final bool recent = history[i].date.isAfter(limit);
      final bool inLastFive = i >= history.length - _keepCount;
      if (recent || inLastFive) {
        kept.add(history[i]);
      }
    }
    history = kept;
  }

  /// Workouts per week the user aims for.
  int get weekGoal => coachProfile.done && !coachProfile.aiDecides ? coachProfile.days : 3;

  int get workoutsThisWeek => weeks[weekKey(DateTime.now())] ?? 0;

  int get streak => weekStreak(weeks, weekGoal);

  /// Groups not trained for a while, longest ago first.
  List<String> get dueMuscles => dueGroups(muscleLast);

  void addChat(ChatMessage m) {
    chat.add(m);
    if (chat.length > _maxChat) {
      chat = chat.sublist(chat.length - _maxChat);
    }
    _changed();
  }

  void clearChat() {
    chat = <ChatMessage>[];
    _changed();
  }

  /// Adds the plan of a chat message to the plan list.
  void saveChatProgram(ChatMessage m) {
    if (m.programJson.isEmpty || m.saved) {
      return;
    }
    final CoachProgram program = CoachProgram.parse(m.programJson);
    _storeProgram(program);
    m.saved = true;
    _changed();
  }

  /// Stores the weights of one workout. Key = exercise id.
  void addWeights(Map<String, WeightEntry> entries) {
    entries.forEach((String id, WeightEntry e) {
      final List<WeightEntry> list = weights.putIfAbsent(id, () => <WeightEntry>[]);
      list.add(e);
      if (e.kg > (records[id] ?? 0)) {
        records[id] = e.kg;
      }
    });
    _pruneValues();
    _changed();
  }

  double? suggestedWeight(String exerciseId) => suggestWeight(weights[exerciseId] ?? <WeightEntry>[]);

  WeightEntry? lastWeight(String exerciseId) {
    final List<WeightEntry>? l = weights[exerciseId];
    return (l == null || l.isEmpty) ? null : l.last;
  }

  void markWelcomeSeen() {
    welcomeSeen = true;
    _changed();
  }

  void setWarmup(bool v) {
    warmup = v;
    _changed();
  }

  void setAskWeights(bool v) {
    askWeights = v;
    _changed();
  }

  /// Adds facts the coach wants to remember. Duplicates are skipped.
  void addMemory(List<String> facts) {
    for (final String f in facts) {
      final String t = f.trim();
      if (t.isNotEmpty && !memory.contains(t)) {
        memory.add(t);
      }
    }
    if (memory.length > _maxMemory) {
      memory = memory.sublist(memory.length - _maxMemory);
    }
    _changed();
  }

  void removeMemory(String fact) {
    memory.remove(fact);
    _changed();
  }

  void saveShop(ShopSettings s) {
    shop = s;
    _changed();
  }

  /// Takes over the shopping list of a chat message. It becomes the current list.
  void saveChatList(ChatMessage m) {
    if (m.listJson.isEmpty || m.listSaved) {
      return;
    }
    shopping.insert(0, ShoppingList.fromJson(Map<String, dynamic>.from(jsonDecode(m.listJson) as Map)));
    if (shopping.length > DataLimits.maxShoppingLists) {
      shopping = shopping.sublist(0, DataLimits.maxShoppingLists);
    }
    m.listSaved = true;
    _changed();
  }

  void toggleShoppingItem(ShoppingItem item) {
    item.done = !item.done;
    _changed();
  }

  void deleteShoppingList(ShoppingList list) {
    shopping.remove(list);
    _changed();
  }

  /// Workouts of the last [days] days.
  List<WorkoutLog> recentWorkouts({int days = 14}) {
    final DateTime from = DateTime.now().subtract(Duration(days: days));
    return history.where((WorkoutLog w) => w.date.isAfter(from)).toList();
  }

  void setCoachModel(String model) {
    coachModel = model.trim().isEmpty ? kDefaultCoachModel : model.trim();
    _changed();
  }

  /// Saves the programme of the coach as plans on the device.
  void saveProgram(CoachProgram program) {
    lastProgramJson = program.json;
    _storeProgram(program);
    _changed();
  }

  /// Days with a date go to the calendar only (day plans). Days without a
  /// date become templates under "Pläne".
  void _storeProgram(CoachProgram program) {
    final List<Plan> list = program.toPlans(newId);
    bool scheduled = false;
    for (int i = 0; i < list.length; i++) {
      final DateTime? date = program.days[i].date;
      if (date != null && canPlan(date)) {
        list[i].day = _dayKey(date);
        plans.add(list[i]);
        schedule.add(ScheduledUnit(id: '${newId()}_u$i', day: _dayKey(date), planId: list[i].id));
        scheduled = true;
      } else {
        plans.add(list[i]);
      }
    }
    if (scheduled) {
      _pruneSchedule();
      rescheduleReminders();
    }
  }

  void setPlannerMode(String mode) {
    plannerMode = mode == 'list' ? 'list' : 'drag';
    _changed();
  }

  // ---- Appearance ----

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _changed();
  }

  void setFirstName(String v) {
    firstName = v.trim();
    _changed();
  }

  void setLightStyle(String v) {
    lightStyle = v;
    _changed();
  }

  void setDarkStyle(String v) {
    darkStyle = v;
    _changed();
  }

  void setHighContrast(bool v) {
    highContrast = v;
    _changed();
  }

  void setTextScale(double v) {
    textScale = v;
    _changed();
  }

  // ---- Push messages ----

  void setPushEnabled(bool v) {
    pushEnabled = v;
    _changed();
    rescheduleReminders();
  }

  void setTrainingReminders(bool v) {
    trainingReminders = v;
    _changed();
    rescheduleReminders();
  }

  /// Plans all reminders again: stretch breaks and training reminders.
  void rescheduleReminders() {
    NotificationService.instance.reschedule(pushEnabled && features.stretch ? stretch : StretchSettings());
    NotificationService.instance.scheduleBodyReminder(pushEnabled && features.tracking && bodyReminder);
    NotificationService.instance.scheduleTraining(
      pushEnabled && trainingReminders ? schedule : <ScheduledUnit>[],
      (String id) => planById(id)?.name ?? 'Training',
    );
  }

  // ---- Calendar ----

  static String dayKeyOf(DateTime d) => _dayKey(d);

  List<ScheduledUnit> unitsOn(DateTime d) {
    final String k = _dayKey(d);
    final List<ScheduledUnit> list = schedule.where((ScheduledUnit u) => u.day == k && planById(u.planId) != null).toList();
    list.sort((ScheduledUnit a, ScheduledUnit b) => (a.minute ?? 9999).compareTo(b.minute ?? 9999));
    return list;
  }

  Plan? planById(String id) {
    for (final Plan p in plans) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }

  /// Next day from today on (including today) with at least one unit.
  DateTime? nextTrainingDay() {
    final DateTime now = DateTime.now();
    for (int i = 0; i < 60; i++) {
      final DateTime d = DateTime(now.year, now.month, now.day + i);
      if (unitsOn(d).isNotEmpty) {
        return d;
      }
    }
    return null;
  }

  void addUnit(DateTime day, String planId, {int? minute}) {
    if (!canPlan(day)) {
      return;
    }
    schedule.add(ScheduledUnit(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      day: _dayKey(day),
      planId: planId,
      minute: minute,
    ));
    _pruneSchedule();
    _changed();
    rescheduleReminders();
  }

  void removeUnit(String id) {
    schedule.removeWhere((ScheduledUnit u) => u.id == id);
    _pruneSchedule();
    _changed();
    rescheduleReminders();
  }

  /// Day of a key like '2026-11-19'. Null when the key is broken.
  static DateTime? dayFromKey(String k) => _parseDayKey(k);

  static DateTime? _parseDayKey(String k) {
    final List<String> p = k.split('-');
    if (p.length != 3) {
      return null;
    }
    return DateTime(int.tryParse(p[0]) ?? 0, int.tryParse(p[1]) ?? 1, int.tryParse(p[2]) ?? 1);
  }

  /// Applies [DataLimits] to the calendar: drops entries outside the window and
  /// entries of deleted plans, then day plans that no entry uses any more
  /// (a day plan lives exactly as long as its calendar entry). Hard caps last.
  void _pruneSchedule() {
    final DateTime first = DataLimits.firstDay;
    schedule.removeWhere((ScheduledUnit u) {
      final DateTime? d = _parseDayKey(u.day);
      return d == null || d.isBefore(first) || planById(u.planId) == null;
    });
    if (schedule.length > DataLimits.maxUnits) {
      schedule.sort((ScheduledUnit a, ScheduledUnit b) => _parseDayKey(a.day)!.compareTo(_parseDayKey(b.day)!));
      schedule = schedule.sublist(schedule.length - DataLimits.maxUnits);
    }
    final Set<String> used = schedule.map((ScheduledUnit u) => u.planId).toSet();
    plans.removeWhere((Plan p) => !p.isTemplate && !used.contains(p.id));
    final List<Plan> dayPlans = plans.where((Plan p) => !p.isTemplate).toList();
    if (dayPlans.length > DataLimits.maxDayPlans) {
      dayPlans.sort((Plan a, Plan b) => (_parseDayKey(a.day!) ?? first).compareTo(_parseDayKey(b.day!) ?? first));
      final Set<String> drop = dayPlans.take(dayPlans.length - DataLimits.maxDayPlans).map((Plan p) => p.id).toSet();
      plans.removeWhere((Plan p) => drop.contains(p.id));
      schedule.removeWhere((ScheduledUnit u) => drop.contains(u.planId));
    }
  }

  // ---- Stretch breaks ----

  void _rollDay() {
    final String today = _dayKey(DateTime.now());
    if (stretchDay != today) {
      stretchDay = today;
      stretchDone = <String>[];
    }
  }

  /// The plan of today: times and stretches. Empty when the plan does not run today.
  List<({DateTime time, Stretch stretch})> get todayPlan {
    final DateTime now = DateTime.now();
    final DateTime day = DateTime(now.year, now.month, now.day);
    if (!stretch.activeOn(day)) {
      return <({DateTime time, Stretch stretch})>[];
    }
    final List<DateTime> slots = stretch.slotsFor(day);
    final List<Stretch> plan = stretchPlanFor(stretch, day);
    return <({DateTime time, Stretch stretch})>[
      for (int i = 0; i < slots.length && i < plan.length; i++) (time: slots[i], stretch: plan[i]),
    ];
  }

  /// Switches the plan on or off for today only.
  void setToday(bool on) {
    final StretchSettings s = stretch.copy();
    s.todayKey = on ? StretchSettings.keyOf(DateTime.now()) : '';
    updateStretch(s);
  }

  /// New random stretches for today. Times stay the same.
  void rerollToday() {
    final StretchSettings s = stretch.copy();
    final String today = StretchSettings.keyOf(DateTime.now());
    s.reroll = s.rerollKey == today ? s.reroll + 1 : 1;
    s.rerollKey = today;
    updateStretch(s);
  }

  void updateStretch(StretchSettings settings) {
    stretch = settings;
    _changed();
    rescheduleReminders();
  }

  void markStretchDone(String id) {
    _rollDay();
    if (!stretchDone.contains(id)) {
      stretchDone.add(id);
    }
    _changed();
  }

  /// Groups already stretched today.
  Set<String> get coveredGroups {
    _rollDay();
    return stretchDone.map((String id) => stretchById(id).group).toSet();
  }

  /// Picks a random stretch. Groups not covered today come first.
  Stretch pickStretch({String? notId}) {
    _rollDay();
    final Set<String> covered = coveredGroups;
    List<Stretch> pool = stretchCatalog.where((Stretch s) => !covered.contains(s.group) && s.id != notId).toList();
    if (pool.isEmpty) {
      pool = stretchCatalog.where((Stretch s) => !stretchDone.contains(s.id) && s.id != notId).toList();
    }
    if (pool.isEmpty) {
      pool = stretchCatalog.where((Stretch s) => s.id != notId).toList();
    }
    return pool[_random.nextInt(pool.length)];
  }

  DateTime? get nextReminder {
    final List<DateTime> next = stretch.upcoming(days: 8);
    return next.isEmpty ? null : next.first;
  }
}

/// Makes the [AppState] available to all screens.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState super.notifier, required super.child});

  static AppState of(BuildContext context) {
    final AppScope? scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    return scope!.notifier!;
  }
}
