import 'spend_log_entry.dart';

// Budget is determined by user's weeklyBdugetGoal
// spend log entries recorded against it.
class Budget {
  Budget({required this.userId, required this.weeklyBudgetGoal});

  final String userId;
  double weeklyBudgetGoal;//can be changed

  final List<SpendLogEntry> _entries = [];

  // Adds a new spend entry to this budget's history.
  void addSpendEntry(SpendLogEntry entry) {
    _entries.add(entry);
  }

 DateTime _startOfWeek(DateTime date) {
  // Strip the time of day from Date Time so that it doesn't affect the calculation
  var current = DateTime(date.year, date.month, date.day);

  // Loop backwards until it is the Monday of that same week
  while (current.weekday != DateTime.monday) {
    current = current.subtract(const Duration(days: 1));
  }
  return current;
}

  // All entries recorded within the week of the date are added to a list
  List<SpendLogEntry> _entriesForWeek(DateTime date) {
    final weekStart = _startOfWeek(date); 
    final weekEnd = weekStart.add(const Duration(days: 7));// for the full week Monday to Sunday
    return _entries.where((entry) {
      return !entry.entryDate.isBefore(weekStart) &&
          entry.entryDate.isBefore(weekEnd);
    }).toList();
  }

//total amount spent during that week
  double getSpent(DateTime date) {
  final weekEntries = _entriesForWeek(date);
  double total = 0.0;
  for (var entry in weekEntries) {
    total += entry.amountSpent;
  }
  return total;
}

  // The amount remaining in budget for the week. Can go negative.
  double getRemaining(DateTime date) {
    return weeklyBudgetGoal - getSpent(date);
  }

  // Check if overbudget
  bool isOverBudget(DateTime date) {
    return getSpent(date) > weeklyBudgetGoal;
  }

  //All Entries for the week, starting from most recent
  List<SpendLogEntry> entriesForWeek(DateTime date) {
    final entries = _entriesForWeek(date);
    entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return entries;
  }
}
