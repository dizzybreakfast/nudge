# Release Notes - Version N1.2.0

Date: May 30, 2025

This release introduces new features and improvements.

## ✨ New Features & Enhancements

*   **📅 Calendar Page & ✅ Task Board Screen (`lib/calendar_page.dart`, `lib/task_board_screen.dart`)**
    *   Tasks are now loaded from the database directly within the Calendar Page, providing up-to-date task visibility.
    *   Improved date formatting on the Task Board Screen for better readability.
    *   Enhanced design of the Task Board, including synchronization with the calendar.
*   **🍅 Pomodoro Timer (`lib/pomodoro_page.dart`)**
    *   Introduced a new Pomodoro timer feature to help users manage their work and break intervals effectively.
*   **🔔 Notifications (`lib/notification_service.dart`)**
    *   Added a notification system to provide timely reminders and alerts.
    *   Upgraded the `flutter_local_notifications` package to the latest version for improved notification handling.

## 🐞 Bug Fixes

*   **📅 Calendar Page (`lib/calendar_page.dart`)**
    *   Fixed an issue related to task synchronization with the calendar, ensuring data consistency.

## Internal

*   Updated package namespace and application ID.
*   Incremented version code and version name to N1.2.0.
*   Added ProGuard rules for release build optimization.

---

We are committed to continuously improving Nudge. We hope you find these updates helpful!
