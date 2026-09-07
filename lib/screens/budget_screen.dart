import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../models/spend_log_entry.dart';
import '../models/spend_source.dart';

// StatefulWidget so UI can change, entry list needs to update with everyspend
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // Prototype-only: starts with a sample weekly goal and no persistence. Final version should load this from user budgetgoal.
  final Budget _budget = Budget(userId: 'demo-user', weeklyBudgetGoal: 120.0);

  // Controllers for textfield snf clear
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

  // Tracks which SpendSource is currently selected in the dropdown.
  SpendSource _selectedSource = SpendSource.inventoryItem;
  
   @override
  void dispose() {
    _amountController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _submitEntry() {
    final amountText = _amountController.text.trim();

    // tryParse returns null instead of throwing if the text isn't a valid number
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount greater than 0.')), 
      );
      return;
    }

    // The label field depdends on the SpendSource selected
    final label = _labelController.text.trim();

    setState(() {
      // use whichever concrete subclass matches
      final SpendLogEntry newEntry;
      if (_selectedSource == SpendSource.inventoryItem) {
        newEntry = InventoryPurchaseSpend(
          userId: _budget.userId,
          amountSpent: amount,
          entryDate: DateTime.now(),
          itemName: label.isEmpty ? 'Unnamed item' : label,
        );
      } else {
        newEntry = MealOutSpend(
          userId: _budget.userId,
          amountSpent: amount,
          entryDate: DateTime.now(),
          mealName: label.isEmpty ? 'Unnamed meal' : label,
        );
      }
      _budget.addSpendEntry(newEntry);
    });

    _amountController.clear();
    _labelController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Spend logged.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final spent = _budget.getSpent(now);
    final remaining = _budget.getRemaining(now);
    final overBudget = _budget.isOverBudget(now);
    final entries = _budget.entriesForWeek(now);

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
              'Log a spend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildEntryForm(),
            const SizedBox(height: 24),
            Text(
              "This week's spending",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Expanded so the list fills whatever is left on the screen
            Expanded(child: _buildEntryList(entries)),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amountController,
                // Shows a numeric keyboard with a decimal point on mobile.
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: r'$',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // User picks which SpendSource this entry belongs to.
            DropdownButton<SpendSource>(
              value: _selectedSource,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedSource = value);
              },
              // Builds one menu item per SpendSource enum value, so this, automatically includes new items.
              items: SpendSource.values
                  .map(
                    (source) => DropdownMenuItem(
                      value: source,
                      child: Text(source.label),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _labelController,
          decoration: InputDecoration(
            labelText: _selectedSource == SpendSource.inventoryItem
                ? 'Item name'
                : 'Meal name',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitEntry,
            child: const Text('Add to spend log'),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryList(List<SpendLogEntry> entries) {
  if (entries.isEmpty) {
    return const Center(child: Text('No spending logged yet this week.'));
  }

  return ListView(
    children: [
      for (var entry in entries)
        ListTile(
          leading: CircleAvatar(
            backgroundColor: entry.source.color,
            child: Icon(entry.source.icon, color: Colors.white),
          ),
          title: Text(entry.description),
          subtitle: Text(entry.source.label),
          trailing: Text('\$${entry.amountSpent.toStringAsFixed(2)}'),
        ),
     ],
    );
  }
}

// displays whatever values are passed into it from BudgetScreen.
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
      // Card color signals status at a glance: red if over budget,
      // green otherwise.
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