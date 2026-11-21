import 'package:flutter/material.dart';

import '../../features/today/today_page.dart';
import '../../features/habits/habits_page.dart';
import '../../features/focus/focus_page.dart';
import '../../features/notes/notes_page.dart';
import '../../features/vault/vault_page.dart';
import '../../features/trips/trips_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/carts/carts_page.dart';
import '../../features/reminders/reminders_page.dart';
import '../../features/notes/widgets/note_editor_page.dart';
import '../../features/carts/cart_detail_page.dart';
import '../../features/vault/widgets/vault_editor_page.dart';

class AppRoutes {
  static const String today = '/today';
  static const String habits = '/habits';
  static const String focus = '/focus';
  static const String notes = '/notes';
  static const String vault = '/vault';
  static const String trips = '/trips';
  static const String settings = '/settings';
  static const String carts = '/carts';
  static const String reminders = '/reminders';
  static const String habitDetail = '/habits/detail';
  static const String noteEditor = '/notes/editor';
  static const String tripDetail = '/trips/detail';
  static const String cartDetail = '/carts/detail';
  static const String vaultEditor = '/vault/editor';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? AppRoutes.today;
    final args = settings.arguments;

    switch (name) {
      case AppRoutes.today:
        return _buildRoute(const TodayPage(), settings);
      case AppRoutes.habits:
        return _buildRoute(const HabitsPage(), settings);
      case AppRoutes.focus:
        return _buildRoute(const FocusPage(), settings);
      case AppRoutes.notes:
        return _buildRoute(const NotesPage(), settings);
      case AppRoutes.vault:
        return _buildRoute(const VaultPage(), settings);
      case AppRoutes.trips:
        return _buildRoute(const TripsPage(), settings);
      case AppRoutes.settings:
        return _buildRoute(const SettingsPage(), settings);
      case AppRoutes.carts:
        return _buildRoute(const CartsPage(), settings);
      case AppRoutes.reminders:
        return _buildRoute(const RemindersPage(), settings);
      case AppRoutes.habitDetail:
        final id = (args is Map) ? args['id'] as String? : null;
        return _buildRoute(HabitsPage(initialHabitId: id), settings);
      case AppRoutes.noteEditor:
        final id = (args is Map) ? args['id'] as String? : null;
        return id == null
            ? _buildRoute(const NotesPage(), settings)
            : _buildRoute(NoteEditorPage(noteId: id), settings);
      case AppRoutes.tripDetail:
        final id = (args is Map) ? args['id'] as String? : null;
        return _buildRoute(TripsPage(initialTripId: id), settings);
      case AppRoutes.cartDetail:
        final id = (args is Map) ? args['id'] as String? : null;
        return id == null
            ? _buildRoute(const CartsPage(), settings)
            : _buildRoute(CartDetailPage(cartId: id), settings);
      case AppRoutes.vaultEditor:
        final id = (args is Map) ? args['id'] as String? : null;
        return id == null
            ? _buildRoute(const VaultPage(), settings)
            : _buildRoute(VaultEditorPage(noteId: id), settings);
      default:
        return _buildRoute(const TodayPage(), settings);
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0.01),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
    );
  }

  /// Helper for typed navigation
  static Future<T?> push<T>(BuildContext context, String route,
      {Object? arguments}) {
    return Navigator.of(context).pushNamed<T>(route, arguments: arguments);
  }

  static void pushReplacement(BuildContext context, String route,
      {Object? arguments}) {
    Navigator.of(context).pushReplacementNamed(route, arguments: arguments);
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }
}
