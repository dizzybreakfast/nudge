import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'task_board_screen.dart';
import 'event.dart';
import 'models/task.dart';
import 'services/database.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<Event>> _events = {};
  DateTime? _highlightStart;
  DateTime? _highlightEnd;
  Color _highlightColor = Colors.orangeAccent;
  int _colorIndex = 0;
  Event? _selectedEvent;

  final List<Color> _highlightColors = [
    Colors.orangeAccent,
    Colors.tealAccent,
    Colors.purpleAccent,
    Colors.greenAccent,
    Colors.blueAccent,
  ];

  DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  void _clearHighlight() {
    setState(() {
      _highlightStart = null;
      _highlightEnd = null;
      _selectedEvent = null;
    });
  }

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
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  calendarStyle: const CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(color: Colors.red),
                    holidayTextStyle: TextStyle(color: Colors.red),
                    selectedDecoration: BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    cellMargin: EdgeInsets.all(4.0),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    weekendStyle: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) => setState(() => _calendarFormat = format),
                  onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, date, _) {
                      final isInRange = _highlightStart != null &&
                          _highlightEnd != null &&
                          !date.isBefore(_highlightStart!) &&
                          !date.isAfter(_highlightEnd!);
                      if (isInRange) {
                        return Container(
                          margin: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color: _highlightColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Events for ${_selectedDay?.day ?? _focusedDay.day}/${_selectedDay?.month ?? _focusedDay.month}/${_selectedDay?.year ?? _focusedDay.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: _events.entries
                    .where((e) => isSameDay(e.key, _selectedDay ?? _focusedDay))
                    .expand((e) => e.value.toSet())
                    .map((event) {
                  final isSelected = _selectedEvent == event;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [Colors.deepPurple.shade50, Colors.deepPurple.shade100]
                            : [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.deepPurple.shade200 : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            if (_selectedEvent != event) {
                              // Select and highlight the event
                              _highlightStart = _normalizeDate(event.start);
                              _highlightEnd = _normalizeDate(event.end.add(const Duration(days: 1)));
                              _selectedEvent = event;
                              _colorIndex = (_colorIndex + 1) % _highlightColors.length;
                              _highlightColor = _highlightColors[_colorIndex];
                            } else {
                              // Toggle off - clear highlight
                              _clearHighlight();
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Event icon and color indicator
                              Container(
                                width: 4,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Event details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${event.start.toLocal().toString().split(" ")[0]} → ${event.end.toLocal().toString().split(" ")[0]}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      event.description?.isNotEmpty == true
                                          ? event.description!
                                          : "No description",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Action buttons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.blue.shade600,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _clearHighlight();
                                        _showEditEventDialog(event);
                                      },
                                      tooltip: 'Edit Event',
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red.shade600,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _showDeleteConfirmation(event);
                                      },
                                      tooltip: 'Delete Event',
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddEventDialog(context),
          backgroundColor: Colors.deepPurple,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Event',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteEvent(event);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime start = _selectedDay ?? _focusedDay;
    DateTime end = start;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Add Event"),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text("Start: ${start.toLocal().toString().split(' ')[0]}"),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: start,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          start = picked;
                          if (end.isBefore(start)) end = picked;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text("End: ${end.toLocal().toString().split(' ')[0]}"),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: end,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && !picked.isBefore(start)) {
                        setState(() => end = picked);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                final event = Event(
                  title: title,
                  description: descriptionController.text.trim(),
                  start: _normalizeDate(start),
                  end: _normalizeDate(end),
                );
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
            ),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _deleteEvent(Event event) {
    setState(() {
      _events.forEach((key, value) {
        value.removeWhere((e) => e == event);
      });
      _events.removeWhere((key, value) => value.isEmpty);
      _clearHighlight();
    });
  }

  void _showEditEventDialog(Event oldEvent) {
    final titleController = TextEditingController(text: oldEvent.title);
    final descriptionController = TextEditingController(text: oldEvent.description);
    DateTime start = oldEvent.start;
    DateTime end = oldEvent.end;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Event"),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text("Start: ${start.toLocal().toString().split(' ')[0]}"),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: start,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          start = picked;
                          if (end.isBefore(start)) end = picked;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text("End: ${end.toLocal().toString().split(' ')[0]}"),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: end,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && !picked.isBefore(start)) {
                        setState(() => end = picked);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                setState(() {
                  for (var date = oldEvent.start;
                  !date.isAfter(oldEvent.end);
                  date = date.add(const Duration(days: 1))) {
                    final key = _normalizeDate(date);
                    _events[key]?.removeWhere((e) => e == oldEvent);
                  }
                  _events.removeWhere((_, list) => list.isEmpty);

                  final updatedEvent = Event(
                    title: title,
                    description: descriptionController.text.trim(),
                    start: _normalizeDate(start),
                    end: _normalizeDate(end),
                  );
                  for (var date = updatedEvent.start;
                  !date.isAfter(updatedEvent.end);
                  date = date.add(const Duration(days: 1))) {
                    final key = _normalizeDate(date);
                    _events.putIfAbsent(key, () => []);
                    _events[key]!.add(updatedEvent);
                  }

                  _selectedEvent = updatedEvent;
                });

                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
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