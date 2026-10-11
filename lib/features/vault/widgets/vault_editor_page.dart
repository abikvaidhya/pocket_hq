import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/models/vault_note.dart';
import '../../../providers/vault_provider.dart';

class VaultEditorPage extends ConsumerStatefulWidget {
  final String noteId;
  const VaultEditorPage({super.key, required this.noteId});

  @override
  ConsumerState<VaultEditorPage> createState() => _VaultEditorPageState();
}

class _VaultEditorPageState extends ConsumerState<VaultEditorPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  VaultNote? _note;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _load();
  }

  void _load() {
    final note = ref.read(vaultProvider.notifier).getById(widget.noteId);
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

  Future<void> _save() async {
    final note = _note;
    if (note == null) return;
    note.title = _titleCtrl.text;
    note.body = _bodyCtrl.text;
    await ref.read(vaultProvider.notifier).update(note);
    _dirty = false;
  }

  Future<bool> _onWillPop() async {
    if (!_dirty) {
      final note = _note;
      if (note != null && note.isEmpty) {
        await ref.read(vaultProvider.notifier).delete(note.id);
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
          title: const Text('Private entry'),
          actions: [
            IconButton(
              onPressed: _save,
              icon: const Icon(Iconsax.tick_circle),
              tooltip: 'Save',
            ),
          ],
        ),
        body: note == null
            ? const Center(child: Text('Entry not found'))
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
                          hintText: 'Write privately…',
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
