import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// mic permission, recording, amplitude peaks, and name suggestions.
class VoiceNoteService {
  VoiceNoteService._();
  static final VoiceNoteService instance = VoiceNoteService._();

  final AudioRecorder _recorder = AudioRecorder();
  final stt.SpeechToText _speech = stt.SpeechToText();

  StreamSubscription<Amplitude>? _ampSub;
  final List<double> _peaks = [];
  DateTime? _startedAt;
  String? _path;

  bool get isRecording => _startedAt != null;

  List<double> get peaks => List.unmodifiable(_peaks);

  Duration get elapsed {
    if (_startedAt == null) return Duration.zero;
    return DateTime.now().difference(_startedAt!);
  }

  Future<bool> ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> startRecording() async {
    final ok = await ensureMicPermission();
    if (!ok) return false;

    final has = await _recorder.hasPermission();
    if (!has) return false;

    final dir = await getApplicationDocumentsDirectory();
    final voiceDir = Directory('${dir.path}/voice_notes');
    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }

    final filePath =
        '${voiceDir.path}/vn_${DateTime.now().millisecondsSinceEpoch}.m4a';

    _peaks.clear();
    _path = filePath;
    _startedAt = DateTime.now();

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    _ampSub?.cancel();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((amp) {
      // normalize audio dBFS (~ -45..0) to 0..1
      final db = amp.current;
      final norm = ((db + 45) / 45).clamp(0.05, 1.0);
      _peaks.add(norm);
      // Cap stored peaks for Hive size
      if (_peaks.length > 200) {
        final step = (_peaks.length / 150).ceil();
        final reduced = <double>[];
        for (var i = 0; i < _peaks.length; i += step) {
          reduced.add(_peaks[i]);
        }
        _peaks
          ..clear()
          ..addAll(reduced);
      }
    });

    return true;
  }

  // stops recording. Returns path, durationMs, peaks.
  Future<({String path, int durationMs, List<double> peaks})?> stopRecording() async {
    await _ampSub?.cancel();
    _ampSub = null;

    final path = await _recorder.stop();
    final started = _startedAt;
    _startedAt = null;

    final resolved = path ?? _path;
    if (resolved == null || started == null) return null;

    final durationMs = DateTime.now().difference(started).inMilliseconds;
    final peaks = _downsample(_peaks, 48);

    return (path: resolved, durationMs: durationMs, peaks: peaks);
  }

  Future<void> cancelRecording() async {
    await _ampSub?.cancel();
    _ampSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    final p = _path;
    _path = null;
    _startedAt = null;
    _peaks.clear();
    if (p != null) {
      final f = File(p);
      if (await f.exists()) await f.delete();
    }
  }

  // Suggest a short title from on-device speech recognition (practical stand-in
  // for a TFLite audio classifier until a custom model is shipped).
  Future<String?> suggestNameFromSpeech({
    Duration listenFor = const Duration(seconds: 6),
  }) async {
    try {
      final available = await _speech.initialize();
      if (!available) return null;

      final completer = Completer<String?>();
      await _speech.listen(
        listenFor: listenFor,
        pauseFor: const Duration(seconds: 2),
        partialResults: false,
        onResult: (result) {
          if (result.finalResult && !completer.isCompleted) {
            completer.complete(result.recognizedWords);
          }
        },
      );

      final words = await completer.future.timeout(
        listenFor + const Duration(seconds: 2),
        onTimeout: () => null,
      );
      await _speech.stop();

      if (words == null || words.trim().isEmpty) return null;
      return _titleFromTranscript(words);
    } catch (_) {
      try {
        await _speech.stop();
      } catch (_) {}
      return null;
    }
  }

  // Build a title from a known transcript (e.g. after dictation for the name field).
  static String titleFromTranscript(String transcript) =>
      _titleFromTranscript(transcript);

  static String _titleFromTranscript(String transcript) {
    final cleaned = transcript.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return 'Voice note';
    final words = cleaned.split(' ');
    final take = words.take(6).join(' ');
    if (take.length <= 40) {
      return take[0].toUpperCase() + take.substring(1);
    }
    return '${take.substring(0, 37)}…';
  }

  static List<double> _downsample(List<double> src, int target) {
    if (src.isEmpty) {
      return List.generate(target, (i) => 0.15 + 0.1 * math.sin(i / 3));
    }
    if (src.length <= target) return List<double>.from(src);
    final out = <double>[];
    final bucket = src.length / target;
    for (var i = 0; i < target; i++) {
      final start = (i * bucket).floor();
      final end = math.min(((i + 1) * bucket).floor(), src.length);
      var maxV = 0.0;
      for (var j = start; j < end; j++) {
        if (src[j] > maxV) maxV = src[j];
      }
      out.add(maxV.clamp(0.08, 1.0));
    }
    return out;
  }

  Future<void> deleteFile(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
