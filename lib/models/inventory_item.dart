import 'package:hive/hive.dart';
import 'storage_zone.dart';

part 'inventory_item.g.dart'; // Must match this filename

@HiveType(typeId: 0)
class InventoryItem extends HiveObject {
  @HiveField(0)
  final String itemId;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  String itemName;

  @HiveField(3)
  double itemQuantity;

  @HiveField(4)
  double price;

  @HiveField(5)
  bool priceUnknown;

  @HiveField(6)
  DateTime expiryDate;

  @HiveField(7)
  StorageZone storageZone;

  @HiveField(8)
  final String? barcode;

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

  bool isExpired() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.isBefore(today);
  }

  bool isExpiringSoon() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final difference = expiry.difference(today).inDays;
    return difference >= 0 && difference <= 3;
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'userId': userId,
        'itemName': itemName,
        'itemQuantity': itemQuantity,
        'price': price,
        'priceUnknown': priceUnknown,
        'expiryDate': expiryDate.toIso8601String(),
        'storageZone': storageZone.name,
        'barcode': barcode,
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        itemId: json['itemId'],
        userId: json['userId'],
        itemName: json['itemName'],
        itemQuantity: (json['itemQuantity'] as num).toDouble(),
        price: (json['price'] as num).toDouble(),
        priceUnknown: json['priceUnknown'] ?? false,
        expiryDate: DateTime.parse(json['expiryDate']),
        storageZone: StorageZone.values.byName(json['storageZone']),
        barcode: json['barcode'],
      );
}