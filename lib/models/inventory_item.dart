import 'storage_zone.dart';

class InventoryItem {
  final String itemId; 
  final String userId; 
  String itemName;
  double itemQuantity;
  double price;
  bool priceUnknown;
  DateTime expiryDate;
  StorageZone storageZone;

  InventoryItem({
    required this.itemId,
    required this.userId,
    required this.itemName,
    required this.itemQuantity,
    required this.price,
    this.priceUnknown = false,
    required this.expiryDate,
    required this.storageZone,
  });

  // Helper method to update an item while keeping its existing ID
  void edit({
    String? name,
    double? quantity,
    double? price,
    DateTime? expiry,
    StorageZone? zone,
    bool? priceUnknown,
  }) {
    if (name != null) itemName = name;
    if (quantity != null) itemQuantity = quantity;
    if (price != null) this.price = price;
    if (expiry != null) expiryDate = expiry;
    if (zone != null) storageZone = zone;
    if (priceUnknown != null) this.priceUnknown = priceUnknown;
  }

  void delete() {} //empty it to be implemented later whaen a database is added

  //for the UML diagram
  bool isExpired() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.isBefore(today);
  }

  //for the UML diagram 
  bool isExpiringSoon() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final difference = expiry.difference(today).inDays;
    return difference >= 0 && difference <= 3;
  }
}