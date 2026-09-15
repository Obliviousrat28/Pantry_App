import 'package:flutter/material.dart';

class SignupConfirmPasswordField extends StatelessWidget
{
  final TextEditingController controller;

  const SignupConfirmPasswordField({
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
        labelText: 'Confirm Password',
        border: OutlineInputBorder(),
      ),
    );
  }
}