import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/hive_boxes.dart';
import '../data/models/reminder.dart';
import '../services/notification_service.dart';
import '../services/reminder_parser.dart';

final remindersProvider =
    StateNotifierProvider<RemindersNotifier, List<Reminder>>((ref) {
  return RemindersNotifier();
});

final activeRemindersProvider = Provider<List<Reminder>>((ref) {
  final list = ref.watch(remindersProvider);
  final now = DateTime.now();
  return list.where((r) => !r.completed && r.triggerAt.isAfter(now)).toList()
    ..sort((a, b) => a.triggerAt.compareTo(b.triggerAt));
});

class RemindersNotifier extends StateNotifier<List<Reminder>> {
  RemindersNotifier() : super([]) {
    _load();
  }

  Box<Reminder> get _box => Hive.box<Reminder>(HiveBoxes.reminders);

  void _load() {
    final list = _box.values.toList()
      ..sort((a, b) => a.triggerAt.compareTo(b.triggerAt));
    state = list;
  }

  /// Parse text and schedule. Returns the saved reminder.
  Future<Reminder> addFromText(String text) async {
    final parsed = ReminderParser.parse(text);
    return _saveAndSchedule(
      label: parsed.label,
      triggerAt: parsed.triggerAt,
      kind: parsed.kind,
      sourceText: parsed.sourceText,
    );
  }

  Future<Reminder> addManual({
    required String label,
    required DateTime triggerAt,
    String kind = 'reminder',
  }) async {
    return _saveAndSchedule(
      label: label.trim().isEmpty ? 'Reminder' : label.trim(),
      triggerAt: triggerAt,
      kind: kind,
      sourceText: '',
    );
  }

  Future<Reminder> _saveAndSchedule({
    required String label,
    required DateTime triggerAt,
    required String kind,
    required String sourceText,
  }) async {
    final reminder = Reminder(
      label: label,
      triggerAt: triggerAt,
      kind: kind,
      sourceText: sourceText,
    );
    await _box.put(reminder.id, reminder);

    try {
      await NotificationService.instance.scheduleOnce(
        id: reminder.notificationId,
        title: reminder.kindLabel,
        body: reminder.label,
        when: reminder.triggerAt,
        payload: 'reminder:${reminder.id}',
      );
    } catch (_) {
      // Permission / exact alarm may fail; still keep the row
    }

    _load();
    return reminder;
  }

  Future<void> complete(String id) async {
    final r = _box.get(id);
    if (r == null) return;
    r.completed = true;
    await r.save();
    await NotificationService.instance.cancel(r.notificationId);
    _load();
  }

  Future<void> delete(String id) async {
    final r = _box.get(id);
    if (r != null) {
      await NotificationService.instance.cancel(r.notificationId);
    }
    await _box.delete(id);
    _load();
  }
}
