import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../widgets/shopping_item_add_dialog.dart';
import '../widgets/item_card.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final List<InventoryItem> _shoppingItems = [];

  // 1. ADD ITEM
  void _openAddItemDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ShoppingItemAddDialog(
        onAddItem: (newItem) {
          setState(() {
            _shoppingItems.add(newItem);
          });
        },
      ),
    );
  }

  // In _openEditItemDialog:
  void _openEditItemDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => ShoppingItemAddDialog(
        initialData: item,
        onAddItem: (updatedItem) {
          setState(() {
            item.edit(
              name: updatedItem.itemName,
              quantity: updatedItem.itemQuantity,
              price: updatedItem.price,
              priceUnknown: updatedItem.priceUnknown,
            );
          });
        },
      ),
    );
  }

  // 3. DELETE ITEM
  void _deleteItem(InventoryItem item) {
    setState(() {
      _shoppingItems.removeWhere((element) => element.itemId == item.itemId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.itemName} removed from shopping list')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'), // Back button automatically included
      ),
      body: _shoppingItems.isEmpty
          ? const Center(
              child: Text(
                'Your shopping list is empty.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: _shoppingItems.length,
              itemBuilder: (context, index) {
                final item = _shoppingItems[index];
                return Dismissible(
                  key: ValueKey(item.itemId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteItem(item),
                  child: ItemCard(
                    item: item,
                    onEdit: () => _openEditItemDialog(item),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemDialog,
        tooltip: 'Add to Shopping List',
        child: const Icon(Icons.add),
      ),
    );
  }
}