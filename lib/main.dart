import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'data/local/hive_adapters.dart';
import 'data/models/habit.dart';
import 'data/models/note.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for dashboard feel
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Timezone for notifications
  tz.initializeTimeZones();

  // Hive
  await Hive.initFlutter();
  await registerHiveAdapters();
  await openHiveBoxes();

  // Local notifications
  await NotificationService.instance.init();

  runApp(
    const ProviderScope(
      child: PocketHQApp(),
    ),
  );
}

Future<void> openHiveBoxes() async {
  await Future.wait([
    Hive.openBox(HiveBoxes.settings),
    Hive.openBox<Habit>(HiveBoxes.habits),
    Hive.openBox<Note>(HiveBoxes.notes),
    Hive.openBox(HiveBoxes.vaultNotes),
    Hive.openBox(HiveBoxes.trips),
    Hive.openBox(HiveBoxes.dailyStats),
    Hive.openBox(HiveBoxes.dashboardLayout),
  ]);
}
