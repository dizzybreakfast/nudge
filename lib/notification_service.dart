import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> scheduleTaskNotifications({
    required String title,
    required String body,
    required DateTime deadline,
  }) async {
    // Notify one day before
    await _notifications.zonedSchedule(
      0,
      '$title (Tomorrow)',
      'Reminder: $body is due tomorrow.',
      tz.TZDateTime.from(deadline.subtract(Duration(days: 1)), tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Task Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Notify on the actual deadline
    await _notifications.zonedSchedule(
      1,
      '$title (Today)',
      'Reminder: $body is due today!',
      tz.TZDateTime.from(deadline, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Task Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
