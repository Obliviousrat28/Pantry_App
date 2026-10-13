import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
 
class ShoppingItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onEdit;
  final ValueChanged<bool> onCheckedChanged;
 
  const ShoppingItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onCheckedChanged,
  });
 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChecked = item.isChecked;
 
    return Opacity(
      opacity: isChecked ? 0.5 : 1.0, // Greys out the card when checked
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Qty: ${item.itemQuantity.toInt()}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  Row(
                    children: [
                      Text(
                        isChecked ? 'Bought' : 'To Buy',
                        style: TextStyle(
                          fontSize: 12,
                          color: isChecked
                              ? Colors.grey
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Checkbox(
                        value: isChecked,
                        onChanged: (v) => onCheckedChanged(v ?? false),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 
