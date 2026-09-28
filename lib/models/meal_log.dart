import 'package:cloud_firestore/cloud_firestore.dart';

class MealLog {
  final String mealName;
  final String mealPrice;
  final DateTime mealDate;

  MealLog({
    required this.mealName,
    required this.mealPrice,
    required this.mealDate,
  });

  Map<String, dynamic> toFirestore() => {
    'mealName': mealName,
    'mealPrice': mealPrice,
    'mealDate': Timestamp.fromDate(mealDate),
  };

  factory MealLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final json = doc.data()!;
    return MealLog(
      mealName: json['mealName'] ?? '',
      mealPrice: json['mealPrice'] ?? '0.00',
      mealDate: (json['mealDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}