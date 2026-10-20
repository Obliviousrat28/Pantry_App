import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/inventory_item.dart';
import '../services/storage_service.dart';
import '../widgets/item_card.dart';
import '../widgets/item_add_dialog.dart';
import 'package:uuid/uuid.dart';

class ShoppingListScreen extends StatefulWidget {
  final Function(InventoryItem) onAddItem;

  const ShoppingListScreen({super.key, required this.onAddItem});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final StorageService _storageService = StorageService();
  List<InventoryItem> _shoppingItems = [];
  bool _isLoading = true;
  
  //loads the data from Firestore when the screen is initialized
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
    builder: (ctx) => ItemAddDialog(
      onAddItem: (newItem) async {
        setState(() {
          _shoppingItems.add(newItem);
        });
        await _storageService.saveShoppingItem(newItem);
      },
    ),
  );
}

void _openEditItemDialog(InventoryItem item) {
  showDialog(
    context: context,
    builder: (ctx) => ItemAddDialog(
      initialData: item,
      onAddItem: (updatedItem) async {
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

    // Show SnackBar with Undo option
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

    // Check and request location permissions 
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
    
    // Handle permanently denied permissions
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    // Get current position and open Google Maps with nearby supermarkets
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Construct the Google Maps URL for nearby supermarkets
    final googleMapsUrl = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': 'supermarket near ${position.latitude},${position.longitude}',
    });

    // Launch the URL in an external application
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

  Future<void> _markAsBought(InventoryItem item) async {
    DateTime? expiry;

    if (item.expiryDate.isAfter(DateTime.now())) {
      // Came from history: use the stored expiry
      expiry = item.expiryDate;
    } else {
      // Manual item (or shelf life already passed): ask the user
      expiry = await showDatePicker(
        context: context,
        helpText: 'When does ${item.itemName} expire?',
        initialDate: DateTime.now().add(const Duration(days: 7)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      );
    }

    if (!mounted) return;

    if (expiry == null) {
      // Cancelled: put the checkbox back
      setState(() => item.isChecked = false);
      return;
    }

    final inventoryItem = InventoryItem(
      itemId: const Uuid().v4(),
      userId: item.userId,
      itemName: item.itemName,
      itemQuantity: item.itemQuantity,
      price: item.price,
      priceUnknown: item.priceUnknown,
      expiryDate: expiry,
      storageZone: item.storageZone,
    );

    widget.onAddItem(inventoryItem);

    setState(() {
      _shoppingItems.removeWhere((e) => e.itemId == item.itemId);
    });
    await _storageService.deleteShoppingItem(item.itemId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.itemName} moved to inventory')),
    );
  }

  // Build the Shopping List Screen UI
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shopping List')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Build the main scaffold for the Shopping List Screen
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
                // Wrap each item in a Dismissible widget to allow swipe-to-delete functionality
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
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Checkbox(
                          value: currentItem.isChecked,
                          onChanged: (v) {
                            final checked = v ?? false;
                            setState(() => currentItem.isChecked = checked);
                            if (checked) _markAsBought(currentItem);
                          },
                        ),
                      ),
                      Expanded(
                        child: ItemCard(
                          item: currentItem,
                          showPrice: true,
                          onEdit: () => _openEditItemDialog(currentItem),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      // Floating action button to add new items to the shopping list
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemDialog,
        tooltip: 'Add to Shopping List',
        child: const Icon(Icons.add),
      ),
    );
  }
}