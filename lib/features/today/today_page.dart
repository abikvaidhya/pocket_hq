import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/router/app_router.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/summary_card.dart';
import 'widgets/habits_preview_card.dart';
import 'widgets/calendar_preview_card.dart';
import 'widgets/focus_preview_card.dart';
import 'widgets/notes_preview_card.dart';
import 'widgets/trips_preview_card.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardOrder = ref.watch(dashboardLayoutProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 20,),
                          Text(
                            'Pocket HQ',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => AppRouter.push(context, AppRoutes.settings),
                      icon: const Icon(Iconsax.setting_2, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                onReorder: (oldIndex, newIndex) {
                  ref.read(dashboardLayoutProvider.notifier).reorder(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final key = cardOrder[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(key),
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCard(key),
                    ),
                  );
                },
              ),
            ),

            const SliverGap(32),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 0),
    );
  }

  Widget _buildCard(String key) {
    return switch (key) {
      'summary' => const SummaryCard(),
      'habits' => const HabitsPreviewCard(),
      'calendar' => const CalendarPreviewCard(),
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
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        final routes = [
          AppRoutes.today,
          AppRoutes.habits,
          AppRoutes.focus,
          AppRoutes.notes,
          AppRoutes.trips,
        ];
        if (index != currentIndex) {
          AppRouter.pushReplacement(context, routes[index]);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Iconsax.home),
          selectedIcon: Icon(Iconsax.home_1),
          label: 'Today',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.task_square),
          selectedIcon: Icon(Iconsax.task_square5),
          label: 'Habits',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.chart_2),
          selectedIcon: Icon(Iconsax.chart_21),
          label: 'Focus',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.note_1),
          selectedIcon: Icon(Iconsax.note_15),
          label: 'Notes',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.map),
          selectedIcon: Icon(Iconsax.map5),
          label: 'Trips',
        ),
      ],
    );
  }
}

// Helper because SliverToBoxAdapter is verbose in some places
Widget convertSliver(Widget child) =>
    SliverToBoxAdapter(child: child);

class SliverGap extends StatelessWidget {
  final double height;
  const SliverGap(this.height, {super.key});

  @override
  Widget build(BuildContext context) {
    return convertSliver(SizedBox(height: height));
  }
}
