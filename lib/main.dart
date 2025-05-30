import 'package:flutter/material.dart';
import 'package:nudge/calendar_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'notification_service.dart'; // Keep this import if other parts of main need it, or remove if not.

// Added ThemeProvider class
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themeModeKey = 'themeMode';

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  void toggleTheme(bool isDarkMode) {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _saveThemeMode();
    notifyListeners();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeModeKey);
    if (themeModeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_themeModeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }
}

Future<void> main() async { // Changed to async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized
  // await NotificationService.initialize(); // REMOVE THIS LINE
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Nudge',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
              surface: Colors.grey[200]!,
              onSurface: Colors.black,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.teal, 
            scaffoldBackgroundColor: Colors.grey[850],
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[900],
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            cardColor: Colors.grey[800],
            iconTheme: const IconThemeData(color: Colors.white70),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              titleLarge: TextStyle(color: Colors.white),
            ),
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: Brightness.dark,
                surface: Colors.grey[800]!,
                onSurface: Colors.white,
            )
          ),
          themeMode: themeProvider.themeMode,
          home: const CalendarPage(),
        );
      },
    );
  }
}
