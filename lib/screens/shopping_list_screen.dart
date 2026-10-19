import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/inventory_item.dart';
import '../services/storage_service.dart';
import '../widgets/shopping_item_add_dialog.dart';
import '../widgets/shopping_item_card.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final StorageService _storageService = StorageService();
  List<InventoryItem> _shoppingItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load items from Firestore on startup
  Future<void> _loadData() async {
    final items = await _storageService.loadShoppingItems();
    setState(() {
      _shoppingItems = items;
      _isLoading = false;
    });
  }

  // Open Dialog to Add Item & Save to Firestore
  void _openAddItemDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ShoppingItemAddDialog(
        onAddItem: (newItem) async {
          setState(() {
            _shoppingItems.add(newItem);
          });
          await _storageService.saveShoppingItem(newItem);
        },
      ),
    );
  }

  // Open Dialog to Edit Item & Update Firestore
  void _openEditItemDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => ShoppingItemAddDialog(
        initialData: item,
        onAddItem: (updatedItem) async {
          setState(() {
            item.edit(
              name: updatedItem.itemName,
              quantity: updatedItem.itemQuantity,
              price: updatedItem.price,
              priceUnknown: updatedItem.priceUnknown,
            );
          });
          await _storageService.saveShoppingItem(item);
        },
      ),
    );
  }

  // Delete Item & Remove from Firestore with Undo option
  void _deleteItem(InventoryItem item) async {
    final deletedIndex = _shoppingItems.indexWhere((e) => e.itemId == item.itemId);
    
    setState(() {
      _shoppingItems.removeWhere((e) => e.itemId == item.itemId);
    });
    await _storageService.deleteShoppingItem(item.itemId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.itemName} removed from shopping list'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            setState(() {
              _shoppingItems.insert(
                deletedIndex > _shoppingItems.length ? _shoppingItems.length : deletedIndex,
                item,
              );
            });
            await _storageService.saveShoppingItem(item);
          },
        ),
      ),
    );
  }

  // Handle Location Permission & Open Nearby Supermarkets on Google Maps
  Future<void> _showNearbySupermarkets() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final googleMapsUrl = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': 'supermarket near ${position.latitude},${position.longitude}',
    });

    try {
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps application.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open maps: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shopping List')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            tooltip: 'Find nearby supermarkets',
            onPressed: _showNearbySupermarkets,
          ),
        ],
      ),
      body: _shoppingItems.isEmpty
          ? const Center(
              child: Text(
                'Your shopping list is empty.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: _shoppingItems.length,
              itemBuilder: (context, index) {
                final currentItem = _shoppingItems[index];
                return Dismissible(
                  key: ValueKey(currentItem.itemId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteItem(currentItem),
                  child: ShoppingItemCard(
                    item: currentItem,
                    onEdit: () => _openEditItemDialog(currentItem),
                    onCheckedChanged: (bool checked) {
                      // update the item here, then save it
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemDialog,
        tooltip: 'Add to Shopping List',
        child: const Icon(Icons.add),
      ),
    );
  }
}