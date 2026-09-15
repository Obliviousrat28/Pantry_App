import 'package:hive_flutter/hive_flutter.dart';
import '../models/inventory_item.dart';
import '../models/meal_log.dart';

class StorageService {
  static final Box<InventoryItem> _itemBox = Hive.box<InventoryItem>('inventory_box');
  static final Box<MealLog> _mealBox = Hive.box<MealLog>('meal_logs_box');
  static final Box _settingsBox = Hive.box('settings_box');

  // --- Inventory Items ---
  static Future<void> saveItems(List<InventoryItem> items) async {
    await _itemBox.clear();
    await _itemBox.addAll(items);
  }

  static Future<List<InventoryItem>> loadItems() async {
    return _itemBox.values.toList();
  }

  // --- Meal Logs ---
  static Future<void> saveMealLogs(List<MealLog> meals) async {
    await _mealBox.clear();
    await _mealBox.addAll(meals);
  }

  static Future<List<MealLog>> loadMealLogs() async {
    return _mealBox.values.toList();
  }

  // --- Budget ---
  static Future<void> saveRemainingBudget(double budget) async {
    await _settingsBox.put('remaining_budget', budget);
  }

  static Future<double> loadRemainingBudget(double defaultBudget) async {
    return _settingsBox.get('remaining_budget', defaultValue: defaultBudget) as double;
  }
}