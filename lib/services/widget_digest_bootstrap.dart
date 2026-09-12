import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/focus_provider.dart';
import '../providers/habits_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/trips_provider.dart';
import 'digest_sync_service.dart';

/// Call once after app start or when returning to Today.
Future<void> syncWidgetAndDigest(WidgetRef ref) async {
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

  await DigestSyncService.instance.sync(
    habitsPending: pending,
    habitsTotal: habits.length,
    notesCount: notes,
    tripsToday: tripsToday,
    screenTimeFormatted: screen,
  );
}
