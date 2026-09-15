import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'budget_screen.dart';
import 'zone_screens.dart';
//import 'recipe_screen.dart';
//import 'recipe_details_screen.dart';
//import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // List of your 4 screen widgets
  final List<Widget> _screens = [
    const ZoneScreen(title: 'Inventory'),
    const BudgetScreen(),
    const Center(child: Text('Recipe Screen Placeholder')),
    const Center(child: Text('Settings Screen Placeholder')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Shows the selected screen as the body
      body: _screens[_currentIndex],
      // Bottom nav bar stays fixed at the bottom across all tabs
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}