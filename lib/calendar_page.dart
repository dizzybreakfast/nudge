// At the top of your calendar_page.dart file

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
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
    // _loadTasksAsEvents(); // If you have this method and want to load tasks
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
    // final bool isNewEvent = true; // Flag for new event - removed as it's unused

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
                              context: stfContext, // Use StatefulBuilder's context for dialogs within dialog
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
                              context: stfContext, // Use StatefulBuilder's context
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
                      controller: _titleController, // Make sure controller is assigned
                      decoration: const InputDecoration(hintText: "Event Title"),
                    ),
                    TextField(
                      controller: _descriptionController, // Make sure controller is assigned
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
                      );

                      setState(() {
                        // Remove the original event from all dates it spanned
                        for (var date = originalEvent.start; !date.isAfter(originalEvent.end); date = date.add(const Duration(days: 1))) {
                          final key = _normalizeDate(date);
                          _events[key]?.removeWhere((e) =>
                            e.title == originalEvent.title && // Using a simple comparison, consider a unique ID if available
                            e.start == originalEvent.start &&
                            e.end == originalEvent.end);
                          if (_events[key]?.isEmpty ?? false) {
                            _events.remove(key);
                          }
                        }

                        // Add the updated event
                        for (var date = updatedEvent.start; !date.isAfter(updatedEvent.end); date = date.add(const Duration(days: 1))) {
                           final key = _normalizeDate(date);
                          _events.putIfAbsent(key, () => []);
                          // Ensure not to add duplicates if logic allows (e.g. if event could already exist)
                          if (!_events[key]!.any((e) => e.title == updatedEvent.title && e.start == updatedEvent.start && e.end == updatedEvent.end)) {
                            _events[key]!.add(updatedEvent);
                          }
                        }

                        // Update highlight if the selected event was the one edited
                        if (_selectedEvent?.title == originalEvent.title &&
                            _selectedEvent?.start == originalEvent.start &&
                            _selectedEvent?.end == originalEvent.end) {
                          _selectedEvent = updatedEvent;
                          _highlightStart = updatedEvent.start;
                          _highlightEnd = updatedEvent.end.add(const Duration(days:1));
                          // Keep the same color or re-assign if needed
                        } else {
                          _clearHighlight(); // Or decide on other highlight behavior
                        }
                      });

                      // --- MODIFICATION FOR NOTIFICATION SERVICE ---
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
              todayBuilder: (context, date, focusedDay) {
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
                if (_highlightEnd != null && _normalizeDate(date) == _normalizeDate(_highlightEnd!.subtract(const Duration(days:1)))) {
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
                    !isSameDay(date, _highlightEnd!.subtract(const Duration(days:1))) &&
                    date.isAfter(_highlightStart!) &&
                    date.isBefore(_highlightEnd!.subtract(const Duration(days:1)))) {
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
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: ValueNotifier(_getEventsForDay(_selectedDay ?? DateTime.now())),
              builder: (context, value, _) {
                // It's better to fetch eventsForSelectedDay directly inside builder
                // to ensure it's always up-to-date with _selectedDay
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
                            // This logic for color finding is a bit complex and might not always find the original color.
                            // A more robust way would be to store the color index with the event or use a map.
                            // For now, we'll stick to cycling colors on selection.
                            _colorIndex = (_colorIndex + 1) % _highlightColors.length;
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
              },
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
        color: Colors.blue[400], // Consider making this color dynamic or theme-based
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

  // _manualEvents and _loadTasksAsEvents are removed as they were part of the conflicting code
  // and not fully integrated with the HEAD version. If task loading is needed,
  // it should be re-integrated carefully.
  // final List<Event> _manualEvents = [];

  // Future<void> _loadTasksAsEvents() async {
  //   // This method would need to be adapted if you use a DatabaseService
  //   // For example, if you have a DatabaseService:
  //   // final tasks = await DatabaseService().getTasks();
  //   // print("Loaded tasks: ${tasks.map((t) => '${t.title} ${t.startDate} ${t.endDate}').toList()}");
  //   setState(() {
  //     _events.clear();
  //     // Add tasks from database
  //     // for (final task in tasks) { ... }
  //     // Add manual events
  //     // for (final event in _manualEvents) { ... }
  //   });
  // }
}