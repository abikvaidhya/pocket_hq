import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../providers/notes_provider.dart';
import '../../../services/voice_note_service.dart';
import 'voice_waveform.dart';

class VoiceRecordSheet extends ConsumerStatefulWidget {
  const VoiceRecordSheet({super.key});

  @override
  ConsumerState<VoiceRecordSheet> createState() => _VoiceRecordSheetState();
}

enum _Phase { record, name }

class _VoiceRecordSheetState extends ConsumerState<VoiceRecordSheet> {
  _Phase _phase = _Phase.record;
  bool _recording = false;
  bool _busy = false;
  String? _path;
  int _durationMs = 0;
  List<double> _peaks = [];
  Timer? _tick;
  Duration _elapsed = Duration.zero;

  final _nameCtrl = TextEditingController();
  String? _suggestion;
  bool _listeningName = false;

  @override
  void dispose() {
    _tick?.cancel();
    _nameCtrl.dispose();
    if (_recording) {
      VoiceNoteService.instance.cancelRecording();
    }
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_busy) return;
    setState(() => _busy = true);

    if (!_recording) {
      final ok = await VoiceNoteService.instance.startRecording();
      if (!ok) {
        setState(() => _busy = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
        return;
      }
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted) return;
        setState(() {
          _elapsed = VoiceNoteService.instance.elapsed;
          _peaks = List.from(VoiceNoteService.instance.peaks);
        });
      });
      setState(() {
        _recording = true;
        _busy = false;
        _elapsed = Duration.zero;
      });
    } else {
      _tick?.cancel();
      final result = await VoiceNoteService.instance.stopRecording();
      setState(() {
        _recording = false;
        _busy = false;
      });
      if (result == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      setState(() {
        _path = result.path;
        _durationMs = result.durationMs;
        _peaks = result.peaks;
        _phase = _Phase.name;
      });
      // Background suggestion via on-device speech (user can still type)
      _loadSuggestion();
    }
  }

  Future<void> _loadSuggestion() async {
    // Lightweight default from duration; speech suggestion optional on name phase
    final sec = _durationMs ~/ 1000;
    final fallback = sec < 15
        ? 'Quick voice note'
        : 'Voice note ${TimeOfDay.now().format(context)}';
    if (mounted) {
      setState(() {
        _suggestion = fallback;
        if (_nameCtrl.text.isEmpty) _nameCtrl.text = fallback;
      });
    }
  }

  Future<void> _suggestFromMic() async {
    setState(() => _listeningName = true);
    final s = await VoiceNoteService.instance.suggestNameFromSpeech();
    if (!mounted) return;
    setState(() {
      _listeningName = false;
      if (s != null) {
        _suggestion = s;
        _nameCtrl.text = s;
      }
    });
  }

  Future<void> _save() async {
    final path = _path;
    if (path == null) return;
    final title = _nameCtrl.text.trim().isEmpty
        ? (_suggestion ?? 'Voice note')
        : _nameCtrl.text.trim();

    await ref.read(notesProvider.notifier).addVoiceNote(
          title: title,
          audioPath: path,
          durationMs: _durationMs,
          waveformPeaks: _peaks,
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _cancel() async {
    if (_recording) {
      await VoiceNoteService.instance.cancelRecording();
    }
    if (mounted) Navigator.pop(context);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _phase == _Phase.record ? 'Record voice note' : 'Name this note',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          if (_phase == _Phase.record) ..._recordPhase(theme),
          if (_phase == _Phase.name) ..._namePhase(theme),
        ],
      ),
    );
  }

  List<Widget> _recordPhase(ThemeData theme) {
    return [
      VoiceWaveform(
        peaks: _peaks,
        progress: _recording ? 1 : 0,
        height: 56,
      ),
      const SizedBox(height: 16),
      Center(
        child: Text(
          _fmt(_elapsed),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          _recording ? 'Listening… tap stop when done' : 'Tap to start recording',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
      const SizedBox(height: 28),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : _cancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _busy ? null : _toggleRecord,
              icon: Icon(_recording ? Iconsax.stop : Iconsax.microphone),
              label: Text(_recording ? 'Stop' : 'Record'),
              style: _recording
                  ? FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                    )
                  : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _namePhase(ThemeData theme) {
    final durSec = _durationMs ~/ 1000;
    final m = (durSec ~/ 60).toString().padLeft(2, '0');
    final s = (durSec % 60).toString().padLeft(2, '0');

    return [
      VoiceWaveform(peaks: _peaks, progress: 1, height: 40),
      const SizedBox(height: 8),
      Text(
        'Duration $m:$s',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _nameCtrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: 'Name',
          hintText: 'e.g. Meeting idea',
          prefixIcon: const Icon(Iconsax.edit_2),
          suffixIcon: IconButton(
            tooltip: 'Dictate name',
            onPressed: _listeningName ? null : _suggestFromMic,
            icon: _listeningName
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Iconsax.microphone),
          ),
        ),
      ),
      if (_suggestion != null) ...[
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ActionChip(
            avatar: const Icon(Iconsax.magic_star, size: 16),
            label: Text('Use “$_suggestion”'),
            onPressed: () => setState(() => _nameCtrl.text = _suggestion!),
          ),
        ),
      ],
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Iconsax.tick_circle),
        label: const Text('Save voice note'),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _cancel,
        child: const Text('Discard'),
      ),
    ];
  }
}
