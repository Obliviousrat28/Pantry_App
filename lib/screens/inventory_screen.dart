import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/storage_zone.dart';
import '../widgets/item_add_dialog.dart';
import '../widgets/item_card.dart';

// A screen that displays the inventory items grouped by their storage zones.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

// The state class for the InventoryScreen, managing the list of inventory items and their interactions.
class _InventoryScreenState extends State<InventoryScreen> {
  final List<InventoryItem> _items = [];

  // Opens a dialog to add a new inventory item.
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

  // Opens a dialog to edit an existing inventory item.
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

  // Builds the widget tree for the InventoryScreen, displaying inventory items grouped by storage zones.
  @override
  Widget build(BuildContext context) {
    // Sort items by expiry date (earliest first)
    _items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    // Group items by storage zone
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: StorageZone.values.map((zone) {
          // Filter items for the specific storage zone
          final zoneItems = _items.where((item) => item.storageZone == zone).toList();

          // Return a column for each storage zone, displaying its items or a message if there are no items.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Always display Zone Header (Fridge, Freezer, Pantry)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text(
                  zone.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Display items under the zone or fallback text
              if (zoneItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'No items in this zone.',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                )
              else
                ...zoneItems.map(
                  (item) => ItemCard(
                    item: item,
                    onEdit: () => _openEditItemDialog(item),
                  ),
                ),
              const Divider(height: 24, thickness: 1),
            ],
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}