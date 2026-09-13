import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String icon; // Iconsax name or emoji key

  @HiveField(3)
  late int colorValue; // Color.value

  @HiveField(4)
  late int currentStreak;

  @HiveField(5)
  late int bestStreak;

  @HiveField(6)
  late List<String> completedDates; // yyyy-MM-dd

  @HiveField(7)
  int? reminderHour;

  @HiveField(8)
  int? reminderMinute;

  @HiveField(9)
  late bool isActive;

  @HiveField(10)
  late DateTime createdAt;

  Habit({
    String? id,
    required this.title,
    this.icon = 'tick_circle',
    this.colorValue = 0xFF5B6CFF,
    this.currentStreak = 0,
    this.bestStreak = 0,
    List<String>? completedDates,
    this.reminderHour,
    this.reminderMinute,
    this.isActive = true,
    DateTime? createdAt,
  }) {
    this.id = id ?? const Uuid().v4();
    this.completedDates = completedDates ?? [];
    this.createdAt = createdAt ?? DateTime.now();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool isCompletedOn(DateTime date) {
    final key = _dateKey(date);
    return completedDates.contains(key);
  }

  bool get isCompletedToday => isCompletedOn(DateTime.now());

  /// Toggle completion for a given day and recalculate streaks.
  void toggleCompletion(DateTime date) {
    final key = _dateKey(date);
    if (completedDates.contains(key)) {
      completedDates.remove(key);
    } else {
      completedDates.add(key);
      completedDates.sort();
    }
    _recalculateStreaks();
  }

  void _recalculateStreaks() {
    if (completedDates.isEmpty) {
      currentStreak = 0;
      return;
    }

    // final sorted = completedDates.map(_parseKey).toList()..sort();
    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    // Current streak: consecutive days ending today or yesterday
    int streak = 0;
    DateTime cursor = today;

    // If today is not completed, start from yesterday
    if (!isCompletedOn(today)) {
      if (!isCompletedOn(yesterday)) {
        currentStreak = 0;
        _updateBest();
        return;
      }
      cursor = yesterday;
    }

    while (isCompletedOn(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    currentStreak = streak;
    _updateBest();
  }

  void _updateBest() {
    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }

    // Also scan full history for best streak
    if (completedDates.length < 2) {
      if (completedDates.length == 1 && bestStreak < 1) bestStreak = 1;
      return;
    }

    final dates = completedDates.map(_parseKey).toList()..sort();
    int maxStreak = 1;
    int run = 1;

    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        run++;
        if (run > maxStreak) maxStreak = run;
      } else if (diff > 1) {
        run = 1;
      }
    }

    if (maxStreak > bestStreak) bestStreak = maxStreak;
  }

  /// Last 7 days completion map (oldest → newest)
  List<bool> last7DaysStatus() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return isCompletedOn(d);
    });
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _parseKey(String key) {
    final p = key.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Habit copyWith({
    String? title,
    String? icon,
    int? colorValue,
    int? reminderHour,
    int? reminderMinute,
    bool? isActive,
  }) {
    return Habit(
      id: id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      completedDates: List.from(completedDates),
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
