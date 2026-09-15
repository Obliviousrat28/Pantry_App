// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_zone.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StorageZoneAdapter extends TypeAdapter<StorageZone> {
  @override
  final int typeId = 2;

  @override
  StorageZone read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StorageZone.pantry;
      case 1:
        return StorageZone.fridge;
      case 2:
        return StorageZone.freezer;
      default:
        return StorageZone.pantry;
    }
  }

  @override
  void write(BinaryWriter writer, StorageZone obj) {
    switch (obj) {
      case StorageZone.pantry:
        writer.writeByte(0);
        break;
      case StorageZone.fridge:
        writer.writeByte(1);
        break;
      case StorageZone.freezer:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageZoneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
