import 'package:hive/hive.dart';

part 'meal_log.g.dart';

@HiveType(typeId: 1)
class MealLog extends HiveObject {
  @HiveField(0)
  final String mealName;

  @HiveField(1)
  final String mealPrice;

  @HiveField(2)
  final DateTime mealDate;

  MealLog({
    required this.mealName,
    required this.mealPrice,
    required this.mealDate,
  });

  Map<String, dynamic> toJson() => {
        'mealName': mealName,
        'mealPrice': mealPrice,
        'mealDate': mealDate.toIso8601String(),
      };

  factory MealLog.fromJson(Map<String, dynamic> json) => MealLog(
        mealName: json['mealName'],
        mealPrice: json['mealPrice'],
        mealDate: DateTime.parse(json['mealDate']),
      );
}