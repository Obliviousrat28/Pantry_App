// lib/services/item_lookup_service.dart

/// Looks up a product name from a barcode serial number.
/// A real implementation (e.g. Open Food Facts API) can be added later;
/// the add item form only depends on this interface.
abstract class ItemLookupService {
  /// Returns the product name for [barcode], or null if it isn't found.
  Future<String?> getItemName(String barcode);
}
