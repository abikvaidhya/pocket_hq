import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class VoicePlaybackState {
  final String? noteId;
  final bool playing;
  final Duration position;
  final Duration duration;
  final String? error;

  const VoicePlaybackState({
    this.noteId,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  double get progress {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  VoicePlaybackState copyWith({
    String? noteId,
    bool clearNote = false,
    bool? playing,
    Duration? position,
    Duration? duration,
    String? error,
  }) {
    return VoicePlaybackState(
      noteId: clearNote ? null : (noteId ?? this.noteId),
      playing: playing ?? this.playing,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error,
    );
  }
}

final voicePlaybackProvider =
    StateNotifierProvider<VoicePlaybackNotifier, VoicePlaybackState>((ref) {
  final n = VoicePlaybackNotifier();
  ref.onDispose(n.dispose);
  return n;
});

class VoicePlaybackNotifier extends StateNotifier<VoicePlaybackState> {
  VoicePlaybackNotifier() : super(const VoicePlaybackState()) {
    _player.positionStream.listen((pos) {
      if (!mounted) return;
      state = state.copyWith(position: pos);
    });
    _player.playerStateStream.listen((ps) {
      if (!mounted) return;
      final playing = ps.playing;
      if (ps.processingState == ProcessingState.completed) {
        state = state.copyWith(
          playing: false,
          position: Duration.zero,
        );
        _player.seek(Duration.zero);
        _player.pause();
        return;
      }
      state = state.copyWith(playing: playing);
    });
    _player.durationStream.listen((d) {
      if (!mounted || d == null) return;
      state = state.copyWith(duration: d);
    });
  }

  final AudioPlayer _player = AudioPlayer();
  @override
  bool mounted = true;

  Future<void> toggle(String noteId, String path, {int? durationMs}) async {
    try {
      if (state.noteId == noteId) {
        if (state.playing) {
          await _player.pause();
        } else {
          await _player.play();
        }
        return;
      }

      await _player.stop();
      await _player.setFilePath(path);
      state = VoicePlaybackState(
        noteId: noteId,
        playing: false,
        position: Duration.zero,
        duration: durationMs != null
            ? Duration(milliseconds: durationMs)
            : Duration.zero,
      );
      await _player.play();
    } catch (e) {
      state = state.copyWith(error: e.toString(), playing: false);
    }
  }

  Future<void> seekFraction(double fraction) async {
    final d = state.duration;
    if (d.inMilliseconds <= 0) return;
    final target = Duration(
      milliseconds: (d.inMilliseconds * fraction.clamp(0.0, 1.0)).round(),
    );
    await _player.seek(target);
  }

  Future<void> stop() async {
    await _player.stop();
    state = const VoicePlaybackState();
  }

  @override
  void dispose() {
    mounted = false;
    _player.dispose();
    super.dispose();
  }
}
