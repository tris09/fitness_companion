import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../catalog.dart';
import '../models.dart';

/// Schedules the stretch reminders as local notifications.
/// Written for flutter_local_notifications 18.0.1.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Called when the user taps a stretch reminder. Set in main.dart.
  void Function()? onOpenStretch;

  Future<void> init() async {
    if (_ready) {
      return;
    }
    try {
      tzdata.initializeTimeZones();
      const AndroidInitializationSettings android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: (NotificationResponse r) {
          if (r.payload == 'stretch') {
            onOpenStretch?.call();
          }
        },
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// True when the app was started by a tap on a stretch reminder.
  Future<bool> launchedFromStretch() async {
    await init();
    try {
      final NotificationAppLaunchDetails? d = await _plugin.getNotificationAppLaunchDetails();
      return (d?.didNotificationLaunchApp ?? false) && d?.notificationResponse?.payload == 'stretch';
    } catch (_) {
      return false;
    }
  }

  /// Asks the user to allow notifications. Returns false when denied.
  Future<bool> requestPermission() async {
    await init();
    try {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final IOSFlutterLocalNotificationsPlugin? ios =
          _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final bool? a = await android?.requestNotificationsPermission();
      final bool? i = await ios?.requestPermissions(alert: true, badge: false, sound: true);
      return a ?? i ?? true;
    } catch (_) {
      return false;
    }
  }

  /// Removes all planned reminders and plans the next days again.
  Future<void> reschedule(StretchSettings settings) async {
    await init();
    if (!_ready) {
      return;
    }
    try {
      await _plugin.cancelAll();
      if (!settings.anyActive) {
        return;
      }
      const NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          'stretch_breaks',
          'Dehnpausen',
          channelDescription: 'Erinnerungen an Dehnpausen',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      final DateTime now = DateTime.now();
      int id = 1000;
      for (int d = 0; d < 7 && id < 1060; d++) {
        final DateTime day = DateTime(now.year, now.month, now.day + d);
        if (!settings.activeOn(day)) {
          continue;
        }
        final List<DateTime> slots = settings.slotsFor(day);
        final List<Stretch> plan = stretchPlanFor(settings, day);
        for (int i = 0; i < slots.length && i < plan.length; i++) {
          if (!slots[i].isAfter(now)) {
            continue;
          }
          await _plugin.zonedSchedule(
            id,
            'Dehnplan ${i + 1} von ${slots.length}: ${plan[i].name}',
            '${plan[i].group} · ${plan[i].seconds} Sekunden. Anleitung im Dehnplan der App.',
            tz.TZDateTime.from(slots[i], tz.UTC),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'stretch',
          );
          id++;
        }
      }
    } catch (_) {
      // Scheduling failed. The rest of the app keeps working.
    }
  }
}
