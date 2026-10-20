import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/spending_pie_summary.dart';

// One coloured slice of the pie, with its label and value.
class _Slice {
  final String label;
  final double value;
  final Color color;
  final Color textColor;

  const _Slice(this.label, this.value, this.color,
      {this.textColor = Colors.white});
}

// Pie chart of where this week's budget went, with a legend underneath.
class WeeklySpendingPieChart extends StatelessWidget {
  final WeeklyPieSummary summary;

  const WeeklySpendingPieChart({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    // Nothing to draw until something has been spent.
    if (!summary.hasSpending) {
      return const Center(child: Text('No spending logged yet this week.'));
    }

    // All possible slices; zero-value ones are left out.
    final slices = [
      _Slice('Used', summary.used, Colors.green),
      _Slice('Wasted', summary.wasted, Colors.red),
      _Slice('Still in pantry', summary.inPantry, Colors.blueGrey),
      _Slice('Meals out', summary.mealsOut, Colors.orange),
      _Slice('Remaining', summary.remaining, Colors.grey.shade300,
          textColor: Colors.black87),
    ].where((s) => s.value > 0).toList();

    return Column(
      children: [
        // The pie itself, with dollar amounts on each slice.
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                for (final s in slices)
                  PieChartSectionData(
                    value: s.value,
                    color: s.color,
                    radius: 70,
                    title: '\$${s.value.toStringAsFixed(0)}',
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: s.textColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Legend: colour, label and exact amount for each slice.
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            for (final s in slices)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: s.color),
                  const SizedBox(width: 4),
                  Text('${s.label}: \$${s.value.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
          ],
        ),

        // Warning if the weekly goal has been exceeded.
        if (summary.overBudgetBy > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Over budget by \$${summary.overBudgetBy.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}