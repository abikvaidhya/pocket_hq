import '../services/native_bridge.dart';

// pushes summary data to native SharedPreferences for WorkManager + Glance.
class DigestSyncService {
  DigestSyncService._();
  static final DigestSyncService instance = DigestSyncService._();

  Future<void> sync({
    required int habitsPending,
    required int habitsTotal,
    required int notesCount,
    required int tripsToday,
    required String screenTimeFormatted,
  }) async {
    final summary = StringBuffer();
    if (habitsTotal > 0) {
      summary.write('$habitsPending/$habitsTotal habits left');
    } else {
      summary.write('No habits yet');
    }
    if (notesCount > 0) summary.write(' · $notesCount notes');
    if (tripsToday > 0) summary.write(' · $tripsToday trips');

    try {
      await NativeBridge.updateDigestData(
        habitsPending: habitsPending,
        notesCount: notesCount,
        tripsToday: tripsToday,
        summary: summary.toString(),
      );
    } catch (_) {}
  }
}
