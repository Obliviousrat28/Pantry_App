import 'package:flutter/material.dart';
import '../models/meal_log.dart';
import '../models/budget.dart';

class BudgetScreen extends StatelessWidget {
  final double remainingBudget;
  final List<MealLog> mealLogs;

  const BudgetScreen({
    super.key,
    required this.remainingBudget,
    required this.mealLogs,
  });

  // Prototype budget goal reference
  static final Budget _budget = Budget(userId: 'demo-user', weeklyBudgetGoal: 120.0);

  @override
  Widget build(BuildContext context) {
    final spent = _budget.weeklyBudgetGoal - remainingBudget;
    final remaining = remainingBudget;
    final overBudget = remaining < 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Tracking')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BudgetSummaryCard(
              weeklyGoal: _budget.weeklyBudgetGoal,
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
            Expanded(child: _buildMealList(mealLogs)),
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