import 'dart:ui';
import 'package:flutter/material.dart';
import 'models/task.dart'; // Make sure to import your Task model
import 'services/database.dart'; // Make sure to import your DatabaseService

class TaskBoardScreen extends StatefulWidget {
  const TaskBoardScreen({Key? key}) : super(key: key);

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
  final Color backgroundColor = Color(0xFFF3F0FA);   // Soft off-white background
  final Color cardColor = Color(0xFFFDFDFE);         // Softer off-white for cards
  final Color borderColor = Color(0xFFE0E3E7);       // Light gray border
  final Color primaryColor = Color(0xFF22223B);      // Charcoal for text
  final Color accentColor = Color(0xFF673AB7);       // Deep Purple
  final Color textPrimary = Color(0xFF22223B);       // Charcoal
  final Color textSecondary = Color(0xFF6C757D);     // Cool Gray
  final Color cardBackground = Color(0xFF673AB7).withOpacity(0.06); // subtle accent
  final Color cardTextColor = Color(0xFF22223B);     // Charcoal

  // Remove the old columns map!
  // Use a fixed list of column names:
  final List<String> columnNames = ['To Do', 'In Progress', 'Done'];

  final Map<String, bool> columnHighlight = {
    'To Do': false,
    'In Progress': false,
    'Done': false,
  };

  List<Task> tasks = [];

  void _showAddTaskDialog() {
    final TextEditingController controller = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Add New Task',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: 20,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      cursorColor: accentColor,
                      decoration: InputDecoration(
                        hintText: 'Enter task name',
                        hintStyle: TextStyle(color: textSecondary),
                        filled: true,
                        fillColor: backgroundColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                      style: TextStyle(color: primaryColor),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(
                        startDate == null
                            ? "Pick start date"
                            : "Start: ${startDate!.toLocal().toString().split(' ')[0]}",
                        style: TextStyle(color: primaryColor),
                      ),
                      trailing: Icon(Icons.calendar_today, color: accentColor),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() {
                          startDate = picked;
                          if (endDate != null && endDate!.isBefore(startDate!)) {
                            endDate = picked;
                          }
                        });
                      },
                    ),
                    ListTile(
                      title: Text(
                        endDate == null
                            ? "Pick end date"
                            : "End: ${endDate!.toLocal().toString().split(' ')[0]}",
                        style: TextStyle(color: primaryColor),
                      ),
                      trailing: Icon(Icons.calendar_today, color: accentColor),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? startDate ?? DateTime.now(),
                          firstDate: startDate ?? DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => endDate = picked);
                      },
                    ),
                  ],
                ),
              ),
              actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: TextStyle(color: textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    if (controller.text.trim().isEmpty) return;
                    final task = Task(
                      title: controller.text.trim(),
                      column: 'To Do',
                      startDate: startDate,
                      endDate: endDate,
                    );
                    await DatabaseService().insertTask(task);
                    Navigator.of(context).pop(true); // Pass 'true' to indicate a new task was added
                    _loadTasks();
                  },
                  child: Text(
                    'Add',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadTasks() async {
    tasks = await DatabaseService().getTasks();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Task Board',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add, size: 28, color: Colors.white),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: columnNames.map((columnName) {
            return buildColumn(columnName);
          }).toList(),
        ),
      ),
    );
  }

  Widget buildColumn(String columnName) {
    final columnTasks = tasks.where((t) => t.column == columnName).toList();
    return DragTarget<Task>(
      onWillAccept: (_) {
        setState(() => columnHighlight[columnName] = true);
        return true;
      },
      onLeave: (_) => setState(() => columnHighlight[columnName] = false),
      onAccept: (task) async {
        print('Dragged task: ${task.title}, id: ${task.id}, from: ${task.column} to: $columnName');
        await DatabaseService().updateTaskColumn(task.id!, columnName);
        await _loadTasks();
        setState(() => columnHighlight[columnName] = false);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 280,
          margin: EdgeInsets.symmetric(horizontal: 12),
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: columnHighlight[columnName]!
                ? cardColor.withOpacity(0.95)
                : cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: 500, // <-- Add this line (or use MediaQuery for dynamic height)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  columnName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: Scrollbar(
                    child: ListView(
                      physics: BouncingScrollPhysics(),
                      shrinkWrap: true,
                      children: columnTasks.map((task) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Draggable<Task>(
                            data: task,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Opacity(
                                opacity: 0.85,
                                child: buildTaskCard(task),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: buildTaskCard(task),
                            ),
                            child: buildTaskCard(task),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildTaskCard(Task task) {
    String dateInfo = '';
    final localizations = MaterialLocalizations.of(context);

    if (task.startDate != null && task.endDate != null) {
      final String formattedStartDate = localizations.formatShortDate(task.startDate!);
      final String formattedEndDate = localizations.formatShortDate(task.endDate!);
      dateInfo = "Work on: $formattedStartDate\nDeadline: $formattedEndDate";
    } else if (task.startDate != null) {
      final String formattedStartDate = localizations.formatShortDate(task.startDate!);
      dateInfo = "Work on: $formattedStartDate";
    } else if (task.endDate != null) {
      final String formattedEndDate = localizations.formatShortDate(task.endDate!);
      dateInfo = "Deadline: $formattedEndDate";
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: cardColor, // Using the defined cardColor for background
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: TextStyle(
              color: textPrimary, // Using defined textPrimary
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (dateInfo.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              dateInfo,
              style: TextStyle(
                color: textSecondary, // Using defined textSecondary
                fontSize: 13,
                height: 1.4, // Improves readability for multi-line text
              ),
            ),
          ],
        ],
      ),
    );
  }
}
