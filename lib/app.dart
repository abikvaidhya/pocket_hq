import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'core/constants/hive_boxes.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'services/native_bridge.dart';
import 'services/widget_digest_bootstrap.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleDeepLink();
      syncWidgetAndDigest(ref);
    });
    setAppVersionCode();
  }

  Future<void> setAppVersionCode() async {
    final box = Hive.box(HiveBoxes.settings);
    box.clear();

    PackageInfo info = await PackageInfo.fromPlatform();

    String version = '${info.version}+${info.buildNumber}';

    box.put(HiveKeys.appVersion, version);
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
      nav.pushNamed(route);
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
