import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  static Future<void> scheduleBillingReminder({
    required int id,
    required String title,
    required String body,
    required int dayOfMonth,
    bool oneDayBefore = false,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, dayOfMonth, 9, 0); // 9 AM
    
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
          'billing_reminders',
          'Billing Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
