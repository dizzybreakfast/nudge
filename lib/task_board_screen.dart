import 'dart:ui';
import 'package:flutter/material.dart';
import 'models/task.dart';
import 'services/database.dart';

class TaskBoardScreen extends StatefulWidget {
  const TaskBoardScreen({Key? key}) : super(key: key);

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
  final Color backgroundColor = Color(0xFFF3F0FA);
  final Color cardColor = Color(0xFFFDFDFE);
  final Color borderColor = Color(0xFFE0E3E7);
  final Color primaryColor = Color(0xFF22223B);
  final Color accentColor = Color(0xFF673AB7);
  final Color textPrimary = Color(0xFF22223B);
  final Color textSecondary = Color(0xFF6C757D);
  final Color cardBackground = Color(0xFF673AB7).withOpacity(0.06);
  final Color cardTextColor = Color(0xFF22223B);

  final List<String> columnNames = ['To Do', 'In Progress', 'Done'];

  final Map<String, bool> columnHighlight = {
    'To Do': false,
    'In Progress': false,
    'Done': false,
  };

  List<Task> tasks = [];
  bool _tasksChanged = false;

  void _showAddTaskDialog() {
    final TextEditingController controller = TextEditingController();
    final TextEditingController descriptionController = TextEditingController(); 
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.95),
                    child: AlertDialog(
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
                      content: Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: descriptionController, // <-- Add this
                                maxLines: 3,
                                cursorColor: accentColor,
                                decoration: InputDecoration(
                                  hintText: 'Enter description (optional)',
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
                                      : "Start: "+startDate!.toLocal().toString().split(' ')[0],
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
                                      : "End: "+(endDate != null ? endDate!.toLocal().toString().split(' ')[0] : ''),
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
                          onPressed: controller.text.trim().isEmpty
                              ? null
                              : () async {
                                  print('Add button pressed');
                                  print('Task title: ' + controller.text.trim());
                                  final columnTasks = tasks
                                      .where((t) => t.column == 'To Do')
                                      .toList();
                                  final lastOrder = columnTasks.isEmpty
                                      ? -1
                                      : columnTasks.map((t) => t.order).reduce((a, b) => a > b ? a : b);
                                  final task = Task(
                                    title: controller.text.trim(),
                                    description: descriptionController.text.trim(), // <-- Add this
                                    column: 'To Do',
                                    startDate: startDate,
                                    endDate: endDate,
                                    order: lastOrder + 1,
                                  );
                                  print('Inserting task: ' + task.title);
                                  try {
                                    await DatabaseService().insertTask(task);
                                    print('Task inserted');
                                    _tasksChanged = true;
                                    Navigator.of(context).pop(true);
                                    _loadTasks();
                                  } catch (e, stack) {
                                    print('Error inserting task: ' + e.toString());
                                    print(stack);
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Error Adding Task'),
                                          content: Text(e.toString()),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: Text(
                            'Add',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _loadTasks() async {
    tasks = await DatabaseService().getTasks();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    bool changed = false;

    for (final task in tasks) {
      String? newColumn;

      // Normalize dates to ignore time part
      final start = task.startDate != null
          ? DateTime(task.startDate!.year, task.startDate!.month, task.startDate!.day)
          : null;
      final end = task.endDate != null
          ? DateTime(task.endDate!.year, task.endDate!.month, task.endDate!.day)
          : null;

      // Move to "Done" if end date is before today
      if (end != null && end.isBefore(todayDate)) {
        if (task.column != 'Done') newColumn = 'Done';
      }
      // Move to "In Progress" if start date is today or earlier and end date is today or later
      else if (start != null && start.isBefore(todayDate.add(const Duration(days: 1))) &&
          (end == null || end.isAfter(todayDate.subtract(const Duration(days: 1))))) {
        if (task.column != 'In Progress') newColumn = 'In Progress';
      }

      if (newColumn != null) {
        await DatabaseService().updateTaskColumn(task.id!, newColumn);
        changed = true;
      }
    }

    if (changed) {
      // Re-fetch tasks if any were updated
      tasks = await DatabaseService().getTasks();
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_tasksChanged);
        return false;
      },
      child: Scaffold(
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
      ),
    );
  }

  Widget buildColumn(String columnName) {
    final columnTasks = tasks
        .where((t) => t.column == columnName)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return DragTarget<Task>(
      onWillAccept: (task) {
        setState(() => columnHighlight[columnName] = true);
        return task != null && task.column != columnName;
      },
      onLeave: (_) => setState(() => columnHighlight[columnName] = false),
      onAccept: (task) async {
        final targetColumnTasks = tasks
            .where((t) => t.column == columnName)
            .toList();
        final lastOrder = targetColumnTasks.isEmpty
            ? -1
            : targetColumnTasks.map((t) => t.order).reduce((a, b) => a > b ? a : b);

        await DatabaseService().updateTaskColumnAndOrder(task.id!, columnName, lastOrder + 1);
        _tasksChanged = true;
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
            height: 500,
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
                Flexible(
                  child: ListView(
                    children: [
                      for (final task in columnTasks)
                        Padding(
                          key: ValueKey(task.id),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: LongPressDraggable<Task>(
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
                        ),
                    ],
                  ),
                ),
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

    return GestureDetector(
      onTap: () => _showTaskOptions(task),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: borderColor.withOpacity(0.18), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dateInfo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      dateInfo,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.more_vert, color: borderColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showTaskOptions(Task task) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: accentColor),
                title: Text('Edit Task'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditTaskDialog(task);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete Task'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete Task'),
                      content: Text('Are you sure you want to delete this task?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await DatabaseService().deleteTask(task.id!);
                    _tasksChanged = true;
                    await _loadTasks();
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.close, color: textSecondary),
                title: Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditTaskDialog(Task task) {
    final TextEditingController controller = TextEditingController(text: task.title);
    DateTime? startDate = task.startDate;
    DateTime? endDate = task.endDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Edit Task',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: 20,
                ),
              ),
              content: Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                              : "End: ${endDate != null ? endDate!.toLocal().toString().split(' ')[0] : ''}",
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
                    final updatedTask = Task(
                      id: task.id,
                      title: controller.text.trim(),
                      column: task.column,
                      startDate: startDate,
                      endDate: endDate,
                      order: task.order,
                    );
                    await DatabaseService().insertTask(updatedTask);
                    _tasksChanged = true;
                    Navigator.of(context).pop(true);
                    _loadTasks();
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Future<void> _reorderTasks(List<Task> columnTasks, int oldIndex, int newIndex, String columnName) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final task = columnTasks.removeAt(oldIndex);
    columnTasks.insert(newIndex, task);

    // Update order in DB for all tasks in this column
    for (int i = 0; i < columnTasks.length; i++) {
      await DatabaseService().updateTaskOrder(columnTasks[i].id!, i);
    }
    await _loadTasks();
  }
}
