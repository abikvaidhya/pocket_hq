import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/hive_boxes.dart';
import '../data/models/trip.dart';

class TripsState {
  final List<Trip> trips;
  final Trip? activeTrip;
  final bool tracking;
  final bool loading;
  final String? error;
  final Position? lastPosition;

  const TripsState({
    this.trips = const [],
    this.activeTrip,
    this.tracking = false,
    this.loading = false,
    this.error,
    this.lastPosition,
  });

  TripsState copyWith({
    List<Trip>? trips,
    Trip? activeTrip,
    bool clearActive = false,
    bool? tracking,
    bool? loading,
    String? error,
    Position? lastPosition,
  }) {
    return TripsState(
      trips: trips ?? this.trips,
      activeTrip: clearActive ? null : (activeTrip ?? this.activeTrip),
      tracking: tracking ?? this.tracking,
      loading: loading ?? this.loading,
      error: error,
      lastPosition: lastPosition ?? this.lastPosition,
    );
  }
}

final tripsProvider =
    StateNotifierProvider<TripsNotifier, TripsState>((ref) {
  return TripsNotifier()..load();
});

class TripsNotifier extends StateNotifier<TripsState> {
  TripsNotifier() : super(const TripsState());
  final Geocoding _geocoding = Geocoding();
  StreamSubscription<Position>? _sub;
  Box<Trip> get _box => Hive.box<Trip>(HiveBoxes.trips);

  void load() {
    final list = _box.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final activeList = list.where((t) => t.isActive).toList();
    final active = activeList.isEmpty ? null : activeList.first;
    state = state.copyWith(
      trips: list,
      activeTrip: active,
      tracking: active != null,
    );
  }

  Future<bool> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = state.copyWith(error: 'Location permission denied');
      return false;
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      state = state.copyWith(error: 'Location services are disabled');
      return false;
    }
    return true;
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      List<Placemark> places = await _geocoding.placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) return null;
      final p = places.first;
      final parts = [
        p.street,
        p.locality,
        p.administrativeArea,
      ].where((e) => e != null && e.trim().isNotEmpty).map((e) => e!.trim());
      final s = parts.join(', ');
      return s.isEmpty ? null : s;
    } catch (_) {
      return null;
    }
  }

  Future<void> startTrip({String? title}) async {
    state = state.copyWith(loading: true, error: null);
    if (!await _ensurePermission()) {
      state = state.copyWith(loading: false);
      return;
    }

    // End any existing active trip first
    if (state.activeTrip != null) {
      await stopTrip();
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final address = await _reverseGeocode(pos.latitude, pos.longitude);
    final trip = Trip(
      title: title ?? 'Trip ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      startedAt: DateTime.now(),
      startAddress: address,
      isActive: true,
      route: [
        TripPoint(
          lat: pos.latitude,
          lng: pos.longitude,
          timestamp: DateTime.now(),
        ),
      ],
    );

    await _box.put(trip.id, trip);
    load();
    state = state.copyWith(
      activeTrip: trip,
      tracking: true,
      loading: false,
      lastPosition: pos,
    );
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8, // meters
      ),
    ).listen((pos) async {
      final trip = state.activeTrip;
      if (trip == null || !trip.isActive) return;

      final last = trip.route.isNotEmpty ? trip.route.last : null;
      if (last != null) {
        final d = _haversineMeters(
          last.lat,
          last.lng,
          pos.latitude,
          pos.longitude,
        );
        // Ignore GPS noise
        if (d < 3) return;
        trip.distanceMeters += d;
      }

      trip.route = [
        ...trip.route,
        TripPoint(
          lat: pos.latitude,
          lng: pos.longitude,
          timestamp: DateTime.now(),
        ),
      ];
      await trip.save();
      load();
      state = state.copyWith(
        activeTrip: _box.get(trip.id),
        lastPosition: pos,
      );
    }, onError: (e) {
      state = state.copyWith(error: e.toString());
    });
  }

  Future<void> stopTrip() async {
    _sub?.cancel();
    _sub = null;

    final trip = state.activeTrip;
    if (trip == null) {
      state = state.copyWith(tracking: false, clearActive: true);
      return;
    }

    trip.isActive = false;
    trip.endedAt = DateTime.now();

    if (trip.route.isNotEmpty) {
      final last = trip.route.last;
      trip.endAddress = await _reverseGeocode(last.lat, last.lng);
    }

    await trip.save();
    load();
    state = state.copyWith(tracking: false, clearActive: true);
  }

  Future<void> deleteTrip(String id) async {
    if (state.activeTrip?.id == id) {
      await stopTrip();
    }
    await _box.delete(id);
    load();
  }

  Future<void> renameTrip(String id, String title) async {
    final trip = _box.get(id);
    if (trip == null) return;
    trip.title = title.trim().isEmpty ? trip.title : title.trim();
    await trip.save();
    load();
  }

  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _rad(double deg) => deg * math.pi / 180.0;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
