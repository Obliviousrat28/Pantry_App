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
    required this.onRestoreItem,//restore item callback for UNDO
  });

  /// The title of the screen, typically representing the storage zone.
  final String title;
  final List<InventoryItem> items;
  final Function(InventoryItem) onAddItem;
  final Function(InventoryItem) onEditItem;
  final Function(InventoryItem, String) onDeleteItem;
  final Function(InventoryItem) onRestoreItem;

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
                        // Remembers what the user chose in the delete prompts.
                        String? deleteOutcome;

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

                          // Swipe flow: cancel, delete only, or record usage.
                          confirmDismiss: (direction) async {
                            // First prompt: delete only, or record usage?
                            final choice = await showDialog<String>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Delete "${item.itemName}"?'),
                                  content: const Text(
                                      'Delete removes the item only. Choose '
                                      '"Record usage" to log waste or '
                                      'consumption.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(null),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop('record'),
                                      child: const Text('Record usage'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop('delete'),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );

                            // Cancel keeps the item.
                            if (choice == null) return false;

                            // Delete only: no usage record.
                            if (choice == 'delete') {
                              deleteOutcome = 'none';
                              return true;
                            }

                            // Record usage: ask what happened to the item.
                            if (!context.mounted) return false;
                            deleteOutcome = await showDialog<String>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Record usage'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(null),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop('wasted'),
                                      child: const Text('Thrown away (wasted)'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop('used'),
                                      child: const Text('Used (consumed)'),
                                    ),
                                  ],
                                );
                              },
                            );
                            return deleteOutcome != null;
                          },

                          // Delete the item, then show a SnackBar with UNDO.
                          onDismissed: (direction) {
                            onDeleteItem(item, deleteOutcome ?? 'none');

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
                                    //restore the item if the user taps UNDO
                                    onRestoreItem(item);
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