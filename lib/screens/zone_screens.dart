import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/storage_zone.dart';
import '../widgets/item_card.dart';
import '../widgets/item_add_dialog.dart';

class ZoneScreen extends StatelessWidget {
  const ZoneScreen({
    super.key,
    required this.title,
    required this.items,
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  final String title;
  final List<InventoryItem> items;
  final Function(InventoryItem) onAddItem;
  final Function(InventoryItem) onEditItem;
  final Function(InventoryItem) onDeleteItem;

  List<InventoryItem> _getItemsForZone(StorageZone zone) {
    final zoneItems = items.where((item) => item.storageZone == zone).toList();
    zoneItems.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return zoneItems;
  }

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

          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
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
                    ? [
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
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
                            onDeleteItem(item);

                            final messenger = ScaffoldMessenger.of(context);
                            messenger.clearSnackBars();

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