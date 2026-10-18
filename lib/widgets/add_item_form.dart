import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/storage_zone.dart';
import '../services/barcode_scanner.dart';
import '../services/item_lookup_service.dart';

/// A form widget for adding or editing an inventory item, including fields for name, quantity, price, expiry date, and storage zone.
class AddItemForm extends StatefulWidget {
  final Function(InventoryItem) onAddItem;
  final InventoryItem? initialData;
  final String? initialName;

  final BarcodeScanSource? barcodeService;
  final ItemLookupService? itemLookup;

  /// Creates an instance of AddItemForm with the specified callback for adding an item, optional initial data, and optional initial name.
  const AddItemForm({
    super.key,
    required this.onAddItem,
    this.initialData,
    this.initialName,
    this.barcodeService,
    this.itemLookup,
  });

  /// Creates an instance of AddItemForm with the specified callback for adding an item, optional initial data, and optional initial name.
  @override
  State<AddItemForm> createState() => AddItemFormState();
}

/// The state class for AddItemForm, managing form field controllers, selected storage zone, expiry date, and barcode scanning.
class AddItemFormState extends State<AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController qtyController;
  late TextEditingController priceController;

  // The currently selected storage zone for the inventory item, defaulting to fridge.
  StorageZone _selectedZone = StorageZone.fridge;
  DateTime? _selectedDate; //item expiry
  DateTime _entryDate = DateTime.now(); //default to today when item is bought
  bool isPriceUnknown = false;
  String? _scannedBarcode;

  late final BarcodeScanSource _barcodeService;

  // Initializes the state of the AddItemForm, setting up text controllers with initial values if provided, and initializing other state variables.
  @override
  void initState() {
    super.initState();
    _barcodeService = widget.barcodeService ?? BarcodeScannerService();
    nameController = TextEditingController(
      text: widget.initialData?.itemName ?? widget.initialName ?? '',
    ); // Initialize nameController with initialData's itemName or initialName if provided, otherwise empty string
    qtyController = TextEditingController(
      text: widget.initialData != null
          ? widget.initialData!.itemQuantity.toInt().toString()
          : '',
    ); // Initialize qtyController with initialData's itemQuantity if provided, otherwise empty string
    priceController = TextEditingController(
      text: widget.initialData != null
          ? widget.initialData!.price.toString()
          : '',
    ); // Initialize priceController with initialData's price if provided, otherwise empty string
    _selectedZone = widget.initialData?.storageZone ?? StorageZone.fridge;
    _selectedDate = widget.initialData?.expiryDate ?? DateTime.now();
    _entryDate = widget.initialData?.entryDate ?? DateTime.now(); //keep item's original purchase date
    isPriceUnknown = widget.initialData?.priceUnknown ?? false;
    _scannedBarcode = widget.initialData?.barcode;
  }

  // Disposes of the text controllers and barcode service when the widget is removed from the widget tree to free up resources.
  @override
  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
    _barcodeService.close();
    super.dispose();
  }

  // Opens the barcode scanner and updates the scanned barcode and item name if a barcode is successfully scanned.
  Future<void> _scanBarcode() async {
    final code = await _barcodeService.scanBarcode(context);
    if (code == null || !mounted) return;
    final productName = await widget.itemLookup?.getItemName(code);
    if (!mounted) return;
    setState(() {
      _scannedBarcode = code;
      if (nameController.text.isEmpty) {
        nameController.text = productName ?? code;
      }
    });
  }

  // Validates the form and, if valid, creates a new InventoryItem with the provided data and invokes the onAddItem callback, then closes the dialog.
  void submit() {
    if (_formKey.currentState!.validate()) {
      final double parsedQty = double.parse(qtyController.text);
      final double parsedPrice = isPriceUnknown ? 0.0 : double.parse(priceController.text);
      //chosen day with current time of day so two items bought on the same day have different timestamps
      final now = DateTime.now();
      final entryDateTime = DateTime(
        _entryDate.year,
        _entryDate.month,
        _entryDate.day,
        now.hour,
        now.minute,
        now.second,
        now.millisecond,
      );

      // Create a new InventoryItem with the provided data
      final newItem = InventoryItem(
        itemId: widget.initialData?.itemId ?? DateTime.now().microsecondsSinceEpoch.toString(),
        userId: 'user_1',
        itemName: nameController.text,
        itemQuantity: parsedQty,
        price: parsedPrice,
        priceUnknown: isPriceUnknown,
        expiryDate: _selectedDate ?? DateTime.now(),
        storageZone: _selectedZone,
        barcode: _scannedBarcode,
        //editing still keeps the original data, 
        entryDate: widget.initialData?.entryDate ?? entryDateTime,
      );

      // Invoke the onAddItem callback with the new InventoryItem and close the dialog
      widget.onAddItem(newItem);
      Navigator.of(context).pop();
    }
  }

  // Builds the widget tree for the AddItemForm, including form fields for item name, quantity, price, storage zone selection, expiry date picker, and barcode scanning button.
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
          // TextFormField for item name input, with validation to ensure a name is provided.
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Item Name'),
            validator: (val) => val == null || val.isEmpty ? 'Enter an item name' : null,
          ),
          // TextFormField for item quantity input, with validation to ensure a valid number is provided.
          TextFormField(
            controller: qtyController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Enter a quantity';
              if (double.tryParse(val) == null) return 'Enter a valid number';
              return null;
            },// TextFormField for item price input, with validation to ensure a valid number is provided unless the price is marked as unknown.
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
            },// CheckboxListTile for indicating if the price is unknown, which disables the price input field when checked.
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
          // DropdownButtonFormField for selecting the storage zone of the item, with options populated from the StorageZone enum.
          DropdownButtonFormField<StorageZone>(
            initialValue: _selectedZone,
            decoration: const InputDecoration(
              labelText: 'Storage Zone',
              border: OutlineInputBorder(),
            ),
            // Populate the dropdown menu with storage zone options from the StorageZone enum.
            items: StorageZone.values.map((StorageZone zone) {
              return DropdownMenuItem<StorageZone>(
                value: zone,
                child: Text(zone.displayName),
              );
              // Map each StorageZone value to a DropdownMenuItem with the zone's display name.
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
            // Row for displaying the selected expiry date and a button to pick a new date, with the date picker limited to a specific range.
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedDate == null
                    ? 'No Date Chosen'
                    : 'Expiry: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                style: const TextStyle(fontWeight: FontWeight.w500),
                // Display the selected expiry date in a readable format, or indicate that no date has been chosen.
              ),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('Pick Date'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                  );// Show a date picker dialog for selecting the expiry date, with the initial date set to the currently selected date or today's date, and a range from 2025 to 2030.
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
           // Date bought picker. Only shown when adding a new item.
          if (widget.initialData == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bought: ${_entryDate.day}/${_entryDate.month}/${_entryDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.event, size: 18),
                  label: const Text('Pick Date'),
                  onPressed: () async {
                    // Only past dates and today are allowed.
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _entryDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _entryDate = picked;
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