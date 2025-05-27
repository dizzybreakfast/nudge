// At the top of your calendar_page.dart file

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
<<<<<<< HEAD
import 'task_board_screen.dart'; // Your existing import
import 'event.dart';             // Your existing import for the Event class

// --- THIS IS THE IMPORTANT IMPORT ---
// Make sure this path is correct for where your notification_service.dart file is.
// If it's directly in the 'lib' folder:
import 'notification_service.dart';
// If it's in 'lib/services/':
// import 'services/notification_service.dart';
// Or if you use package imports (replace 'your_project_name'):
// import 'package:your_project_name/notification_service.dart';
// import 'package:your_project_name/services/notification_service.dart';
// --- END OF IMPORTANT IMPORT ---

=======
import 'task_board_screen.dart';
import 'event.dart';
import 'models/task.dart';
import 'services/database.dart';
>>>>>>> d8714224393271f58169bb0452a1b073eaee647f

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  Event? _selectedEvent; // To store the selected event for highlighting

  // For highlighting
  DateTime? _highlightStart;
  DateTime? _highlightEnd;
  Color _highlightColor = Colors.transparent;
  final List<Color> _highlightColors = [
    Colors.red.withOpacity(0.3),
    Colors.blue.withOpacity(0.3),
    Colors.green.withOpacity(0.3),
    Colors.orange.withOpacity(0.3),
    Colors.purple.withOpacity(0.3),
  ];
  int _colorIndex = -1; // Initialize to -1 so first event gets first color

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _eventStartDate;
  DateTime? _eventEndDate;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // You might load existing events here from storage if needed
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
      _selectedEvent = null; // Clear selected event when clearing highlight
    });
  }

<<<<<<< HEAD
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _clearHighlight(); // Clear highlight when a new day is selected
      });
    }
  }

  void _showAddEventDialog() {
    // Reset fields for new event
    _titleController.clear();
    _descriptionController.clear();
    _eventStartDate = _selectedDay ?? DateTime.now();
    _eventEndDate = _selectedDay ?? DateTime.now();
    final bool isNewEvent = true; // Flag for new event

    showDialog(
      context: context,
      builder: (dialogContext) { // Capture dialog's context
        return StatefulBuilder( // Use StatefulBuilder for dialog's own state
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              title: const Text("Add New Event"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(hintText: "Event Title"),
=======
  @override
  void initState() {
    super.initState();
    _loadTasksAsEvents();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _clearHighlight,
      child: Scaffold(
        appBar: AppBar(
            title: const Text("Nudge"),
            actions: [
              IconButton(
                icon: const Icon(Icons.view_kanban),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TaskBoardScreen()),
                  );
                  if (result == true) {
                    await _loadTasksAsEvents(); // reload events if a task was added
                  }
                },
              ),
            ]
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TableCalendar<Event>(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: (day) => _events[_normalizeDate(day)] ?? [],
                  rowHeight: 52,
                  daysOfWeekHeight: 40,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    headerPadding: EdgeInsets.symmetric(vertical: 8.0),
                    formatButtonDecoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
>>>>>>> d8714224393271f58169bb0452a1b073eaee647f
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(hintText: "Description (Optional)"),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Start: ${(_eventStartDate != null) ? MaterialLocalizations.of(stfContext).formatShortDate(_eventStartDate!) : 'Select'}"),
                        TextButton(
                          child: const Text("Select Start Date"),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: stfContext,
                              initialDate: _eventStartDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != _eventStartDate) {
                              stfSetState(() { // Use StatefulBuilder's setState
                                _eventStartDate = picked;
                                // Ensure end date is not before start date
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("End: ${(_eventEndDate != null) ? MaterialLocalizations.of(stfContext).formatShortDate(_eventEndDate!) : 'Select'}"),
                        TextButton(
                          child: const Text("Select End Date"),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: stfContext,
                              initialDate: _eventEndDate ?? _eventStartDate ?? DateTime.now(),
                              firstDate: _eventStartDate ?? DateTime(2000), // End date cannot be before start date
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != _eventEndDate) {
                              stfSetState(() { // Use StatefulBuilder's setState
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
                  onPressed: () => Navigator.pop(dialogContext), // Use dialog's context
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_titleController.text.isNotEmpty && _eventStartDate != null && _eventEndDate != null) {
                      final event = Event(
                        title: _titleController.text,
                        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                        start: _eventStartDate!,
                        end: _eventEndDate!,
                      );

                      // This setState is for the main page's state
                      setState(() {
                        for (var date = event.start; !date.isAfter(event.end); date = date.add(const Duration(days: 1))) {
                          final key = _normalizeDate(date); // Ensure key is normalized
                          _events.putIfAbsent(key, () => []);
                          if (!_events[key]!.any((e) => e.title == event.title && e.start == event.start && e.end == event.end)) {
                            _events[key]!.add(event);
                          }
                        }
                        _clearHighlight();
                        _selectedEvent = event;
                        _highlightStart = event.start;
                        _highlightEnd = event.end.add(const Duration(days:1)); // Adjust for exclusive end in range
                        _colorIndex = (_colorIndex + 1) % _highlightColors.length;
                        _highlightColor = _highlightColors[_colorIndex];
                      });

                      // --- MODIFICATION FOR NOTIFICATION SERVICE ---
                      // Schedule notification
                      NotificationService.scheduleTaskNotifications(
                        id: event.hashCode, // Using hashCode as a simple unique ID
                        title: event.title,
                        body: event.description ?? "Task due: ${event.title}", // Provide a default body if description is null
                        deadline: event.end, // Assuming the event's end date is the deadline
                      );
                      print("Scheduled notification for: ${event.title} with ID: ${event.hashCode}");
                      // --- END OF MODIFICATION ---

                      Navigator.pop(dialogContext); // Use dialog's context to pop
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
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
    final originalEvent = eventToEdit; // Keep a reference to the original event

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              title: const Text("Edit Event"),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Start: ${(_eventStartDate != null) ? MaterialLocalizations.of(stfContext).formatShortDate(_eventStartDate!) : 'Select'}"),
                        TextButton(
                          child: const Text("Select Start Date"),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("End: ${(_eventEndDate != null) ? MaterialLocalizations.of(stfContext).formatShortDate(_eventEndDate!) : 'Select'}"),
                        TextButton(
                          child: const Text("Select End Date"),
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
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_titleController.text.isNotEmpty && _eventStartDate != null && _eventEndDate != null) {
                      final updatedEvent = Event(
                        title: _titleController.text,
                        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                        start: _eventStartDate!,
                        end: _eventEndDate!,
                        // If your Event class has an ID that should persist, make sure to carry it over:
                        // id: originalEvent.id, // Example, if Event has an 'id' property
                      );

                      setState(() {
                        // Remove the old event first
                        _events.forEach((key, dayEvents) {
                          dayEvents.removeWhere((e) =>
                          e.title == originalEvent.title &&
                              e.start == originalEvent.start &&
                              e.end == originalEvent.end); // Use a more robust ID if available
                        });
                        _events.removeWhere((key, dayEvents) => dayEvents.isEmpty); // Clean up empty day entries


                        // Add the updated event
                        for (var date = updatedEvent.start; !date.isAfter(updatedEvent.end); date = date.add(const Duration(days: 1))) {
                          final key = _normalizeDate(date);
                          _events.putIfAbsent(key, () => []);
                          // Avoid adding duplicate event instances if logic allows
                          if (!_events[key]!.any((e) => e.title == updatedEvent.title && e.start == updatedEvent.start && e.end == updatedEvent.end)) {
                            _events[key]!.add(updatedEvent);
                          }
                        }

                        // Update highlight if the selected event was the one edited
                        if (_selectedEvent?.title == originalEvent.title && // simplistic comparison
                            _selectedEvent?.start == originalEvent.start) {
                          _selectedEvent = updatedEvent;
                          _highlightStart = updatedEvent.start;
                          _highlightEnd = updatedEvent.end.add(const Duration(days:1));
                          // Keep the same color or re-assign if needed
                        } else {
                          _clearHighlight(); // Or select the new event
                          _selectedEvent = updatedEvent;
                          _highlightStart = updatedEvent.start;
                          _highlightEnd = updatedEvent.end.add(const Duration(days:1));
                          // Potentially find the color index if it was stored with the event
                        }
                      });

                      // --- MODIFICATION FOR NOTIFICATION SERVICE ---
                      // Reschedule notification for the updated event
                      // First, if your Event class has a persistent ID, use that for cancellation.
                      // Here, we use originalEvent.hashCode. If it changes due to content change,
                      // old notifications might not be cancelled if using newEvent.hashCode directly for cancel.
                      // It's better if NotificationService.cancel can take the specific IDs it generated.
                      // For now, let's assume scheduleTaskNotifications handles cancelling old ones if ID matches.

                      // Get the ID for the event. If Event has a persistent ID, use that.
                      // Otherwise, use hashCode. If using hashCode, ensure it's the *original* event's
                      // hashCode if you need to cancel a notification scheduled with that.
                      // However, our NotificationService's scheduleTaskNotifications now takes an ID
                      // and internally cancels notifications for that base ID + offset before scheduling.
                      // So, using updatedEvent.hashCode should be fine here for the `id` param.

                      int eventIdForNotification = updatedEvent.hashCode;
                      // If your Event has a stable ID, use it:
                      // int eventIdForNotification = updatedEvent.id; // (if Event has an id property)

                      NotificationService.scheduleTaskNotifications(
                        id: eventIdForNotification,
                        title: updatedEvent.title,
                        body: updatedEvent.description ?? "Task due: ${updatedEvent.title}",
                        deadline: updatedEvent.end,
                      );
                      print("Rescheduled notification for: ${updatedEvent.title} with ID: $eventIdForNotification");
                      // --- END OF MODIFICATION ---

                      Navigator.pop(dialogContext);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TaskBoardScreen()),
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
              _focusedDay = focusedDay;
            },
            // ... inside your TableCalendar widget ...
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) { // 'date' is defined here
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: _buildEventsMarker(date, events),
                  );
                }
                return null;
              },
              selectedBuilder: (context, date, focusedDay) { // 'date' is defined here
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorLight,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(color: Theme.of(context).primaryColorDark),
                  ),
                );
              },
              todayBuilder: (context, date, focusedDay) { // 'date' is defined here
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },

              // --- CORRECTED HIGHLIGHTING BUILDERS ---
              rangeStartBuilder: (context, date, focusedDay) { // 'date' is a parameter here
                if (_highlightStart != null && _normalizeDate(date) == _normalizeDate(_highlightStart!)) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(
                      color: _highlightColor,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(50)),
                    ),
                    alignment: Alignment.center,
                    child: Text('${date.day}', style: TextStyle(color: Colors.white)),
                  );
                }
                return null; // Return null if the condition isn't met
              },
              rangeEndBuilder: (context, date, focusedDay) { // 'date' is a parameter here
                if (_highlightEnd != null && _normalizeDate(date) == _normalizeDate(_highlightEnd!.subtract(Duration(days:1)))) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(
                      color: _highlightColor,
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(50)),
                    ),
                    alignment: Alignment.center,
                    child: Text('${date.day}', style: TextStyle(color: Colors.white)),
                  );
                }
                return null; // Return null if the condition isn't met
              },
              withinRangeBuilder: (context, date, focusedDay) { // 'date' is a parameter here
                if (_highlightStart != null && _highlightEnd != null &&
                    !isSameDay(date, _highlightStart!) &&
                    !isSameDay(date, _highlightEnd!.subtract(Duration(days:1))) &&
                    date.isAfter(_highlightStart!) &&
                    date.isBefore(_highlightEnd!.subtract(Duration(days:1)))) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(color: _highlightColor),
                    alignment: Alignment.center,
                    child: Text('${date.day}', style: TextStyle(color: Colors.white)),
                  );
                }
                return null; // Return null if the condition isn't met
              },
              // --- END OF CORRECTED HIGHLIGHTING BUILDERS ---
            ),
// ...
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
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: ValueNotifier(_getEventsForDay(_selectedDay ?? DateTime.now())), // Rebuilds on day selection
              builder: (context, value, _) {
                final eventsForSelectedDay = _getEventsForDay(_selectedDay ?? DateTime.now());
                if (eventsForSelectedDay.isEmpty) {
                  return const Center(child: Text("No events for this day."));
                }
                return ListView.builder(
                  itemCount: eventsForSelectedDay.length,
                  itemBuilder: (context, index) {
                    final event = eventsForSelectedDay[index];
                    bool isSelected = _selectedEvent == event;
                    return Card(
                      color: isSelected ? _highlightColor.withOpacity(0.5) : null,
                      child: ListTile(
                        title: Text(event.title),
                        subtitle: Text(event.description ?? 'No description'),
                        onTap: () {
                          setState(() {
                            _selectedEvent = event;
                            _highlightStart = event.start;
                            _highlightEnd = event.end.add(const Duration(days:1)); // for calendar range
                            // Try to find the color previously used for this event
                            // This part needs a more robust way to link events to colors if they should persist
                            int foundColorIndex = -1;
                            // This is a simplistic way, better to store color with event or have a map
                            if (_events[_normalizeDate(event.start)]?.firstWhere((e) => e == event, orElse: () => Event(title: "", start: DateTime.now(), end: DateTime.now())) == event) {
                              // This logic is flawed for finding the exact color used
                              // For now, just cycle or pick based on selection
                              _colorIndex = (_colorIndex + 1) % _highlightColors.length; // Simple cycle
                            }
                            _highlightColor = _highlightColors[_colorIndex];

                            _focusedDay = event.start; // Focus the calendar on the event's start day
                          });
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditEventDialog(event),
                        ),
                      ),
                    );
                  },
                );
<<<<<<< HEAD
              },
=======
                _manualEvents.add(event); // <-- add to manual events
                for (var date = event.start;
                !date.isAfter(event.end);
                date = date.add(const Duration(days: 1))) {
                  final key = _normalizeDate(date);
                  _events.putIfAbsent(key, () => []);
                  if (!_events[key]!.contains(event)) _events[key]!.add(event);
                }
                setState(() {});
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
>>>>>>> d8714224393271f58169bb0452a1b073eaee647f
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventsMarker(DateTime date, List<Event> events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue[400],
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

  final List<Event> _manualEvents = [];

  Future<void> _loadTasksAsEvents() async {
    final tasks = await DatabaseService().getTasks();
    print("Loaded tasks: ${tasks.map((t) => '${t.title} ${t.startDate} ${t.endDate}').toList()}"); // <-- Add this line
    setState(() {
      _events.clear();
      // Add tasks from database
      for (final task in tasks) {
        if (task.startDate != null) {
          final event = Event(
            title: task.title,
            description: '', // You can add a description field to Task if you want
            start: DateTime(task.startDate!.year, task.startDate!.month, task.startDate!.day),
            end: task.endDate != null
                ? DateTime(task.endDate!.year, task.endDate!.month, task.endDate!.day)
                : DateTime(task.startDate!.year, task.startDate!.month, task.startDate!.day),
          );
          for (var date = event.start;
              !date.isAfter(event.end);
              date = date.add(const Duration(days: 1))) {
            final key = _normalizeDate(date);
            _events.putIfAbsent(key, () => []);
            if (!_events[key]!.contains(event)) _events[key]!.add(event);
          }
        }
      }
      // Add manual events
      for (final event in _manualEvents) {
        for (var date = event.start;
            !date.isAfter(event.end);
            date = date.add(const Duration(days: 1))) {
          final key = _normalizeDate(date);
          _events.putIfAbsent(key, () => []);
          if (!_events[key]!.contains(event)) _events[key]!.add(event);
        }
      }
    });
  }
}