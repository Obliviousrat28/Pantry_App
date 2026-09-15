// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealLogAdapter extends TypeAdapter<MealLog> {
  @override
  final int typeId = 1;

  @override
  MealLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealLog(
      mealName: fields[0] as String,
      mealPrice: fields[1] as String,
      mealDate: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MealLog obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.mealName)
      ..writeByte(1)
      ..write(obj.mealPrice)
      ..writeByte(2)
      ..write(obj.mealDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
