import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/models/habit.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HabitTile({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(habit.colorValue);
    final done = habit.isCompletedToday;
    final week = habit.last7DaysStatus();

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Iconsax.trash, color: theme.colorScheme.error),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // we handle delete in dialog
      },
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    // Check button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onToggle();
                      },
                      child: AnimatedScale(
                        scale: done ? 1.0 : 0.96,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: done
                                ? color
                                : color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: done
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.28),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            done ? Iconsax.tick_circle5 : Iconsax.tick_circle,
                            color: done ? Colors.white : color,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: done ? TextDecoration.lineThrough : null,
                              color: done
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Iconsax.flash_1, size: 14, color: color),
                              const SizedBox(width: 4),
                              Text(
                                '${habit.currentStreak} day streak',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (habit.bestStreak > 0) ...[
                                const SizedBox(width: 10),
                                Text(
                                  'Best ${habit.bestStreak}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Iconsax.arrow_right_3,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 7-day dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final filled = week[i];
                    final isToday = i == 6;
                    return Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: filled
                            ? color
                            : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(color: color, width: 1.5)
                            : null,
                      ),
                      child: filled
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
