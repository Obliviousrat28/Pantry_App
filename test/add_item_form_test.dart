// test/add_item_form_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pantry/services/barcode_scanner.dart';
import 'package:my_pantry/services/item_lookup_service.dart';
import 'package:my_pantry/widgets/add_item_form.dart';

// ---------- Fakes (replace the real camera / ML Kit / product database) ----------

class FakeBarcodeScanner implements BarcodeScanSource {
  final String? result;
  int scanCalls = 0;

  FakeBarcodeScanner({this.result});

  @override
  Future<String?> scanBarcode(BuildContext context) async {
    scanCalls++; // proves the scanner/camera flow was started
    return result;
  }

  @override
  void close() {}
}

class FakeItemLookup implements ItemLookupService {
  final Map<String, String> products;

  FakeItemLookup(this.products);

  @override
  Future<String?> getItemName(String barcode) async => products[barcode];
}

// ---------- Helpers ----------

Widget buildForm({
  required FakeBarcodeScanner scanner,
  ItemLookupService? lookup,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: AddItemForm(
          onAddItem: (_) {},
          barcodeService: scanner,
          itemLookup: lookup,
        ),
      ),
    ),
  );
}

// The first TextFormField in the form is "Item Name".
String nameFieldText(WidgetTester tester) {
  final field = tester.widget<TextFormField>(find.byType(TextFormField).first);
  return field.controller!.text;
}

// ---------- Tests: one per acceptance test ----------

void main() {
  group('User Story: scan a barcode through the add item widget', () {
    testWidgets(
        'AT1: Given user is on add item widget, when they select scan barcode, '
        'then they are redirected to their camera', (tester) async {
      final scanner = FakeBarcodeScanner(result: '5449000000996');
      await tester.pumpWidget(buildForm(scanner: scanner));

      await tester.tap(find.text('Scan Barcode'));
      await tester.pumpAndSettle();

      expect(scanner.scanCalls, 1);
    });

    testWidgets(
        'AT2: Given user selected scan barcode, when they take a picture of a '
        'barcode, then the correct barcode serial number is scanned',
        (tester) async {
      final scanner = FakeBarcodeScanner(result: '5449000000996');
      await tester.pumpWidget(buildForm(scanner: scanner));

      await tester.tap(find.text('Scan Barcode'));
      await tester.pumpAndSettle();

      expect(find.text('Scanned: 5449000000996'), findsOneWidget);
    });

    testWidgets(
        'AT3: Given user has scanned a barcode, when the scan is submitted, '
        'then the item name is filled in', (tester) async {
      final scanner = FakeBarcodeScanner(result: '5449000000996');
      final lookup = FakeItemLookup({'5449000000996': 'Coca-Cola 330ml'});
      await tester.pumpWidget(buildForm(scanner: scanner, lookup: lookup));

      await tester.tap(find.text('Scan Barcode'));
      await tester.pumpAndSettle();

      expect(nameFieldText(tester), 'Coca-Cola 330ml');
    });
  });
}
