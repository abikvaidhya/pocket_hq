import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/router/app_router.dart';
import '../../providers/settings_provider.dart';
import '../../providers/dashboard_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final dynamicColor = ref.watch(dynamicColorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SectionHeader(title: 'Appearance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Iconsax.moon),
                  title: const Text('Theme'),
                  subtitle: Text(
                    switch (themeMode) {
                      ThemeMode.light => 'Light',
                      ThemeMode.dark => 'Dark',
                      ThemeMode.system => 'System',
                    },
                  ),
                  trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                  onTap: () => ref.read(themeModeProvider.notifier).cycle(),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Iconsax.colorfilter),
                  title: const Text('Dynamic Color'),
                  subtitle: const Text('Material You (Android 12+)'),
                  value: dynamicColor,
                  onChanged: (v) => ref.read(dynamicColorProvider.notifier).setEnabled(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20,),
          _SectionHeader(title: 'Dashboard'),
          Card(
            child: ListTile(
              leading: const Icon(Iconsax.refresh),
              title: const Text('Reset card order'),
              onTap: () {
                ref.read(dashboardLayoutProvider.notifier).reset();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dashboard layout reset')),
                );
              },
            ),
          ),
          const SizedBox(height: 20,),
          _SectionHeader(title: 'Security'),
          Card(
            child: ListTile(
              leading: const Icon(Iconsax.lock),
              title: const Text('Vault'),
              subtitle: const Text('Biometric protected notes'),
              trailing: const Icon(Iconsax.arrow_right_3, size: 18),
              onTap: () => AppRouter.push(context, AppRoutes.vault),
            ),
          ),
          const SizedBox(height: 20,),
          _SectionHeader(title: 'About'),
          Card(
            child: ListTile(
              leading: const Icon(Iconsax.info_circle),
              title: const Text('Pocket HQ'),
              subtitle: Text(
                'v1.0.0',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 20,),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}
