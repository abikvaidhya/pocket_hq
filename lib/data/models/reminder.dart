import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'reminder.g.dart';

/// reminder | timer | alarm
@HiveType(typeId: 7)
class Reminder extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String label;

  @HiveField(2)
  late DateTime triggerAt;

  @HiveField(3)
  late bool completed;

  @HiveField(4)
  late DateTime createdAt;

  /// reminder | timer | alarm
  @HiveField(5)
  late String kind;

  /// Original spoken/typed phrase (optional)
  @HiveField(6)
  late String sourceText;

  Reminder({
    String? id,
    required this.label,
    required this.triggerAt,
    this.completed = false,
    DateTime? createdAt,
    this.kind = 'reminder',
    this.sourceText = '',
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
  }

  bool get isPast => triggerAt.isBefore(DateTime.now());

  String get kindLabel {
    switch (kind) {
      case 'timer':
        return 'Timer';
      case 'alarm':
        return 'Alarm';
      default:
        return 'Reminder';
    }
  }

  int get notificationId => id.hashCode & 0x7fffffff;
}
