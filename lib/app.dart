import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';

class PocketHQApp extends ConsumerWidget {
  const PocketHQApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final useDynamicColor = ref.watch(dynamicColorProvider);

    return MaterialApp(
      title: 'Pocket HQ',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(useDynamicColor: useDynamicColor),
      darkTheme: AppTheme.dark(useDynamicColor: useDynamicColor),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRoutes.today,
      builder: (context, child) {
        // Enforce text scale factor limit for consistent UI
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              mediaQuery.textScaler.scale(1.0).clamp(0.85, 1.15),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
