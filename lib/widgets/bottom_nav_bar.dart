import 'package:flutter/material.dart';

// A custom bottom navigation bar widget that allows users to navigate between different sections of the app.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  // Creates an instance of BottomNavBar with the specified current index and tap callback.
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Builds the widget tree for the bottom navigation bar, including navigation destinations and their icons.
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black12, width: 1.0),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: const [
          // Navigation destination for the Inventory section, with outlined and filled icons.
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ), 
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}