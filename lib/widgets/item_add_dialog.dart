import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/storage_zone.dart';

class ItemAddDialog extends StatefulWidget {
  final Function(InventoryItem) onAddItem;
  final InventoryItem? initialData;

  const ItemAddDialog({
    super.key,
    required this.onAddItem,
    this.initialData,
  });

  @override
  State<ItemAddDialog> createState() => _ItemAddDialogState();
}

class _ItemAddDialogState extends State<ItemAddDialog> {
  late TextEditingController nameController;
  late TextEditingController qtyController;
  late TextEditingController priceController;
  late String selectedZone;
  DateTime? selectedDate;
  bool isPriceUnknown = false;

  final List<String> storageZones = ['Fridge', 'Pantry', 'Freezer'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.initialData?.itemName ?? '',
    );
    qtyController = TextEditingController(
      text: widget.initialData != null
          ? widget.initialData!.itemQuantity.toInt().toString()
          : '',
    );
    priceController = TextEditingController(
      text: widget.initialData != null
          ? widget.initialData!.price.toString()
          : '',
    );
    selectedZone = widget.initialData?.storageZone.displayName ?? 'Fridge';
    
    // Set default date to today so selectedDate is never null
    selectedDate = widget.initialData?.expiryDate ?? DateTime.now();
    isPriceUnknown = widget.initialData?.priceUnknown ?? false;
  }

  @override
  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialData == null ? 'Add New Item' : 'Edit Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceController,
              enabled: !isPriceUnknown,
              decoration: InputDecoration(
                labelText: isPriceUnknown ? 'Price: N/A' : 'Price',
              ),
              keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                Checkbox(
                  value: isPriceUnknown,
                  onChanged: (bool? value) {
                    setState(() {
                      isPriceUnknown = value ?? false;
                      if (isPriceUnknown) {
                        priceController.clear();
                      }
                    });
                  },
                ),
                const Text('Price Unknown'),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedZone,
              decoration: const InputDecoration(
                labelText: 'Storage Zone',
                border: OutlineInputBorder(),
              ),
              items: storageZones.map((String zone) {
                return DropdownMenuItem<String>(
                  value: zone,
                  child: Text(zone),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedZone = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // RESTORED DATE PICKER UI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate == null
                      ? 'No Date Chosen'
                      : 'Expiry: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Pick Date'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validation check
            if (nameController.text.isEmpty ||
                qtyController.text.isEmpty ||
                selectedDate == null) {
              print('>>> VALIDATION ERROR: Please fill all fields <<<');
              return;
            }

            final double parsedPrice = double.tryParse(priceController.text) ?? 0.0;
            final double parsedQty = double.tryParse(qtyController.text) ?? 0.0;

            final newItem = InventoryItem(
              itemId: widget.initialData?.itemId ?? DateTime.now().microsecondsSinceEpoch.toString(),
              userId: 'user_1',
              itemName: nameController.text,
              itemQuantity: parsedQty,
              price: isPriceUnknown ? 0.0 : parsedPrice,
              priceUnknown: isPriceUnknown,
              expiryDate: selectedDate!,
              storageZone: StorageZone.values.firstWhere(
                (z) => z.displayName == selectedZone,
                orElse: () => StorageZone.FRIDGE,
              ),
            );

            widget.onAddItem(newItem);
            Navigator.of(context).pop();
          },
          child: Text(widget.initialData == null ? 'Add Item' : 'Save Changes'),
        ),
      ],
    );
  }
}