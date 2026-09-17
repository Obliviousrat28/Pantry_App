import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inventory_item.dart';
import '../models/meal_log.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper getter to ensure operations only target the authenticated user
  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User is not authenticated.");
    return user.uid;
  }

  // Document reference pointing to users/{userId}
  DocumentReference get _userDoc =>
      _firestore.collection('users').doc(_userId);

  // ================= INVENTORY METHODS =================

  /// Listens to inventory items in real-time
  Stream<List<InventoryItem>> getInventoryStream() {
    return _userDoc.collection('inventory').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => InventoryItem.fromFirestore(doc))
          .toList();
    });
  }

  /// Adds or updates a single inventory item
  Future<void> saveInventoryItem(InventoryItem item) async {
    await _userDoc
        .collection('inventory')
        .doc(item.itemId)
        .set(item.toFirestore(), SetOptions(merge: true));
  }

  /// Executes batch writes for updating multiple inventory items at once
  Future<void> saveInventoryBatch(List<InventoryItem> items) async {
    final batch = _firestore.batch();

    for (final item in items) {
      final docRef = _userDoc.collection('inventory').doc(item.itemId);
      batch.set(docRef, item.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Deletes an inventory item
  Future<void> deleteInventoryItem(String itemId) async {
    await _userDoc.collection('inventory').doc(itemId).delete();
  }

  // ================= MEAL LOG / BUDGET METHODS =================

  /// Listens to meal logs in real-time, ordered by date
  Stream<List<MealLog>> getMealLogsStream() {
    return _userDoc
        .collection('meal_logs')
        .orderBy('mealDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MealLog.fromFirestore(doc)).toList();
    });
  }

  /// Adds a new meal log entry
  Future<void> addMealLog(MealLog log) async {
    await _userDoc.collection('meal_logs').add(log.toFirestore());
  }

  /// Deletes a meal log entry by document ID
  Future<void> deleteMealLog(String logId) async {
    await _userDoc.collection('meal_logs').doc(logId).delete();
  }
}