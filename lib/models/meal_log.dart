class MealLog {
  final String mealName;
  final String mealPrice;
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