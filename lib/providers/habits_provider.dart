import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/hive_boxes.dart';
import '../data/models/habit.dart';
import '../services/notification_service.dart';

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, List<Habit>>((ref) {
  return HabitsNotifier();
});

final activeHabitsProvider = Provider<List<Habit>>((ref) {
  return ref.watch(habitsProvider).where((h) => h.isActive).toList();
});

final todayCompletedCountProvider = Provider<int>((ref) {
  return ref.watch(activeHabitsProvider).where((h) => h.isCompletedToday).length;
});

class HabitsNotifier extends StateNotifier<List<Habit>> {
  HabitsNotifier() : super([]) {
    _load();
  }

  Box<Habit> get _box => Hive.box<Habit>(HiveBoxes.habits);

  void _load() {
    state = _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> add(Habit habit) async {
    await _box.put(habit.id, habit);
    _load();
    await _syncReminder(habit);
  }

  Future<void> update(Habit habit) async {
    await _box.put(habit.id, habit);
    _load();
    await _syncReminder(habit);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    await NotificationService.instance.cancel(id.hashCode);
    _load();
  }

  Future<void> toggleToday(String id) async {
    final habit = _box.get(id);
    if (habit == null) return;

    habit.toggleCompletion(DateTime.now());
    await habit.save();
    _load();
  }

  Future<void> toggleDate(String id, DateTime date) async {
    final habit = _box.get(id);
    if (habit == null) return;

    habit.toggleCompletion(date);
    await habit.save();
    _load();
  }

  Future<void> _syncReminder(Habit habit) async {
    final notifId = habit.id.hashCode;

    if (habit.reminderHour != null &&
        habit.reminderMinute != null &&
        habit.isActive) {
      await NotificationService.instance.scheduleDaily(
        id: notifId,
        title: 'Habit reminder',
        body: habit.title,
        hour: habit.reminderHour!,
        minute: habit.reminderMinute!,
        payload: 'habit:${habit.id}',
      );
    } else {
      await NotificationService.instance.cancel(notifId);
    }
  }
}
