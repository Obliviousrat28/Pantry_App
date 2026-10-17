// lib/services/open_food_facts_lookup.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'item_lookup_service.dart';

/// Looks up a product name from a barcode using the free Open Food Facts API.
/// Returns null if the product isn't found or the request fails, so the form
/// falls back to showing the barcode number.
class OpenFoodFactsLookup implements ItemLookupService {
  @override
  Future<String?> getItemName(String barcode) async {
    try {
      final uri = Uri.https(
        'world.openfoodfacts.org',
        '/api/v2/product/$barcode.json',
        {'fields': 'product_name'},
      );
      final response = await http
          .get(uri, headers: {'User-Agent': 'MyPantry/0.1 (student project)'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 1) return null;

      final name = (data['product']?['product_name'] as String?)?.trim();
      return (name == null || name.isEmpty) ? null : name;
    } catch (_) {
      return null; // no internet, timeout, bad response, etc.
    }
  }
}