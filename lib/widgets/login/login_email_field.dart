import 'package:flutter/material.dart';

class LoginEmailField extends StatelessWidget
{
  final TextEditingController controller;

  const LoginEmailField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context)
  {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
      ),
    );
  }
}