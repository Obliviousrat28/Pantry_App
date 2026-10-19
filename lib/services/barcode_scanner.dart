import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// interface for anything that can scan a barcode, so the real scanner
// can be swapped for a fake one (for example in tests)
abstract class BarcodeScanSource {
  Future<String?> scanBarcode(BuildContext context);
  void close();
}

//***** BARCODE SCANNER PROTOTYPE - START *****

// standalone barcode scanning service. it handles the camera and reading
// the barcode digits from a photo. the barcode number is stored on the item
// as metadata (useful later for spotting duplicates). the product name comes
// from Gemini reading the photo, see GeminiVisionClient in
// ai_camera_recognition.dart
class BarcodeScannerService implements BarcodeScanSource {
  final BarcodeScanner _scanner = BarcodeScanner();

  // asks for camera permission and opens the camera. returns the photo
  // taken, or null if permission was denied or the user backed out
  Future<File?> capturePhoto(BuildContext context) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is needed to scan'),
          ),
        );
      }
      return null;
    }

    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null) return null; // user backed out of the camera
    return File(photo.path);
  }

  // runs just the barcode detection on an already taken photo. returns the
  // raw barcode number if the photo has one, or null if it does not
  Future<String?> scanBarcodeFromFile(File image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final barcodes = await _scanner.processImage(inputImage);
    if (barcodes.isEmpty) return null;

    // just grabbing the first barcode found in the photo
    return barcodes.first.rawValue ?? barcodes.first.displayValue;
  }

  // original all in one flow: take a photo, read the barcode, tell the user
  // if none was found. kept so the interface and anything using it still work
  @override
  Future<String?> scanBarcode(BuildContext context) async {
    final photo = await capturePhoto(context);
    if (photo == null) return null;

    final code = await scanBarcodeFromFile(photo);
    if (code == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't find a barcode in that photo, try again"),
        ),
      );
    }
    return code;
  }

  @override
  void close() {
    _scanner.close();
  }
}

//***** BARCODE SCANNER PROTOTYPE - END *****