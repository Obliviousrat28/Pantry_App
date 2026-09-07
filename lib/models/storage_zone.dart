enum StorageZone {
  FRIDGE,
  FREEZER,
  PANTRY,
}

extension StorageZoneExtension on StorageZone {
  String get displayName {
    switch (this) {
      case StorageZone.FRIDGE:
        return 'Fridge';
      case StorageZone.FREEZER:
        return 'Freezer';
      case StorageZone.PANTRY:
        return 'Pantry';
    }
  }
}