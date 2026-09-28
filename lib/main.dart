import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'add_item_widget.dart';
import 'ai_camera_recognition.dart';
import 'barcode_scanner.dart';
import 'meal_log_widget.dart';
import 'api_keys.dart';

// this is just my own test screen for trying out my four features
// (barcode scanner, AI camera identify, add item, log meal) before
// they get wired into the team's real navigation. not meant to be
// the final home screen of the app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Gemini.init(apiKey: geminiApiKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Pantry - Mustafa test screen',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<InventoryItem> _items = [];
  final List<MealLog> _mealsEatenOut = [];

  final BarcodeScannerService _barcodeService = BarcodeScannerService();

  // true when the little buttons are popped out, false when hidden
  bool _isFabExpanded = false;

  @override
  void dispose() {
    _barcodeService.close();
    super.dispose();
  }

  // opens the add item popup and adds the result to the list
  Future<void> _openAddItemDialog({String? initialName, String? initialBarcode}) async {
    final result = await showDialog<InventoryItem>(
      context: context,
      builder: (context) => AddItemDialog(
        initialName: initialName,
        initialBarcode: initialBarcode,
      ),
    );
    if (result == null) return;
    if (!mounted) return; // stops it crashing if i've already left the screen

    // checking if i already added this item before (same name + same zone)
    final existingIndex = _items.indexWhere(
      (item) =>
          item.itemName.toLowerCase() == result.itemName.toLowerCase() &&
          item.storageZone == result.storageZone,
    );

    if (existingIndex == -1) {
      setState(() {
        result.attachTo(_items);
        _items.add(result);
      });
      return;
    }

    // found a match, so ask if i want to merge or keep them separate
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item already exists'),
        content: Text(
          '${result.itemName} is already in your ${result.storageZone.label}. '
          'Merge the quantities, or add it as a separate entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('separate'),
            child: const Text('Add separately'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('merge'),
            child: const Text('Merge'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (choice == 'merge') {
      final existingItem = _items[existingIndex];
      setState(() {
        existingItem.edit(
          quantity: existingItem.itemQuantity + result.itemQuantity,
          expiry: result.expiryDate,
        );
      });
    } else if (choice == 'separate') {
      setState(() {
        result.attachTo(_items);
        _items.add(result);
      });
    }
  }

  // opens the log meal popup and adds the result to the list
  Future<void> _openLogMealDialog() async {
    setState(() {
      _isFabExpanded = false;
    });
    final result = await showDialog<MealLog>(
      context: context,
      builder: (context) => const LogMealDialog(),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _mealsEatenOut.add(result);
      });
    }
  }

  // single camera action: takes one photo, reads the barcode if there
  // is one (kept as metadata only), and always sends the photo to
  // Gemini to actually name the product. Gemini reads the real
  // packaging/label directly, which is more reliable than trusting an
  // incomplete barcode database
  Future<void> _scanOrIdentifyItem() async {
    setState(() {
      _isFabExpanded = false;
    });

    final photo = await _barcodeService.capturePhoto(context);
    if (photo == null) return; // permission denied or backed out
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // still read a barcode number if the photo has one, kept as
    // metadata on the item, no longer used to look up a name in an external database
    final barcode = await _barcodeService.scanBarcodeFromFile(photo);

    // Gemini reads the actual photo, the packaging, the label, or the
    // fruit itself, and names the product directly. this runs every
    // time, whether or not the photo happens to contain a barcode,
    // since reading the real label beats trusting an incomplete
    // barcode database
    final cameraRecognition = CameraRecognition(aiClient: GeminiVisionClient());
    final recognizedItems = await cameraRecognition.recognizeItems(photo);
    if (!mounted) return;
    Navigator.of(context).pop(); // close the spinner

    if (recognizedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't recognize the item, try again or add it manually")),
      );
      _openAddItemDialog(initialBarcode: barcode); // keep the barcode if we got one
      return;
    }

    final bestGuess = recognizedItems.first;
    _openAddItemDialog(initialName: bestGuess.suggestedName, initialBarcode: barcode);
  }

  // filters _items down to just one zone
  List<InventoryItem> _itemsFor(StorageZone zone) {
    return _items.where((item) => item.storageZone == zone).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mustafa test screen'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              StorageBox(zone: StorageZone.kitchen, color: Colors.blue, items: _itemsFor(StorageZone.kitchen)),
              const SizedBox(height: 12),
              StorageBox(zone: StorageZone.pantry, color: Colors.brown, items: _itemsFor(StorageZone.pantry)),
              const SizedBox(height: 12),
              StorageBox(zone: StorageZone.freezer, color: Colors.blueGrey, items: _itemsFor(StorageZone.freezer)),
              const SizedBox(height: 12),
              StorageBox(zone: StorageZone.fridge, color: Colors.indigoAccent, items: _itemsFor(StorageZone.fridge)),
              const SizedBox(height: 24),
              // just so i can see the meals i've logged while testing
              if (_mealsEatenOut.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Meals logged:', style: TextStyle(fontWeight: FontWeight.bold)),
                      for (final meal in _mealsEatenOut)
                        Text('${meal.mealName} - \$${meal.mealPrice} on ${meal.mealDate.toLocal()}'.split(' ').take(6).join(' ')),
                    ],
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            offset: _isFabExpanded ? Offset.zero : const Offset(0, 0.5),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isFabExpanded ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_isFabExpanded,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingActionButton(
                    heroTag: 'logMealButton',
                    mini: true,
                    backgroundColor: Colors.orange,
                    onPressed: _openLogMealDialog,
                    child: const Icon(Icons.restaurant, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            offset: _isFabExpanded ? Offset.zero : const Offset(0, 0.5),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isFabExpanded ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_isFabExpanded,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingActionButton(
                    heroTag: 'addItemButton',
                    mini: true,
                    backgroundColor: Colors.green,
                    onPressed: () {
                      setState(() {
                        _isFabExpanded = false;
                      });
                      _openAddItemDialog();
                    },
                    child: const Icon(Icons.kitchen, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          // this one purple button now does both jobs: reads the
          // barcode (if any) as metadata, then always sends the photo
          // to Gemini for the actual product name
          AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            offset: _isFabExpanded ? Offset.zero : const Offset(0, 0.5),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isFabExpanded ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_isFabExpanded,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingActionButton(
                    heroTag: 'scanOrIdentifyButton',
                    mini: true,
                    backgroundColor: Colors.purple,
                    onPressed: _scanOrIdentifyItem,
                    child: const Icon(Icons.camera_alt, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          FloatingActionButton(
            heroTag: 'mainAddButton',
            backgroundColor: Colors.blue,
            onPressed: () {
              setState(() {
                _isFabExpanded = !_isFabExpanded;
              });
            },
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _isFabExpanded ? 0.125 : 0,
              child: const Icon(Icons.add, size: 30, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// box for Kitchen, Pantry, Freezer, Fridge, expands to show the items
// saved in that zone so i can confirm stuff is landing in the right spot
class StorageBox extends StatelessWidget {
  final StorageZone zone;
  final Color color;
  final List<InventoryItem> items;

  const StorageBox({
    super.key,
    required this.zone,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          title: Text(
            zone.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          children: items.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No items yet',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                ]
              : items.map((item) {
                  return Container(
                    color: Colors.white,
                    child: ListTile(
                      title: Text(item.itemName),
                      subtitle: Text(
                        item.barcode != null ? 'Barcode: ${item.barcode}' : 'No barcode',
                      ),
                      trailing: Text('Qty: ${item.itemQuantity.toStringAsFixed(0)}'),
                    ),
                  );
                }).toList(),
        ),
      ),
    );
  }
}