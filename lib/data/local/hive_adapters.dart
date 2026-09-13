
import 'package:hive/hive.dart';

import '../models/habit.dart';
import '../models/note.dart';
import '../models/trip.dart';
import '../models/vault_note.dart';

/// Register all Hive type adapters here.
/// Run `dart run build_runner build --delete-conflicting-outputs`
/// after adding @HiveType models.
Future<void> registerHiveAdapters() async {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(HabitAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(NoteAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(VaultNoteAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(TripPointAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(TripAdapter());
  }
}
