import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'trip.g.dart';

@HiveType(typeId: 3)
class TripPoint {
  @HiveField(0)
  final double lat;

  @HiveField(1)
  final double lng;

  @HiveField(2)
  final DateTime timestamp;

  const TripPoint({
    required this.lat,
    required this.lng,
    required this.timestamp,
  });
}

@HiveType(typeId: 4)
class Trip extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late DateTime startedAt;

  @HiveField(3)
  DateTime? endedAt;

  @HiveField(4)
  late double distanceMeters;

  @HiveField(5)
  String? startAddress;

  @HiveField(6)
  String? endAddress;

  @HiveField(7)
  late List<TripPoint> route;

  @HiveField(8)
  late bool isActive;

  Trip({
    String? id,
    this.title = 'Trip',
    DateTime? startedAt,
    this.endedAt,
    this.distanceMeters = 0,
    this.startAddress,
    this.endAddress,
    List<TripPoint>? route,
    this.isActive = false,
  }) {
    this.id = id ?? const Uuid().v4();
    this.startedAt = startedAt ?? DateTime.now();
    this.route = route ?? [];
  }

  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }

  String get formattedDuration {
    final d = duration;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String get destinationLabel {
    if (endAddress != null && endAddress!.isNotEmpty) return endAddress!;
    if (startAddress != null && startAddress!.isNotEmpty) return startAddress!;
    return title;
  }
}
