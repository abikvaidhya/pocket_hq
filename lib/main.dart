import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'data/local/hive_adapters.dart';
import 'data/models/habit.dart';
import 'data/models/note.dart';
import 'data/models/reminder.dart';
import 'data/models/shopping_cart.dart';
import 'data/models/trip.dart';
import 'data/models/vault_note.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for dashboard feel
  SystemChrome.setPreferredOrientations([
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

  // Hive
  await Hive.initFlutter();
  await registerHiveAdapters();
  await openHiveBoxes();

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
    Hive.openBox<VaultNote>(HiveBoxes.vaultNotes),
    Hive.openBox<Trip>(HiveBoxes.trips),
    Hive.openBox(HiveBoxes.dailyStats),
    Hive.openBox(HiveBoxes.dashboardLayout),
    Hive.openBox<ShoppingCart>(HiveBoxes.shoppingCarts),
    Hive.openBox<Reminder>(HiveBoxes.reminders),
  ]);
  await _ensureSingleShoppingCart();
}

Future<void> _ensureSingleShoppingCart() async {
  final box = Hive.box<ShoppingCart>(HiveBoxes.shoppingCarts);
  final carts = box.values.toList()
    ..sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return a.createdAt.compareTo(b.createdAt);
    });

  if (carts.isEmpty) {
    final cart = ShoppingCart(title: 'To Get', isPinned: true);
    await box.put(cart.id, cart);
    return;
  }

  final cart = carts.first;
  if (carts.length == 1 &&
      cart.title == 'To Get' &&
      cart.purpose.isEmpty &&
      cart.isPinned) {
    return;
  }

  cart.title = 'To Get';
  cart.purpose = '';
  cart.isPinned = true;
  if (carts.length > 1) {
    cart.items = [
      ...cart.items,
      ...carts.skip(1).expand((other) => other.items)
    ];
  }
  cart.updatedAt = DateTime.now();
  await box.put(cart.id, cart);
  for (final other in carts.skip(1)) {
    await box.delete(other.id);
  }
}
