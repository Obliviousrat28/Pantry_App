import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;

class SettingsScreen extends StatefulWidget {
  final User? user;
  final double weeklyBudgetGoal;
  final Function(double) onUpdateBudgetGoal;
  final Function(List<String>) onUpdateDietaryPreferences;

  const SettingsScreen({
    super.key,
    required this.user,
    required this.weeklyBudgetGoal,
    required this.onUpdateBudgetGoal,
    required this.onUpdateDietaryPreferences,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _goalController;
  late List<String> _dietaryPreference;

  final List<String> dietaryOptions = [ //to be replaced with enum
    'Vegetarian',
    'Vegan',
    'Halal',
    'Dairy-Free',
    'Nut-Free',
    'High-Protein',
  ];

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(text: widget.weeklyBudgetGoal.toStringAsFixed(2));
    _dietaryPreference = List<String>.from(widget.user?.dietaryPreference ?? []);
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _saveBudgetGoal() {
    final newGoal = double.tryParse(_goalController.text);

    if (newGoal == null || newGoal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number.')),
      );
      return;
    }

    if (newGoal == widget.weeklyBudgetGoal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That's already your current budget goal.")),
      );
      return;
    }

    widget.onUpdateBudgetGoal(newGoal);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weekly budget goal updated!')),
    );
  }

  void _toggleDietaryPreference(String option, bool selected) {
    setState(() {
      if (selected) {
        _dietaryPreference.add(option);
      } else {
        _dietaryPreference.remove(option);
      }
    });
    widget.onUpdateDietaryPreferences(_dietaryPreference);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard when tapping outside
      child: Scaffold(resizeToAvoidBottomInset: false,
      appBar: AppBar(title:const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Account Details', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Username: ${user?.userName ?? 'Not signed in'}'),
                  const SizedBox(height: 4),
                  Text('Email: ${user?.userEmail ?? 'N/A'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Weekly Budget Goal', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _goalController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                    labelText: 'Update your weekly budget goal',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _saveBudgetGoal,
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Dietary Preferences', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: dietaryOptions.map((option) {
              return FilterChip(
                label: Text(option),
                selected: _dietaryPreference.contains(option),
                onSelected: (selected) => _toggleDietaryPreference(option, selected),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
          child: const Text('Sign Out'),
          ),
          ],
        ),
      ),
    );
  }
}