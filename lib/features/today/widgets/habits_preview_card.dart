import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/router/app_router.dart';
import '../../../providers/habits_provider.dart';

class HabitsPreviewCard extends ConsumerWidget {
  const HabitsPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habits = ref.watch(activeHabitsProvider);
    final completed = ref.watch(todayCompletedCountProvider);
    final preview = habits.take(3).toList();

    return Card(
      child: InkWell(
        onTap: () => AppRouter.push(context, AppRoutes.habits),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Iconsax.task_square, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Habits',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (habits.isNotEmpty)
                    Text(
                      '$completed/${habits.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (habits.isEmpty)
                Text(
                  'No habits yet. Tap to add one.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                )
              else
                ...preview.map((h) {
                  final done = h.isCompletedToday;
                  final color = Color(h.colorValue);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          done ? Iconsax.tick_circle5 : Iconsax.tick_circle,
                          size: 22,
                          color: done ? color : theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            h.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              decoration:
                                  done ? TextDecoration.lineThrough : null,
                              color: done
                                  ? theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🔥 ${h.currentStreak}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
