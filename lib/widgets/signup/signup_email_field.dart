import 'package:flutter/material.dart';

class SignupEmailField extends StatelessWidget
{
  final TextEditingController controller;

  const SignupEmailField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context)
  {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email Address',
        border: OutlineInputBorder(),
      ),
    );
  }
}