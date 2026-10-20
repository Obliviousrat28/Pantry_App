import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/meal_log.dart';
import '../models/usage_event.dart';
import '../services/spending_pie_summary.dart';
import '../services/spending_summary.dart';
import '../services/storage_service.dart';
import '../widgets/weekly_spending_line_chart.dart';
import '../widgets/weekly_spending_pie_chart.dart';


// Full-page view of the user's spending charts for the current week.
// Opened from the Budget tab. Each chart has its own tab.
class SpendingInsightsScreen extends StatelessWidget {
  final double weeklyBudgetGoal;
  final List<MealLog> mealLogs;
  final List<InventoryItem> inventoryItems;

  const SpendingInsightsScreen({
    super.key,
    required this.mealLogs,
    required this.weeklyBudgetGoal,
    required this.inventoryItems,
  });

  @override
  Widget build(BuildContext context) {
    // Weekly totals for line graph from spending log
    final summary = WeeklySpendingSummary.fromLogs(mealLogs, weeklyBudgetGoal);

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
            _PieTab(
              mealLogs: mealLogs,
              inventoryItems: inventoryItems,
              weeklyBudgetGoal: weeklyBudgetGoal,
            ),
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

// Pie chart tab: loads the usage records, then shows how this week's
// money was split between used, wasted, pantry, meals out and remaining.
class _PieTab extends StatefulWidget {
  final List<MealLog> mealLogs;
  final List<InventoryItem> inventoryItems;
  final double weeklyBudgetGoal;

  const _PieTab({
    required this.mealLogs,
    required this.inventoryItems,
    required this.weeklyBudgetGoal,
  });

  @override
  State<_PieTab> createState() => _PieTabState();
}

class _PieTabState extends State<_PieTab> {
  late final Future<List<UsageEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    // user records (used/wasted) from firestore
    _eventsFuture = StorageService().loadUsageEvents();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UsageEvent>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        // Wait for the records to load.
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        // If loading failed, tell the user instead of showing an empty pie.
        if (snapshot.hasError) {
          return const Center(
            child: Text("Couldn't load usage records. Please try again."),
          );
        }

        final summary = WeeklyPieSummary.fromData(
          mealLogs: widget.mealLogs,
          usageEvents: snapshot.data ?? [],
          inventory: widget.inventoryItems,
          weeklyGoal: widget.weeklyBudgetGoal,
        );

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: WeeklySpendingPieChart(summary: summary),
        );
      },
    );
  }
}