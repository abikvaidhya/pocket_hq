import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/router/app_router.dart';

class HabitsPreviewCard extends StatelessWidget {
  const HabitsPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => AppRouter.push(context, AppRoutes.habits),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 10,
                children: [
                  Icon(Iconsax.task_square, size: 20, color: theme.colorScheme.primary),
                  Expanded(
                    child: Text(
                      'Habits',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              _HabitRow(title: 'Morning stretch', done: true, streak: 12),
              _HabitRow(title: 'Read 20 min', done: false, streak: 5),
              _HabitRow(title: 'No sugar', done: true, streak: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final String title;
  final bool done;
  final int streak;

  const _HabitRow({
    required this.title,
    required this.done,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      spacing: 10,
      children: [
        Icon(
          done ? Iconsax.tick_circle5 : Iconsax.tick_circle,
          size: 22,
          color: done ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: done ? TextDecoration.lineThrough : null,
              color: done
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '🔥 $streak',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
