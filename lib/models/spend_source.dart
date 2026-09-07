import 'package:flutter/material.dart';

//enum SpendSource: inventoryItem or mealOut
enum SpendSource {
  inventoryItem(Colors.blue),
  //color-coding spendsources
  mealOut(Colors.orange);

  const SpendSource(this.color);

//the color that will be displayed in the UI to distringuish
  final Color color;

  String get label => switch (this) {
    SpendSource.inventoryItem => 'Inventory Purchase',
    SpendSource.mealOut => 'Meal Out',
  };

  IconData get icon => switch (this) {
    SpendSource.inventoryItem => Icons.shopping_cart,
    SpendSource.mealOut => Icons.restaurant,
  };
}