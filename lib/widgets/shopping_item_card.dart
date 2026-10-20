import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
 
class ShoppingItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onEdit;
  final ValueChanged<bool> onCheckedChanged;
  
  // Constructor for the ShoppingItemCard widget, requiring an InventoryItem, an edit callback, and a checked state change callback.
  const ShoppingItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onCheckedChanged,
  });
 
  // Builds the widget tree for the shopping item card, displaying item details and providing edit and check functionalities.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChecked = item.isChecked;
 
    // Returns an Opacity widget that greys out the card when the item is checked, containing a Card widget with item details and action buttons.
    return Opacity(
      opacity: isChecked ? 0.5 : 1.0, // Greys out the card when checked
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        // The Card widget is styled with rounded corners and a border, containing a Padding widget that holds the item details and action buttons.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row containing the item name and edit button, with the item name struck through if checked.
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
              // Row containing the item quantity and a checkbox to mark the item as bought or to buy, with the checkbox state reflecting the item's checked status.
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
 
