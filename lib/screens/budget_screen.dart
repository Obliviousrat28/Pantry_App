import 'package:flutter/material.dart';
import '../models/meal_log.dart';
import 'spending_insights_screen.dart';

//Budget screen shows this week's spending against weekly budget goal
//as a summary card, a line graph and list of individual entries
class BudgetScreen extends StatelessWidget {
  final double weeklyBudgetGoal;
  final List<MealLog> mealLogs;

  const BudgetScreen({
    super.key,
    required this.mealLogs,
    required this.weeklyBudgetGoal,
  });

//return true if the given date is in the current week (Monday to Sunday)
  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return !date.isBefore(startOfWeek) && date.isBefore(endOfWeek);
  }

     @override
  Widget build(BuildContext context) {
    // This week's entries, total spent, and what is left of the goal.
    final thisWeeksLogs = mealLogs.where((log) => _isThisWeek(log.mealDate)).toList();
    final spent = thisWeeksLogs.fold<double>(
      0.0,
      (sum, log) => sum + (double.tryParse(log.mealPrice) ?? 0.0),
    );
    final remaining = weeklyBudgetGoal - spent;
    final overBudget = remaining < 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Tracking')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Weekly goal, spent, and remaining summary.
            _BudgetSummaryCard(
              weeklyGoal: weeklyBudgetGoal,
              spent: spent,
              remaining: remaining,
              overBudget: overBudget,
            ),
            const SizedBox(height: 12),

            // Opens the full-page spending charts.
            OutlinedButton.icon(
              icon: const Icon(Icons.show_chart),
              label: const Text('View spending charts'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => SpendingInsightsScreen(
                      mealLogs: mealLogs,
                      weeklyBudgetGoal: weeklyBudgetGoal,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // List of this week's individual entries.
            Text(
              "This week's spending",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildMealList(thisWeeksLogs)),
          ],
        ),
      ),
    );
  }

// Builds a scrollable list of meal logs for this week, or a message if there are none.
  Widget _buildMealList(List<MealLog> meals) {
    if (meals.isEmpty) {
      return const Center(child: Text('No spending logged yet this week.'));
    }

    return ListView.builder(
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.fastfood, color: Colors.white),
          ),
          title: Text(meal.mealName),
          subtitle: Text(meal.mealDate.toString().split(' ')[0]),
          trailing: Text('\$${meal.mealPrice}'),
        );
      },
    );
  }
}

//card showing weekly goal, spent and remaining budget, with color coding for over/under budget
class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({
    required this.weeklyGoal,
    required this.spent,
    required this.remaining,
    required this.overBudget,
  });

  final double weeklyGoal;
  final double spent;
  final double remaining;
  final bool overBudget;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: overBudget ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly goal: \$${weeklyGoal.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Spent so far: \$${spent.toStringAsFixed(2)}'),
            Text(
              overBudget
                  ? 'Over budget by \$${(-remaining).toStringAsFixed(2)}'
                  : 'Remaining: \$${remaining.toStringAsFixed(2)}',
              style: TextStyle(
                color: overBudget
                    ? Colors.red.shade700
                    : Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}