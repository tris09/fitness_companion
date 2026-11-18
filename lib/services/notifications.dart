import 'dart:math';

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
  final Random _random = Random();
  bool _ready = false;

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
      await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
      _ready = true;
    } catch (_) {
      _ready = false;
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
      if (!settings.enabled) {
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
      final List<DateTime> times = settings.upcoming(days: 7);
      int id = 1000;
      for (final DateTime t in times.take(60)) {
        final Stretch s = stretchCatalog[_random.nextInt(stretchCatalog.length)];
        await _plugin.zonedSchedule(
          id,
          'Zeit für eine Pause, dehn dich! 🤸',
          s.name,
          tz.TZDateTime.from(t, tz.UTC),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        id++;
      }
    } catch (_) {
      // Scheduling failed. The rest of the app keeps working.
    }
  }
}
