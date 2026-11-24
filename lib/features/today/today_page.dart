import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/router/app_router.dart';
import '../../core/widgets/matte_card.dart';
import '../../providers/dashboard_provider.dart';
import '../bottom_nav_bar.dart';
import 'widgets/focus_preview_card.dart';
import 'widgets/habits_preview_card.dart';
import 'widgets/notes_preview_card.dart';
import 'widgets/summary_card.dart';
import 'widgets/trips_preview_card.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardOrder = ref.watch(dashboardLayoutProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Text(
                        'Pocket HQ',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _DrawerDestination(
                      icon: Iconsax.shopping_cart,
                      title: 'To Get',
                      route: AppRoutes.carts,
                    ),
                    _DrawerDestination(
                      icon: Iconsax.notification,
                      title: 'Reminders',
                      route: AppRoutes.reminders,
                    ),
                    _DrawerDestination(
                      icon: Iconsax.map,
                      title: 'Trips',
                      route: AppRoutes.trips,
                    ),
                    _DrawerDestination(
                      icon: Iconsax.chart_2,
                      title: 'Screen time usage',
                      route: AppRoutes.focus,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: IconButton(
                    tooltip: 'Settings',
                    onPressed: () {
                      Navigator.pop(context);
                      AppRouter.push(context, AppRoutes.settings);
                    },
                    icon: const Icon(Iconsax.setting_2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Open navigation menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu),
          ),
        ),
        title: Text(
          _greeting(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      // Text(
      //     'Pocket HQ',
      //     style: theme.textTheme.headlineSmall?.copyWith(
      //       fontWeight: FontWeight.w800,
      //       letterSpacing: -0.5,
      //     ),,),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Date chip ───────────────────────────────────────────────────
            convertSliver(
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Text(
                  _formatDate(now),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),

            // ── Reorderable dashboard cards ─────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverReorderableList(
                itemCount: cardOrder.length,
                onReorderItem: (oldIndex, newIndex) {
                  ref
                      .read(dashboardLayoutProvider.notifier)
                      .reorder(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final key = cardOrder[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(key),
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCard(key).matteEnter(index: index),
                    ),
                  );
                },
              ),
            ),

            const SliverGap(32),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }

  Widget _buildCard(String key) {
    return switch (key) {
      'summary' => const SummaryCard(),
      'habits' => const HabitsPreviewCard(),
      'focus' => const FocusPreviewCard(),
      'notes' => const NotesPreviewCard(),
      'trips' => const TripsPreviewCard(),
      _ => const SizedBox.shrink(),
    };
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _DrawerDestination extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;

  const _DrawerDestination({
    required this.icon,
    required this.title,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        AppRouter.push(context, route);
      },
    );
  }
}

// sliverToBoxAdapter (verbose in some places) helper
Widget convertSliver(Widget child) => SliverToBoxAdapter(child: child);

class SliverGap extends StatelessWidget {
  final double height;

  const SliverGap(this.height, {super.key});

  @override
  Widget build(BuildContext context) {
    return convertSliver(SizedBox(height: height));
  }
}
