import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/router/app_router.dart';

class TripsPreviewCard extends StatelessWidget {
  const TripsPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => AppRouter.push(context, AppRoutes.trips),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 10,               children: [
                  Icon(Iconsax.map, size: 20, color: theme.colorScheme.primary),
                  Expanded(
                    child: Text(
                      'Trips',
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
              Text(
                'Track distance, destinations & routes.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
