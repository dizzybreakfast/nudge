import 'package:flutter/material.dart';
import 'package:nudge/authentication_screen.dart';
import 'package:nudge/services/database.dart';
import 'package:nudge/models/account.dart';
import 'package:nudge/widgets/custom_bottom_nav_widget.dart'; // Add this import
import 'package:nudge/widgets/personal_island_widget.dart'; // Add this import

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Account? _currentAccount;
  bool _isLoading = true;
  int _selectedIndex = 0; // For BottomNavigationBar

  @override
  void initState() {
    super.initState();
    _loadAccountDetails();
  }

  Future<void> _loadAccountDetails() async {
    final dbService = DatabaseService();
    List<Account> accounts = await dbService.getSignedAccount();
    if (accounts.isNotEmpty) {
      setState(() {
        _currentAccount = accounts.first;
        _isLoading = false;
      });
    } else {
      // Handle case where no signed-in account is found (should not happen if navigation is correct)
      setState(() {
        _isLoading = false;
      });
      _signOut(); // Or navigate to login
    }
  }

  Future<void> _signOut() async {
    final dbService = DatabaseService();
    if (_currentAccount != null) {
      _currentAccount!.isSignedIn = 0;
      await dbService.updateAccount(_currentAccount!);
    }
    // Dismiss dialog if it's open before navigating
    if (mounted) {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthenticationScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // TODO: Implement navigation or content change based on index
      // For now, just printing the index
      print('Tapped index: $index');
    });
  }

  void _showPersonalIslandDialog() {
    if (_currentAccount == null) return; // Should not happen if UI is built

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Make dialog background transparent
          elevation: 0,
          child: PersonalIslandWidget(
            account: _currentAccount!,
            onSignOut: _signOut,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme color from mockup for AppBar background
    const appBarColor = Color(0xfff5f5f5); // Light grey from mockup
    const titleColor = Colors.black;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentAccount == null) {
      // This case should ideally be handled by redirecting to login immediately
      return const Scaffold(
        body: Center(child: Text('Error: No user data found. Please sign in again.')),
      );
    }

    // Determine the title based on the selected index
    String appBarTitle = 'Baby Dino'; // Default or from account
    if (_currentAccount?.apiName != null && _currentAccount!.apiName!.isNotEmpty) {
      appBarTitle = _currentAccount!.apiName!;
    }

    // Placeholder bodies for different tabs
    // The PersonalIslandWidget is now shown in a dialog, so the Home tab can have different content or be simplified.
    // For now, let's put a placeholder for the Home tab content.
    final List<Widget> widgetOptions = <Widget>[
      // Home Tab: Content for when PersonalIslandWidget is not directly in the body
      const Center(child: Text('Home Content - Access account via settings icon')),
      // Study Tab
      const Center(child: Text('Study Screen')),
      // Leaderboard Tab
      const Center(child: Text('Leaderboard Screen')),
      // Contribute Tab
      const Center(child: Text('Contribute Screen')),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0), // Grey background from mockup
      appBar: AppBar(
        title: Text(appBarTitle, style: const TextStyle(color: titleColor)),
        backgroundColor: appBarColor,
        elevation: 0, // Remove shadow to match mockup
        iconTheme: const IconThemeData(color: titleColor), // For back button, if any
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: titleColor), // Settings icon
            tooltip: 'Account Settings',
            onPressed: _showPersonalIslandDialog, // Show dialog
          ),
        ],
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: CustomBottomNavWidget(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
