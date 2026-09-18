import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'barcode_scanner.dart';

//***** ADD ITEM WIDGET - START *****
// StorageZone enum: matches the diagram's StorageZone.
// the diagram only lists FRIDGE, FREEZER, PANTRY
// kept kitchen here since the app needs it
enum StorageZone { fridge, freezer, pantry, kitchen }

extension StorageZoneLabel on StorageZone {
  String get label {
    switch (this) {
      case StorageZone.fridge:
        return 'Fridge';
      case StorageZone.freezer:
        return 'Freezer';
      case StorageZone.pantry:
        return 'Pantry';
      case StorageZone.kitchen:
        return 'Kitchen';
    }
  }
}

// InventoryItem: matches the diagram's InventoryItem class.
// the diagram doesn't show a price field, only priceUnknown
// bool: itemPrice is added here as an extra field beyond the
// diagram, since something has to hold the actual value when known.
class InventoryItem {
  final String itemId;
  final String? userId; // null for now since no login system exists yet
  String itemName;
  double itemQuantity;
  bool priceUnknown;
  double? itemPrice;
  DateTime? expiryDate;
  StorageZone storageZone;
  final String? barcode;

  // reference to whichever list this item currently lives in, so
  // delete() can remove it from there directly
  List<InventoryItem>? _sourceList;

  InventoryItem({
    required this.itemId,
    this.userId,
    required this.itemName,
    required this.itemQuantity,
    required this.priceUnknown,
    this.itemPrice,
    required this.expiryDate,
    required this.storageZone,
    this.barcode,
  });

  void attachTo(List<InventoryItem> list) {
    _sourceList = list;
  }

  void edit({
    String? name,
    double? quantity,
    double? price,
    DateTime? expiry,
    StorageZone? zone,
  }) {
    if (name != null) itemName = name;
    if (quantity != null) itemQuantity = quantity;
    if (price != null) {
      itemPrice = price;
      priceUnknown = false;
    }
    if (expiry != null) expiryDate = expiry;
    if (zone != null) storageZone = zone;
  }

  void delete() {
    _sourceList?.remove(this);
  }

  bool isExpired() {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  bool isExpiringSoon() {
    if (expiryDate == null) return false;
    final daysLeft = expiryDate!.difference(DateTime.now()).inDays;
    return daysLeft >= 0 && daysLeft <= 3;
  }
}

// the form that pops up when i hit add item
class AddItemDialog extends StatefulWidget {
  final String? initialName; // pre-fills the name field, e.g. from AI identify

  const AddItemDialog({super.key, this.initialName});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  StorageZone? _selectedZone;
  DateTime? _expiryDate;
  bool _priceUnknown = false;
  String? _scannedBarcode;

  // uses the BarcodeScannerService defined above instead of scanning
  // logic living directly in this class
  final BarcodeScannerService _barcodeService = BarcodeScannerService();

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _barcodeService.close();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final result = await _barcodeService.scanBarcode(context);
    if (result == null) return;
    if (!mounted) return;
    setState(() {
      _scannedBarcode = result.code;
      if (_nameController.text.isEmpty) {
        _nameController.text = result.productName ?? result.code;
      }
    });
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newItem = InventoryItem(
        itemId: DateTime.now().millisecondsSinceEpoch.toString(),
        itemName: _nameController.text,
        itemQuantity: double.tryParse(_quantityController.text) ?? 0,
        priceUnknown: _priceUnknown,
        itemPrice: _priceUnknown ? null : double.tryParse(_priceController.text),
        expiryDate: _expiryDate,
        storageZone: _selectedZone!,
        barcode: _scannedBarcode,
      );
      Navigator.of(context).pop(newItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter an item name' : null,
              ),
              DropdownButtonFormField<StorageZone>(
                initialValue: _selectedZone,
                decoration: const InputDecoration(labelText: 'Storage zone'),
                items: StorageZone.values
                    .map((zone) => DropdownMenuItem(value: zone, child: Text(zone.label)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedZone = value;
                  });
                },
                validator: (value) => value == null ? 'Select a zone' : null,
              ),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a quantity' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _expiryDate == null
                          ? 'No expiry date selected'
                          : 'Expiry: ${_expiryDate!.toLocal()}'.split(' ')[0],
                    ),
                  ),
                  TextButton(
                    onPressed: _pickExpiryDate,
                    child: const Text('Pick date'),
                  ),
                ],
              ),
              TextFormField(
                controller: _priceController,
                enabled: !_priceUnknown,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              CheckboxListTile(
                title: const Text("I don't know the price"),
                value: _priceUnknown,
                onChanged: (value) {
                  setState(() {
                    _priceUnknown = value ?? false;
                    if (_priceUnknown) _priceController.clear();
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
//***** ADD ITEM WIDGET - END *****