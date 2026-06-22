// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalendarDataAdapter extends TypeAdapter<CalendarData> {
  @override
  final int typeId = 0;

  @override
  CalendarData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarData(
      monthDaysData: (fields[0] as Map).cast<String, dynamic>(),
      tithi: (fields[1] as Map).cast<String, dynamic>(),
      holidays: (fields[2] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, CalendarData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.monthDaysData)
      ..writeByte(1)
      ..write(obj.tithi)
      ..writeByte(2)
      ..write(obj.holidays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VersionInfoAdapter extends TypeAdapter<VersionInfo> {
  @override
  final int typeId = 1;

  @override
  VersionInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VersionInfo(version: fields[0] as String);
  }

  @override
  void write(BinaryWriter writer, VersionInfo obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.version);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VersionInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
