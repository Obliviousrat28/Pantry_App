import 'package:cloud_firestore/cloud_firestore.dart';
import 'storage_zone.dart';

// Represents one entry in the user's history, recording an item that was added to or removed from their inventory.
class HistoryEntry
{
  final String itemName;
  final double itemQuantity;
  final double price;
  final bool priceUnknown;
  final StorageZone storageZone;
  final DateTime expiryDate;
  final String action; // Either 'added' or 'removed'
  final DateTime dateAdded; // When the action happened

  // Creates a history entry with all the item details and the action that was taken.
  HistoryEntry({
    required this.itemName,
    required this.itemQuantity,
    required this.price,
    required this.priceUnknown,
    required this.storageZone,
    required this.expiryDate,
    required this.action,
    required this.dateAdded,
  });

  // Converts the history entry into a map so it can be saved in Firestore.
  Map<String, dynamic> toFirestore()
  {
    return {
      'itemName': itemName,
      'itemQuantity': itemQuantity,
      'price': price,
      'priceUnknown': priceUnknown,
      'storageZone': storageZone.name,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'action': action,
      'dateAdded': Timestamp.fromDate(dateAdded),
    };
  }

  // Creates a history entry from a Firestore document, using default values if any fields are missing.
  factory HistoryEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc)
  {
    final data = doc.data()!;
    return HistoryEntry(
      itemName: data['itemName'] ?? '',
      itemQuantity: (data['itemQuantity'] as num?)?.toDouble() ?? 1.0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      priceUnknown: data['priceUnknown'] ?? false,
      storageZone: StorageZone.values.firstWhere(
        (zone) => zone.name == data['storageZone'],
        orElse: () => StorageZone.pantry,
      ), // Default to pantry if the storage zone is not found
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      action: data['action'] ?? 'added', // Older entries without an action are treated as added
      dateAdded: (data['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}