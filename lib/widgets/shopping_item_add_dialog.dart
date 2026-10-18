import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/storage_zone.dart';
// import '../services/barcode_scanner.dart'; // Commented out barcode scanner service

class ShoppingItemAddDialog extends StatefulWidget {
  final Function(InventoryItem) onAddItem;
  final InventoryItem? initialData;
  final String? initialName;

  const ShoppingItemAddDialog({
    super.key,
    required this.onAddItem,
    this.initialData,
    this.initialName,
  });

  @override
  State<ShoppingItemAddDialog> createState() => _ShoppingItemAddDialogState();
}

class _ShoppingItemAddDialogState extends State<ShoppingItemAddDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController qtyController;
  late TextEditingController priceController;

  bool isPriceUnknown = false;
  // String? _scannedBarcode; // Commented out barcode variable

  // final BarcodeScannerService _barcodeService = BarcodeScannerService(); // Commented out barcode service instance

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.initialData?.itemName ?? widget.initialName ?? '',
    );
    qtyController = TextEditingController(
      text: widget.initialData != null
          ? widget.initialData!.itemQuantity.toInt().toString()
          : '',
    );
    priceController = TextEditingController(
      text: widget.initialData != null && !widget.initialData!.priceUnknown
          ? widget.initialData!.price.toString()
          : '',
    );
    isPriceUnknown = widget.initialData?.priceUnknown ?? false;
    // _scannedBarcode = widget.initialData?.barcode;
  }

  @override
  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
    // _barcodeService.close(); // Commented out barcode service disposal
    super.dispose();
  }

  /*
  // Commented out barcode scanning method
  Future<void> _scanBarcode() async {
    final code = await _barcodeService.scanBarcode(context);
    if (code == null || !mounted) return;
    setState(() {
      _scannedBarcode = code;
      if (nameController.text.isEmpty) {
        nameController.text = code;
      }
    });
  }
  */

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final double parsedPrice = double.tryParse(priceController.text) ?? 0.0;
      final double parsedQty = double.tryParse(qtyController.text) ?? 1.0;

      final newItem = InventoryItem(
        itemId: widget.initialData?.itemId ?? DateTime.now().microsecondsSinceEpoch.toString(),
        userId: widget.initialData?.userId ?? 'user_1',
        itemName: nameController.text.trim(),
        itemQuantity: parsedQty,
        price: isPriceUnknown ? 0.0 : parsedPrice,
        priceUnknown: isPriceUnknown,
        expiryDate: DateTime.now(), // Default fallback date
        storageZone: StorageZone.pantry, // Default fallback zone
        // barcode: _scannedBarcode,
      );

      widget.onAddItem(newItem);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(20),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /*
              // Commented out Scan Barcode button
              OutlinedButton.icon(
                onPressed: _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(
                  _scannedBarcode == null
                      ? 'Scan Barcode'
                      : 'Scanned: $_scannedBarcode',
                ),
              ),
              const SizedBox(height: 12),
              */

              // Item Name Field
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter an item name' : null,
              ),

              // Quantity Field
              TextFormField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter a quantity';
                  if (double.tryParse(val) == null) return 'Enter a valid number';
                  return null;
                },
              ),

              // Price Field
              TextFormField(
                controller: priceController,
                enabled: !isPriceUnknown,
                decoration: InputDecoration(
                  labelText: isPriceUnknown ? 'Price: N/A' : 'Price',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (isPriceUnknown) return null;
                  if (val == null || val.trim().isEmpty) return 'Enter a price';
                  if (double.tryParse(val) == null) return 'Enter a valid price';
                  return null;
                },
              ),

              // Price Unknown Checkbox
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("I don't know the price"),
                value: isPriceUnknown,
                onChanged: (bool? value) {
                  setState(() {
                    isPriceUnknown = value ?? false;
                    if (isPriceUnknown) priceController.clear();
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add Item'),
        ),
      ],
    );
  }
}