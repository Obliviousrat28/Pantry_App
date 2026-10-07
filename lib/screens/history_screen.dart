import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/history_entry.dart';
import '../models/inventory_item.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget
{
  final Function(InventoryItem) onAddItem;

  const HistoryScreen({super.key, required this.onAddItem});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

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

  String _formatDate(DateTime date)
  {
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _zoneName(HistoryEntry entry)
  {
    String name = entry.storageZone.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  String _priceText(HistoryEntry entry)
  {
    if (entry.priceUnknown)
    {
      return 'Price unknown';
    }
    return '\$${entry.price.toStringAsFixed(2)} each';
  }

  String _totalText(HistoryEntry entry)
  {
    if (entry.priceUnknown)
    {
      return 'Total unknown';
    }
    double total = entry.price * entry.itemQuantity;
    return 'Total \$${total.toStringAsFixed(2)}';
  }

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

    HistoryEntry updated = HistoryEntry(
      itemName: entry.itemName,
      itemQuantity: entry.itemQuantity,
      price: entry.price,
      priceUnknown: entry.priceUnknown,
      storageZone: entry.storageZone,
      expiryDate: entry.expiryDate,
      dateAdded: DateTime.now(),
    );

    setState(()
    {
      _history.remove(entry);
      _history.insert(0, updated);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.itemName} added back to your inventory')),
    );
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: _buildBody(),
    );
  }

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
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.itemName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text('Qty: ${entry.itemQuantity.toInt()}  •  ${_priceText(entry)}  •  ${_totalText(entry)}'),
                      Text('${_zoneName(entry)}  •  Expires: ${_formatDate(entry.expiryDate)}'),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _confirmReAdd(entry),
                  child: const Text('Re-add'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}