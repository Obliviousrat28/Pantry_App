import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inventory_item.dart';
import '../models/meal_log.dart';
import '../models/history_entry.dart';
import 'notification_service.dart';
import '../models/usage_event.dart'; 

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Retrieves the current user's ID from Firebase Authentication, defaulting to a test user ID if no user is logged in.
  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    // Bypasses auth completely for testing
    return user?.uid ?? 'dev_test_user'; 
  }

  DocumentReference get _userDoc =>
      _firestore.collection('users').doc(_userId);

  // ================= USER & PROFILE =================
  // Saves user data to Firestore, including userName, email, weeklyBudgetGoal, remainingBudget, dietaryPreferences, and createdAt timestamp.
  Future<void> saveUserData({
    required String userName,
    required String email,
    required double weeklyBudgetGoal,
    required List<String> dietaryPreferences,
  }) async {// Saves user data to Firestore, including userName, email, weeklyBudgetGoal, remainingBudget, dietaryPreferences, and createdAt timestamp.
    await _userDoc.set({
      'userName': userName,
      'email': email,
      'weeklyBudgetGoal': weeklyBudgetGoal,
      'remainingBudget': weeklyBudgetGoal, // Sets starting budget equal to goal
      'dietaryPreferences': dietaryPreferences,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }// Loads the user profile from Firestore, returning a map of user data or null if the document does not exist.
  Future<Map<String, dynamic>?> loadUserProfile() async {
    final doc = await _userDoc.get();
    return doc.data() as Map<String, dynamic>?;
  }



  // ================= INVENTORY =================

  // Loads the inventory items for the current user from Firestore, returning a list of InventoryItem objects.
  Future<List<InventoryItem>> loadItems() async {
  final snapshot = await _userDoc.collection('inventory').get();
  final items = snapshot.docs
      .map((doc) => InventoryItem.fromFirestore(doc))
      .toList();
  NotificationService.instance.rescheduleAll(items); // not awaited on purpose
  return items;
}

  // Saves a list of inventory items to Firestore using a batch operation, merging data for existing items.
    Future<void> saveItems(List<InventoryItem> items) async {
    // Schedule reminders first, so a slow or offline Firestore save
    // can never block them. Errors are logged, not thrown, so
    // notifications can never break saving.
    for (final item in items) {
      try {
        await NotificationService.instance.scheduleExpiryReminder(
          itemId: item.itemId,
          itemName: item.itemName,
          expiryDate: item.expiryDate,
        );
      } catch (e) {
        debugPrint('Reminder error for ${item.itemName}: $e');
      }
    }

    final batch = _firestore.batch();
    for (final item in items) {
      final docRef = _userDoc.collection('inventory').doc(item.itemId);
      batch.set(docRef, item.toFirestore(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  // Deletes an inventory item from Firestore based on the provided itemId.
  Future<void> deleteItem(String itemId) async {
  await _userDoc.collection('inventory').doc(itemId).delete();
  try {
    await NotificationService.instance.cancelReminder(itemId);
  } catch (_) {}
}

  // ================= SHOPPING LIST =================

  // Loads the shopping list items for the current user from Firestore.
  Future<List<InventoryItem>> loadShoppingItems() async {
    final snapshot = await _userDoc.collection('shopping_list').get();
    return snapshot.docs
        .map((doc) => InventoryItem.fromFirestore(doc))
        .toList();
  }

  // Saves or updates a single shopping list item in Firestore.
  Future<void> saveShoppingItem(InventoryItem item) async {
    final docRef = _userDoc.collection('shopping_list').doc(item.itemId);
    await docRef.set(item.toFirestore(), SetOptions(merge: true));
  }

  // Deletes a shopping list item from Firestore based on its itemId.
  Future<void> deleteShoppingItem(String itemId) async {
    await _userDoc.collection('shopping_list').doc(itemId).delete();
  }

  // ================= MEAL LOGS =================

  // Loads the meal logs for the current user from Firestore, returning a list of MealLog objects ordered by mealDate in descending order.
  Future<List<MealLog>> loadMealLogs() async {
    final snapshot = await _userDoc
        .collection('meal_logs')
        .orderBy('mealDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => MealLog.fromFirestore(doc)).toList();
  }

  // Saves a list of meal logs to Firestore using a batch operation, merging by log ID to ensure uniqueness and prevent duplicates.
  Future<void> saveMealLogs(List<MealLog> logs) async {
    final batch = _firestore.batch();
    for (final log in logs) {
      final docRef = _userDoc.collection('meal_logs').doc(log.id);//Using log.id as the document ID to ensure uniqueness
      batch.set(docRef, log.toFirestore(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ================= BUDGET =================

  // Loads the remaining budget for the current user from Firestore, returning the value or a default budget if not found.
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

  // Saves the remaining budget for the current user to Firestore, merging the new value with existing data.
  Future<void> saveRemainingBudget(double budget) async {
    await _userDoc.set(
      {'remainingBudget': budget},
      SetOptions(merge: true),
    );
  }

  // Loads the weekly budget goal for the current user from Firestore, returning the value or a default goal if not found.
  Future<double> loadWeeklyBudgetGoal(double defaultGoal) async {
    final doc = await _userDoc.get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('weeklyBudgetGoal')) {
        return (data['weeklyBudgetGoal'] as num).toDouble();
      }
    }
    return defaultGoal;
  }

  // Saves the weekly budget goal for the current user to Firestore, merging the new value with existing data.
  Future<void> saveWeeklyBudgetGoal(double goal) async {
    await _userDoc.set(
      {'weeklyBudgetGoal': goal},
      SetOptions(merge: true),
    );
  }
// ================= USAGE EVENTS =================

  // ================= HISTORY =================

  Future<void> addHistoryItem(InventoryItem item, String action) async
  {
    HistoryEntry entry = HistoryEntry(
      itemName: item.itemName,
      itemQuantity: item.itemQuantity,
      price: item.price,
      priceUnknown: item.priceUnknown,
      storageZone: item.storageZone,
      expiryDate: item.expiryDate,
      action: action,
      dateAdded: DateTime.now(),
    );
    await _userDoc.collection('history').add(entry.toFirestore());
  }

  Future<List<HistoryEntry>> loadHistory() async
  {
    final snapshot = await _userDoc
        .collection('history')
        .orderBy('dateAdded', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.map((doc) => HistoryEntry.fromFirestore(doc)).toList();
  // Save a usage record (used or waste) under user_events
  Future<void> saveUsageEvent(UsageEvent event) async {
    await _userDoc.collection('usage_events').doc(event.id).set(event.toFirestore(), SetOptions(merge: true));
  }

  // Deletes a usage event when user undoes a delete.
  Future<void> deleteUsageEvent(String eventId) async {
    await _userDoc.collection('usage_events').doc(eventId).delete();
  }
//load usage records and callers filter by date (weekly charts)
  Future<List<UsageEvent>> loadUsageEvents() async {
    final snapshot = await _userDoc.collection('usage_events').get();
    return snapshot.docs.map((doc) => UsageEvent.fromFirestore(doc)).toList();
  }
}