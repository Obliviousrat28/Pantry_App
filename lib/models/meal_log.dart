import 'package:cloud_firestore/cloud_firestore.dart';

//meals are logged in the app to track spending and budget
// This class represents a single meal log entry
class MealLog {
  final String mealName;
  final String mealPrice;
  final DateTime mealDate;
// 'meal' = eaten out, "grocery" = bought for the pantry
final String source;
//'source' is optional and defaults to meal
  MealLog({
    required this.mealName,
    required this.mealPrice,
    required this.mealDate,
    this.source = 'meal',
  });

//conver entry to map for firestore storage
  Map<String, dynamic> toFirestore() => {
    'mealName': mealName,
    'mealPrice': mealPrice,
    'mealDate': Timestamp.fromDate(mealDate),
    'source' : source,
  };

//rebuild entry rom FireStore document snapshot
  factory MealLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final json = doc.data()!;
    return MealLog(
      mealName: json['mealName'] ?? '',
      mealPrice: json['mealPrice'] ?? '0.00',
      mealDate: (json['mealDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      source: json['source'] ?? 'meal',
    );
  }
}
