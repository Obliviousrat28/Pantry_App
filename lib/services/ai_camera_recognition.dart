import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import '../models/inventory_item.dart';
import '../models/storage_zone.dart';

//***** AI CAMERA FEATURE - START *****
// StorageZone is defined further down under Add Item, but is used
// here too since RecognizedItem needs it to build an InventoryItem

// AIApiClient — abstract interface any AI provider can implement.
// this is what lets the app swap between Google ML Kit (on-device,
// free, but only gives generic labels) and Gemini (cloud, needs an
// API key, but actually understands what it's looking at) without
// changing CameraRecognition or anything else that uses it.
//
// sendRequest now returns the converted List<RecognizedItem> directly
// instead of a raw provider-specific object, so CameraRecognition
// never needs to know or care which provider is behind the interface.
abstract class AIApiClient {
  Future<List<RecognizedItem>> sendRequest(Object payload);
}

// VISION API CLIENT — the original, free, on-device option using
// Google ML Kit's generic image labeler. Kept as a fallback / cheaper
// option, but it only knows broad categories (e.g. "Food") rather
// than specific items, since it's a general-purpose pretrained model.
class VisionAPIClient implements AIApiClient {
  @override
  Future<List<RecognizedItem>> sendRequest(Object payload) async {
    final imagePath = payload as String;
    final inputImage = InputImage.fromFilePath(imagePath);
    // lower threshold + more labels, then we look for the most
    // specific-sounding one instead of just taking the top guess,
    // since generic bucket words like "Food" often score highest
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.4),
    );
    final labels = await labeler.processImage(inputImage);
    await labeler.close();

    // generic category words to deprioritise if a more specific
    // label is also present in the results
    const genericWords = {
      'food',
      'produce',
      'plant',
      'natural foods',
      'ingredient',
      'fruit',
      'vegetable',
    };

    final specific = labels.where(
      (label) => !genericWords.contains(label.label.toLowerCase()),
    );
    final bestLabels = specific.isNotEmpty ? specific : labels;

    return bestLabels
        .map((label) => RecognizedItem(
              suggestedName: label.label,
              confidenceScore: label.confidence,
              suggestedQuantity: 1,
            ))
        .toList();
  }
}

// GEMINI VISION CLIENT — the new option. sends the photo to Google's
// Gemini model with a plain-English question, and gets back an actual
// answer about what's in the photo (e.g. "Apple", "Mountain Dew")
// instead of a generic label. requires an API key — see api_keys.dart.
class GeminiVisionClient implements AIApiClient {
  @override
  Future<List<RecognizedItem>> sendRequest(Object payload) async {
    final imagePath = payload as String;
    final Uint8List imageBytes = await File(imagePath).readAsBytes();

    try {
      // ignore: deprecated_member_use
      final response = await Gemini.instance.textAndImage(
        text:
            'Identify the single food or grocery item in this photo. '
            'Reply with ONLY the item name in Title Case, nothing else '
            '(e.g. "Apple", "Mountain Dew", "Green Valley Pure Milk"). '
            'If you cannot tell what it is, reply with exactly "Unknown".',
        images: [imageBytes],
      );

      // .output is a convenience getter that concatenates whatever text
      // came back, without us having to manually unwrap Part objects
      // (whose exact shape changed in this package version)
      final text = (response?.output ?? '').trim();

      if (text.isEmpty || text.toLowerCase() == 'unknown') {
        return [];
      }

      return [
        RecognizedItem(
          suggestedName: text,
          confidenceScore: 1.0, // Gemini doesn't give a numeric score
          suggestedQuantity: 1,
        ),
      ];
    } catch (e) {
      // it the same as "couldn't identify anything" rather than crash
      return [];
    }
  }
}

// RECOGNIZED ITEM — matches RecognizedItem in the UML diagram
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
      userId: userId ?? 'user_1',
      itemName: suggestedName,
      itemQuantity: suggestedQuantity.toDouble(),
      priceUnknown: price == null,
      price: price ?? 0.0,
      expiryDate: expiryDate ?? DateTime.now(),
      storageZone: storageZone,
    );
  }
}

// CAMERA RECOGNITION — matches CameraRecognition in the diagram.
// this is the class main.dart actually talks to; it doesn't know or
// care whether aiClient is ML Kit or Gemini underneath.
class CameraRecognition {
  final AIApiClient aiClient;

  CameraRecognition({required this.aiClient});

  Future<File?> captureImage() async {
    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null) return null;
    return File(photo.path);
  }

  Future<List<RecognizedItem>> recognizeItems(File image) async {
    return await aiClient.sendRequest(image.path);
  }
}
//***** AI CAMERA FEATURE - END *****