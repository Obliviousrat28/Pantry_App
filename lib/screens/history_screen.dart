import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/history_entry.dart';
import '../models/inventory_item.dart';
import '../services/storage_service.dart';

// The HistoryScreen displays a list of history entries, allowing users to re-add items to their inventory or add them to their shopping list.
class HistoryScreen extends StatefulWidget
{
  final Function(InventoryItem) onAddItem;

  const HistoryScreen({super.key, required this.onAddItem});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

// The state class for the HistoryScreen, managing the list of history entries and their interactions.
class _HistoryScreenState extends State<HistoryScreen>
{
  final StorageService _storageService = StorageService();
  List<HistoryEntry> _history = [];
  bool _isLoading = true;

  @override
  void initState()
  {
    super.initState();
    _loadHistory();
  }

  // Loads the history entries from the storage service and updates the state accordingly, handling any errors that may occur during the loading process.
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

  // Formats a DateTime object into a string with the format "dd/MM/yyyy".
  String _formatDate(DateTime date)
  {
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  // Formats a DateTime object into a string with the format "dd/MM/yyyy at hh:mm AM/PM".
  String _formatDateTime(DateTime date)
  {
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

  // Returns the name of the storage zone for a history entry, capitalizing the first letter.
  String _zoneName(HistoryEntry entry)
  {
    String name = entry.storageZone.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  // Returns a formatted string representing the price of a history entry, indicating if the price is unknown or displaying the price per unit.
  String _priceText(HistoryEntry entry)
  {
    if (entry.priceUnknown)
    {
      return 'Price unknown';
    }
    return '\$${entry.price.toStringAsFixed(2)} each';
  }

  // Calculates the total price for a history entry, returning a formatted string or indicating if the price is unknown.
  String _totalText(HistoryEntry entry)
  {
    if (entry.priceUnknown)
    {
      return 'Total unknown';
    }
    double total = entry.price * entry.itemQuantity;
    return 'Total \$${total.toStringAsFixed(2)}';
  }

  // Confirms with the user before re-adding an item from the history back to the inventory, displaying relevant details and options to cancel or proceed.
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

    if (confirmed != true || !mounted)
    {
      return;
    }

    _reAddItem(entry);
  }

  // Re-adds the item from the history entry back to the inventory and updates the history with a new entry indicating the addition.
  void _reAddItem(HistoryEntry entry)
  {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'dev_test_user';

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

    widget.onAddItem(item);

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

  // Adds the item from the history entry to the shopping list, calculating a new expiry date based on the previous shelf life.
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

  // Builds the main UI of the history screen, displaying a loading indicator, a message for empty history, or a list of history entries with options to re-add or add to shopping list.
  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      body: _buildBody(),
    );
  }

  // Constructs the body of the history screen, handling loading state, empty history, and displaying a list of history entries with relevant details and actions.
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

    // Display the list of history entries
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _history.length,
      itemBuilder: (context, index)
      {
        HistoryEntry entry = _history[index];
        bool wasRemoved = entry.action == 'removed';

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
                      Text('Qty: ${entry.itemQuantity.toInt()}  •  ${_priceText(entry)}  •  ${_totalText(entry)}'),
                      Text('${_zoneName(entry)}  •  Expires: ${_formatDate(entry.expiryDate)}'),
                      const SizedBox(height: 4),
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