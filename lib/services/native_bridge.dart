import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';

/// Central MethodChannel + EventChannel bridge to Kotlin/Compose native code.
class NativeBridge {
  NativeBridge._();

  static const MethodChannel _channel = MethodChannel(AppConstants.methodChannel);
  static const EventChannel _events = EventChannel(AppConstants.eventChannel);

  // ── Calendar ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTodayEvents() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getTodayEvents');
      return (result ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PlatformException catch (e) {
      throw NativeBridgeException('getTodayEvents failed: ${e.message}');
    }
  }

  // ── Usage / Screen Time ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getScreenTimeToday() async {
    try {
      final result = await _channel.invokeMethod<Map>('getScreenTimeToday');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      throw NativeBridgeException('getScreenTimeToday failed: ${e.message}');
    }
  }

  static Future<List<Map<String, dynamic>>> getAppUsageToday() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getAppUsageToday');
      return (result ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PlatformException catch (e) {
      throw NativeBridgeException('getAppUsageToday failed: ${e.message}');
    }
  }

  // ── Biometric ─────────────────────────────────────────────────────────────

  static Future<bool> authenticate({String reason = 'Unlock Vault'}) async {
    try {
      final result = await _channel.invokeMethod<bool>('authenticate', {
        'reason': reason,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> canAuthenticate() async {
    try {
      final result = await _channel.invokeMethod<bool>('canAuthenticate');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ── WorkManager / Daily Digest ────────────────────────────────────────────

  static Future<void> scheduleDailyDigest({required int hour, required int minute}) async {
    try {
      await _channel.invokeMethod('scheduleDailyDigest', {
        'hour': hour,
        'minute': minute,
      });
    } on PlatformException catch (e) {
      throw NativeBridgeException('scheduleDailyDigest failed: ${e.message}');
    }
  }

  static Future<void> cancelDailyDigest() async {
    try {
      await _channel.invokeMethod('cancelDailyDigest');
    } on PlatformException catch (e) {
      throw NativeBridgeException('cancelDailyDigest failed: ${e.message}');
    }
  }

  // ── Glance Widgets ────────────────────────────────────────────────────────

  static Future<void> updateHomeWidget(Map<String, dynamic> data) async {
    try {
      await _channel.invokeMethod('updateHomeWidget', data);
    } on PlatformException catch (e) {
      throw NativeBridgeException('updateHomeWidget failed: ${e.message}');
    }
  }

  // ── Event stream (optional) ───────────────────────────────────────────────

  static Stream<dynamic> get eventStream => _events.receiveBroadcastStream();
}

class NativeBridgeException implements Exception {
  final String message;
  NativeBridgeException(this.message);

  @override
  String toString() => 'NativeBridgeException: $message';
}
