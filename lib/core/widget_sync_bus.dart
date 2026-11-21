import 'dart:async';

enum WidgetSyncSection { habits, notes, carts, trips, focus, all }

typedef WidgetSyncCallback = Future<void> Function(
  Set<WidgetSyncSection> sections,
);

class WidgetSyncBus {
  WidgetSyncBus._();

  static final Set<WidgetSyncSection> _pending = {};
  static Timer? _timer;
  static WidgetSyncCallback? _callback;

  static void configure(WidgetSyncCallback callback) {
    _callback = callback;
  }

  static void notify(WidgetSyncSection section) {
    _pending.add(section);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 250), () async {
      final sections = Set<WidgetSyncSection>.of(_pending);
      _pending.clear();
      await _callback?.call(sections);
    });
  }

  static void notifyAll() {
    notify(WidgetSyncSection.all);
  }
}
