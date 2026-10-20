import 'package:cloud_firestore/cloud_firestore.dart';

// A record of what happened to food the user bought: it was used
// (eaten or cooked) or wasted (thrown away). Feeds the pie chart.
class UsageEvent {
  final String id;
  final String itemName;
  final double quantity;
  final double value; // price x quantity (0 if the price is unknown)
  final String outcome; // 'used' or 'wasted'
  final String origin; // 'manual' (delete dialog) or 'recipe' (cooked button)
  final DateTime date;

  UsageEvent({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.value,
    required this.outcome,
    required this.origin,
    required this.date,
  });

  // Converts this record into a map for saving to Firestore.
  Map<String, dynamic> toFirestore() => {
        'itemName': itemName,
        'quantity': quantity,
        'value': value,
        'outcome': outcome,
        'origin': origin,
        'date': Timestamp.fromDate(date),
      };

  // Rebuilds a record from a Firestore document, with safe defaults.
  factory UsageEvent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final json = doc.data()!;
    return UsageEvent(
      id: doc.id,
      itemName: json['itemName'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      outcome: json['outcome'] ?? 'used',
      origin: json['origin'] ?? 'manual',
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}