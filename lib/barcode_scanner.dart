import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';

//***** BARCODE SCANNER PROTOTYPE - START *****
// standalone barcode scanning service. kept as its own class, so it's a clean, 
// asks for camera permission, takes a photo, scans it, hands back
// the barcode number or null.
class BarcodeScannerService {
  final BarcodeScanner _scanner = BarcodeScanner();

  Future<String?> scanBarcode(BuildContext context) async {
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
    return barcodes.first.rawValue ?? barcodes.first.displayValue;
  }

  // call this when done using the scanner (e.g. in a State's dispose())
  void close() {
    _scanner.close();
  }
}
//***** BARCODE SCANNER PROTOTYPE - END *****