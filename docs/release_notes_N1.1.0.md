# Release Notes - Version N1.1.0

Date: May 27, 2025

This release focuses on significant improvements to the Calendar and Task Board functionalities, enhancing user experience and providing more clarity in task and event management.

## Google Play Console Summary (Closed Testing)

This version introduces calendar enhancements, including improved event display (grouped by day, sorted by deadline) and a new toggle to switch between daily event view and a list of all upcoming deadlines. Task cards on the Task Board have been simplified for better readability. A bug causing incorrect event highlighting on the calendar has also been fixed.

## ✨ New Features & Enhancements

### 📅 Calendar Page (`lib/calendar_page.dart`)

*   **Improved Event Display**: The list of events below the calendar has been revamped. Events are now:
    *   Grouped by day.
    *   Sorted by deadline within each day, making it easier to see what's due.
*   **Toggleable Event View**: A new toggle has been added, allowing users to switch the event list view between:
    *   **"Upcoming Events by Day"**: Shows events grouped by their respective days.
    *   **"All Upcoming Deadlines"**: Shows a single chronological list of all future deadlines, sorted by the nearest due date.
*   **UI Updates**: Titles and button texts related to the new toggle feature have been updated for clarity.

### ✅ Task Board Screen (`lib/task_board_screen.dart`)

*   **Simplified Task Cards**: Task cards have been redesigned for better readability:
    *   Clear "Work on:" and "Deadline:" labels for start and end dates.
    *   Consistent date formatting.
    *   Improved visual styling with updated padding, margins, borders, and shadows.

## 🐞 Bug Fixes

### 📅 Calendar Page (`lib/calendar_page.dart`)

*   **Corrected Event Highlighting**: Fixed a bug where the visual highlighting of an event on the calendar would extend one day beyond its actual end date. Highlighting is now accurate.

## Internal

*   Project-wide search for the key "N.010.001" was conducted; no instances were found.

---

We are committed to continuously improving Nudge. We hope you find these updates helpful!
