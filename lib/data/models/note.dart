import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'note.g.dart';

@HiveType(typeId: 1)
class Note extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String body;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late DateTime updatedAt;

  @HiveField(5)
  late bool isPinned;

  @HiveField(6)
  int? colorValue;

  Note({
    String? id,
    this.title = '',
    this.body = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
    this.colorValue,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
  }

  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;

  String get preview {
    final t = title.trim();
    if (t.isNotEmpty) return t;
    final b = body.trim();
    if (b.isEmpty) return 'Empty note';
    return b.length > 80 ? '${b.substring(0, 80)}…' : b;
  }

  String get snippet {
    final b = body.trim();
    if (b.isEmpty) return '';
    return b.length > 120 ? '${b.substring(0, 120)}…' : b;
  }
}
