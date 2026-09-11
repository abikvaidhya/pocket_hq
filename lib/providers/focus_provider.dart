import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/native_bridge.dart';

class AppUsageItem {
  final String packageName;
  final String appName;
  final int totalTimeMs;

  const AppUsageItem({
    required this.packageName,
    required this.appName,
    required this.totalTimeMs,
  });

  String get formatted {
    final totalMin = totalTimeMs ~/ 60000;
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  factory AppUsageItem.fromMap(Map<String, dynamic> m) {
    return AppUsageItem(
      packageName: m['packageName'] as String? ?? '',
      appName: m['appName'] as String? ?? m['packageName'] as String? ?? 'Unknown',
      totalTimeMs: (m['totalTimeMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class FocusState {
  final bool hasPermission;
  final bool loading;
  final int totalMs;
  final String formatted;
  final List<AppUsageItem> apps;
  final String? error;

  const FocusState({
    this.hasPermission = false,
    this.loading = true,
    this.totalMs = 0,
    this.formatted = '0h 0m',
    this.apps = const [],
    this.error,
  });

  FocusState copyWith({
    bool? hasPermission,
    bool? loading,
    int? totalMs,
    String? formatted,
    List<AppUsageItem>? apps,
    String? error,
  }) {
    return FocusState(
      hasPermission: hasPermission ?? this.hasPermission,
      loading: loading ?? this.loading,
      totalMs: totalMs ?? this.totalMs,
      formatted: formatted ?? this.formatted,
      apps: apps ?? this.apps,
      error: error,
    );
  }
}

final focusProvider =
    StateNotifierProvider<FocusNotifier, FocusState>((ref) {
  return FocusNotifier()..refresh();
});

class FocusNotifier extends StateNotifier<FocusState> {
  FocusNotifier() : super(const FocusState());

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final permitted = await NativeBridge.hasUsagePermission();
      if (!permitted) {
        state = state.copyWith(
          hasPermission: false,
          loading: false,
          totalMs: 0,
          formatted: '0h 0m',
          apps: [],
        );
        return;
      }

      final summary = await NativeBridge.getScreenTimeToday();
      final rawApps = await NativeBridge.getAppUsageToday();

      final apps = rawApps
          .map(AppUsageItem.fromMap)
          .where((a) => a.totalTimeMs > 0)
          .toList()
        ..sort((a, b) => b.totalTimeMs.compareTo(a.totalTimeMs));

      state = FocusState(
        hasPermission: true,
        loading: false,
        totalMs: (summary['totalMs'] as num?)?.toInt() ?? 0,
        formatted: summary['formatted'] as String? ?? '0h 0m',
        apps: apps.take(15).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> requestPermission() async {
    await NativeBridge.openUsageAccessSettings();
  }
}
