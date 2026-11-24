import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/hive_boxes.dart';
import '../data/models/habit.dart';
import '../services/notification_service.dart';
import '../core/widget_sync_bus.dart';

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, List<Habit>>((ref) {
  return HabitsNotifier();
});

final activeHabitsProvider = Provider<List<Habit>>((ref) {
  return ref.watch(habitsProvider).where((h) => h.isActive).toList();
});

final todayCompletedCountProvider = Provider<int>((ref) {
  return ref
      .watch(activeHabitsProvider)
      .where((h) => h.isCompletedToday)
      .length;
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
    WidgetSyncBus.notify(WidgetSyncSection.habits);
  }

  Future<void> update(Habit habit) async {
    await _box.put(habit.id, habit);
    _load();
    await _syncReminder(habit);
    WidgetSyncBus.notify(WidgetSyncSection.habits);
  }

  Future<void> delete(String id) async {
    await NotificationService.instance.cancelWithPayload('habit:$id');
    await NotificationService.instance.cancel(_notificationId(id));
    await NotificationService.instance.cancel(id.hashCode);
    await _box.delete(id);
    _load();
    WidgetSyncBus.notify(WidgetSyncSection.habits);
  }

  Future<void> toggleToday(String id) async {
    final habit = _box.get(id);
    if (habit == null) return;

    habit.toggleCompletion(DateTime.now());
    await habit.save();
    _load();
    WidgetSyncBus.notify(WidgetSyncSection.habits);
  }

  Future<void> toggleDate(String id, DateTime date) async {
    final habit = _box.get(id);
    if (habit == null) return;

    habit.toggleCompletion(date);
    await habit.save();
    _load();
    WidgetSyncBus.notify(WidgetSyncSection.habits);
  }

  Future<void> _syncReminder(Habit habit) async {
    final notifId = _notificationId(habit.id);
    await NotificationService.instance.cancelWithPayload('habit:${habit.id}');
    await NotificationService.instance.cancel(habit.id.hashCode);

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

  Future<void> syncAllReminders() async {
    await NotificationService.instance.cancelWithPayloadPrefix('habit:');
    for (final habit in _box.values) {
      await _syncReminder(habit);
    }
  }

  int _notificationId(String id) {
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
