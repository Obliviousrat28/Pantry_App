import 'package:cloud_firestore/cloud_firestore.dart';
import 'storage_zone.dart';

class HistoryEntry
{
  final String itemName;
  final double itemQuantity;
  final double price;
  final bool priceUnknown;
  final StorageZone storageZone;
  final DateTime expiryDate;
  final DateTime dateAdded;

  HistoryEntry({
    required this.itemName,
    required this.itemQuantity,
    required this.price,
    required this.priceUnknown,
    required this.storageZone,
    required this.expiryDate,
    required this.dateAdded,
  });

  Map<String, dynamic> toFirestore()
  {
    return {
      'itemName': itemName,
      'itemQuantity': itemQuantity,
      'price': price,
      'priceUnknown': priceUnknown,
      'storageZone': storageZone.name,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'dateAdded': Timestamp.fromDate(dateAdded),
    };
  }

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
      ),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateAdded: (data['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}