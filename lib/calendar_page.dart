// At the top of your calendar_page.dart file

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'task_board_screen.dart';
import 'event.dart';
import 'pomodoro_page.dart';
import 'services/database.dart';
import 'models/task.dart';
import 'notification_service.dart';
import 'settings_screen.dart'; // Added import for SettingsScreen

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  Event? _selectedEvent;

  DateTime? _highlightStart;
  DateTime? _highlightEnd;
  Color _highlightColor = Colors.transparent;
  final List<Color> _highlightColors = [
    const Color.fromARGB(77, 244, 67, 54), // Colors.red.withOpacity(0.3)
    const Color.fromARGB(77, 33, 150, 243), // Colors.blue.withOpacity(0.3)
    const Color.fromARGB(77, 76, 175, 80), // Colors.green.withOpacity(0.3)
    const Color.fromARGB(77, 255, 152, 0), // Colors.orange.withOpacity(0.3)
    const Color.fromARGB(77, 156, 39, 176), // Colors.purple.withOpacity(0.3)
  ];
  int _colorIndex = -1;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _eventStartDate;
  DateTime? _eventEndDate;

  bool _showDailyDeadlinesOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTasksFromDb(); // Added call to load tasks
  }

  // Added method to load tasks from the database
  Future<void> _loadTasksFromDb() async {
    final tasks = await DatabaseService().getTasks();
    final Map<DateTime, List<Event>> loadedEvents = {};
    for (var task in tasks) {
      if (task.startDate != null && task.endDate != null) {
        final event = Event(
          title: task.title,
          description: task.description, 
          start: task.startDate!,
          end: task.endDate!,
        );
        for (var date = event.start; !date.isAfter(event.end); date = date.add(const Duration(days: 1))) {
          final key = _normalizeDate(date);
          loadedEvents.putIfAbsent(key, () => []);
          // Avoid adding duplicate events if a task somehow maps to an already existing event in memory (e.g. from a previous session if not cleared)
          if (!loadedEvents[key]!.any((e) => e.title == event.title && e.start == event.start && e.end == event.end)) {
            loadedEvents[key]!.add(event);
          }
        }
      } else if (task.endDate != null) { // Handle tasks that might only have an end date (as deadlines)
        final event = Event(
          title: task.title,
          description: task.description, 
          start: task.endDate!, // Treat deadline as a single-day event starting and ending on endDate
          end: task.endDate!,
        );
        final key = _normalizeDate(event.start);
        loadedEvents.putIfAbsent(key, () => []);
        if (!loadedEvents[key]!.any((e) => e.title == event.title && e.start == event.start && e.end == event.end)) {
          loadedEvents[key]!.add(event);
        }
      }
    }
    if (mounted) {
      setState(() {
        _events = loadedEvents;
        // Optionally, if you want to clear any highlights or selected event from a previous state:
        // _clearHighlight();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? [];
  }

  DateTime _normalizeDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  void _clearHighlight() {
    setState(() {
      _highlightStart = null;
      _highlightEnd = null;
      _selectedEvent = null;
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _clearHighlight();
      });
    }
  }

  void _showAddEventDialog() {
    _titleController.clear();
    _descriptionController.clear();
    _eventStartDate = _selectedDay ?? DateTime.now();
    _eventEndDate = _selectedDay ?? DateTime.now();
    final theme = Theme.of(context); // Get theme data

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor, // Use theme dialog background color
              title: Text("Add New Event", style: TextStyle(color: theme.textTheme.titleLarge?.color)), // Use theme text color
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(hintText: "Event Title"),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(hintText: "Description (Optional)"),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Start: ${(_eventStartDate != null) ? MaterialLocalizations.of(stfContext).formatShortDate(_eventStartDate!) : 'Select'}",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          child: const Text("Select"),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: stfContext,
                              initialDate: _eventStartDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != _eventStartDate) {
                              stfSetState(() {
                                _eventStartDate = picked;
                                if (_eventEndDate != null && _eventEndDate!.isBefore(_eventStartDate!)) {
                                  _eventEndDate = _eventStartDate;
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "End: ${(_eventEndDate != null) ? MaterialLocalizations.of(stfContext).formatShortDate(_eventEndDate!) : 'Select'}",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          child: const Text("Select"),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: stfContext,
                              initialDate: _eventEndDate ?? _eventStartDate ?? DateTime.now(),
                              firstDate: _eventStartDate ?? DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != _eventEndDate) {
                              stfSetState(() {
                                _eventEndDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_titleController.text.isNotEmpty && _eventStartDate != null && _eventEndDate != null) {
                      final event = Event(
                        title: _titleController.text,
                        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                        start: _eventStartDate!,
                        end: _eventEndDate!,
                      );

                      // First close the dialog
                      Navigator.of(dialogContext).pop();

                      // Then perform the state updates
                      setState(() {
                        for (var date = event.start; !date.isAfter(event.end); date = date.add(const Duration(days: 1))) {
                          final key = _normalizeDate(date);
                          _events.putIfAbsent(key, () => []);
                          if (!_events[key]!.any((e) => e.title == event.title && e.start == event.start && e.end == event.end)) {
                            _events[key]!.add(event);
                          }
                        }
                        _clearHighlight();
                        _selectedEvent = event;
                        _highlightStart = event.start;
                        _highlightEnd = event.end;
                        _colorIndex = (_colorIndex + 1) % _highlightColors.length;
                        _highlightColor = _highlightColors[_colorIndex];
                      });

                      // Sync to task board
                      final tasks = await DatabaseService().getTasks();
                      final lastOrder = tasks
                          .where((t) => t.column == 'To Do')
                          .map((t) => t.order)
                          .fold<int>(-1, (prev, curr) => curr > prev ? curr : prev);

                      final newTask = Task(
                        title: event.title,
                        column: 'To Do',
                        startDate: event.start,
                        endDate: event.end,
                        order: lastOrder + 1,
                      );
                      await DatabaseService().insertTask(newTask);

                      NotificationService.scheduleTaskNotifications(
                        id: event.hashCode,
                        title: event.title,
                        body: event.description ?? "Task due: ${event.title}",
                        deadline: event.end,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary, // Use theme color
                    foregroundColor: theme.colorScheme.onPrimary, // Use theme color
                  ),
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditEventDialog(Event eventToEdit) {
    _titleController.text = eventToEdit.title;
    _descriptionController.text = eventToEdit.description ?? '';
    _eventStartDate = eventToEdit.start;
    _eventEndDate = eventToEdit.end;
    final originalEvent = eventToEdit;
    final theme = Theme.of(context); // Get theme data

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor, // Use theme dialog background color
              title: Text("Edit Event", style: TextStyle(color: theme.textTheme.titleLarge?.color)), // Use theme text color
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(hintText: "Event Title"),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(hintText: "Description (Optional)"),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Start: ${(_eventStartDate != null) ? MaterialLocalizations.of(stfContext).formatShortDate(_eventStartDate!) : 'Select'}",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          child: const Text("Select"),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: stfContext,
                              initialDate: _eventStartDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != _eventStartDate) {
                              stfSetState(() {
                                _eventStartDate = picked;
                                if (_eventEndDate != null && _eventEndDate!.isBefore(_eventStartDate!)) {
                                  _eventEndDate = _eventStartDate;
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "End: ${(_eventEndDate != null) ? MaterialLocalizations.of(stfContext).formatShortDate(_eventEndDate!) : 'Select'}",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          child: const Text("Select"),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: stfContext,
                              initialDate: _eventEndDate ?? _eventStartDate ?? DateTime.now(),
                              firstDate: _eventStartDate ?? DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != _eventEndDate) {
                              stfSetState(() {
                                _eventEndDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_titleController.text.isNotEmpty && _eventStartDate != null && _eventEndDate != null) {
                      final updatedEvent = Event(
                        title: _titleController.text,
                        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                        start: _eventStartDate!,
                        end: _eventEndDate!,
                      );

                      // First close the dialog
                      Navigator.of(dialogContext).pop();

                      // Then perform the state updates
                      setState(() {
                        for (var date = originalEvent.start; !date.isAfter(originalEvent.end); date = date.add(const Duration(days: 1))) {
                          final key = _normalizeDate(date);
                          _events[key]?.removeWhere((e) =>
                          e.title == originalEvent.title &&
                              e.start == originalEvent.start &&
                              e.end == originalEvent.end);
                          if (_events[key]?.isEmpty ?? false) {
                            _events.remove(key);
                          }
                        }

                        for (var date = updatedEvent.start; !date.isAfter(updatedEvent.end); date = date.add(const Duration(days: 1))) {
                          final key = _normalizeDate(date);
                          _events.putIfAbsent(key, () => []);
                          if (!_events[key]!.any((e) => e.title == updatedEvent.title && e.start == updatedEvent.start && e.end == updatedEvent.end)) {
                            _events[key]!.add(updatedEvent);
                          }
                        }

                        if (_selectedEvent?.title == originalEvent.title &&
                            _selectedEvent?.start == originalEvent.start &&
                            _selectedEvent?.end == originalEvent.end) {
                          _selectedEvent = updatedEvent;
                          _highlightStart = updatedEvent.start;
                          _highlightEnd = updatedEvent.end;
                        } else {
                          _clearHighlight();
                        }
                      });

                      NotificationService.scheduleTaskNotifications(
                        id: updatedEvent.hashCode,
                        title: updatedEvent.title,
                        body: updatedEvent.description ?? "Task due: ${updatedEvent.title}",
                        deadline: updatedEvent.end,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary, // Use theme color
                    foregroundColor: theme.colorScheme.onPrimary, // Use theme color
                  ),
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteEvent(Event event) async {
    final theme = Theme.of(context); // Get theme data
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor, // Use theme dialog background color
        title: Text("Delete Event", style: TextStyle(color: theme.textTheme.titleLarge?.color)), // Use theme text color
        content: Text("Are you sure you want to delete '${event.title}'?", style: TextStyle(color: theme.textTheme.bodyMedium?.color)), // Use theme text color
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: theme.colorScheme.primary)), // Use theme color
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                for (var date = event.start; !date.isAfter(event.end); date = date.add(const Duration(days: 1))) {
                  final key = _normalizeDate(date);
                  _events[key]?.removeWhere((e) =>
                  e.title == event.title &&
                      e.start == event.start &&
                      e.end == event.end);
                  if (_events[key]?.isEmpty ?? false) {
                    _events.remove(key);
                  }
                }
                if (_selectedEvent == event) {
                  _clearHighlight();
                }
              });

              // Also delete from database
              await DatabaseService().deleteTaskByTitleAndDate(event.title, event.end);

              // Cancel any scheduled notifications
              //NotificationService.cancelNotification(event.hashCode);
            },
            child: Text("Delete", style: TextStyle(color: theme.colorScheme.error)), // Use theme error color
          ),
        ],
      ),
    );
  }

  List<MapEntry<DateTime, List<Event>>> _getGroupedAndSortedDailyEvents() {
    if (_events.isEmpty) {
      return [];
    }

    final DateTime todayNormalized = _normalizeDate(DateTime.now());
    List<MapEntry<DateTime, List<Event>>> result = [];

    var allEventDaysSorted = _events.entries.toList();
    allEventDaysSorted.sort((a, b) => a.key.compareTo(b.key));

    for (var entry in allEventDaysSorted) {
      DateTime day = entry.key;
      List<Event> eventsOnThisDay = List<Event>.from(entry.value);

      eventsOnThisDay.removeWhere((event) => event.end.isBefore(todayNormalized));

      if (eventsOnThisDay.isEmpty) {
        continue;
      }

      eventsOnThisDay.sort((a, b) => a.end.compareTo(b.end));
      result.add(MapEntry(day, eventsOnThisDay));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nudge'), // Changed title
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: 'Pomodoro Timer',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PomodoroPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.view_kanban_outlined),
            tooltip: 'Task Board',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TaskBoardScreen()),
              );
            },
          ),
          IconButton( // Added IconButton for Settings
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: _onDaySelected,
            onPageChanged: (focusedDay) {
              setState(() { // Ensure UI updates when page changes
                _focusedDay = focusedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: _buildEventsMarker(date, events),
                  );
                }
                return null;
              },
              selectedBuilder: (context, date, focusedDay) {
                final theme = Theme.of(context); // Get theme data
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.primaryColorLight,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(color: theme.primaryColorDark),
                  ),
                );
              },
              todayBuilder: (context, date, focusedDay) {
                final theme = Theme.of(context); // Get theme data
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.5), // Use theme color
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(color: theme.colorScheme.onSecondary), // Use theme color
                  ),
                );
              },
              rangeStartBuilder: (context, date, focusedDay) {
                if (_highlightStart != null && _normalizeDate(date) == _normalizeDate(_highlightStart!)) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(
                      color: _highlightColor,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(50)),
                    ),
                    alignment: Alignment.center,
                    child: Text('${date.day}', style: const TextStyle(color: Colors.white)),
                  );
                }
                return null;
              },
              rangeEndBuilder: (context, date, focusedDay) {
                if (_highlightEnd != null && _normalizeDate(date) == _normalizeDate(_highlightEnd!)) { // MODIFIED: Compare directly with _highlightEnd
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(
                      color: _highlightColor,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(50)),
                    ),
                    alignment: Alignment.center,
                    child: Text('${date.day}', style: const TextStyle(color: Colors.white)),
                  );
                }
                return null;
              },
              withinRangeBuilder: (context, date, focusedDay) {
                if (_highlightStart != null && _highlightEnd != null &&
                    !isSameDay(date, _highlightStart!) &&
                    !isSameDay(date, _highlightEnd!) && // MODIFIED: Compare directly with _highlightEnd
                    date.isAfter(_highlightStart!) &&
                    date.isBefore(_highlightEnd!)) { // MODIFIED: Compare directly with _highlightEnd
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(color: _highlightColor),
                    alignment: Alignment.center,
                    child: Text('${date.day}', style: const TextStyle(color: Colors.white)),
                  );
                }
                return null;
              },
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            rangeStartDay: _highlightStart,
            rangeEndDay: _highlightEnd,
          ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded( // Wrap title in Expanded to prevent overflow if text is long
                  child: Text(
                    _showDailyDeadlinesOnly
                        ? "All Upcoming Deadlines" // MODIFIED Text
                        : "Upcoming Events by Day",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500, color: theme.textTheme.titleMedium?.color), // Use theme color
                    overflow: TextOverflow.ellipsis, // Add ellipsis for long text
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showDailyDeadlinesOnly = !_showDailyDeadlinesOnly;
                    });
                  },
                  child: Text(
                      _showDailyDeadlinesOnly
                          ? "Show Upcoming by Day" // MODIFIED Text
                          : "Show All Deadlines",
                      style: TextStyle(color: theme.colorScheme.primary), // Use theme color
                   ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_showDailyDeadlinesOnly) {
                  final todayNormalized = _normalizeDate(DateTime.now());
                  List<Event> allUpcomingDeadlines = _events.values
                      .expand((list) => list) // Flatten all event lists
                      .toSet() // Remove duplicates that might exist across days if events span multiple days
                      .toList()
                      .where((event) => !event.end.isBefore(todayNormalized)) // Filter out past deadlines
                      .toList();
                  allUpcomingDeadlines.sort((a, b) => a.end.compareTo(b.end)); // Sort by deadline

                  if (allUpcomingDeadlines.isEmpty) {
                    return Center(
                        child: Text(
                            "No upcoming deadlines to display.", style: TextStyle(color: theme.textTheme.bodyMedium?.color))); // MODIFIED Text & Use theme color
                  }
                  return _buildDailyDeadlineList(allUpcomingDeadlines);
                } else {
                  final List<MapEntry<DateTime, List<Event>>>
                  groupedSortedEvents = _getGroupedAndSortedDailyEvents();
                  if (groupedSortedEvents.isEmpty) {
                    return Center(
                        child: Text("No current events to display.", style: TextStyle(color: theme.textTheme.bodyMedium?.color))); // Use theme color
                  }
                  return _buildGroupedEventList(groupedSortedEvents);
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: theme.colorScheme.secondary, // Use theme color
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupedEventList(List<MapEntry<DateTime, List<Event>>> groupedSortedEvents) {
    final theme = Theme.of(context); // Get theme data
    return ListView.builder(
      itemCount: groupedSortedEvents.length, // Number of days with current events
      itemBuilder: (context, dayIndex) {
        final dayEntry = groupedSortedEvents[dayIndex];
        final DateTime day = dayEntry.key;
        final List<Event> eventsOnThisDay = dayEntry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text(
                MaterialLocalizations.of(context).formatFullDate(day),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary), // Use theme color
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: eventsOnThisDay.length,
              itemBuilder: (context, eventIndex) {
                final event = eventsOnThisDay[eventIndex];
                bool isSelected = _selectedEvent == event;

                return Card(
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  color: isSelected ? _highlightColor.withOpacity(0.6) : theme.cardColor, // Use theme card color
                  child: ListTile(
                    title: Text(event.title, style: TextStyle(fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color)), // Use theme text color
                    subtitle: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "${event.description?.isNotEmpty == true ? event.description : 'No description'}\n",
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color, // Use theme text color
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          TextSpan(
                            text: "Deadline: ${MaterialLocalizations.of(context).formatShortDate(event.end)} at ${TimeOfDay.fromDateTime(event.end).format(context)}",
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color, // Use theme text color
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    isThreeLine: true,
                    onTap: () {
                      setState(() {
                        _selectedEvent = event;
                        _highlightStart = event.start;
                        _highlightEnd = event.end;
                        _colorIndex = (_colorIndex + 1) % _highlightColors.length;
                        _highlightColor = _highlightColors[_colorIndex];
                        _focusedDay = event.start;
                      });
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: theme.colorScheme.primary), // Use theme color
                          onPressed: () => _showEditEventDialog(event),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: theme.colorScheme.error), // Use theme error color
                          onPressed: () => _deleteEvent(event),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (dayIndex < groupedSortedEvents.length - 1)
              const Divider(height: 20, indent: 16, endIndent: 16, thickness: 0.5),
          ],
        );
      },
    );
  }

  Widget _buildDailyDeadlineList(List<Event> events) {
    final localizations = MaterialLocalizations.of(context);
    final theme = Theme.of(context); // Get theme data
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        bool isSelected = _selectedEvent == event;
        return Card(
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          color: isSelected ? _highlightColor.withOpacity(0.6) : theme.cardColor, // Use theme card color
          child: ListTile(
            title: Text(event.title, style: TextStyle(fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color)), // Use theme text color
            subtitle: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Deadline: ${localizations.formatShortDate(event.end)} at ${TimeOfDay.fromDateTime(event.end).format(context)}\n",
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color, // Use theme text color
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  TextSpan(
                    text: event.description ?? 'No description',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color, // Use theme text color
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            isThreeLine: (event.description ?? '').isNotEmpty, // Make it three lines if description exists
            onTap: () {
              setState(() {
                _selectedEvent = event;
                _highlightStart = event.start;
                _highlightEnd = event.end;
                _colorIndex = (_colorIndex + 1) % _highlightColors.length;
                _highlightColor = _highlightColors[_colorIndex];
                _focusedDay = event.start;
              });
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: theme.colorScheme.primary), // Use theme color
                  onPressed: () => _showEditEventDialog(event),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: theme.colorScheme.error), // Use theme error color
                  onPressed: () => _deleteEvent(event),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventsMarker(DateTime date, List<Event> events) {
    final theme = Theme.of(context); // Get theme data
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.secondary, // Use theme color
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: const TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}