import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/hive_boxes.dart';

final dashboardLayoutProvider =
    StateNotifierProvider<DashboardLayoutNotifier, List<String>>((ref) {
  return DashboardLayoutNotifier();
});

class DashboardLayoutNotifier extends StateNotifier<List<String>> {
  DashboardLayoutNotifier() : super(_load());

  static List<String> _load() {
    final box = Hive.box(HiveBoxes.dashboardLayout);
    final stored = box.get(HiveKeys.cardOrder) as List<dynamic>?;
    if (stored == null || stored.isEmpty) {
      return List<String>.from(AppConstants.defaultCardOrder);
    }
    return stored.cast<String>();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = state.removeAt(oldIndex);
    state = [...state]..insert(newIndex, item);
    await _persist();
  }

  Future<void> reset() async {
    state = List<String>.from(AppConstants.defaultCardOrder);
    await _persist();
  }

  Future<void> _persist() async {
    final box = Hive.box(HiveBoxes.dashboardLayout);
    await box.put(HiveKeys.cardOrder, state);
  }
}
