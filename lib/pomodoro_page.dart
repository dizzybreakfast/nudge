import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  int _selectedStudyMinutes = 25;
  int _selectedBreakMinutes = 5;
  int _remainingTime = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;
  bool _isStudyPhase = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadTimerState();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload == 'start_break') {
          _startBreakTimer();
        }
      },
    );
  }

  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    setState(() {
      _remainingTime = _selectedStudyMinutes * 60;
      _isRunning = true;
      _isStudyPhase = true;
    });

    _startBackgroundTimer();
    _saveTimerState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
        _showNotification();
        _saveTimerState();
      } else {
        timer.cancel();
        _notifyStudyComplete();
      }
    });
  }

  void _notifyStudyComplete() async {
    setState(() {
      _isRunning = false;
    });

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Timer',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      actions: [ // Interactive actions for break decision
        AndroidNotificationAction(
          'start_break',
          'Start Break',
        ),
        AndroidNotificationAction(
          'end_session',
          'End Session',
        ),
      ],
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      1,
      'Study Session Complete!',
      'Would you like to start your break now?',
      platformChannelSpecifics,
      payload: 'start_break',
    );
  }

  void _startBreakTimer() {
    setState(() {
      _remainingTime = _selectedBreakMinutes * 60;
      _isStudyPhase = false;
      _isRunning = true;
    });

    _startBackgroundTimer();
    _saveTimerState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
        _showNotification();
        _saveTimerState();
      } else {
        timer.cancel();
        _showNotification(message: 'Break Complete! Ready to start again?');
        setState(() {
          _isRunning = false;
        });
      }
    });
  }

  void _showNotification({String message = 'Pomodoro Running...'}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Timer',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      onlyAlertOnce: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      message,
      '${_isStudyPhase ? "Study" : "Break"} Time: ${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}',
      platformChannelSpecifics,
    );
  }

  void _startBackgroundTimer() {
    FlutterForegroundTask.startService(
      notificationTitle: 'Pomodoro Timer Running',
      notificationText: 'Remaining time: ${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}',
      callback: _backgroundTask,
    );
  }

  void _backgroundTask() async {
    while (_remainingTime > 0) {
      await Future.delayed(const Duration(seconds: 1));
      _remainingTime--;
      FlutterForegroundTask.updateService(
        notificationText: 'Remaining time: ${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}',
      );
    }
    FlutterForegroundTask.stopService();
  }

  void _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('remaining_time', _remainingTime);
    prefs.setBool('is_running', _isRunning);
  }

  void _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _remainingTime = prefs.getInt('remaining_time') ?? (_selectedStudyMinutes * 60);
      _isRunning = prefs.getBool('is_running') ?? false;
    });

    if (_isRunning) {
      _startBackgroundTimer();
    }
  }

  void _resetTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    setState(() {
      _remainingTime = _selectedStudyMinutes * 60;
      _isRunning = false;
      _isStudyPhase = true;
    });
    flutterLocalNotificationsPlugin.cancel(0);
    flutterLocalNotificationsPlugin.cancel(1);
    FlutterForegroundTask.stopService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isStudyPhase ? 'Study Time' : 'Break Time',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Slider(
              value: _selectedStudyMinutes.toDouble(),
              min: 5,
              max: 60,
              label: 'Study: $_selectedStudyMinutes min',
              onChanged: _isRunning ? null : (value) {
                setState(() {
                  _selectedStudyMinutes = value.toInt();
                  _remainingTime = _selectedStudyMinutes * 60;
                });
              },
            ),
            Slider(
              value: _selectedBreakMinutes.toDouble(),
              min: 1,
              max: 30,
              label: 'Break: $_selectedBreakMinutes min',
              onChanged: _isRunning ? null : (value) {
                setState(() {
                  _selectedBreakMinutes = value.toInt();
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _isRunning ? null : _startTimer, child: const Text('Start')),
                ElevatedButton(onPressed: _resetTimer, child: const Text('Reset')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}