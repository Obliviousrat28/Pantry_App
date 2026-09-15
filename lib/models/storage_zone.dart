import 'package:hive/hive.dart';

part 'storage_zone.g.dart';

@HiveType(typeId: 2)
enum StorageZone {
  @HiveField(0)
  pantry,

  @HiveField(1)
  fridge,

  @HiveField(2)
  freezer,
}

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