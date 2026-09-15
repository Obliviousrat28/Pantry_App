part of 'inventory_item.dart';


class InventoryItemAdapter extends TypeAdapter<InventoryItem> {
  @override
  final int typeId = 0;

  @override
  InventoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InventoryItem(
      itemId: fields[0] as String,
      userId: fields[1] as String,
      itemName: fields[2] as String,
      itemQuantity: fields[3] as double,
      price: fields[4] as double,
      priceUnknown: fields[5] as bool,
      expiryDate: fields[6] as DateTime,
      storageZone: fields[7] as StorageZone,
      barcode: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.itemId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.itemName)
      ..writeByte(3)
      ..write(obj.itemQuantity)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.priceUnknown)
      ..writeByte(6)
      ..write(obj.expiryDate)
      ..writeByte(7)
      ..write(obj.storageZone)
      ..writeByte(8)
      ..write(obj.barcode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
