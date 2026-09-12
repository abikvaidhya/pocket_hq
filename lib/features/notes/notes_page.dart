import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../data/models/note.dart';
import '../../providers/notes_provider.dart';
import 'widgets/note_editor_page.dart';

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
            onPressed: () => _openEditor(context, ref),
            icon: const Icon(Iconsax.add),
            tooltip: 'New note',
          ),
        ],
      ),
      body: notes.isEmpty
          ? _EmptyState(onAdd: () => _openEditor(context, ref))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              physics: const BouncingScrollPhysics(),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final note = notes[index];
                return _NoteCard(
                  note: note,
                  onTap: () => _openEditor(context, ref, note: note),
                  onPin: () =>
                      ref.read(notesProvider.notifier).togglePin(note.id),
                  onDelete: () => _confirmDelete(context, ref, note),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Iconsax.add),
        label: const Text('New note'),
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 3),
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
        title: const Text('Delete note?'),
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
      await ref.read(notesProvider.notifier).delete(note.id);
    }
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _NoteCard({
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
                        note.isPinned ? Iconsax.attach_circle5 : Iconsax.attach_circle,
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
              'Capture ideas, lists, and quick thoughts.',
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
