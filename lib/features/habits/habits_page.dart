import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/router/app_router.dart';
import '../../data/models/habit.dart';
import '../../providers/habits_provider.dart';
import 'widgets/habit_tile.dart';
import 'widgets/add_habit_sheet.dart';
import 'widgets/habit_stats_header.dart';

class HabitsPage extends ConsumerWidget {
  final String? initialHabitId;
  const HabitsPage({super.key, this.initialHabitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(activeHabitsProvider);
    final completed = ref.watch(todayCompletedCountProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Habits'),
        actions: [
          IconButton(
            onPressed: () => _showAddSheet(context),
            icon: const Icon(Iconsax.add),
            tooltip: 'Add habit',
          ),
        ],
      ),
      body: habits.isEmpty
          ? _EmptyState(onAdd: () => _showAddSheet(context))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: HabitStatsHeader(
                    total: habits.length,
                    completed: completed,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final habit = habits[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: HabitTile(
                            habit: habit,
                            onToggle: () => ref
                                .read(habitsProvider.notifier)
                                .toggleToday(habit.id),
                            onTap: () => _showEditSheet(context, habit),
                            onDelete: () => _confirmDelete(context, ref, habit),
                          ),
                        );
                      },
                      childCount: habits.length,
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: habits.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Iconsax.add),
              label: const Text('Add habit'),
            ),
      bottomNavigationBar: const _BottomNav(currentIndex: 1),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddHabitSheet(),
    );
  }

  void _showEditSheet(BuildContext context, Habit habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddHabitSheet(existing: habit),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('“${habit.title}” and its streak history will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(habitsProvider.notifier).delete(habit.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.task_square,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No habits yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Build consistency one day at a time.\nAdd your first habit to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Iconsax.add),
              label: const Text('Add habit'),
            ),
          ],
        ),
      ),
    );
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
