import '../models/inventory_item.dart';
import '../models/meal_log.dart';
import '../models/usage_event.dart';

// How this week's food and money were split, for the pie chart:
// used, wasted, still in the pantry, meals out, and the budget remaining.
class WeeklyPieSummary {
  final double used;
  final double wasted;
  final double inPantry;
  final double mealsOut;
  final double remaining; // 0 when over budget
  final double overBudgetBy; // 0 when within budget
  final double weeklyGoal;

  const WeeklyPieSummary({
    required this.used,
    required this.wasted,
    required this.inPantry,
    required this.mealsOut,
    required this.remaining,
    required this.overBudgetBy,
    required this.weeklyGoal,
  });

  // True if there is anything to show in the pie chart.
  bool get hasSpending => used + wasted + inPantry + mealsOut > 0;

  // Works out the split for the week containing 'now' (defaults to today).
  factory WeeklyPieSummary.fromData({
    required List<MealLog> mealLogs,
    required List<UsageEvent> usageEvents,
    required List<InventoryItem> inventory,
    required double weeklyGoal,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();

    // Monday to Sunday of this week.
    final weekStart =
        DateTime(today.year, today.month, today.day - (today.weekday - 1));
    final weekEnd =
        DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
    bool inWeek(DateTime d) => !d.isBefore(weekStart) && d.isBefore(weekEnd);

    // Today at midnight. Item expires on its expiry day
    // Items expiring today count as wasted in the pie chart.
    final todayDate = DateTime(today.year, today.month, today.day);
    bool reachedExpiry(DateTime d) =>
        !DateTime(d.year, d.month, d.day).isAfter(todayDate);

    // Spending this week: groceries vs meals eaten out. Used only for
    // meals out and the remaining budget.
    double groceries = 0;
    double mealsOut = 0;
    for (final log in mealLogs) {
      if (!inWeek(log.mealDate)) continue;
      final amount = double.tryParse(log.mealPrice) ?? 0.0;
      if (log.source == 'grocery') {
        groceries += amount;
      } else {
        mealsOut += amount;
      }
    }

    // Value used and wasted this week, from usage events. Not limited by this week
    // spending because the food may have been bought in an earlier week.
    double used = 0;
    double wasted = 0;
    for (final event in usageEvents) {
      if (!inWeek(event.date)) continue;
      if (event.outcome == 'wasted') {
        wasted += event.value;
      } else {
        used += event.value;
      }
    }

    // Go through the inventory:
    // - expired items counts (even if bought before this week)
    //- items not yet expired are still in pantry
    double inPantry = 0;
    for (final item in inventory) {
      if (item.itemQuantity <= 0) continue;
      final value =
          (item.priceUnknown ? 0.0 : item.price) * item.itemQuantity;
      if (reachedExpiry(item.expiryDate)) {
        if (inWeek(item.expiryDate)) wasted += value;
      } else if (inWeek(item.entryDate)) {
        inPantry += value;
      }
    }

    // Remaining budget, or how far over budget the user is.
    final difference = weeklyGoal - (groceries + mealsOut);

    return WeeklyPieSummary(
      used: used,
      wasted: wasted,
      inPantry: inPantry,
      mealsOut: mealsOut,
      remaining: difference > 0 ? difference : 0,
      overBudgetBy: difference < 0 ? -difference : 0,
      weeklyGoal: weeklyGoal,
    );
  }
}