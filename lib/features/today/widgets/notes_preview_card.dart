import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/router/app_router.dart';
import '../../../providers/notes_provider.dart';

class NotesPreviewCard extends ConsumerWidget {
  const NotesPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notes = ref.watch(notesProvider);
    final preview = notes.take(2).toList();

    return Card(
      child: InkWell(
        onTap: () => AppRouter.push(context, AppRoutes.notes),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Iconsax.note_1, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quick Notes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (notes.isNotEmpty)
                    Text(
                      '${notes.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (notes.isEmpty)
                Text(
                  'No notes yet. Tap to capture one.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                )
              else
                ...preview.map((n) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        if (n.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Iconsax.attach_circle5,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            n.preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
