import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../widgets/item_card.dart';
import '../widgets/item_add_dialog.dart';
import '../models/storage_zone.dart';

/// A screen that displays the inventory items grouped by their storage zones.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// The state class for the HomeScreen, managing the list of inventory items and their interactions.
class _HomeScreenState extends State<HomeScreen> {
  final List<InventoryItem> _items = [];

  // Sorts the inventory items by their expiry date in ascending order.
  void _sortItemsByExpiry() {
    _items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  // Retrieves a list of inventory items that belong to the specified storage zone.
  List<InventoryItem> _getItemsForZone(StorageZone zone) {
    return _items.where((item) => item.storageZone == zone).toList();
  }

  // Opens a dialog to add a new inventory item.
  void _showPopUpScreen() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ItemAddDialog(
          onAddItem: (newItem) {
            setState(() {
              _items.add(newItem);
              _sortItemsByExpiry();
            });
          },
        );
      },
    );
  }

  // Opens a dialog to edit an existing inventory item.
  void _editItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ItemAddDialog(
          initialData: item,
          onAddItem: (updatedItem) {
            setState(() {
              final index = _items.indexWhere((element) => element.itemId == item.itemId);
              if (index != -1) {
                _items[index] = updatedItem;
                _sortItemsByExpiry();
              }
            });
          },
        );
      },
    );
  }

  // Builds the widget tree for the HomeScreen, displaying inventory items grouped by storage zones.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
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
            // Use Theme to customize the ExpansionTile's appearance, including removing the divider line.
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: false,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text('${zone.displayName} (${zoneItems.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                children: zoneItems.isEmpty
                    ? [// Display a message when there are no items in the storage zone.
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                            child: Text(
                              'Your kitchen is empty. Add your first item.',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                        ),
                      ]// Display the list of items in the storage zone.
                    : zoneItems.map((item) {
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
                          // Show a confirmation dialog before dismissing the item.
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: Text('Are you sure you want to delete "${item.itemName}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                      // Close the dialog without deleting the item.
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },// Handle the dismissal of the item, including showing a SnackBar with an UNDO option.
                          onDismissed: (direction) {
                            final deletedItem = item;
                            final deletedIndex = _items.indexWhere((element) => element.itemId == item.itemId);

                            // Remove item from local state immediately
                            if (deletedIndex != -1) {
                              setState(() {
                                _items.removeAt(deletedIndex);
                              });
                            }

                            // Clear any active snackbars
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.clearSnackBars();

                            // Show the SnackBar without relying solely on internal auto-dismissal
                            final controller = messenger.showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 4),
                                content: Text('${deletedItem.itemName} deleted'),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  textColor: Colors.amber,
                                  onPressed: () {
                                    setState(() {// Restore the deleted item if UNDO is pressed, ensuring it is not duplicated in the list.
                                      if (!_items.any((e) => e.itemId == deletedItem.itemId)) {
                                        _items.insert(
                                          deletedIndex > _items.length ? _items.length : deletedIndex,
                                          deletedItem,
                                        );
                                        _sortItemsByExpiry();
                                      }
                                    });
                                  },
                                ),
                              ),
                            );// Automatically close the SnackBar after 4 seconds to prevent it from lingering on the screen.
                            Future.delayed(const Duration(seconds: 4), () {
                              if (mounted) {
                                controller.close();
                              }
                            });
                          },
                          child: ItemCard(
                            item: item,
                            onEdit: () => _editItem(item),
                          ),
                        );
                      }).toList(),
              ),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPopUpScreen,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}