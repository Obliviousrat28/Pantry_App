import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/spending_summary.dart';

// Line graph of cumulative spending for the current week (Monday to Sunday),
// with the weekly budget goal drawn as a dashed horizontal line.
class WeeklySpendingLineChart extends StatelessWidget {
  final WeeklySpendingSummary summary;

  const WeeklySpendingLineChart({super.key, required this.summary});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final cumulative = summary.cumulativeSpent;
    final goal = summary.weeklyGoal;

    // Only plot up to today, so the line stops instead of running flat
    // through days that haven't happened yet.
    final todayIndex = DateTime.now().weekday - 1;
    final spots = [
      for (var i = 0; i <= todayIndex; i++) FlSpot(i.toDouble(), cumulative[i]),
    ];

    // Leave headroom above the highest value so nothing touches the top.
    final highest = max(goal, cumulative.last);
    final maxY = (highest <= 0 ? 100.0 : highest) * 1.2;

    // Green while within budget, red once the goal has been exceeded.
    final lineColour = summary.overBudget ? Colors.red : Colors.green;

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),

              // Axis labels: dollar amounts on the left, day names below.
              titlesData: FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) => Text(
                      '\$${value.toInt()}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      // Only label whole numbers 0 to 6.
                      if (i < 0 || i > 6 || value != i.toDouble()) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _dayLabels[i],
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Dashed line showing the weekly budget goal.
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: goal,
                    color: Colors.orange,
                    strokeWidth: 2,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topLeft,
                      style: const TextStyle(fontSize: 10, color: Colors.orange),
                      labelResolver: (_) => 'Goal \$${goal.toStringAsFixed(0)}',
                    ),
                  ),
                ],
              ),

              // The spending line itself, with a light fill underneath.
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: lineColour,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColour.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Small legend explaining the two lines.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 16, color: lineColour),
            const SizedBox(width: 4),
            const Text('Total spent', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 16),
            const Icon(Icons.horizontal_rule, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            const Text('Weekly goal', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}