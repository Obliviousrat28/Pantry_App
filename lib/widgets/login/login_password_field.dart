import 'package:flutter/material.dart';

class LoginPasswordField extends StatelessWidget
{
  final TextEditingController controller;

  const LoginPasswordField({
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