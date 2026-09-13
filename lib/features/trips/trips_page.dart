import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../data/models/trip.dart';
import '../../providers/trips_provider.dart';
import 'widgets/trip_detail_page.dart';

class TripsPage extends ConsumerWidget {
  final String? initialTripId;
  const TripsPage({super.key, this.initialTripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripsProvider);
    final theme = Theme.of(context);
    final trips = state.trips;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips'),
      ),
      body: Column(
        children: [
          if (state.activeTrip != null)
            _ActiveTripBanner(
              trip: state.activeTrip!,
              onStop: () => ref.read(tripsProvider.notifier).stopTrip(),
              onOpen: () => _openDetail(context, state.activeTrip!),
            ),
          Expanded(
            child: trips.isEmpty
                ? _EmptyState(
                    onStart: () => ref.read(tripsProvider.notifier).startTrip(),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: trips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return _TripCard(
                        trip: trip,
                        onTap: () => _openDetail(context, trip),
                        onDelete: () => _confirmDelete(context, ref, trip),
                      );
                    },
                  ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                state.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: state.tracking
          ? FloatingActionButton.extended(
              onPressed: state.loading
                  ? null
                  : () => ref.read(tripsProvider.notifier).stopTrip(),
              icon: const Icon(Iconsax.stop),
              label: const Text('Stop trip'),
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            )
          : FloatingActionButton.extended(
              onPressed: state.loading
                  ? null
                  : () => ref.read(tripsProvider.notifier).startTrip(),
              icon: state.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Iconsax.play),
              label: Text(state.loading ? 'Starting…' : 'Start trip'),
            ),
      bottomNavigationBar: const _BottomNav(currentIndex: 4),
    );
  }

  void _openDetail(BuildContext context, Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TripDetailPage(tripId: trip.id)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text('“${trip.title}” and its route will be removed.'),
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
      await ref.read(tripsProvider.notifier).deleteTrip(trip.id);
    }
  }
}

class _ActiveTripBanner extends StatelessWidget {
  final Trip trip;
  final VoidCallback onStop;
  final VoidCallback onOpen;

  const _ActiveTripBanner({
    required this.trip,
    required this.onStop,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tracking · ${trip.title}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${trip.formattedDistance} · ${trip.formattedDuration}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onStop,
                child: const Text('Stop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TripCard({
    required this.trip,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d · HH:mm');

    return Dismissible(
      key: ValueKey(trip.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(Iconsax.trash, color: theme.colorScheme.error),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (trip.isActive)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'LIVE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        trip.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      trip.formattedDistance,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  trip.endAddress ??
                      trip.startAddress ??
                      'Route · ${trip.route.length} points',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${dateFmt.format(trip.startedAt)} · ${trip.formattedDuration}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onStart;
  const _EmptyState({required this.onStart});

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
              Iconsax.map,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              'No trips yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking to log distance,\ndestinations and routes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Iconsax.play),
              label: const Text('Start trip'),
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
