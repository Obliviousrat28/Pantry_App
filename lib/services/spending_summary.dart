import '../models/meal_log.dart';

// Spending for a single day of the week, split by source.
class DailySpending {
  final DateTime day;
  final double grocery; // bought for the pantry
  final double meals; // eaten out

  DailySpending({required this.day, this.grocery = 0, this.meals = 0});

  double get total => grocery + meals;
}

// All the numbers needed to draw the weekly line graph and pie chart,
// worked out from the user's spending entries for the current week.
class WeeklySpendingSummary {
  final DateTime weekStart; // Monday at midnight
  final List<DailySpending> days; // always 7 entries, Monday to Sunday
  final double weeklyGoal;

  WeeklySpendingSummary({
    required this.weekStart,
    required this.days,
    required this.weeklyGoal,
  });

  // Totals for the whole week.
  double get groceryTotal => days.fold(0.0, (sum, d) => sum + d.grocery);
  double get mealsTotal => days.fold(0.0, (sum, d) => sum + d.meals);
  double get totalSpent => groceryTotal + mealsTotal;

  // How much of the budget is left, and whether it has been exceeded.
  double get remaining => weeklyGoal - totalSpent;
  bool get overBudget => remaining < 0;

  // Running total after each day, used for the line graph.
  List<double> get cumulativeSpent {
    double running = 0;
    return days.map((d) {
      running += d.total;
      return running;
    }).toList();
  }

  // Builds the summary for the week containing 'now' (defaults to today).
  // Entries outside this Monday-to-Sunday week are ignored.
  factory WeeklySpendingSummary.fromLogs(
    List<MealLog> logs,
    double weeklyGoal, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();

    // Monday of this week at midnight. Using the DateTime constructor
    // (instead of subtracting a Duration) avoids daylight-saving errors.
    final weekStart = DateTime(today.year, today.month, today.day - (today.weekday - 1));

    // Start with seven empty days.
    final grocery = List<double>.filled(7, 0);
    final meals = List<double>.filled(7, 0);

    for (final log in logs) {
      // Compare dates in UTC so a daylight-saving change can't shift the day.
      final dayIndex = DateTime.utc(log.mealDate.year, log.mealDate.month, log.mealDate.day)
          .difference(DateTime.utc(weekStart.year, weekStart.month, weekStart.day))
          .inDays;

      // Skip entries before Monday or after Sunday.
      if (dayIndex < 0 || dayIndex > 6) continue;

      final amount = double.tryParse(log.mealPrice) ?? 0.0;
      if (log.source == 'grocery') {
        grocery[dayIndex] += amount;
      } else {
        meals[dayIndex] += amount;
      }
    }

    // Package the seven days together.
    final days = List.generate(
      7,
      (i) => DailySpending(
        day: DateTime(weekStart.year, weekStart.month, weekStart.day + i),
        grocery: grocery[i],
        meals: meals[i],
      ),
    );

    return WeeklySpendingSummary(
      weekStart: weekStart,
      days: days,
      weeklyGoal: weeklyGoal,
    );
  }
}

  // TEMPORARY: sample spending for the current week, used only to test the
// charts. It is never saved to Firestore. Delete before submitting.
List<MealLog> sampleMealLogs({DateTime? now}) {
  final today = now ?? DateTime.now();
  final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));

  // (days after Monday, name, price, source)
  final samples = [
    (0, 'Sample groceries', '45.00', 'grocery'),
    (1, 'Sample lunch', '12.50', 'meal'),
    (2, 'Sample groceries', '30.00', 'grocery'),
    (2, 'Sample dinner out', '18.00', 'meal'),
    (3, 'Sample groceries', '20.00', 'grocery'),
    (4, 'Sample takeaway', '25.00', 'meal'),
    (5, 'Sample groceries', '60.00', 'grocery'),
  ];

  return [
    for (final s in samples)
      // Only include days that have already happened this week.
      if (s.$1 <= today.weekday - 1)
        MealLog(
          mealName: s.$2,
          mealPrice: s.$3,
          mealDate: DateTime(monday.year, monday.month, monday.day + s.$1, 12),
          source: s.$4,
        ),
    ];
  }
