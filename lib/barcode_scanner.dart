import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

//***** BARCODE SCANNER PROTOTYPE - START *****

// holds what came back from a scan: the raw barcode number, and the
// product name if the lookup found one (null if not found)
class BarcodeScanResult {
  final String code;
  final String? productName;

  BarcodeScanResult({required this.code, this.productName});
}

// standalone barcode scanning service. kept as its own class so it's a
// clean, separate unit — asks for camera permission, takes a photo,
// scans it, then looks the number up against Open Food Facts to try
// to get an actual product name instead of just the raw digits.
class BarcodeScannerService {
  final BarcodeScanner _scanner = BarcodeScanner();

  Future<BarcodeScanResult?> scanBarcode(BuildContext context) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is needed to scan a barcode')),
        );
      }
      return null;
    }

    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null) return null; // user backed out of the camera

    final inputImage = InputImage.fromFilePath(photo.path);
    final barcodes = await _scanner.processImage(inputImage);

    if (barcodes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't find a barcode in that photo, try again")),
        );
      }
      return null;
    }

    // just grabbing the first barcode found in the photo
    final code = barcodes.first.rawValue ?? barcodes.first.displayValue;
    if (code == null) return null;

    // now try to look the code up against Open Food Facts
    final productName = await _lookupProductName(code);
    return BarcodeScanResult(code: code, productName: productName);
  }

  // looks a barcode up against Open Food Facts' free product database.
  // returns the product name if found, or null if not found / offline /
  // request failed for any reason — callers should fall back to
  // showing the raw barcode number when this returns null.
  Future<String?> _lookupProductName(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
        headers: {
          // Open Food Facts asks for a descriptive User-Agent on requests
          'User-Agent': 'MyPantryApp - Flutter - University Project',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      // status is 1 if Open Food Facts actually has this barcode on file
      if (data['status'] != 1) return null;

      final name = data['product']?['product_name'];
      if (name == null || name.toString().isEmpty) return null;

      return name.toString();
    } catch (e) {
      // network error, timeout, bad JSON, etc — just treat it as "not found"
      return null;
    }
  }

  // call this when done using the scanner (e.g. in a State's dispose())
  void close() {
    _scanner.close();
  }
}
//***** BARCODE SCANNER PROTOTYPE - END *****