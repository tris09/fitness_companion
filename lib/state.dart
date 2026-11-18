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

/// Holds all app data and saves it on the device.
class AppState extends ChangeNotifier {
  static const String _key = 'app_state_v1';

  /// Swap these two for server versions later.
  final AuthService auth = LocalAuthService();
  final CoachService coach = GeminiCoachService();

  AuthUser? user;
  List<Plan> plans = <Plan>[];
  ThemeMode themeMode = ThemeMode.system;

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
  static const int _maxHistory = 30;

  /// Short facts the coach should keep in mind, e.g. 'Knie schonen'.
  List<String> memory = <String>[];
  static const int _maxMemory = 20;

  /// Shopping lists, newest first.
  List<ShoppingList> shopping = <ShoppingList>[];
  ShopSettings shop = ShopSettings();

  /// The coach chat, newest last.
  List<ChatMessage> chat = <ChatMessage>[];
  static const int _maxChat = 60;
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
          user = email == kTestEmail ? auth.testUser : auth.userFor(email);
        }
      } else {
        plans = <Plan>[_samplePlan()];
      }
    } catch (_) {
      plans = <Plan>[_samplePlan()];
    }
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

  Future<void> _save() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String mode = themeMode == ThemeMode.light ? 'light' : (themeMode == ThemeMode.dark ? 'dark' : 'system');
      final Map<String, dynamic> j = <String, dynamic>{
        'plans': plans.map((Plan p) => p.toJson()).toList(),
        'themeMode': mode,
        'plannerMode': plannerMode,
        'coachModel': coachModel,
        'modelV': 10,
        'lastProgram': lastProgramJson,
        'coachProfile': coachProfile.toJson(),
        'body': body.toJson(),
        'history': history.map((WorkoutLog e) => e.toJson()).toList(),
        'memory': memory,
        'shopping': shopping.map((ShoppingList e) => e.toJson()).toList(),
        'shop': shop.toJson(),
        'chat': chat.map((ChatMessage e) => e.toJson()).toList(),
        'stretch': stretch.toJson(),
        'stretchDay': stretchDay,
        'stretchDone': stretchDone,
        'email': user?.email ?? '',
      };
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

  /// Admin tool: back to the sample plan and default settings. The login stays.
  void resetData() {
    plans = <Plan>[_samplePlan()];
    stretch = StretchSettings();
    stretchDone = <String>[];
    coachProfile = CoachProfile();
    body = BodyProfile();
    history = <WorkoutLog>[];
    chat = <ChatMessage>[];
    memory = <String>[];
    shopping = <ShoppingList>[];
    shop = ShopSettings();
    _changed();
    NotificationService.instance.reschedule(stretch);
  }

  // ---- Plans ----

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

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
    _changed();
  }

  void addPlans(List<Plan> list) {
    plans.addAll(list);
    _changed();
  }

  // ---- Coach ----

  /// Stores the set-up answers and marks the set-up as finished.
  void saveCoachProfile(CoachProfile profile) {
    coachProfile = profile.copy()..done = true;
    _changed();
  }

  void saveBody(BodyProfile b) {
    body = b.copy()..done = true;
    _changed();
  }

  /// Remembers a finished workout for the coach.
  void logWorkout(Plan plan) {
    history.add(WorkoutLog(
      date: DateTime.now(),
      planName: plan.name,
      items: plan.items.map((PlanItem e) => e.copy()).toList(),
    ));
    if (history.length > _maxHistory) {
      history = history.sublist(history.length - _maxHistory);
    }
    _changed();
  }

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
    plans.addAll(program.toPlans(newId));
    m.saved = true;
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
    if (shopping.length > 5) {
      shopping = shopping.sublist(0, 5);
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
    plans.addAll(program.toPlans(newId));
    _changed();
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
    NotificationService.instance.reschedule(stretch);
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
