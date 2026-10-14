import 'package:flutter/material.dart';
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
  final List<InventoryItem> _shoppingItems = [];
  bool _isLoading = true;
 
  @override
  void initState() {
    super.initState();
    _loadItems();
  }
 
  // LOAD from Firestore
  Future<void> _loadItems() async {
    try {
      final items = await _storageService.loadShoppingItems();
      if (!mounted) return;
      setState(() {
        _shoppingItems
          ..clear()
          ..addAll(items);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load shopping list: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }
 
  // SAVE helper: surfaces Firestore errors instead of failing silently
  Future<void> _save(InventoryItem item) async {
    try {
      await _storageService.saveShoppingItem(item);
    } catch (e) {
      debugPrint('Failed to save ${item.itemName}: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save ${item.itemName}')),
      );
    }
  }
 
  // ADD
  void _openAddItemDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ShoppingItemAddDialog(
        onAddItem: (newItem) {
          setState(() => _shoppingItems.add(newItem));
          _save(newItem);
        },
      ),
    );
  }
 
  // EDIT
  void _openEditItemDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => ShoppingItemAddDialog(
        initialData: item,
        onAddItem: (updatedItem) {
          setState(() {
            item.edit(
              name: updatedItem.itemName,
              quantity: updatedItem.itemQuantity,
              price: updatedItem.price,
              priceUnknown: updatedItem.priceUnknown,
            );
          });
          _save(item);
        },
      ),
    );
  }
 
  // CHECK / UNCHECK
  void _toggleChecked(InventoryItem item, bool value) {
    setState(() => item.isChecked = value);
    _save(item);
  }
 
  // DELETE
  void _deleteItem(InventoryItem item) async {
    setState(() {
      _shoppingItems.removeWhere((e) => e.itemId == item.itemId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.itemName} removed from shopping list')),
    );
    try {
      await _storageService.deleteShoppingItem(item.itemId);
    } catch (e) {
      debugPrint('Failed to delete ${item.itemName}: $e');
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shoppingItems.isEmpty
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
                    final item = _shoppingItems[index];
                    return Dismissible(
                      key: ValueKey(item.itemId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteItem(item),
                      child: ShoppingItemCard(
                        item: item,
                        onEdit: () => _openEditItemDialog(item),
                        onCheckedChanged: (v) => _toggleChecked(item, v),
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
