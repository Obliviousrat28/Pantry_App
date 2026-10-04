import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget
{
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No items in your history yet.\nItems you add will appear here.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}