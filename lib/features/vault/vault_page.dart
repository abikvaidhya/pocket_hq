import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../data/models/vault_note.dart';
import '../../providers/vault_provider.dart';
import 'widgets/vault_editor_page.dart';

class VaultPage extends ConsumerStatefulWidget {
  const VaultPage({super.key});

  @override
  ConsumerState<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends ConsumerState<VaultPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Auto-lock when app goes to background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(vaultProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(vaultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () {
            ref.read(vaultProvider.notifier).lock();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (vault.unlocked)
            IconButton(
              onPressed: () => ref.read(vaultProvider.notifier).lock(),
              icon: const Icon(Iconsax.lock),
              tooltip: 'Lock',
            ),
          if (vault.unlocked)
            IconButton(
              onPressed: () => _openEditor(context),
              icon: const Icon(Iconsax.add),
              tooltip: 'New entry',
            ),
        ],
      ),
      body: vault.unlocked ? _UnlockedBody(notes: vault.notes) : const _LockGate(),
      floatingActionButton: vault.unlocked
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(context),
              icon: const Icon(Iconsax.add),
              label: const Text('New entry'),
            )
          : null,
    );
  }

  Future<void> _openEditor(BuildContext context, {VaultNote? note}) async {
    if (note == null) {
      note = await ref.read(vaultProvider.notifier).add();
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VaultEditorPage(noteId: note!.id),
      ),
    );
  }
}

class _LockGate extends ConsumerWidget {
  const _LockGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultProvider);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Iconsax.shield_tick,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Private Vault',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Journal and private notes are protected.\nAuthenticate to continue.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 28),
            if (vault.loading)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else ...[
              FilledButton.icon(
                onPressed: () => ref.read(vaultProvider.notifier).unlock(),
                icon: const Icon(Iconsax.finger_scan),
                label: const Text('Unlock with biometrics'),
              ),
              if (!vault.biometricsAvailable) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      ref.read(vaultProvider.notifier).unlockWithoutBiometrics(),
                  child: const Text('Continue without biometrics'),
                ),
              ],
            ],
            if (vault.error != null) ...[
              const SizedBox(height: 16),
              Text(
                vault.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UnlockedBody extends ConsumerWidget {
  final List<VaultNote> notes;
  const _UnlockedBody({required this.notes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.book_1,
                size: 56,
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 16),
              Text(
                'No private entries yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your vault is empty. Add a private note or journal entry.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dateFmt = DateFormat('MMM d, HH:mm');

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final note = notes[index];
        return Dismissible(
          key: ValueKey(note.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Iconsax.trash, color: theme.colorScheme.error),
          ),
          confirmDismiss: (_) async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete entry?'),
                content: Text('“${note.preview}” will be permanently removed.'),
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
              await ref.read(vaultProvider.notifier).delete(note.id);
            }
            return false;
          },
          child: Card(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VaultEditorPage(noteId: note.id),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (note.snippet.isNotEmpty && note.title.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note.snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
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
      },
    );
  }
}
