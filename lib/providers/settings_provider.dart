import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/hive_boxes.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

final dynamicColorProvider = StateNotifierProvider<DynamicColorNotifier, bool>((ref) {
  return DynamicColorNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_load()) {
    // Listen to box changes if needed
  }

  static ThemeMode _load() {
    final box = Hive.box(HiveBoxes.settings);
    final value = box.get(HiveKeys.themeMode, defaultValue: 'system') as String;
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final box = Hive.box(HiveBoxes.settings);
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await box.put(HiveKeys.themeMode, value);
  }

  void cycle() {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    setThemeMode(next);
  }
}

class DynamicColorNotifier extends StateNotifier<bool> {
  DynamicColorNotifier() : super(_load());

  static bool _load() {
    final box = Hive.box(HiveBoxes.settings);
    return box.get(HiveKeys.dynamicColor, defaultValue: true) as bool;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final box = Hive.box(HiveBoxes.settings);
    await box.put(HiveKeys.dynamicColor, enabled);
  }

  void toggle() => setEnabled(!state);
}
