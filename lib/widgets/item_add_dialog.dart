import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/meal_log.dart';
import 'add_item_form.dart';
import 'log_meal_form.dart';

class ItemAddDialog extends StatefulWidget {
  final Function(InventoryItem) onAddItem;
  final Function(MealLog)? onLogMeal;
  final InventoryItem? initialData;
  final String? initialName;

  const ItemAddDialog({
    super.key,
    required this.onAddItem,
    this.onLogMeal,
    this.initialData,
    this.initialName,
  });

  @override
  State<ItemAddDialog> createState() => _ItemAddDialogState();
}

class _ItemAddDialogState extends State<ItemAddDialog> {
  int _selectedTabIndex = 0;
  final GlobalKey<AddItemFormState> _addItemKey = GlobalKey<AddItemFormState>();
  final GlobalKey<LogMealFormState> _logMealKey = GlobalKey<LogMealFormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Darkening Segmented Tab Selector
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Add Item',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedTabIndex == 0 ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Log Meal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedTabIndex == 1 ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Displays either AddItemForm or LogMealForm based on selected tab
            if (_selectedTabIndex == 0)
              AddItemForm(
                key: _addItemKey,
                onAddItem: widget.onAddItem,
                initialData: widget.initialData,
                initialName: widget.initialName,
              )
            else
              LogMealForm(
                key: _logMealKey,
                onLogMeal: widget.onLogMeal,
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedTabIndex == 0) {
              _addItemKey.currentState?.submit();
            } else {
              _logMealKey.currentState?.submit();
            }
          },
          child: Text(_selectedTabIndex == 0 ? 'Add Item' : 'Save Meal'),
        ),
      ],
    );
  }
}