import 'package:flutter/material.dart';
import '../models/meal_log.dart';
import '../services/spending_summary.dart';
import '../widgets/weekly_spending_line_chart.dart';

// TEMPORARY: while true, the charts use sample data. Set to false
// (and delete the sample function) before submitting.
const bool useSampleData = false;

// Full-page view of the user's spending charts for the current week.
// Opened from the Budget tab. Each chart has its own tab.
class SpendingInsightsScreen extends StatelessWidget {
  final double weeklyBudgetGoal;
  final List<MealLog> mealLogs;

  const SpendingInsightsScreen({
    super.key,
    required this.mealLogs,
    required this.weeklyBudgetGoal,
  });

  @override
  Widget build(BuildContext context) {
    // Weekly numbers for the charts (sample data while testing).
    final chartLogs = useSampleData ? sampleMealLogs() : mealLogs;
    final summary = WeeklySpendingSummary.fromLogs(chartLogs, weeklyBudgetGoal);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Spending Insights'),
          // Tabs to switch between the two charts.
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Line graph'),
              Tab(text: 'Pie chart'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LineGraphTab(summary: summary),
            // Placeholder until the pie chart is built.
            const Center(child: Text('Pie chart coming soon')),
          ],
        ),
      ),
    );
  }
}

// Line graph tab: week label, spending figures, and the chart itself.
class _LineGraphTab extends StatelessWidget {
  final WeeklySpendingSummary summary;

  const _LineGraphTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    final weekStart = summary.weekStart;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Which week the chart covers.
          Text(
            'Week of ${weekStart.day}/${weekStart.month}/${weekStart.year}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          // Total spent and remaining (or over budget) for the week.
          Text('Total spent: \$${summary.totalSpent.toStringAsFixed(2)}'),
          Text(
            summary.overBudget
                ? 'Over budget by \$${(-summary.remaining).toStringAsFixed(2)}'
                : 'Remaining: \$${summary.remaining.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: summary.overBudget
                  ? Colors.red.shade700
                  : Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 16),

          // The line graph fills the rest of the page.
          Expanded(child: WeeklySpendingLineChart(summary: summary)),
        ],
      ),
    );
  }
}