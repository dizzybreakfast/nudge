import 'package:flutter/material.dart';

class CustomBottomNavWidget extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavWidget> createState() => _CustomBottomNavWidgetState();
}

class _CustomBottomNavWidgetState extends State<CustomBottomNavWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme context

    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
      type: BottomNavigationBarType.fixed, // To ensure all items are visible and have labels
      selectedItemColor: theme.colorScheme.primary, // Use theme color
      unselectedItemColor: theme.unselectedWidgetColor, // Use theme color for unselected items
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book), // Icon for Study
          label: 'Study',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard), // Icon for Leaderboard
          label: 'Leaderboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline), // Icon for Contribute
          label: 'Contribute',
        ),
      ],
    );
  }
}
