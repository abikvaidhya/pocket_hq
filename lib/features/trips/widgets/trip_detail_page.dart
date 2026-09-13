import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/hive_boxes.dart';
import '../../../data/models/trip.dart';
import '../../../providers/trips_provider.dart';

class TripDetailPage extends ConsumerStatefulWidget {
  final String tripId;
  const TripDetailPage({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends ConsumerState<TripDetailPage> {
  final _titleCtrl = TextEditingController();

  Trip? get _trip {
    final box = Hive.box<Trip>(HiveBoxes.trips);
    return box.get(widget.tripId);
  }

  @override
  void initState() {
    super.initState();
    final t = _trip;
    if (t != null) _titleCtrl.text = t.title;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when trips change
    ref.watch(tripsProvider);
    final trip = _trip;
    final theme = Theme.of(context);
    final dateFmt = DateFormat('EEE, MMM d · HH:mm');

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip')),
        body: const Center(child: Text('Trip not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.isActive ? 'Live trip' : 'Trip details'),
        actions: [
          if (trip.isActive)
            TextButton(
              onPressed: () => ref.read(tripsProvider.notifier).stopTrip(),
              child: Text(
                'Stop',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleCtrl,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Trip name',
                    ),
                    onSubmitted: (v) {
                      ref.read(tripsProvider.notifier).renameTrip(trip.id, v);
                    },
                    onEditingComplete: () {
                      ref
                          .read(tripsProvider.notifier)
                          .renameTrip(trip.id, _titleCtrl.text);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Stat(
                        icon: Iconsax.routing_2,
                        label: 'Distance',
                        value: trip.formattedDistance,
                      ),
                      const SizedBox(width: 12),
                      _Stat(
                        icon: Iconsax.clock,
                        label: 'Duration',
                        value: trip.formattedDuration,
                      ),
                      const SizedBox(width: 12),
                      _Stat(
                        icon: Iconsax.location,
                        label: 'Points',
                        value: '${trip.route.length}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Route',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AddressRow(
                    icon: Iconsax.flag,
                    label: 'Start',
                    value: trip.startAddress ??
                        (trip.route.isNotEmpty
                            ? '${trip.route.first.lat.toStringAsFixed(5)}, ${trip.route.first.lng.toStringAsFixed(5)}'
                            : '—'),
                    time: dateFmt.format(trip.startedAt),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 11),
                    child: Container(
                      width: 2,
                      height: 20,
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  _AddressRow(
                    icon: Iconsax.location,
                    label: trip.isActive ? 'Current' : 'End',
                    value: trip.endAddress ??
                        (trip.route.isNotEmpty
                            ? '${trip.route.last.lat.toStringAsFixed(5)}, ${trip.route.last.lng.toStringAsFixed(5)}'
                            : '—'),
                    time: trip.endedAt != null
                        ? dateFmt.format(trip.endedAt!)
                        : (trip.isActive ? 'Live' : '—'),
                  ),
                ],
              ),
            ),
          ),
          if (trip.route.length > 2) ...[
            const SizedBox(height: 16),
            Text(
              'Track points',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trip.route.length.clamp(0, 30),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = trip.route[i];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      '${p.lat.toStringAsFixed(5)}, ${p.lng.toStringAsFixed(5)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Text(
                      DateFormat('HH:mm:ss').format(p.timestamp),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (trip.route.length > 30)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Showing first 30 of ${trip.route.length} points',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String time;

  const _AddressRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                time,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
