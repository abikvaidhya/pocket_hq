import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/native_bridge.dart';

class CalendarEvent {
  final String title;
  final DateTime begin;
  final DateTime end;
  final String? location;
  final bool allDay;
  final String? calendar;

  const CalendarEvent({
    required this.title,
    required this.begin,
    required this.end,
    this.location,
    this.allDay = false,
    this.calendar,
  });

  String get timeLabel {
    if (allDay) return 'All day';
    final h = begin.hour.toString().padLeft(2, '0');
    final m = begin.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> m) {
    return CalendarEvent(
      title: m['title'] as String? ?? 'Event',
      begin: DateTime.fromMillisecondsSinceEpoch((m['begin'] as num?)?.toInt() ?? 0),
      end: DateTime.fromMillisecondsSinceEpoch((m['end'] as num?)?.toInt() ?? 0),
      location: m['location'] as String?,
      allDay: m['allDay'] as bool? ?? false,
      calendar: m['calendar'] as String?,
    );
  }
}

class CalendarState {
  final bool loading;
  final bool permissionDenied;
  final List<CalendarEvent> events;
  final String? error;

  const CalendarState({
    this.loading = true,
    this.permissionDenied = false,
    this.events = const [],
    this.error,
  });

  CalendarState copyWith({
    bool? loading,
    bool? permissionDenied,
    List<CalendarEvent>? events,
    String? error,
  }) {
    return CalendarState(
      loading: loading ?? this.loading,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      events: events ?? this.events,
      error: error,
    );
  }
}

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier()..refresh();
});

class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier() : super(const CalendarState());

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final status = await Permission.calendarFullAccess.request();
      // Fallback for older permission names
      final ok = status.isGranted ||
          await Permission.calendarWriteOnly.request().isGranted ||
          (await Permission.calendarFullAccess.status).isGranted;

      if (!ok) {
        // Still try native — may work if granted previously
      }

      final raw = await NativeBridge.getTodayEvents();
      final events = raw.map(CalendarEvent.fromMap).toList()
        ..sort((a, b) => a.begin.compareTo(b.begin));

      state = CalendarState(
        loading: false,
        permissionDenied: events.isEmpty && !ok,
        events: events,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
