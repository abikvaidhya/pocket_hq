part of 'reminder.dart';

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 7;

  @override
  Reminder read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return Reminder(
      id: fields[0] as String,
      label: fields[1] as String? ?? 'Reminder',
      triggerAt: fields[2] as DateTime,
      completed: fields[3] as bool? ?? false,
      createdAt: fields[4] as DateTime? ?? DateTime.now(),
      kind: fields[5] as String? ?? 'reminder',
      sourceText: fields[6] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.triggerAt)
      ..writeByte(3)
      ..write(obj.completed)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.kind)
      ..writeByte(6)
      ..write(obj.sourceText);
  }
}
