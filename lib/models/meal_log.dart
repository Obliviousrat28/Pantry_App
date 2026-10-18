import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

//meals are logged in the app to track spending and budget
// This class represents a single meal log entry
class MealLog {
  final String id = const Uuid().v4(); // Unique identifier for the meal log entry
  final String mealName;
  final String mealPrice;
  final DateTime mealDate;
// 'meal' = eaten out, "grocery" = bought for the pantry
final String source;
//'source' is optional and defaults to meal
  MealLog({
    String? id,
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
      id : doc.id, // Use the document ID from Firestore
      mealName: json['mealName'] ?? '',
      mealPrice: json['mealPrice'] ?? '0.00',
      mealDate: (json['mealDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      source: json['source'] ?? 'meal',
    );
  }
}
