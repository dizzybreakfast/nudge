import 'package:flutter/material.dart';
import 'package:nudge/calendar_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void main() {
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
            brightness: Brightness.light,
            primarySwatch: Colors.deepPurple, // Example primary color
            // Define other light theme properties if needed
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.teal, // Example primary color for dark theme
            scaffoldBackgroundColor: Colors.grey[850], // Dark background
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[900], // Dark app bar
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            cardColor: Colors.grey[800], // Dark card color
            iconTheme: const IconThemeData(color: Colors.white70), // Icons
            textTheme: const TextTheme( // Define text styles for dark theme
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              titleLarge: TextStyle(color: Colors.white),
            ),
            // Add other dark theme properties as needed
            // For example, button themes, dialog themes, etc.
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal, // Seed color for dark theme
                brightness: Brightness.dark,
                background: Colors.grey[850]!,
                surface: Colors.grey[800]!,
                onBackground: Colors.white,
                onSurface: Colors.white,
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const CalendarPage(),
        );
      },
    );
  }
}
