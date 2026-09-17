import 'package:flutter/material.dart';
import 'package:my_pantry/screens/recipe_screen.dart';
import '../models/inventory_item.dart';
import '../models/meal_log.dart';
import '../services/storage_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/item_add_dialog.dart';
import 'budget_screen.dart';
import 'zone_screens.dart';
import 'login_screen.dart';
import '../models/user.dart';

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
    final goal = await _storageService.loadWeeklyBudgetGoal(120.00);
    final budget = await _storageService.loadRemainingBudget(goal);

    setState(() {
      inventoryItems = items;
      mealLogs = meals;
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
          mealDate: DateTime.now(),
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

  void _editItem(InventoryItem updatedItem) async {
    final index = inventoryItems.indexWhere((e) => e.itemId == updatedItem.itemId);
    if (index == -1) return;

    final oldItem = inventoryItems[index];

    final double oldUnitCost = oldItem.priceUnknown ? 0.0 : oldItem.price;
    final double oldTotalCost = oldUnitCost * oldItem.itemQuantity;

    final double newUnitCost = updatedItem.priceUnknown ? 0.0 : updatedItem.price;
    final double newTotalCost = newUnitCost * updatedItem.itemQuantity;

    final double costDifference = newTotalCost - oldTotalCost;

    setState(() {
      inventoryItems[index] = updatedItem;
      remainingBudget -= costDifference;

      final oldFormattedName = '${oldItem.itemName} (x${oldItem.itemQuantity.toInt()})';
      final logIndex = mealLogs.indexWhere(
        (log) => log.mealName == oldFormattedName,
      );

      if (logIndex != -1) {
        mealLogs[logIndex] = MealLog(
          mealName: '${updatedItem.itemName} (x${updatedItem.itemQuantity.toInt()})',
          mealPrice: newTotalCost.toStringAsFixed(2),
          mealDate: mealLogs[logIndex].mealDate,
        );
      }
    });

    await _storageService.saveItems(inventoryItems);
    await _storageService.saveMealLogs(mealLogs);
    await _storageService.saveRemainingBudget(remainingBudget);
  }

  void _deleteItem(InventoryItem item) async {
    setState(() {
      inventoryItems.removeWhere((e) => e.itemId == item.itemId);
    });
    
    // Call the dedicated deletion method using the item's unique ID
    await _storageService.deleteItem(item.itemId);
  }

  void _openAddModal() {
    showDialog(
      context: context,
      builder: (ctx) => ItemAddDialog(
        onAddItem: _handleAddItem,
        onLogMeal: _handleLogMeal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> screens = [
      ZoneScreen(
        title: 'Inventory',
        items: inventoryItems,
        onAddItem: _handleAddItem,
        onEditItem: _editItem,
        onDeleteItem: _deleteItem,
      ),
      BudgetScreen(
        remainingBudget: remainingBudget,
        weeklyBudgetGoal: weeklyBudgetGoal,
        mealLogs: mealLogs,
      ),
      RecipesScreen(),
      const Center(child: Text('Settings Screen Placeholder')),
    ];

    return Scaffold(
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