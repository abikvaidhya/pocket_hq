import '../services/native_bridge.dart';

/// Pushes summary data to native SharedPreferences for WorkManager + Glance.
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

    try {
      await NativeBridge.updateHomeWidget({
        'title': 'Pocket HQ',
        'subtitle': _todayLabel(),
        'habits': habitsTotal == 0
            ? '—'
            : '${habitsTotal - habitsPending}/$habitsTotal done',
        'screen': screenTimeFormatted,
      });
    } catch (_) {}
  }

  String _todayLabel() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final n = DateTime.now();
    return '${days[n.weekday - 1]}, ${months[n.month - 1]} ${n.day}';
  }
}
