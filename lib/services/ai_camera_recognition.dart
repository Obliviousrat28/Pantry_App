import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../widgets/add_item_widget.dart';

//***** AI CAMERA FEATURE - START *****
// StorageZone is defined further down under Add Item, but is used
// here too since RecognizedItem needs it to build an InventoryItem

// AIApiClient: abstract interface any AI provider can implement
abstract class AIApiClient {
  Future<dynamic> sendRequest(Object payload);
}

// VisionAPIClient:  implements AIApiClient using Google ML Kit's
// image labeling. swapping to a different AI provider later only
// means writing a new class that implements AIApiClient.
class VisionAPIClient implements AIApiClient {
  @override
  Future<dynamic> sendRequest(Object payload) async {
    final imagePath = payload as String;
    final inputImage = InputImage.fromFilePath(imagePath);
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.6),
    );
    final labels = await labeler.processImage(inputImage);
    await labeler.close();
    return labels; // List<ImageLabel>
  }
}

// RecognizedItem: one AI guess about what's in the photo
class RecognizedItem {
  final String suggestedName;
  final double confidenceScore;
  final int suggestedQuantity;

  RecognizedItem({
    required this.suggestedName,
    required this.confidenceScore,
    required this.suggestedQuantity,
  });

  InventoryItem convertToInventoryItem({
    String? userId,
    required StorageZone storageZone,
    DateTime? expiryDate,
    double? price,
  }) {
    return InventoryItem(
      itemId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      itemName: suggestedName,
      itemQuantity: suggestedQuantity.toDouble(),
      priceUnknown: price == null,
      itemPrice: price,
      expiryDate: expiryDate,
      storageZone: storageZone,
    );
  }
}

// CameraRecognition: takes a photo, runs it through an AIApiClient,
// returns a list of RecognizedItem guesses
class CameraRecognition {
  final AIApiClient aiClient;

  CameraRecognition({required this.aiClient});

  Future<File?> captureImage() async {
    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null) return null;
    return File(photo.path);
  }

  Future<List<RecognizedItem>> recognizeItems(File image) async {
    final response = await aiClient.sendRequest(image.path);
    final labels = response as List<ImageLabel>;
    return labels
        .map((label) => RecognizedItem(
              suggestedName: label.label,
              confidenceScore: label.confidence,
              suggestedQuantity: 1,
            ))
        .toList();
  }
}
//***** AI CAMERA FEATURE - END *****