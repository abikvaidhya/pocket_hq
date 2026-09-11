import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/hive_boxes.dart';
import '../data/models/note.dart';

final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier();
});

final notesCountProvider = Provider<int>((ref) {
  return ref.watch(notesProvider).length;
});

class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier() : super([]) {
    _load();
  }

  Box<Note> get _box => Hive.box<Note>(HiveBoxes.notes);

  void _load() {
    final list = _box.values.toList();
    list.sort((a, b) {
      // Pinned first, then newest updated
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    state = list;
  }

  Future<Note> add({String title = '', String body = ''}) async {
    final note = Note(title: title, body: body);
    await _box.put(note.id, note);
    _load();
    return note;
  }

  Future<void> update(Note note) async {
    note.updatedAt = DateTime.now();
    await _box.put(note.id, note);
    _load();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _load();
  }

  Future<void> togglePin(String id) async {
    final note = _box.get(id);
    if (note == null) return;
    note.isPinned = !note.isPinned;
    note.updatedAt = DateTime.now();
    await note.save();
    _load();
  }

  Note? getById(String id) => _box.get(id);
}
