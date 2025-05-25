import 'dart:ui';
import 'package:flutter/material.dart';

class TaskBoardScreen extends StatefulWidget {
  const TaskBoardScreen({Key? key}) : super(key: key);

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
  final Color primaryColor = Color(0xFF3A5068);
  final Color navyBlue = Color(0xFF1A237E); // Navy Blue
  final Color backgroundColor = Color(0xFFF4F7F6);
  final Color cardTextColor = Colors.white;

  Map<String, List<String>> columns = {
    'To Do': ['Task 1', 'Task 2'],
    'In Progress': ['Task 3'],
    'Done': ['Task 4'],
  };

  void _showAddTaskDialog() {
    String newTask = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            cursorColor: primaryColor,
            decoration: InputDecoration(
              hintText: 'Enter task name',
              hintStyle: TextStyle(color: primaryColor.withOpacity(0.5)),
              filled: true,
              fillColor: backgroundColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
            onChanged: (value) => newTask = value,
            onSubmitted: (_) {
              _addTask(newTask);
              Navigator.of(context).pop();
            },
            style: TextStyle(color: Colors.black87),
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: primaryColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
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
                  color: Colors.white,
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
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 26,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: navyBlue,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add, size: 28, color: Colors.white),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Row(
          children: columns.keys.map((columnName) {
            return buildColumn(columnName, columns[columnName]!);
          }).toList(),
        ),
      ),
    );
  }

  Widget buildColumn(String columnName, List<String> tasks) {
    return Container(
      width: 280,
      margin: EdgeInsets.symmetric(horizontal: 14),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            columnName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 20),
          Flexible(
            child: DragTarget<String>(
              onWillAccept: (_) => true,
              onAccept: (task) {
                setState(() {
                  columns.forEach((key, value) => value.remove(task));
                  columns[columnName]!.add(task);
                });
              },
              builder: (context, candidateData, rejectedData) {
                return ListView(
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
                        childWhenDragging: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 18),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            task,
                            style: TextStyle(
                              color: primaryColor.withOpacity(0.5),
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        child: buildTaskCard(task),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget buildTaskCard(String task) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: navyBlue.withOpacity(0.7), // translucent navy blue
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: navyBlue.withOpacity(0.5),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            task,
            style: TextStyle(
              color: cardTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
