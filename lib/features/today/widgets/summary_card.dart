import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 10,
              children: [
                Icon(Iconsax.calendar_1, size: 20, color: theme.colorScheme.primary),
                Text(
                  'Today at a glance',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Row(
              spacing: 10,
              children: [
                _StatChip(
                  icon: Iconsax.tick_circle,
                  label: 'Habits',
                  value: '3/5',
                  color: theme.colorScheme.primary,
                ),
                _StatChip(
                  icon: Iconsax.clock,
                  label: 'Screen',
                  value: '2h 14m',
                  color: theme.colorScheme.tertiary,
                ),
                _StatChip(
                  icon: Iconsax.note,
                  label: 'Notes',
                  value: '2',
                  color: theme.colorScheme.secondary,
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
            spacing: 5,
          children: [
            Icon(icon, size: 18, color: color),
            Text(
              value,
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
