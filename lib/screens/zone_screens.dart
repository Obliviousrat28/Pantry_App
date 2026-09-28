import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/storage_zone.dart';
import '../widgets/item_card.dart';
import '../widgets/item_add_dialog.dart';

/// A screen that displays inventory items grouped by their storage zones.
class ZoneScreen extends StatelessWidget {
  const ZoneScreen({
    super.key,
    required this.title,
    required this.items,
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  /// The title of the screen, typically representing the storage zone.
  final String title;
  final List<InventoryItem> items;
  final Function(InventoryItem) onAddItem;
  final Function(InventoryItem) onEditItem;
  final Function(InventoryItem) onDeleteItem;

  /// Retrieves a list of inventory items that belong to the specified storage zone.
  List<InventoryItem> _getItemsForZone(StorageZone zone) {
    final zoneItems = items.where((item) => item.storageZone == zone).toList();
    zoneItems.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return zoneItems;
  }

  /// Opens a dialog to edit the specified inventory item.
  void _editItem(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ItemAddDialog(
          initialData: item,
          onAddItem: onEditItem,
        );
      },
    );
  }

  /// Builds the widget tree for the ZoneScreen, displaying inventory items grouped by storage zones.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        children: StorageZone.values.map((zone) {
          final zoneItems = _getItemsForZone(zone);
          // Return a card for each storage zone, displaying its items in an expandable list.
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            // Use Theme to customize the ExpansionTile's divider color to be transparent.
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: false,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  '${zone.displayName} (${zoneItems.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                children: zoneItems.isEmpty
                    ? [// Display a message when there are no items in the zone
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                            child: Text(
                              'Your kitchen is empty. Add your first item.',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                        ),
                      ]
                    : zoneItems.map((item) {
                      // Return a Dismissible widget for each inventory item, allowing swipe-to-delete functionality.
                        return Dismissible(
                          key: ValueKey(item.itemId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: Text(
                                    // Show a confirmation dialog before deleting an item
                                    'Are you sure you want to delete "${item.itemName}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),// Style the delete button in the confirmation dialog
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },// Handle the deletion of an item and show a SnackBar with an undo option
                          onDismissed: (direction) {
                            onDeleteItem(item);

                            final messenger = ScaffoldMessenger.of(context);
                            messenger.clearSnackBars();
                            
                            // Show a SnackBar to inform the user that the item has been deleted, with an option to undo the action.
                            final controller = messenger.showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 3),
                                dismissDirection: DismissDirection.horizontal,
                                content: Text('${item.itemName} deleted'),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  textColor: Colors.amber,
                                  onPressed: () {
                                    onAddItem(item);
                                  },
                                ),
                              ),
                            );
                            
                            // Automatically close the SnackBar after 3 seconds to prevent it from lingering on the screen.
                            Future.delayed(const Duration(seconds: 3), () {
                              controller.close();
                            });
                          },
                          child: ItemCard(
                            item: item,
                            onEdit: () => _editItem(context, item),
                          ),
                        );
                      }).toList(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}