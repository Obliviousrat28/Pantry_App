import 'storage_zone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Represents an inventory item with its properties and methods for editing and checking expiry.
class InventoryItem {
  final String itemId;
  final String userId;
  String itemName;
  double itemQuantity;
  double price;
  bool priceUnknown;
  DateTime expiryDate;
  StorageZone storageZone;
  final String? barcode;

  // Constructor for creating an InventoryItem instance with required and optional parameters.
  InventoryItem({
    required this.itemId,
    required this.userId,
    required this.itemName,
    required this.itemQuantity,
    required this.price,
    this.priceUnknown = false,
    required this.expiryDate,
    required this.storageZone,
    this.barcode,
  });

  // Edits the properties of the inventory item based on provided parameters, allowing for partial updates.
  void edit({
    String? name,
    double? quantity,
    double? price,
    DateTime? expiry,
    StorageZone? zone,
    bool? priceUnknown,
  }) {// Updates the properties of the inventory item based on provided parameters, allowing for partial updates.
    if (name != null) itemName = name;
    if (quantity != null) itemQuantity = quantity;
    if (price != null) this.price = price;
    if (expiry != null) expiryDate = expiry;
    if (zone != null) storageZone = zone;
    if (priceUnknown != null) this.priceUnknown = priceUnknown;
  }

  // Checks if the inventory item is expired based on the current date and the item's expiry date.
  bool isExpired() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.isBefore(today);
  }

  // Checks if the inventory item is expiring soon (within 3 days) based on the current date and the item's expiry date.
  bool isExpiringSoon() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final difference = expiry.difference(today).inDays;
    return difference >= 0 && difference <= 3;
  }

  // Converts the inventory item to a Firestore-compatible map for storage in the database.
  Map<String, dynamic> toFirestore() => {
    'itemId': itemId,
    'userId': userId,
    'itemName': itemName,
    'itemQuantity': itemQuantity,
    'price': price,
    'priceUnknown': priceUnknown,
    'expiryDate': Timestamp.fromDate(expiryDate),
    'storageZone': storageZone.name,
    'barcode': barcode,
  };

  // Factory constructor to create an InventoryItem instance from a Firestore document snapshot.
  factory InventoryItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final json = doc.data()!;
    return InventoryItem(
      itemId: doc.id, // Always use doc.id directly from Firestore
      userId: json['userId'] ?? '',
      itemName: json['itemName'] ?? '',
      itemQuantity: (json['itemQuantity'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      priceUnknown: json['priceUnknown'] ?? false,
      expiryDate: (json['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      storageZone: StorageZone.values.firstWhere(
        (e) => e.name == json['storageZone'],
        orElse: () => StorageZone.pantry,
      ),// Default to pantry if storageZone is not found
      barcode: json['barcode'],
    );
  }
}