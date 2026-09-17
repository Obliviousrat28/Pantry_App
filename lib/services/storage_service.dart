import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inventory_item.dart';
import '../models/meal_log.dart';
import '../models/user.dart';

class StorageService {
  static const String _itemsKey = 'inventory_items';
  static const String _mealsKey = 'meal_logs';
  static const String _budgetKey = 'remaining_budget';
  static const String _goalKey = 'weekly_budget_goal';
  static const String _userKey = 'current_user';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /*String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User is not authenticated.");
    return user.uid;
  }*/

  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    // Bypasses auth completely for testing
    return user?.uid ?? 'dev_test_user'; 
  }

  DocumentReference get _userDoc =>
      _firestore.collection('users').doc(_userId);

  // ================= INVENTORY =================

  Future<List<InventoryItem>> loadItems() async {
    final snapshot = await _userDoc.collection('inventory').get();
    return snapshot.docs
        .map((doc) => InventoryItem.fromFirestore(doc))
        .toList();
  }

  Future<void> saveItems(List<InventoryItem> items) async {
    final batch = _firestore.batch();
    for (final item in items) {
      final docRef = _userDoc.collection('inventory').doc(item.itemId);
      batch.set(docRef, item.toFirestore(), SetOptions(merge: true));
    }
    await batch.commit();
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
  Future<void> deleteItem(String itemId) async {
    await _userDoc.collection('inventory').doc(itemId).delete();
  }

  // ================= MEAL LOGS =================

  Future<List<MealLog>> loadMealLogs() async {
    final snapshot = await _userDoc
        .collection('meal_logs')
        .orderBy('mealDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => MealLog.fromFirestore(doc)).toList();
  }

  Future<void> saveMealLogs(List<MealLog> logs) async {
    final batch = _firestore.batch();
    for (final log in logs) {
      // Deterministic ID prevents duplicate writes in Firestore
      final docId = log.mealDate.millisecondsSinceEpoch.toString();
      final docRef = _userDoc.collection('meal_logs').doc(docId);
      batch.set(docRef, log.toFirestore(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ================= BUDGET =================

  Future<double> loadRemainingBudget(double defaultBudget) async {
    final doc = await _userDoc.get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('remainingBudget')) {
        return (data['remainingBudget'] as num).toDouble();
      }
    }
    return defaultBudget;
  }

  Future<void> saveRemainingBudget(double budget) async {
    await _userDoc.set(
      {'remainingBudget': budget},
      SetOptions(merge: true),
    );
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