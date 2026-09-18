enum StorageZone { fridge, freezer, pantry }

// Extension to provide a display name for each storage zone.
extension StorageZoneExtension on StorageZone {
  String get displayName {
    switch (this) {
      case StorageZone.fridge:
        return 'Fridge';
      case StorageZone.freezer:
        return 'Freezer';
      case StorageZone.pantry:
        return 'Pantry';
    }
  }
}