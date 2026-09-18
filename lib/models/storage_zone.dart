
enum StorageZone { fridge, freezer, pantry }



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