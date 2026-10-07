import 'package:flutter/material.dart';

class SignupErrorMessage extends StatelessWidget
{
  final String errorMessage;

  const SignupErrorMessage({
    Key? key,
    required this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context)
  {
    if (errorMessage.isEmpty)
    {
      return const SizedBox.shrink();
    }

    return Text(
      errorMessage,
      style: const TextStyle(color: Colors.red),
    );
  }
}