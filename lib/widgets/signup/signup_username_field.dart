import 'package:flutter/material.dart';

class SignupUsernameField extends StatelessWidget
{
  final TextEditingController controller;

  const SignupUsernameField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context)
  {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Username',
        border: OutlineInputBorder(),
      ),
    );
  }
}