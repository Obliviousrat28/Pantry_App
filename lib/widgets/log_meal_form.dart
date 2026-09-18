import 'package:flutter/material.dart';
import '../models/meal_log.dart';

class LogMealForm extends StatefulWidget {
  final Function(MealLog)? onLogMeal;

  const LogMealForm({super.key, this.onLogMeal});

  @override
  State<LogMealForm> createState() => LogMealFormState();
}

class LogMealFormState extends State<LogMealForm> {
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

  void submit() {
    if (_formKey.currentState!.validate() && _mealDate != null) {
      final newMeal = MealLog(
        mealName: _mealNameController.text,
        mealPrice: _priceController.text,
        mealDate: _mealDate!,
      );
      if (widget.onLogMeal != null) {
        widget.onLogMeal!(newMeal);
      }
      Navigator.of(context).pop(newMeal);
    } else if (_mealDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a date')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
          const SizedBox(height: 12),
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
    );
  }
}