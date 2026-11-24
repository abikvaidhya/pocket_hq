import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/note.dart';
import '../providers/carts_provider.dart';
import '../providers/notes_provider.dart';
import '../core/widget_sync_bus.dart';
import 'native_bridge.dart';

/// Pushes Notes and shopping-cart payloads to their Android home-screen widgets.
class WidgetSyncService {
  WidgetSyncService._();
  static final WidgetSyncService instance = WidgetSyncService._();

  Future<void> sync(
    WidgetRef ref, {
    Set<WidgetSyncSection> sections = const {WidgetSyncSection.all},
  }) async {
    final syncAll = sections.contains(WidgetSyncSection.all);
    final data = <String, dynamic>{};

    if (syncAll || sections.contains(WidgetSyncSection.notes)) {
      final notes = ref.read(notesProvider);
      data['notesJson'] = jsonEncode(_notesForWidget(notes));
    }
    if (syncAll || sections.contains(WidgetSyncSection.carts)) {
      final cart = ref.read(pinnedCartProvider);
      data['cartJson'] = jsonEncode(cart == null
          ? <String, dynamic>{}
          : {
              'id': cart.id,
              'title': 'To Get',
              'items': cart.sortedItems
                  .where((item) => !item.checked)
                  .map((item) => {
                        'id': item.id,
                        'name': item.name,
                        'checked': false,
                      })
                  .toList(),
            });
    }

    await NativeBridge.updateHomeWidget(data);
  }

  /// Apply cart checks made from the widget while the app was closed.
  Future<void> applyWidgetCartChecks(WidgetRef ref) async {
    final ids = await NativeBridge.drainWidgetCartChecks();
    for (final id in ids) {
      await ref.read(cartsProvider.notifier).toggleItemById(id);
    }
    if (ids.isNotEmpty) await sync(ref);
  }

  List<Map<String, dynamic>> _notesForWidget(List<Note> notes) {
    final pinned = notes.where((n) => n.isPinned).toList();
    final source = pinned.isNotEmpty ? pinned : notes;
    return source.take(8).map((n) {
      return {
        'id': n.id,
        'title': n.preview,
        'isVoice': n.isVoice,
        'audioPath': n.audioPath,
        'isPinned': n.isPinned,
        'durationLabel': n.isVoice ? n.formattedDuration : '',
      };
    }).toList();
  }
}
