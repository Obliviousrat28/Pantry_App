import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:my_pantry/screens/recipe_screen.dart';
import '../models/inventory_item.dart';
import '../models/meal_log.dart';
import '../services/storage_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/item_add_dialog.dart';
import 'budget_screen.dart';
import 'zone_screens.dart';
import '../models/user.dart';
import 'settings_screen.dart';
import 'shopping_list_screen.dart';
import '../models/usage_event.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Instantiate the storage service instance
  final StorageService _storageService = StorageService();

  int _currentIndex = 0;

  // Shared State
  List<InventoryItem> inventoryItems = [];
  List<MealLog> mealLogs = [];
  //value to be loaded from storage on app launch.
  late double remainingBudget;
  late double weeklyBudgetGoal;

  User? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // Load persisted data on app launch
  Future<void> _loadSavedData() async {
    final items = await _storageService.loadItems();
    final meals = await _storageService.loadMealLogs();
    final profile = await _storageService.loadUserProfile();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final user = (profile == null || firebaseUser == null)
        ? null
        : User(
            userId: firebaseUser.uid,
            userName: profile['userName'] ?? '',
            userEmail: profile['email'] ?? '',
            userPassword: '',
            weeklyBudgetGoal: (profile['weeklyBudgetGoal'] as num?)?.toDouble() ?? 120.0,
            dietaryPreference: List<String>.from(profile['dietaryPreferences'] ?? []),
          );

    final defaultGoal = user?.weeklyBudgetGoal ?? 120.0;
    final goal = await _storageService.loadWeeklyBudgetGoal(defaultGoal);
    final budget = await _storageService.loadRemainingBudget(goal);

    setState(() {
      inventoryItems = items;
      mealLogs = meals;
      currentUser = user;
      weeklyBudgetGoal = goal;
      remainingBudget = budget;
      isLoading = false;
    });
  }

  // Scenario 1: Adding an Inventory Item
  void _handleAddItem(InventoryItem item) async {
    final double unitCost = item.priceUnknown ? 0.0 : item.price;
    final double totalCost = unitCost * item.itemQuantity;

    setState(() {
      inventoryItems.add(item);
      
      mealLogs.add(
        MealLog(
          mealName: '${item.itemName} (x${item.itemQuantity.toInt()})',
          mealPrice: totalCost.toStringAsFixed(2),
          //chosen purchase date, defaults to now
          mealDate: item.entryDate,
          //default to 'grocery' for items added to inventory.
          source: 'grocery',
        ),
      );
      
      remainingBudget -= totalCost;
    });

    await _storageService.saveItems(inventoryItems);
    await _storageService.saveMealLogs(mealLogs);
    await _storageService.saveRemainingBudget(remainingBudget);
  }

  // Scenario 2: Logging a Meal Directly
  void _handleLogMeal(MealLog meal) async {
    final double mealCost = double.tryParse(meal.mealPrice) ?? 0.0;

    setState(() {
      mealLogs.add(meal);
      remainingBudget -= mealCost;
    });

    await _storageService.saveMealLogs(mealLogs);
    await _storageService.saveRemainingBudget(remainingBudget);
  }

  // Updates an existing inventory item and keeps the budget and the
  // matching spending entry in sync with the new price and quantity.
  void _editItem(InventoryItem updatedItem) async {
    // Find the item being edited; stop if it no longer exists.
    final index = inventoryItems.indexWhere((e) => e.itemId == updatedItem.itemId);
    if (index == -1) return;

    final oldItem = inventoryItems[index];

    // Work out how much the total cost changed (unknown prices count as 0).
    final double oldUnitCost = oldItem.priceUnknown ? 0.0 : oldItem.price;
    final double oldTotalCost = oldUnitCost * oldItem.itemQuantity;

    final double newUnitCost = updatedItem.priceUnknown ? 0.0 : updatedItem.price;
    final double newTotalCost = newUnitCost * updatedItem.itemQuantity;

    final double costDifference = newTotalCost - oldTotalCost;

    setState(() {
      // Replace the item and adjust the remaining budget by the difference.
      inventoryItems[index] = updatedItem;
      remainingBudget -= costDifference;

      // Find the spending entry created when this item was added, using
      // its old display name, e.g. "Milk (x2)".
      final oldFormattedName = '${oldItem.itemName} (x${oldItem.itemQuantity.toInt()})';
      final logIndex = mealLogs.indexWhere(
        (log) => log.mealName == oldFormattedName,
      );

      // Rebuild that entry with the new name and price. The original date
      // and source are kept, so an edited grocery item stays a grocery.
      if (logIndex != -1) {
        mealLogs[logIndex] = MealLog(
          id: mealLogs[logIndex].id,// Preserve the original ID for Firestore
          mealName: '${updatedItem.itemName} (x${updatedItem.itemQuantity.toInt()})',
          mealPrice: newTotalCost.toStringAsFixed(2),
          mealDate: mealLogs[logIndex].mealDate,
          source: mealLogs[logIndex].source,
        );
      }
    });

    // Save the updated item, spending entries, and budget.
    await _storageService.saveItems(inventoryItems);
    await _storageService.saveMealLogs(mealLogs);
    await _storageService.saveRemainingBudget(remainingBudget);
  }

  // Removes an item. If the user said what happened to it ('used' or
  // 'wasted'), a usage record is saved too; 'none' just deletes it.
  void _deleteItem(InventoryItem item, String outcome) async {
    final double unitCost = item.priceUnknown ? 0.0 : item.price;

    setState(() {
      inventoryItems.removeWhere((e) => e.itemId == item.itemId);
    });

    // Both writes start straight away so a slow connection can't make
    // one wait for the other.
    final deletion = _storageService.deleteItem(item.itemId);
    final recording = outcome == 'none'
        ? Future<void>.value()
        : _storageService.saveUsageEvent(
            UsageEvent(
              id: 'del_${item.itemId}',
              itemName: item.itemName,
              quantity: item.itemQuantity,
              value: unitCost * item.itemQuantity,
              outcome: outcome,
              origin: 'manual',
              date: DateTime.now(),
            ),
          );
    await Future.wait([deletion, recording]);
  }

 // UNDO for a delete: puts the item back in the inventory and removes
  // its usage record. No new spending entry is made and the budget is
  // not touched, because the original purchase is still on record.
  void _restoreItem(InventoryItem item) async {
    setState(() {
      inventoryItems.add(item);
    });

    // Both writes start straight away so neither waits for the other.
    final saving = _storageService.saveItems(inventoryItems);
    final removing = _storageService.deleteUsageEvent('del_${item.itemId}');
    await Future.wait([saving, removing]);
  }


 // Opens the dialog for adding an item or logging a meal.
  void _openAddModal() {
    showDialog(
      context: context,
      builder: (ctx) => ItemAddDialog(
        onAddItem: _handleAddItem,
        onLogMeal: _handleLogMeal,
      ),
    );
  }

  void _updateBudgetGoal(double newGoal) async {
    final spentSoFar = weeklyBudgetGoal - remainingBudget;

    setState(() {
      weeklyBudgetGoal = newGoal;
      remainingBudget = newGoal - spentSoFar;
      if (currentUser != null) {
        currentUser = currentUser!.copyWith(weeklyBudgetGoal: newGoal);
      }
    });

    await _storageService.saveWeeklyBudgetGoal(newGoal);
    await _storageService.saveRemainingBudget(remainingBudget);
  }

  void _updateDietaryPreferences(List<String> preferences) async {
    if (currentUser == null) return;
    setState(() {
      currentUser = currentUser!.copyWith(dietaryPreference: preferences);
    });
    await _storageService.saveUserData(
      userName: currentUser!.userName,
      email: currentUser!.userEmail,
      weeklyBudgetGoal: currentUser!.weeklyBudgetGoal,
      dietaryPreferences: preferences,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Define screen titles for the top app bar
    final List<String> titles = [
      'Inventory',
      'Budget',
      'Recipes',
      'Settings',
    ];

    final List<Widget> screens = [
      ZoneScreen(
        title: 'Inventory',
        items: inventoryItems,
        onAddItem: _handleAddItem,
        onEditItem: _editItem,
        onDeleteItem: _deleteItem,
        onRestoreItem: _restoreItem,
      ),
      BudgetScreen(
        weeklyBudgetGoal: weeklyBudgetGoal,
        mealLogs: mealLogs,
        inventoryItems: inventoryItems,
      ),
      const RecipesScreen(),
      SettingsScreen(
        user: currentUser,
        weeklyBudgetGoal: weeklyBudgetGoal,
        onUpdateBudgetGoal: _updateBudgetGoal,
        onUpdateDietaryPreferences: _updateDietaryPreferences,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          // Show shopping cart icon only when viewing the Inventory tab
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              tooltip: 'Shopping List',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const ShoppingListScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddModal,
        child: const Icon(Icons.add),
      ),
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