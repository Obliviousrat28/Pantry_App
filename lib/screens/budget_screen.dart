import 'package:flutter/material.dart';
import '../models/meal_log.dart';

class BudgetScreen extends StatelessWidget {
  final double weeklyBudgetGoal;
  final List<MealLog> mealLogs;

  const BudgetScreen({
    super.key,
    required this.mealLogs,
    required this.weeklyBudgetGoal,
  });

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return !date.isBefore(startOfWeek) && date.isBefore(endOfWeek);
  }

  @override
  Widget build(BuildContext context) {
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
            _BudgetSummaryCard(
              weeklyGoal: weeklyBudgetGoal,
              spent: spent,
              remaining: remaining,
              overBudget: overBudget,
            ),
            const SizedBox(height: 24),
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