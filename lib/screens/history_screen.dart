import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/history_entry.dart';
import '../models/inventory_item.dart';
import '../services/storage_service.dart';

// Screen that shows the user's history of items added to and removed from their inventory, and lets them re-add items.
class HistoryScreen extends StatefulWidget
{
  // Function from the navigation screen used to add an item back into the inventory
  final Function(InventoryItem) onAddItem;

  // Creates the history screen with the function used for re-adding items.
  const HistoryScreen({super.key, required this.onAddItem});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
{
  final StorageService _storageService = StorageService();
  List<HistoryEntry> _history = [];
  bool _isLoading = true;

  // Loads the history as soon as the screen is opened.
  @override
  void initState()
  {
    super.initState();
    _loadHistory();
  }

  // Loads the user's history from Firestore and updates the screen, showing an empty list if loading fails.
  Future<void> _loadHistory() async
  {
    List<HistoryEntry> entries = [];
    try
    {
      entries = await _storageService.loadHistory();
    }
    catch (e)
    {
      entries = [];
    }

    // Stops if the user has left the screen before loading finished
    if (!mounted)
    {
      return;
    }

    setState(()
    {
      _history = entries;
      _isLoading = false;
    });
  }

  // Formats a date as day/month/year, e.g. 16/10/2026.
  String _formatDate(DateTime date)
  {
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  // Formats a date and time in 12-hour format with AM/PM, e.g. 16/10/2026 at 2:27 AM.
  String _formatDateTime(DateTime date)
  {
    // Converts 24-hour time to 12-hour time, where 0 becomes 12
    int hour = date.hour % 12;
    if (hour == 0)
    {
      hour = 12;
    }

    String period = 'AM';
    if (date.hour >= 12)
    {
      period = 'PM';
    }

    String minute = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)} at $hour:$minute $period';
  }

  // Returns the storage zone name with a capital first letter, e.g. Fridge.
  String _zoneName(HistoryEntry entry)
  {
    String name = entry.storageZone.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  // Returns the price per item as text, or 'Price unknown' if no price was entered.
  String _priceText(HistoryEntry entry)
  {
    if (entry.priceUnknown)
    {
      return 'Price unknown';
    }
    return '\$${entry.price.toStringAsFixed(2)} each';
  }

  // Returns the total cost (price x quantity) as text, matching what is taken off the budget.
  String _totalText(HistoryEntry entry)
  {
    if (entry.priceUnknown)
    {
      return 'Total unknown';
    }
    double total = entry.price * entry.itemQuantity;
    return 'Total \$${total.toStringAsFixed(2)}';
  }

  // Shows a confirmation box with the item's details before re-adding it to the inventory.
  Future<void> _confirmReAdd(HistoryEntry entry) async
  {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext)
      {
        return AlertDialog(
          title: Text('Add ${entry.itemName} back to your inventory?'),
          content: Text(
            'Quantity: ${entry.itemQuantity.toInt()}\n'
            'Price: ${_priceText(entry)}\n'
            '${_totalText(entry)}\n'
            'Storage: ${_zoneName(entry)}\n'
            'Expires: ${_formatDate(entry.expiryDate)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    // Only re-adds the item if the user pressed Add
    if (confirmed != true || !mounted)
    {
      return;
    }

    _reAddItem(entry);
  }

  // Creates a new inventory item with the same details as the history entry and adds it back to the inventory.
  void _reAddItem(HistoryEntry entry)
  {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'dev_test_user';

    // Gives the item a new ID so it is saved as a separate inventory item
    InventoryItem item = InventoryItem(
      itemId: const Uuid().v4(),
      userId: userId,
      itemName: entry.itemName,
      itemQuantity: entry.itemQuantity,
      price: entry.price,
      priceUnknown: entry.priceUnknown,
      expiryDate: entry.expiryDate,
      storageZone: entry.storageZone,
    );

    // Uses the same add function as the + button, so the spend log and budget are updated too
    widget.onAddItem(item);

    // Shows the new 'added' entry at the top of the list straight away
    HistoryEntry newEntry = HistoryEntry(
      itemName: entry.itemName,
      itemQuantity: entry.itemQuantity,
      price: entry.price,
      priceUnknown: entry.priceUnknown,
      storageZone: entry.storageZone,
      expiryDate: entry.expiryDate,
      action: 'added',
      dateAdded: DateTime.now(),
    );

    setState(()
    {
      _history.insert(0, newEntry);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.itemName} added back to your inventory')),
    );
  }

  Future<void> _addToShoppingList(HistoryEntry entry) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'dev_test_user';

    // How long this item lasted last time, with a 1 day minimum
    int shelfLifeDays = entry.expiryDate.difference(entry.dateAdded).inDays;
    if (shelfLifeDays < 1) shelfLifeDays = 7; 

    final shoppingItem = InventoryItem(
      itemId: const Uuid().v4(),
      userId: userId,
      itemName: entry.itemName,
      itemQuantity: entry.itemQuantity,
      price: entry.price,                 // optional: carry the last price over
      priceUnknown: entry.priceUnknown,
      expiryDate: DateTime.now().add(Duration(days: shelfLifeDays)),
      storageZone: entry.storageZone,
    );

    await _storageService.saveShoppingItem(shoppingItem);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.itemName} added to shopping list')),
    );
    // snackbar as before
  }

  // Builds the history screen. The title bar is provided by the main navigation screen.
  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      body: _buildBody(),
    );
  }

  // Shows a loading spinner, an empty message, or the list of history entries.
  Widget _buildBody()
  {
    if (_isLoading)
    {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty)
    {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No items in your history yet.\nItems you add to your inventory will appear here.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _history.length,
      itemBuilder: (context, index)
      {
        HistoryEntry entry = _history[index];
        bool wasRemoved = entry.action == 'removed';

        // Shows 'Added' in green or 'Removed' in red
        String actionText = 'Added';
        Color actionColour = Colors.green;
        if (wasRemoved)
        {
          actionText = 'Removed';
          actionColour = Colors.red;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item name and whether it was added or removed
                      Row(
                        children: [
                          Text(
                            entry.itemName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            actionText,
                            style: TextStyle(color: actionColour, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Quantity, price and total cost
                      Text('Qty: ${entry.itemQuantity.toInt()}  •  ${_priceText(entry)}  •  ${_totalText(entry)}'),
                      // Storage zone and expiry date
                      Text('${_zoneName(entry)}  •  Expires: ${_formatDate(entry.expiryDate)}'),
                      const SizedBox(height: 4),
                      // When the item was added or removed
                      Text(
                        '$actionText on ${_formatDateTime(entry.dateAdded)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _confirmReAdd(entry),
                      child: const Text('Re-add'),
                    ),
                    TextButton(
                      onPressed: () => _addToShoppingList(entry),
                      child: const Text('To list'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}