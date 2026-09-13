import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/models/note.dart';
import '../../../providers/notes_provider.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  final String noteId;
  const NoteEditorPage({super.key, required this.noteId});

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  Note? _note;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _load();
  }

  void _load() {
    final note = ref.read(notesProvider.notifier).getById(widget.noteId);
    _note = note;
    if (note != null) {
      _titleCtrl.text = note.title;
      _bodyCtrl.text = note.body;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save({bool pop = false}) async {
    final note = _note;
    if (note == null) return;

    note.title = _titleCtrl.text;
    note.body = _bodyCtrl.text;
    await ref.read(notesProvider.notifier).update(note);
    _dirty = false;

    if (pop && mounted) Navigator.of(context).pop();
  }

  Future<bool> _onWillPop() async {
    if (!_dirty) {
      // Delete empty new notes on back
      final note = _note;
      if (note != null && note.isEmpty) {
        await ref.read(notesProvider.notifier).delete(note.id);
      }
      return true;
    }
    await _save();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = _note;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _onWillPop();
        if (ok && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left),
            onPressed: () async {
              final ok = await _onWillPop();
              if (ok && context.mounted) Navigator.of(context).pop();
            },
          ),
          actions: [
            if (note != null)
              IconButton(
                onPressed: () async {
                  await ref.read(notesProvider.notifier).togglePin(note.id);
                  setState(() => _note = ref.read(notesProvider.notifier).getById(note.id));
                },
                icon: Icon(
                  note.isPinned ? Iconsax.attach_circle5 : Iconsax.attach_circle,
                  color: note.isPinned ? theme.colorScheme.primary : null,
                ),
                tooltip: note.isPinned ? 'Unpin' : 'Pin',
              ),
            IconButton(
              onPressed: () => _save(pop: false),
              icon: const Icon(Iconsax.tick_circle),
              tooltip: 'Save',
            ),
          ],
        ),
        body: note == null
            ? const Center(child: Text('Note not found'))
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => _dirty = true,
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: TextField(
                        controller: _bodyCtrl,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                        decoration: const InputDecoration(
                          hintText: 'Start writing…',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => _dirty = true,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
