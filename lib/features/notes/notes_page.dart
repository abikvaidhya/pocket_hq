import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../data/models/note.dart';
import '../../providers/notes_provider.dart';
import '../../providers/voice_playback_provider.dart';
import 'widgets/note_editor_page.dart';
import 'widgets/voice_record_sheet.dart';
import 'widgets/voice_waveform.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            onPressed: () => _showCreateMenu(context, ref),
            icon: const Icon(Iconsax.add),
            tooltip: 'New note',
          ),
        ],
      ),
      body: notes.isEmpty
          ? _EmptyState(onAdd: () => _showCreateMenu(context, ref))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              physics: const BouncingScrollPhysics(),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final note = notes[index];
                if (note.isVoice) {
                  return _VoiceNoteCard(
                    note: note,
                    onPin: () =>
                        ref.read(notesProvider.notifier).togglePin(note.id),
                    onDelete: () => _confirmDelete(context, ref, note),
                  );
                }
                return _TextNoteCard(
                  note: note,
                  onTap: () => _openEditor(context, ref, note: note),
                  onPin: () =>
                      ref.read(notesProvider.notifier).togglePin(note.id),
                  onDelete: () => _confirmDelete(context, ref, note),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateMenu(context, ref),
        icon: const Icon(Iconsax.add),
        label: const Text('New note'),
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 3),
    );
  }

  void _showCreateMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Iconsax.note_1, color: theme.colorScheme.primary),
                title: const Text('Text note'),
                subtitle: const Text('Write a quick note'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openEditor(context, ref);
                },
              ),
              ListTile(
                leading: Icon(Iconsax.microphone, color: theme.colorScheme.primary),
                title: const Text('Voice note'),
                subtitle: const Text('Record and save audio'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openVoiceRecorder(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openVoiceRecorder(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceRecordSheet(),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    Note? note,
  }) async {
    note ??= await ref.read(notesProvider.notifier).add();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(noteId: note!.id),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(note.isVoice ? 'Delete voice note?' : 'Delete note?'),
        content: Text(
          note.preview.isEmpty
              ? 'This note will be permanently deleted.'
              : '“${note.preview}” will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final playback = ref.read(voicePlaybackProvider);
      if (playback.noteId == note.id) {
        await ref.read(voicePlaybackProvider.notifier).stop();
      }
      await ref.read(notesProvider.notifier).delete(note.id);
    }
  }
}

class _VoiceNoteCard extends ConsumerWidget {
  final Note note;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _VoiceNoteCard({
    required this.note,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, HH:mm');
    final playback = ref.watch(voicePlaybackProvider);
    final isFocused = playback.noteId == note.id;
    final isPlaying = isFocused && playback.playing;
    final progress = isFocused ? playback.progress : 0.0;
    final peaks = note.waveformPeaks ?? const <double>[];

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Iconsax.trash, color: theme.colorScheme.error),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isPinned) ...[
                    Icon(
                      Iconsax.attach_circle5,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    Iconsax.microphone,
                    size: 16,
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onPin,
                    icon: Icon(
                      note.isPinned
                          ? Iconsax.attach_circle5
                          : Iconsax.attach_circle,
                      size: 20,
                      color: note.isPinned
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: note.audioPath == null
                        ? null
                        : () => ref.read(voicePlaybackProvider.notifier).toggle(
                              note.id,
                              note.audioPath!,
                              durationMs: note.durationMs,
                            ),
                    icon: Icon(isPlaying ? Iconsax.pause : Iconsax.play),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: VoiceWaveform(
                      peaks: peaks,
                      progress: progress,
                      interactive: isFocused,
                      onSeek: isFocused
                          ? (f) => ref
                              .read(voicePlaybackProvider.notifier)
                              .seekFraction(f)
                          : null,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isFocused && playback.duration.inMilliseconds > 0
                        ? _fmt(playback.position)
                        : note.formattedDuration,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                dateFmt.format(note.updatedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _TextNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _TextNoteCard({
    required this.note,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, HH:mm');

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Iconsax.trash, color: theme.colorScheme.error),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (note.isPinned) ...[
                      Icon(
                        Iconsax.attach_circle5,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        note.preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onPin,
                      icon: Icon(
                        note.isPinned
                            ? Iconsax.attach_circle5
                            : Iconsax.attach_circle,
                        size: 20,
                        color: note.isPinned
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (note.snippet.isNotEmpty && note.title.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    note.snippet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  dateFmt.format(note.updatedAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.note_1,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No notes yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture text or voice notes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Iconsax.add),
              label: const Text('New note'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        final routes = [
          AppRoutes.today,
          AppRoutes.habits,
          AppRoutes.focus,
          AppRoutes.notes,
          AppRoutes.trips,
        ];
        if (index != currentIndex) {
          AppRouter.pushReplacement(context, routes[index]);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Iconsax.home),
          selectedIcon: Icon(Iconsax.home_1),
          label: 'Today',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.task_square),
          selectedIcon: Icon(Iconsax.task_square5),
          label: 'Habits',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.chart_2),
          selectedIcon: Icon(Iconsax.chart_21),
          label: 'Focus',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.note_1),
          selectedIcon: Icon(Iconsax.note_15),
          label: 'Notes',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.map),
          selectedIcon: Icon(Iconsax.map5),
          label: 'Trips',
        ),
      ],
    );
  }
}
