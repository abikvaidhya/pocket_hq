// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

class TripPointAdapter extends TypeAdapter<TripPoint> {
  @override
  final int typeId = 3;

  @override
  TripPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripPoint(
      lat: fields[0] as double,
      lng: fields[1] as double,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TripPoint obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.lat)
      ..writeByte(1)
      ..write(obj.lng)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TripAdapter extends TypeAdapter<Trip> {
  @override
  final int typeId = 4;

  @override
  Trip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Trip(
      id: fields[0] as String,
      title: fields[1] as String,
      startedAt: fields[2] as DateTime,
      endedAt: fields[3] as DateTime?,
      distanceMeters: fields[4] as double,
      startAddress: fields[5] as String?,
      endAddress: fields[6] as String?,
      route: (fields[7] as List?)?.cast<TripPoint>() ?? [],
      isActive: fields[8] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Trip obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.startedAt)
      ..writeByte(3)
      ..write(obj.endedAt)
      ..writeByte(4)
      ..write(obj.distanceMeters)
      ..writeByte(5)
      ..write(obj.startAddress)
      ..writeByte(6)
      ..write(obj.endAddress)
      ..writeByte(7)
      ..write(obj.route)
      ..writeByte(8)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
