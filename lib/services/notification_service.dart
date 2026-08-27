import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications to schedule the two daily azkar
/// reminders (morning/evening). Notification ids are fixed so re-scheduling
/// simply replaces the previous one.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int morningNotificationId = 1001;
  static const int eveningNotificationId = 1002;

  static const _channelId = 'azkari_reminders';
  static const _channelName = 'تذكيرات الأذكار';
  static const _channelDescription = 'تذكيرات أذكار الصباح والمساء اليومية';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      // Fall back silently; zonedSchedule will still use UTC-relative time
      // if the device timezone name isn't recognized by the tz database.
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    _initialized = true;
  }

  /// Requests notification permission on Android 13+ and iOS. Call this
  /// right before the user enables a reminder for the first time.
  Future<bool> requestPermission() async {
    await init();

    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  Future<void> scheduleMorningReminder(TimeOfDay time) async {
    await _schedule(
      id: morningNotificationId,
      time: time,
      title: 'أذكار الصباح',
      body: 'حان وقت أذكار الصباح، بادر بذكر الله 🌅',
    );
  }

  Future<void> scheduleEveningReminder(TimeOfDay time) async {
    await _schedule(
      id: eveningNotificationId,
      time: time,
      title: 'أذكار المساء',
      body: 'حان وقت أذكار المساء، اختم يومك بذكر الله 🌙',
    );
  }

  Future<void> cancelMorningReminder() async {
    await init();
    await _plugin.cancel(morningNotificationId);
  }

  Future<void> cancelEveningReminder() async {
    await init();
    await _plugin.cancel(eveningNotificationId);
  }

  Future<void> _schedule({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(time),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
