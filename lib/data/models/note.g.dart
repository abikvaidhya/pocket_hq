// GENERATED CODE - DO NOT MODIFY BY HAND
// Manual adapter — supports older notes without voice fields.

part of 'note.dart';

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 1;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      title: fields[1] as String? ?? '',
      body: fields[2] as String? ?? '',
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      isPinned: fields[5] as bool? ?? false,
      colorValue: fields[6] as int?,
      isVoice: fields[7] as bool? ?? false,
      audioPath: fields[8] as String?,
      durationMs: fields[9] as int?,
      waveformPeaks: (fields[10] as List?)?.cast<double>(),
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.isPinned)
      ..writeByte(6)
      ..write(obj.colorValue)
      ..writeByte(7)
      ..write(obj.isVoice)
      ..writeByte(8)
      ..write(obj.audioPath)
      ..writeByte(9)
      ..write(obj.durationMs)
      ..writeByte(10)
      ..write(obj.waveformPeaks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
