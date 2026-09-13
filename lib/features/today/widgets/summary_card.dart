import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../providers/calendar_provider.dart';
import '../../../providers/focus_provider.dart';
import '../../../providers/habits_provider.dart';
import '../../../providers/notes_provider.dart';
import '../../../providers/trips_provider.dart';

class SummaryCard extends ConsumerWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final habits = ref.watch(activeHabitsProvider);
    final habitsDone = ref.watch(todayCompletedCountProvider);
    final habitsTotal = habits.length;
    final habitsLabel =
        habitsTotal == 0 ? '0' : '$habitsDone/$habitsTotal';

    final focus = ref.watch(focusProvider);
    final screenLabel = !focus.hasPermission && !focus.loading
        ? '—'
        : (focus.loading ? '…' : focus.formatted);

    final notesCount = ref.watch(notesCountProvider);

    final trips = ref.watch(tripsProvider);
    final today = DateTime.now();
    final tripsToday = trips.trips.where((t) {
      final s = t.startedAt;
      return s.year == today.year &&
          s.month == today.month &&
          s.day == today.day;
    }).length;
    final tripsLabel = trips.activeTrip != null
        ? 'Live'
        : (tripsToday == 0 ? '0' : '$tripsToday');

    final events = ref.watch(calendarProvider).events.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.calendar_1,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Today at a glance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (habitsTotal > 0)
                  Text(
                    habitsDone == habitsTotal
                        ? 'All done'
                        : '${habitsTotal - habitsDone} left',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: habitsDone == habitsTotal
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(
                  icon: Iconsax.tick_circle,
                  label: 'Habits',
                  value: habitsLabel,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Iconsax.clock,
                  label: 'Screen',
                  value: screenLabel,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Iconsax.note,
                  label: 'Notes',
                  value: '$notesCount',
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatChip(
                  icon: Iconsax.map,
                  label: 'Trips',
                  value: tripsLabel,
                  color: const Color(0xFF00BCD4),
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Iconsax.calendar,
                  label: 'Events',
                  value: '$events',
                  color: const Color(0xFFFF6D00),
                ),
                const SizedBox(width: 10),
                // Spacer chip keeps row balanced; shows focus permission hint
                Expanded(
                  child: focus.hasPermission
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Grant usage access for live screen time',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
