import 'package:flutter/material.dart';
import 'models/task.dart';
import 'services/database.dart';

class TaskBoardScreen extends StatefulWidget {
  const TaskBoardScreen({Key? key}) : super(key: key);

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
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

    // Get theme colors
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final borderColor = theme.dividerColor;

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
                                controller: descriptionController,
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
                                  if (picked != null) {
                                    setState(() {
                                    startDate = picked;
                                    if (endDate != null && endDate!.isBefore(startDate!)) {
                                      endDate = picked;
                                    }
                                  });
                                  }
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
                      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: controller.text.trim().isEmpty
                              ? null
                              : () async {
                                  /*print('Add button pressed');*/
                                  /*print('Task title: ${controller.text.trim()}');*/
                                  final columnTasks = tasks
                                      .where((t) => t.column == 'To Do')
                                      .toList();
                                  final lastOrder = columnTasks.isEmpty
                                      ? -1
                                      : columnTasks.map((t) => t.order).reduce((a, b) => a > b ? a : b);
                                  final task = Task(
                                    title: controller.text.trim(),
                                    description: descriptionController.text.trim(), 
                                    column: 'To Do',
                                    startDate: startDate,
                                    endDate: endDate,
                                    order: lastOrder + 1,
                                  );
                                  /*print('Inserting task: ${task.title}');*/
                                  try {
                                    await DatabaseService().insertTask(task);
                                    /*print('Task inserted');*/
                                    _tasksChanged = true;
                                    if (!context.mounted) return; // Check mounted before using context
                                    Navigator.of(context).pop(true);
                                    _loadTasks();
                                  } catch (e) { // Removed unused stack trace variable
                                    /*print('Error inserting task: $e');*/
                                    if (context.mounted) { // Check mounted before using context
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Error Adding Task'),
                                          content: Text(e.toString()),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: const Text('OK'),
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
                              color: theme.colorScheme.onSecondary, // Use onSecondary for text on accentColor
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
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        _showExitConfirmationDialog(context);
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
          child: Icon(Icons.add, size: 28, color: theme.colorScheme.onSecondary), // Use onSecondary
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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

    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;
    final primaryColor = theme.colorScheme.primary;


    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) { // Changed task to details to access data property
        setState(() => columnHighlight[columnName] = true);
        return details.data.column != columnName; // Removed redundant null check, accessed column via details.data
      },
      onLeave: (_) => setState(() => columnHighlight[columnName] = false),
      onAcceptWithDetails: (details) async { // Changed task to details
        final targetColumnTasks = tasks
            .where((t) => t.column == columnName)
            .toList();
        final lastOrder = targetColumnTasks.isEmpty
            ? -1
            : targetColumnTasks.map((t) => t.order).reduce((a, b) => a > b ? a : b);

        await DatabaseService().updateTaskColumnAndOrder(details.data.id!, columnName, lastOrder + 1); // Accessed id via details.data
        _tasksChanged = true;
        await _loadTasks();
        setState(() => columnHighlight[columnName] = false);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 280,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: columnHighlight[columnName]!
                ? cardColor.withAlpha(242) // 0.95 * 255 = 242.25
                : cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withAlpha(31), // Replace withOpacity with withAlpha
                blurRadius: 6,
                offset: const Offset(0, 2),
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
                const SizedBox(height: 16),
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
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface.withAlpha(178); // 0.7 * 255 = 178.5
    final borderColor = theme.dividerColor;
    final accentColor = theme.colorScheme.secondary;

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
          color: theme.cardColor, // Use theme card color
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: borderColor.withAlpha(46), width: 1), // 0.18 * 255 = 45.9
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withAlpha(10), // 0.04 * 255 = 10.2
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
                color: accentColor.withAlpha(179), // 0.7 * 255 = 178.5
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
      backgroundColor: Theme.of(context).cardColor, // Use theme card color for modal
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final accentColor = theme.colorScheme.secondary;
        final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.grey;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: accentColor),
                title: Text('Edit Task', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                onTap: () {
                  Navigator.pop(context);
                  _showEditTaskDialog(task);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: theme.colorScheme.error), // Use theme error color
                title: Text('Delete Task', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: theme.dialogTheme.backgroundColor, // Use theme dialog background
                      title: Text('Delete Task', style: TextStyle(color: theme.textTheme.titleLarge?.color)),
                      content: Text('Are you sure you want to delete this task?', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: TextStyle(color: theme.colorScheme.primary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)), // Use theme error color
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
                title: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
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
    final TextEditingController descriptionController = TextEditingController(text: task.description); // Initialize with task.description
    DateTime? startDate = task.startDate;
    DateTime? endDate = task.endDate;

    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final borderColor = theme.dividerColor;


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
                            borderRadius: BorderRadius.circular(12), // Added border radius
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), // Added border radius
                            borderSide: BorderSide(color: accentColor),
                          ),
                        ),
                        style: TextStyle(color: primaryColor),
                      ),
                      const SizedBox(height: 12),
                      TextField( // Added description field
                        controller: descriptionController,
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
                              ? "Pick start date" // Added missing text for null case
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
                             builder: (context, child) { // Apply theme to DatePicker
                              return Theme(
                                data: theme.copyWith(
                                  colorScheme: theme.colorScheme.copyWith(
                                    primary: accentColor, // header background color
                                    onPrimary: theme.colorScheme.onSecondary, // header text color
                                    onSurface: primaryColor, // body text color
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: accentColor, // button text color
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              startDate = picked;
                              if (endDate != null && endDate!.isBefore(startDate!)) {
                                endDate = picked;
                              }
                            });
                          }
                        },
                      ),
                      ListTile(
                        title: Text(
                          endDate == null
                              ? "Pick end date" // Added missing text for null case
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
                            builder: (context, child) { // Apply theme to DatePicker
                              return Theme(
                                data: theme.copyWith(
                                  colorScheme: theme.colorScheme.copyWith(
                                    primary: accentColor, // header background color
                                    onPrimary: theme.colorScheme.onSecondary, // header text color
                                    onSurface: primaryColor, // body text color
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: accentColor, // button text color
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) setState(() => endDate = picked);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    if (controller.text.trim().isEmpty) return;
                    final updatedTask = Task(
                      id: task.id,
                      title: controller.text.trim(),
                      description: descriptionController.text.trim(), // save description
                      column: task.column,
                      startDate: startDate,
                      endDate: endDate,
                      order: task.order,
                    );
                    // Ensure you have a method like updateTask in DatabaseService
                    // For now, using insertTask as a placeholder if it handles updates by ID
                    // Or replace with the correct update method e.g., DatabaseService().updateTaskDetails(updatedTask);
                    await DatabaseService().insertTask(updatedTask); 
                    _tasksChanged = true;
                    if (!context.mounted) return; // Check mounted before using context
                    Navigator.of(context).pop(true);
                    _loadTasks();
                  },
                  child: Text(
                    'Save', // Changed from 'Add' to 'Save'
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSecondary), // Use onSecondary
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showExitConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.grey;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Confirm Exit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 20,
            ),
          ),
          content: Text(
            'You have unsaved changes. Do you really want to exit?',
            style: TextStyle(color: textSecondary),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(_tasksChanged);
              },
              child: Text(
                'Exit',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
