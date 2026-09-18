import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/storage_zone.dart';
import '../services/barcode_scanner.dart';

class AddItemForm extends StatefulWidget {
  final Function(InventoryItem) onAddItem;
  final InventoryItem? initialData;
  final String? initialName;

  const AddItemForm({
    super.key,
    required this.onAddItem,
    this.initialData,
    this.initialName,
  });

  @override
  State<AddItemForm> createState() => AddItemFormState();
}

class AddItemFormState extends State<AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController qtyController;
  late TextEditingController priceController;

  StorageZone _selectedZone = StorageZone.fridge;
  DateTime? selectedDate;
  bool isPriceUnknown = false;
  String? _scannedBarcode;

  final BarcodeScannerService _barcodeService = BarcodeScannerService();

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
      text: widget.initialData != null
          ? widget.initialData!.price.toString()
          : '',
    );
    _selectedZone = widget.initialData?.storageZone ?? StorageZone.fridge;
    selectedDate = widget.initialData?.expiryDate ?? DateTime.now();
    isPriceUnknown = widget.initialData?.priceUnknown ?? false;
    _scannedBarcode = widget.initialData?.barcode;
  }

  @override
  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
    _barcodeService.close();
    super.dispose();
  }

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

  void submit() {
    if (_formKey.currentState!.validate()) {
      final double parsedQty = double.parse(qtyController.text);
      final double parsedPrice = isPriceUnknown ? 0.0 : double.parse(priceController.text);

      final newItem = InventoryItem(
        itemId: widget.initialData?.itemId ?? DateTime.now().microsecondsSinceEpoch.toString(),
        userId: 'user_1',
        itemName: nameController.text,
        itemQuantity: parsedQty,
        price: parsedPrice,
        priceUnknown: isPriceUnknown,
        expiryDate: selectedDate ?? DateTime.now(),
        storageZone: _selectedZone,
        barcode: _scannedBarcode,
      );

      widget.onAddItem(newItem);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Item Name'),
            validator: (val) => val == null || val.isEmpty ? 'Enter an item name' : null,
          ),
          TextFormField(
            controller: qtyController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Enter a quantity';
              if (double.tryParse(val) == null) return 'Enter a valid number';
              return null;
            },
          ),
          TextFormField(
            controller: priceController,
            enabled: !isPriceUnknown,
            decoration: InputDecoration(
              labelText: isPriceUnknown ? 'Price: N/A' : 'Price',
            ),
            keyboardType: TextInputType.number,
            validator: (val) {
              if (isPriceUnknown) return null; // Skip validation if price is unknown
              if (val == null || val.isEmpty) return 'Enter a price';
              if (double.tryParse(val) == null) return 'Enter a valid price';
              return null;
            },
          ),
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
          const SizedBox(height: 12),
          DropdownButtonFormField<StorageZone>(
            initialValue: _selectedZone,
            decoration: const InputDecoration(
              labelText: 'Storage Zone',
              border: OutlineInputBorder(),
            ),
            items: StorageZone.values.map((StorageZone zone) {
              return DropdownMenuItem<StorageZone>(
                value: zone,
                child: Text(zone.displayName),
              );
            }).toList(),
            onChanged: (StorageZone? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedZone = newValue;
                });
              }
            },
          ),
          const SizedBox(height: 16),
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
    );
  }
}