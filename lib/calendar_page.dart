import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // Add this import
import 'task_board_screen.dart';
import 'event.dart';
//import 'event_dialog.dart';


class CalendarPage extends StatefulWidget { // Change to StatefulWidget
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState(); // Add this
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _clearHighlight,
      child: Scaffold(
        appBar: AppBar(title: const Text("Calendar"),
        actions: [
          IconButton(
            icon: Icon(Icons.view_kanban),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TaskBoardScreen()),
              );
            },
          ),
        ]),
        body: Column(
          children: [
            TableCalendar<Event>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) => _events[_normalizeDate(day)] ?? [],
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
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: _events.entries
                    .where((e) => isSameDay(e.key, _selectedDay ?? _focusedDay))
                    .expand((e) => e.value.toSet())
                    .map((event) {
                  final isSelected = _selectedEvent == event;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedEvent != event) {
                          _highlightStart = _normalizeDate(event.start);
                          _highlightEnd = _normalizeDate(event.end.add(const Duration(days: 1)));
                          //_highlightEnd = _normalizeDate(event.end); reenable ts if something goes wrong, only for correct highlighting
                          _selectedEvent = event;
                          _colorIndex = (_colorIndex + 1) % _highlightColors.length;
                          _highlightColor = _highlightColors[_colorIndex];
                        } else {
                          _highlightStart = _normalizeDate(event.start);
                          _highlightEnd = _normalizeDate(event.end.add(const Duration(days: 1)));
                          //_highlightEnd = _normalizeDate(event.end);
                        }
                      });
                    },
                    onLongPress: () {
                      _clearHighlight();
                      _showEditDeleteDialog(event);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey[300] : Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${event.start.toLocal().toString().split(" ")[0]} → ${event.end.toLocal().toString().split(" ")[0]}',
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(event.description ?? "No description"),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEventDialog(context),
          child: const Icon(Icons.add),
        ),
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
        title: const Text("Add Event"),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
              const SizedBox(height: 10),
              ListTile(
                title: Text("Start: ${start.toLocal().toString().split(' ')[0]}"),
                trailing: const Icon(Icons.calendar_today),
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
              ListTile(
                title: Text("End: ${end.toLocal().toString().split(' ')[0]}"),
                trailing: const Icon(Icons.calendar_today),
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
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
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
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showEditDeleteDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modify "${event.title}"'),
        actions: [
          TextButton(
            onPressed: () {
              _deleteEvent(event);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close current dialog
              _showEditEventDialog(event); // Open edit dialog
            },
            child: const Text("Edit"),
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
        title: const Text("Edit Event"),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
              const SizedBox(height: 10),
              ListTile(
                title: Text("Start: ${start.toLocal().toString().split(' ')[0]}"),
                trailing: const Icon(Icons.calendar_today),
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
              ListTile(
                title: Text("End: ${end.toLocal().toString().split(' ')[0]}"),
                trailing: const Icon(Icons.calendar_today),
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
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                // Remove old event from all relevant dates
                setState(() {
                  for (var date = oldEvent.start;
                      !date.isAfter(oldEvent.end);
                      date = date.add(const Duration(days: 1))) {
                    final key = _normalizeDate(date);
                    _events[key]?.removeWhere((e) => e == oldEvent);
                  }
                  _events.removeWhere((_, list) => list.isEmpty);

                  // Add updated event
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
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

}
