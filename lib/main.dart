import 'package:flutter/material.dart';

import 'screens/budget_screen.dart';

void main() {
  runApp(const MyPantryPrototype());
}

class MyPantryPrototype extends StatelessWidget {
  const MyPantryPrototype({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Pantry - Budget Prototype',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const BudgetScreen(),
    );
  }
}//random comment