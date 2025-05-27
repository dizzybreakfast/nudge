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
    String dateText = '';
    if (task.startDate != null && task.endDate != null) {
      dateText =
      "From: ${task.startDate is DateTime ? task.startDate!.toLocal().toString().split(' ')[0] : ''}  "
          "To: ${task.endDate is DateTime ? task.endDate!.toLocal().toString().split(' ')[0] : ''}";
    } else if (task.startDate != null) {
      dateText = "Date: ${task.startDate is DateTime ? task.startDate!.toLocal().toString().split(' ')[0] : ''}";
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
      ),
      child: ListTile(
        title: Text(
          task.title,
          style: TextStyle(
            color: cardTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: dateText.isNotEmpty
            ? Text(
          dateText,
          style: TextStyle(color: textSecondary, fontSize: 13),
        )
            : null,
        contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        dense: true,
      ),
    );
  }
}
