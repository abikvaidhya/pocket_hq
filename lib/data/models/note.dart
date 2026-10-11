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

  /// true = voice note (no body editor)
  @HiveField(7)
  late bool isVoice;

  /// Absolute path to local audio file
  @HiveField(8)
  String? audioPath;

  /// Duration in milliseconds
  @HiveField(9)
  int? durationMs;

  /// Normalized peaks 0..1 for waveform UI (optional)
  @HiveField(10)
  List<double>? waveformPeaks;

  Note({
    String? id,
    this.title = '',
    this.body = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
    this.colorValue,
    this.isVoice = false,
    this.audioPath,
    this.durationMs,
    this.waveformPeaks,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
  }

  bool get isEmpty {
    if (isVoice) return audioPath == null || audioPath!.isEmpty;
    return title.trim().isEmpty && body.trim().isEmpty;
  }

  String get preview {
    final t = title.trim();
    if (t.isNotEmpty) return t;
    if (isVoice) return 'Voice note';
    final b = body.trim();
    if (b.isEmpty) return 'Empty note';
    return b.length > 80 ? '${b.substring(0, 80)}…' : b;
  }

  String get snippet {
    if (isVoice) {
      if (durationMs == null) return 'Voice note';
      return formattedDuration;
    }
    final b = body.trim();
    if (b.isEmpty) return '';
    return b.length > 120 ? '${b.substring(0, 120)}…' : b;
  }

  String get formattedDuration {
    final ms = durationMs ?? 0;
    final totalSec = ms ~/ 1000;
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
