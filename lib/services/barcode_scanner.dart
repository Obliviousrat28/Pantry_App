import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';

//***** BARCODE SCANNER PROTOTYPE - START *****

// standalone barcode scanning service. this now only handles the
// camera + reading the barcode digits themselves — it no longer looks
// the number up against an external database, since Open Food Facts
// kept missing NZ products (it's a crowdsourced, mostly EU-focused
// database). the barcode number is still captured and stored on the
// item (useful later for spotting duplicates), but the actual product
// NAME now comes from Gemini reading the photo directly — see
// ai_camera_recognition.dart's GeminiVisionClient.
class BarcodeScannerService {
  final BarcodeScanner _scanner = BarcodeScanner();

  // asks for camera permission and opens the camera. returns the photo
  // taken, or null if permission was denied or the user backed out.
  Future<File?> capturePhoto(BuildContext context) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is needed')),
        );
      }
      return null;
    }

    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null) return null; // user backed out of the camera
    return File(photo.path);
  }

  // runs just the barcode detection on an already-taken photo. returns
  // the raw barcode number if the photo has one, or null if it doesn't.
  // this is now used only to store the barcode as metadata on the
  // item — not to look up its name.
  Future<String?> scanBarcodeFromFile(File image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final barcodes = await _scanner.processImage(inputImage);
    if (barcodes.isEmpty) return null;
    return barcodes.first.rawValue ?? barcodes.first.displayValue;
  }

  // call this when done using the scanner (e.g. in a State's dispose())
  void close() {
    _scanner.close();
  }
}
//***** BARCODE SCANNER PROTOTYPE - END *****