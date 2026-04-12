import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ─── Notification channel definitions ────────────────────────────────────
  static const _billingChannelId = 'billing_reminders';
  static const _billingChannelName = 'Billing Reminders';
  static const _taskChannelId = 'task_reminders';
  static const _taskChannelName = 'Task Reminders';

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap — can navigate to tasks screen here
      },
    );

    // Request Android 13+ notification permission
    await _requestAndroidPermission();
  }

  /// Request POST_NOTIFICATIONS permission on Android 13+.
  static Future<void> _requestAndroidPermission() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  // ─── Billing Reminder (monthly repeating) ────────────────────────────────
  static Future<void> scheduleBillingReminder({
    required int id,
    required String title,
    required String body,
    required int dayOfMonth,
    bool oneDayBefore = false,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, dayOfMonth, 9, 0);

    if (oneDayBefore) {
      scheduledDate = scheduledDate.subtract(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = DateTime(now.year, now.month + 1, dayOfMonth, 9, 0);
      if (oneDayBefore) {
        scheduledDate = scheduledDate.subtract(const Duration(days: 1));
      }
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _billingChannelId,
          _billingChannelName,
          channelDescription: 'Reminders for upcoming credit card bills',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  // ─── Task Reminder (one-time) ─────────────────────────────────────────────
  /// Schedules a one-time local notification for a user task reminder.
  /// [id] should be unique per task (use hashCode of task id).
  static Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Don't schedule if time is in the past
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _taskChannelId,
          _taskChannelName,
          channelDescription: 'Reminders for your scheduled tasks',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels a specific notification by id.
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancels all scheduled notifications.
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
