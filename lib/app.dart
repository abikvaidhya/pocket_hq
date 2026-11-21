import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';

import 'core/constants/hive_boxes.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'services/native_bridge.dart';
import 'services/widget_digest_bootstrap.dart';
import 'services/notification_service.dart';
import 'providers/calendar_provider.dart';
import 'providers/focus_provider.dart';
import 'core/widget_sync_bus.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class PocketHQApp extends ConsumerStatefulWidget {
  const PocketHQApp({super.key});

  @override
  ConsumerState<PocketHQApp> createState() => _PocketHQAppState();
}

class _PocketHQAppState extends ConsumerState<PocketHQApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NativeBridge.setDeepLinkHandler(_handleDeepLink);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleDeepLink();
      WidgetSyncBus.configure((sections) async {
        await syncWidgetAndDigest(ref, sections: sections);
      });
      _deferNonEssentialStartup();
    });
    setAppVersionCode();
  }

  Future<void> setAppVersionCode() async {
    final box = Hive.box(HiveBoxes.settings);
    final info = await PackageInfo.fromPlatform();
    final version = '${info.version}+${info.buildNumber}';
    if (box.get(HiveKeys.appVersion) != version) {
      await box.put(HiveKeys.appVersion, version);
    }
  }

  Future<void> _deferNonEssentialStartup() async {
    unawaited(NotificationService.instance.init());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await Future.wait([
      syncWidgetAndDigest(ref),
      ref.read(calendarProvider.notifier).refresh(),
      ref.read(focusProvider.notifier).refresh(),
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncWidgetAndDigest(ref);
      _handleDeepLink();
    }
  }

  Future<void> _handleDeepLink() async {
    try {
      final link = await NativeBridge.getPendingDeepLink();
      if (link == null) return;
      final route = link['route'] as String?;
      if (route == null || route.isEmpty) return;
      final nav = rootNavigatorKey.currentState;
      if (nav == null) return;
      final noteId = link['noteId'] as String?;
      final target = route == AppRoutes.notes && noteId != null
          ? AppRoutes.noteEditor
          : route;
      nav.pushNamedAndRemoveUntil(
        target,
        (existing) => existing.isFirst,
        arguments: noteId == null ? null : {'id': noteId},
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final useDynamicColor = ref.watch(dynamicColorProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Pocket HQ',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(useDynamicColor: useDynamicColor),
      darkTheme: AppTheme.dark(useDynamicColor: useDynamicColor),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRoutes.today,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              mediaQuery.textScaler.scale(1.0).clamp(0.85, 1.15),
            ),
          ),
          child: child ?? const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
