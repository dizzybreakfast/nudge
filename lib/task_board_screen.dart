import 'dart:ui';
import 'package:flutter/material.dart';

class TaskBoardScreen extends StatefulWidget {
  const TaskBoardScreen({Key? key}) : super(key: key);

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
  final Color backgroundColor = Color(0xFFF7F7FA);   // Soft off-white background
  final Color cardColor = Color(0xFFFDFDFE);         // Softer off-white for cards
  final Color borderColor = Color(0xFFE0E3E7);       // Light gray border
  final Color primaryColor = Color(0xFF22223B);      // Charcoal for text
  final Color accentColor = Color(0xFF5BC0BE);       // Modern Teal
  final Color textPrimary = Color(0xFF22223B);       // Charcoal
  final Color textSecondary = Color(0xFF6C757D);     // Cool Gray
  final Color cardBackground = Color(0xFF5BC0BE).withOpacity(0.06); // even subtler accent
  final Color cardTextColor = Color(0xFF22223B);     // Charcoal

  Map<String, List<String>> columns = {
    'To Do': ['Task 1', 'Task 2'],
    'In Progress': ['Task 3'],
    'Done': ['Task 4'],
  };

  final Map<String, bool> columnHighlight = {
    'To Do': false,
    'In Progress': false,
    'Done': false,
  };

  void _showAddTaskDialog() {
    String newTask = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor, // Use dark card color
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Add New Task',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryColor,
              fontSize: 20,
            ),
          ),
          content: TextField(
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
            onChanged: (value) => newTask = value,
            onSubmitted: (_) {
              _addTask(newTask);
              Navigator.of(context).pop();
            },
            style: TextStyle(color: primaryColor),
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
              onPressed: () {
                _addTask(newTask);
                Navigator.of(context).pop();
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
  }

  void _addTask(String task) {
    if (task.trim().isEmpty) return;

    setState(() {
      columns['To Do']!.add(task.trim());
    });
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
          children: columns.keys.map((columnName) {
            return buildColumn(columnName, columns[columnName]!);
          }).toList(),
        ),
      ),
    );
  }

  Widget buildColumn(String columnName, List<String> tasks) {
    return DragTarget<String>(
      onWillAccept: (_) {
        setState(() => columnHighlight[columnName] = true);
        return true;
      },
      onLeave: (_) => setState(() => columnHighlight[columnName] = false),
      onAccept: (task) {
        setState(() {
          columns.forEach((key, value) => value.remove(task));
          columns[columnName]!.add(task);
          columnHighlight[columnName] = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 280,
          height: 500,
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
                child: ListView(
                  physics: BouncingScrollPhysics(),
                  shrinkWrap: true,
                  children: tasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Draggable<String>(
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
              )
            ],
          ),
        );
      },
    );
  }

  Widget buildTaskCard(String task) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: accentColor, width: 4), // Accent bar
        ),
      ),
      child: ListTile(
        title: Text(
          task,
          style: TextStyle(
            color: cardTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        dense: true,
      ),
    );
  }
}
