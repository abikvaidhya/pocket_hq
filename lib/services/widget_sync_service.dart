import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/habit.dart';
import '../data/models/note.dart';
import '../providers/focus_provider.dart';
import '../providers/habits_provider.dart';
import '../providers/notes_provider.dart';
import 'native_bridge.dart';

/// Pushes Notes / Habits / Screen-time payloads to the Android Glance widget.
class WidgetSyncService {
  WidgetSyncService._();
  static final WidgetSyncService instance = WidgetSyncService._();

  Future<void> sync(WidgetRef ref) async {
    final notes = ref.read(notesProvider);
    final habits = ref.read(activeHabitsProvider);
    final focus = ref.read(focusProvider);

    final notesPayload = _notesForWidget(notes);
    final habitsPayload = _pendingHabits(habits);
    final appsPayload = focus.apps.take(5).map((a) {
      return {
        'name': a.appName,
        'minutes': a.totalTimeMs ~/ 60000,
      };
    }).toList();

    try {
      await NativeBridge.updateHomeWidget({
        'title': 'Pocket HQ',
        'subtitle': _todayLabel(),
        'notesJson': jsonEncode(notesPayload),
        'habitsJson': jsonEncode(habitsPayload),
        'appsJson': jsonEncode(appsPayload),
        'screenTotal': focus.hasPermission ? focus.formatted : '—',
      });
    } catch (_) {}
  }

  /// Apply habit completions done from the widget while the app was closed.
  Future<void> applyWidgetHabitCompletions(WidgetRef ref) async {
    try {
      final ids = await NativeBridge.drainWidgetHabitCompletions();
      for (final id in ids) {
        await ref.read(habitsProvider.notifier).toggleToday(id);
      }
      if (ids.isNotEmpty) {
        await sync(ref);
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _notesForWidget(List<Note> notes) {
    final pinned = notes.where((n) => n.isPinned).toList();
    final source = pinned.isNotEmpty ? pinned : notes;
    return source.take(8).map((n) {
      return {
        'id': n.id,
        'title': n.preview,
        'isVoice': n.isVoice,
        'audioPath': n.audioPath,
        'isPinned': n.isPinned,
        'durationLabel': n.isVoice ? n.formattedDuration : '',
      };
    }).toList();
  }

  /// Pending (not completed today), max 3 — sorted by creation (stable order).
  /// Reminder time could refine sort when present.
  List<Map<String, dynamic>> _pendingHabits(List<Habit> habits) {
    final pending = habits.where((h) => !h.isCompletedToday).toList();
    pending.sort((a, b) {
      final ah = a.reminderHour ?? 99;
      final bh = b.reminderHour ?? 99;
      final am = a.reminderMinute ?? 0;
      final bm = b.reminderMinute ?? 0;
      final at = ah * 60 + am;
      final bt = bh * 60 + bm;
      if (at != bt) return at.compareTo(bt);
      return a.createdAt.compareTo(b.createdAt);
    });
    return pending.take(3).map((h) {
      return {
        'id': h.id,
        'title': h.title,
        'color': h.colorValue,
      };
    }).toList();
  }

  String _todayLabel() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final n = DateTime.now();
    return '${days[n.weekday - 1]}, ${months[n.month - 1]} ${n.day}';
  }
}
