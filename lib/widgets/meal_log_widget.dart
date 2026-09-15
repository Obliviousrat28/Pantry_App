import 'package:flutter/material.dart';

//***** MEAL ADDING WIDGET - START *****
// this is what one logged meal looks like, natalia needs this for the budget stuff
class MealLog {
  final String mealName;
  final String mealPrice;
  final DateTime mealDate;

  MealLog({
    required this.mealName,
    required this.mealPrice,
    required this.mealDate,
  });
}

// form that pops up for logging a meal i ate out
class LogMealDialog extends StatefulWidget {
  const LogMealDialog({super.key});

  @override
  State<LogMealDialog> createState() => _LogMealDialogState();
}

class _LogMealDialogState extends State<LogMealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _mealNameController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _mealDate;

  @override
  void dispose() {
    _mealNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickMealDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _mealDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _mealDate != null) {
      final newMeal = MealLog(
        mealName: _mealNameController.text,
        mealPrice: _priceController.text,
        mealDate: _mealDate!,
      );
      Navigator.of(context).pop(newMeal);
    } else if (_mealDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a date')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log a Meal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _mealNameController,
              decoration: const InputDecoration(labelText: 'What did you eat?'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter a meal name' : null,
            ),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'How much did it cost?'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter the price' : null,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _mealDate == null
                        ? 'No date selected'
                        : 'Date: ${_mealDate!.toLocal()}'.split(' ')[0],
                  ),
                ),
                TextButton(
                  onPressed: _pickMealDate,
                  child: const Text('Pick date'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
//***** MEAL ADDING WIDGET - END *****