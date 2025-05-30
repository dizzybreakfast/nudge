# Release Notes - Version N1.3.0

Date: May 30, 2025

This release introduces new features, improvements, and internal updates.

## ✨ New Features & Enhancements

*   **🔔 Notification Service (`lib/notification_service.dart`)**
    *   Initialized notification service in `main.dart`.
    *   Added a method to initialize the plugin, including requesting Android 13+ notification permissions.
    *   Added a method to cancel notifications for a specific event ID.
*   **🎨 Dark Mode & UI/UX Improvements (`lib/main.dart`, `lib/calendar_page.dart`)**
    *   **Added Dark Mode:** Implemented a `ThemeProvider` to allow users to toggle between light and dark themes. Theme preference is saved using `shared_preferences`.
    *   Updated `CalendarPage` to use theme colors for various UI elements, ensuring consistency with the selected theme.
    *   Improved event list display with better text styling and theme-aware colors.
    *   Enhanced the "All Upcoming Deadlines" view with clearer text and theme integration.
    *   Event markers on the calendar now use theme colors.

## Internal

*   Updated Android `compileSdk` to 35 and `targetSdk` to 35.
*   Updated `versionCode` to 5 and `versionName` to "N1.3.0" in `build.gradle.kts`.
*   Updated Java compatibility to version 17.
*   Enabled core library desugaring.
*   Set Kotlin JVM target to "17".

---

We are committed to continuously improving Nudge. We hope you find these updates helpful!
