import 'package:flutter/material.dart';
import '../../models/inventory_item.dart';

/// A widget that displays an inventory item in a card format.
/// It shows the item's name, quantity, and expiry date.
/// The card's border and background color change based on the item's expiry status.
class ItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback? onEdit;

  const ItemCard({
    super.key,
    required this.item,
    required this.onEdit,
  });

/// Builds the widget tree for the ItemCard.
  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${item.expiryDate.day.toString().padLeft(2, '0')}/'
        '${item.expiryDate.month.toString().padLeft(2, '0')}/'
        '${item.expiryDate.year}';

    // Determine the expiry status of the item
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expirationDay = DateTime(
      item.expiryDate.year,
      item.expiryDate.month,
      item.expiryDate.day,
    );

    // Calculate the difference in days between today and the expiry date
    final differenceInDays = expirationDay.difference(today).inDays;

    // Set default colors for the card
    Color borderColor = Colors.transparent;
    Color backgroundColor = Colors.transparent;
    Color textColor = Colors.black;

    // Change colors based on the expiry status
    if (differenceInDays < 0) {
      borderColor = Colors.red;
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade900;
    } else if (differenceInDays <= 3) {
      borderColor = Colors.orange;
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
    }

    // Return the card widget with the appropriate styling and content
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Qty: ${item.itemQuantity.toInt()}'),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(
                      color: borderColor,
                      width: borderColor == Colors.transparent ? 0 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Expires: $formattedDate',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: borderColor == Colors.transparent
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}