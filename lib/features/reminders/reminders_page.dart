import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../data/models/reminder.dart';
import '../../providers/reminders_provider.dart';
import '../../services/reminder_parser.dart';

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _listening = false;
  String _liveText = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _speech.initialize(
        onError: (e) {
          if (mounted) {
            setState(() {
              _listening = false;
              _error = e.errorMsg;
            });
          }
        },
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            if (mounted) setState(() => _listening = false);
          }
        },
      );
      if (mounted) setState(() => _speechReady = ok);
    } catch (_) {
      if (mounted) setState(() => _speechReady = false);
    }
  }

  Future<void> _startListen() async {
    setState(() {
      _error = null;
      _liveText = '';
      _listening = true;
    });
    HapticFeedback.mediumImpact();
    if (!_speechReady) {
      await _initSpeech();
      if (!_speechReady) {
        setState(() {
          _listening = false;
          _error = 'Microphone or speech not available.';
        });
        return;
      }
    }
    await _speech.listen(
      onResult: (r) {
        setState(() => _liveText = r.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> _stopListenAndSave() async {
    HapticFeedback.lightImpact();
    await _speech.stop();
    setState(() => _listening = false);
    final text = _liveText.trim();
    if (text.isEmpty) {
      setState(() => _error = 'No speech heard. Try again or type it.');
      return;
    }
    await _commitText(text);
  }

  Future<void> _commitText(String text) async {
    try {
      final reminder =
          await ref.read(remindersProvider.notifier).addFromText(text);
      if (!mounted) return;
      setState(() {
        _liveText = '';
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${reminder.kindLabel}: "${reminder.label}" · ${_fmt(reminder.triggerAt)}',
          ),
        ),
      );
    } on ReminderParseException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not save: $e');
    }
  }

  Future<void> _showTypeSheet() async {
    final labelCtrl = TextEditingController();
    final phraseCtrl = TextEditingController();
    Duration duration = const Duration(minutes: 15);
    var mode = _TypeMode.quick;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add reminder',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<_TypeMode>(
                    segments: const [
                      ButtonSegment(
                        value: _TypeMode.quick,
                        label: Text('Quick timer'),
                        icon: Icon(Iconsax.timer_1, size: 16),
                      ),
                      ButtonSegment(
                        value: _TypeMode.phrase,
                        label: Text('Phrase'),
                        icon: Icon(Iconsax.text, size: 16),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) => setModal(() => mode = s.first),
                  ),
                  const SizedBox(height: 16),
                  if (mode == _TypeMode.quick) ...[
                    TextField(
                      controller: labelCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Label (optional)',
                        hintText: 'Turn off stove',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Remind in', style: Theme.of(ctx).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final d in const [
                          Duration(minutes: 5),
                          Duration(minutes: 10),
                          Duration(minutes: 15),
                          Duration(minutes: 30),
                          Duration(hours: 1),
                          Duration(hours: 2),
                        ])
                          ChoiceChip(
                            label: Text(_durLabel(d)),
                            selected: duration == d,
                            onSelected: (_) => setModal(() => duration = d),
                          ),
                      ],
                    ),
                  ] else ...[
                    TextField(
                      controller: phraseCtrl,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Say it in text',
                        hintText: 'Remind me to call mom tomorrow at 6 PM',
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Set'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (ok != true) return;

    if (mode == _TypeMode.quick) {
      final label =
          labelCtrl.text.trim().isEmpty ? 'Reminder' : labelCtrl.text.trim();
      final when = DateTime.now().add(duration);
      await ref.read(remindersProvider.notifier).addManual(
            label: label,
            triggerAt: when,
            kind: 'timer',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Timer: "$label" · ${_fmt(when)}')),
      );
    } else {
      final phrase = phraseCtrl.text.trim();
      if (phrase.isEmpty) return;
      await _commitText(phrase);
    }
  }

  static String _durLabel(Duration d) {
    if (d.inHours >= 1 && d.inMinutes % 60 == 0) return '${d.inHours}h';
    return '${d.inMinutes}m';
  }

  String _fmt(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final time = DateFormat('h:mm a').format(dt);
    if (day == today) return 'today $time';
    if (day == today.add(const Duration(days: 1))) return 'tomorrow $time';
    return DateFormat('EEE, MMM d · h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reminders = ref.watch(remindersProvider);
    final active = reminders.where((r) => !r.completed).toList()
      ..sort((a, b) => a.triggerAt.compareTo(b.triggerAt));
    final done = reminders.where((r) => r.completed).toList()
      ..sort((a, b) => b.triggerAt.compareTo(a.triggerAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick reminders'),
        actions: [
          IconButton(
            tooltip: 'Type a reminder',
            onPressed: _showTypeSheet,
            icon: const Icon(Iconsax.edit),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _listening
                          ? 'Listening… release to set'
                          : 'Hold to speak a reminder',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'e.g. "remind me to turn off the stove in 10 minutes"',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onLongPressStart: (_) => _startListen(),
                      onLongPressEnd: (_) => _stopListenAndSave(),
                      onLongPressCancel: () async {
                        await _speech.cancel();
                        setState(() {
                          _listening = false;
                          _liveText = '';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: _listening ? 88 : 72,
                        height: _listening ? 88 : 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _listening
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: (_listening
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary)
                                  .withValues(alpha: 0.35),
                              blurRadius: _listening ? 24 : 12,
                              spreadRadius: _listening ? 4 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _listening ? Iconsax.microphone_2 : Iconsax.microphone,
                          color: theme.colorScheme.onPrimary,
                          size: 32,
                        ),
                      ),
                    ),
                    if (_liveText.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _liveText,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showTypeSheet,
                      icon: const Icon(Iconsax.keyboard, size: 18),
                      label: const Text('Type instead'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: active.isEmpty && done.isEmpty
                ? Center(
                    child: Text(
                      'No reminders yet.\nHold the mic or type one.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.45),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      if (active.isNotEmpty) ...[
                        Text(
                          'UPCOMING',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...active.map(
                          (r) => _ReminderTile(
                            reminder: r,
                            timeLabel: _fmt(r.triggerAt),
                            onDone: () => ref
                                .read(remindersProvider.notifier)
                                .complete(r.id),
                            onDelete: () => ref
                                .read(remindersProvider.notifier)
                                .delete(r.id),
                          ),
                        ),
                      ],
                      if (done.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'DONE',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...done.take(10).map(
                              (r) => _ReminderTile(
                                reminder: r,
                                timeLabel: _fmt(r.triggerAt),
                                done: true,
                                onDone: null,
                                onDelete: () => ref
                                    .read(remindersProvider.notifier)
                                    .delete(r.id),
                              ),
                            ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

enum _TypeMode { quick, phrase }

class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final String timeLabel;
  final bool done;
  final VoidCallback? onDone;
  final VoidCallback onDelete;

  const _ReminderTile({
    required this.reminder,
    required this.timeLabel,
    this.done = false,
    required this.onDone,
    required this.onDelete,
  });

  IconData get _icon {
    switch (reminder.kind) {
      case 'timer':
        return Iconsax.timer_1;
      case 'alarm':
        return Iconsax.alarm;
      default:
        return Iconsax.notification;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Iconsax.trash, color: theme.colorScheme.error),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Icon(
            _icon,
            color: done
                ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
                : theme.colorScheme.primary,
          ),
          title: Text(
            reminder.label,
            style: theme.textTheme.titleSmall?.copyWith(
              decoration: done ? TextDecoration.lineThrough : null,
              color: done
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : null,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${reminder.kindLabel} · $timeLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          trailing: done
              ? null
              : IconButton(
                  tooltip: 'Mark done',
                  onPressed: onDone,
                  icon: const Icon(Iconsax.tick_circle),
                ),
        ),
      ),
    );
  }
}
