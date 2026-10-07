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
    return '\$${entry.price.toStringAsFixed(2)}';
  }

  Future<void> _reAddItem(HistoryEntry entry) async
  {
    DateTime now = DateTime.now();
    DateTime? expiry = await showDatePicker(
      context: context,
      helpText: 'Expiry date for ${entry.itemName}',
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (expiry == null || !mounted)
    {
      return;
    }

    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'dev_test_user';

    InventoryItem item = InventoryItem(
      itemId: const Uuid().v4(),
      userId: userId,
      itemName: entry.itemName,
      itemQuantity: entry.itemQuantity,
      price: entry.price,
      priceUnknown: entry.priceUnknown,
      expiryDate: expiry,
      storageZone: entry.storageZone,
    );

    widget.onAddItem(item);

    setState(()
    {
      _history.insert(0, HistoryEntry(
        itemName: entry.itemName,
        itemQuantity: entry.itemQuantity,
        price: entry.price,
        priceUnknown: entry.priceUnknown,
        storageZone: entry.storageZone,
        dateAdded: DateTime.now(),
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.itemName} added to your inventory')),
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
            'No items in your history yet.\nItems you add will appear here.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _history.length,
      itemBuilder: (context, index)
      {
        HistoryEntry entry = _history[index];
        return Card(
          child: ListTile(
            title: Text(
              entry.itemName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Qty: ${entry.itemQuantity.toInt()}  •  ${_priceText(entry)}  •  ${_zoneName(entry)}\n'
              'Added: ${_formatDate(entry.dateAdded)}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.add_circle_outline),
            onTap: () => _reAddItem(entry),
          ),
        );
      },
    );
  }
}