import 'package:flutter/material.dart';

class SignupPasswordField extends StatelessWidget
{
  final TextEditingController controller;

  const SignupPasswordField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context)
  {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Password',
        border: OutlineInputBorder(),
      ),
    );
  }
}