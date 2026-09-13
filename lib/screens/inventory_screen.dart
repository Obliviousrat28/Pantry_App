import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../widgets/item_add_dialog.dart';
import '../widgets/item_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<InventoryItem> _items = [];

  void _openAddItemDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ItemAddDialog(
        onAddItem: (newItem) {
          setState(() {
            _items.add(newItem);
          });
        },
      ),
    );
  }

  void _openEditItemDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => ItemAddDialog(
        initialData: item,
        onAddItem: (updatedItem) {
          setState(() {
            item.edit(
              name: updatedItem.itemName,
              quantity: updatedItem.itemQuantity,
              price: updatedItem.price,
              expiry: updatedItem.expiryDate,
              zone: updatedItem.storageZone,
              priceUnknown: updatedItem.priceUnknown,
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: _items.isEmpty
          ? const Center(child: Text('No items added yet.'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (ctx, index) {
                final item = _items[index];
                return ItemCard(
                  item: item,
                  onEdit: () => _openEditItemDialog(item),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}