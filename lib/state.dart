import 'dart:convert';
import 'dart:math';

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
  String coachModel = 'gemini-flash-latest';

  /// JSON of the last programme the coach created.
  String lastProgramJson = '';

  /// Answers of the coach set-up. Asked once, changed only on request.
  CoachProfile coachProfile = CoachProfile();
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
        coachModel = (j['coachModel'] as String?) ?? 'gemini-flash-latest';
        lastProgramJson = (j['lastProgram'] as String?) ?? '';
        if (j['coachProfile'] != null) {
          coachProfile = CoachProfile.fromJson(Map<String, dynamic>.from(j['coachProfile'] as Map), trainingStyles);
        }
        if (j['stretch'] != null) {
          stretch = StretchSettings.fromJson(Map<String, dynamic>.from(j['stretch'] as Map));
        }
        stretchDay = (j['stretchDay'] as String?) ?? '';
        final List<dynamic> done = (j['stretchDone'] as List<dynamic>?) ?? <dynamic>[];
        stretchDone = done.map((dynamic e) => e as String).toList();
        final String? email = j['email'] as String?;
        if (email != null && email.isNotEmpty) {
          user = await auth.signInWithEmail(email);
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
        'lastProgram': lastProgramJson,
        'coachProfile': coachProfile.toJson(),
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

  Future<void> signIn(String email) async {
    user = await auth.signInWithEmail(email);
    _changed();
  }

  /// Returns null when it worked, otherwise a message for the user.
  Future<String?> signInWithGoogle() async {
    if (!GoogleAuth.isConfigured) {
      return 'Die Google-Anmeldung ist noch nicht eingerichtet.';
    }
    try {
      final String email = await GoogleAuth.signIn();
      user = await auth.signInWithEmail(email);
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

  void setCoachModel(String model) {
    coachModel = model.trim().isEmpty ? 'gemini-flash-latest' : model.trim();
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
