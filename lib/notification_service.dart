import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // Renamed for clarity, though _notifications is fine too
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // --- ADDED an 'id' parameter ---
  static Future<void> scheduleTaskNotifications({
    required int id, // Unique integer ID for the event/task
    required String title,
    required String body,
    required DateTime deadline,
  }) async {
    // Ensure the base ID is positive and within a reasonable range
    // to avoid collision if we add more types of notifications later.
    // For local notifications, IDs are 32-bit integers.
    // Let's use the provided 'id' for the "deadline" notification
    // and 'id + some_offset' for the "one day before" notification,
    // ensuring they are distinct for the same event.
    // A common practice is to reserve ranges or use a formula.
    // For simplicity here, we'll use a large offset for the "tomorrow" notification
    // to make it less likely to collide with the "today" ID of another event,
    // assuming event IDs are somewhat sequential or smaller.
    // A more robust system might involve a database or ensuring event IDs are globally unique
    // and sufficiently spaced if they are generated sequentially.

    final int tomorrowNotificationId = id + 1000000; // Offset for "tomorrow"
    final int todayNotificationId = id;             // Use base id for "today"

    // Clear any existing notifications for these specific IDs before scheduling new ones
    // This is important if you are *rescheduling* for the same event
    await _notificationsPlugin.cancel(tomorrowNotificationId);
    await _notificationsPlugin.cancel(todayNotificationId);

    // --- Notify one day before ---
    if (deadline.subtract(const Duration(days: 1)).isAfter(DateTime.now())) {
      await _notificationsPlugin.zonedSchedule(
        tomorrowNotificationId, // Use the unique ID for "Tomorrow"
        '$title (Tomorrow)',
        'Reminder: $body is due tomorrow.',
        tz.TZDateTime.from(deadline.subtract(const Duration(days: 1)), tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel_tomorrow', // Potentially a different channel or same, your choice
            'Task Reminders (Tomorrow)',
            channelDescription: 'Reminders for tasks due the next day.',
            importance: Importance.max,
            priority: Priority.high,
          ),
          // Add iOS details if needed
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('Scheduled "tomorrow" notification (ID: $tomorrowNotificationId) for $title at ${deadline.subtract(const Duration(days: 1))}');
    } else {
      print('Skipped "tomorrow" notification for $title as it is in the past.');
    }

    // --- Notify on the actual deadline ---
    if (deadline.isAfter(DateTime.now())) {
      await _notificationsPlugin.zonedSchedule(
        todayNotificationId, // Use the unique ID for "Today"
        '$title (Today)',
        'Reminder: $body is due today!',
        tz.TZDateTime.from(deadline, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel_today', // Potentially a different channel or same
            'Task Reminders (Today)',
            channelDescription: 'Reminders for tasks due today.',
            importance: Importance.max,
            priority: Priority.high,
          ),
          // Add iOS details if needed
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('Scheduled "today" notification (ID: $todayNotificationId) for $title at $deadline');
    } else {
      print('Skipped "today" notification for $title as it is in the past.');
    }
  }

  // --- ADD a method to initialize the plugin (call this from main.dart) ---
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Replace with your app icon

    // For iOS - you'll also need to request permissions
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

    // Request Android 13+ notification permission
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final bool? granted = await androidPlugin.requestNotificationsPermission();
      print("Android notification permission granted: $granted");
    }
  }

  // --- Callbacks for notification interaction (optional but good practice) ---
  static void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details,
    // navigate to a specific page etc.
    print(
        "onDidReceiveLocalNotification: id ($id), title ($title), body ($body), payload ($payload)");
  }

  static void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      print('notification payload: $payload');
    }
    print(
        "onDidReceiveNotificationResponse: id (${notificationResponse.id}), payload ($payload)");
    // Add navigation or other actions here
  }

  // --- ADD a method to cancel notifications for a specific event ID ---
  static Future<void> cancelTaskNotifications(int eventId) async {
    final int tomorrowNotificationId = eventId + 1000000;
    final int todayNotificationId = eventId;

    await _notificationsPlugin.cancel(tomorrowNotificationId);
    await _notificationsPlugin.cancel(todayNotificationId);
    print('Cancelled notifications for event ID: $eventId (IDs: $tomorrowNotificationId, $todayNotificationId)');
  }
}