
import 'package:hive/hive.dart';

import '../models/habit.dart';

/// Register all Hive type adapters here.
/// Run `dart run build_runner build --delete-conflicting-outputs`
/// after adding @HiveType models.
Future<void> registerHiveAdapters() async {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(HabitAdapter());
  }
}
