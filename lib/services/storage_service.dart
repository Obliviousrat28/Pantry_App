import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_item.dart';
import '../models/meal_log.dart';
import '../models/user.dart';

class StorageService {
  static const String _itemsKey = 'inventory_items';
  static const String _mealsKey = 'meal_logs';
  static const String _budgetKey = 'remaining_budget';
  static const String _goalKey = 'weekly_budget_goal';
  static const String _userKey = 'current_user';

  // --- Save Methods ---

  static Future<void> saveItems(List<InventoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(
      items.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_itemsKey, encodedData);
  }

  static Future<void> saveMealLogs(List<MealLog> meals) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(
      meals.map((meal) => meal.toJson()).toList(),
    );
    await prefs.setString(_mealsKey, encodedData);
  }

  static Future<void> saveRemainingBudget(double budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_budgetKey, budget);
  }

    // Saves the user's weekly budget goal (the target, separate from what's left).
  static Future<void> saveWeeklyBudgetGoal(double goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_goalKey, goal);
  }

 // Saves the signed-up user's details.
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  // --- Load Methods ---

  static Future<List<InventoryItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? itemsString = prefs.getString(_itemsKey);
    if (itemsString == null) return [];

    final List<dynamic> decoded = json.decode(itemsString);
    return decoded.map((json) => InventoryItem.fromJson(json)).toList();
  }

  static Future<List<MealLog>> loadMealLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? mealsString = prefs.getString(_mealsKey);
    if (mealsString == null) return [];

    final List<dynamic> decoded = json.decode(mealsString);
    return decoded.map((json) => MealLog.fromJson(json)).toList();
  }

  static Future<double> loadRemainingBudget(double defaultBudget) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_budgetKey) ?? defaultBudget;
  }

  // Loads the saved goal, falling back to defaultGoal if none saved yet.
  static Future<double> loadWeeklyBudgetGoal(double defaultGoal) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_goalKey) ?? defaultGoal;
  }
  
  // Loads the saved user, or null if nobody has signed up yet.
  static Future<User?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userString = prefs.getString(_userKey);
    if (userString == null) return null;
    return User.fromJson(json.decode(userString));
  }
}