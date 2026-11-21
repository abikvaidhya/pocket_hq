import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/focus_provider.dart';
import '../providers/habits_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/trips_provider.dart';
import 'digest_sync_service.dart';
import 'widget_sync_service.dart';
import '../core/widget_sync_bus.dart';

/// Call after app start / when returning to Today.
Future<void> syncWidgetAndDigest(
  WidgetRef ref, {
  Set<WidgetSyncSection> sections = const {WidgetSyncSection.all},
}) async {
  final syncAll = sections.contains(WidgetSyncSection.all);
  final habitsChanged = syncAll || sections.contains(WidgetSyncSection.habits);
  final notesChanged = syncAll || sections.contains(WidgetSyncSection.notes);
  final tripsChanged = syncAll || sections.contains(WidgetSyncSection.trips);
  final focusChanged = syncAll || sections.contains(WidgetSyncSection.focus);

  final habits = ref.read(activeHabitsProvider);
  final completed = habits.where((h) => h.isCompletedToday).length;
  final pending = habits.length - completed;
  final notes = ref.read(notesProvider).length;
  final trips = ref.read(tripsProvider).trips;
  final today = DateTime.now();
  final tripsToday = trips.where((t) {
    final s = t.startedAt;
    return s.year == today.year && s.month == today.month && s.day == today.day;
  }).length;
  final screen = ref.read(focusProvider).formatted;

  if (syncAll ||
      habitsChanged ||
      notesChanged ||
      tripsChanged ||
      focusChanged) {
    await DigestSyncService.instance.sync(
      habitsPending: pending,
      habitsTotal: habits.length,
      notesCount: notes,
      tripsToday: tripsToday,
      screenTimeFormatted: screen,
    );
  }

  if (habitsChanged || syncAll) {
    await WidgetSyncService.instance.applyWidgetHabitCompletions(ref);
  }
  await WidgetSyncService.instance.sync(ref, sections: sections);
}
