import 'package:flutter/material.dart';

class SignupBudgetField extends StatelessWidget
{
  final TextEditingController controller;

  const SignupBudgetField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context)
  {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Weekly Budget Goal',
        border: OutlineInputBorder(),
        prefixText: '\$ ',
        hintText: '0.00',
      ),
    );
  }
}