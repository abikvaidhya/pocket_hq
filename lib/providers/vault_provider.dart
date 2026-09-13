import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/hive_boxes.dart';
import '../data/models/vault_note.dart';
import '../services/biometric_service.dart';

class VaultState {
  final bool unlocked;
  final bool loading;
  final bool biometricsAvailable;
  final List<VaultNote> notes;
  final String? error;

  const VaultState({
    this.unlocked = false,
    this.loading = false,
    this.biometricsAvailable = false,
    this.notes = const [],
    this.error,
  });

  VaultState copyWith({
    bool? unlocked,
    bool? loading,
    bool? biometricsAvailable,
    List<VaultNote>? notes,
    String? error,
  }) {
    return VaultState(
      unlocked: unlocked ?? this.unlocked,
      loading: loading ?? this.loading,
      biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
      notes: notes ?? this.notes,
      error: error,
    );
  }
}

final vaultProvider =
    StateNotifierProvider<VaultNotifier, VaultState>((ref) {
  return VaultNotifier()..init();
});

class VaultNotifier extends StateNotifier<VaultState> {
  VaultNotifier() : super(const VaultState());

  Box<VaultNote> get _box => Hive.box<VaultNote>(HiveBoxes.vaultNotes);

  Future<void> init() async {
    final available = await BiometricService.instance.canCheckBiometrics;
    state = state.copyWith(biometricsAvailable: available);
    // Stay locked by default
  }

  Future<bool> unlock() async {
    state = state.copyWith(loading: true, error: null);
    final ok = await BiometricService.instance.authenticate(
      reason: 'Authenticate to open Vault',
    );
    if (!ok) {
      state = state.copyWith(
        loading: false,
        unlocked: false,
        error: 'Authentication failed or cancelled',
      );
      return false;
    }
    _loadNotes();
    state = state.copyWith(loading: false, unlocked: true, error: null);
    return true;
  }

  /// Soft unlock for devices without biometrics (dev / fallback).
  /// Still requires explicit user action.
  Future<void> unlockWithoutBiometrics() async {
    _loadNotes();
    state = state.copyWith(unlocked: true, loading: false, error: null);
  }

  void lock() {
    state = state.copyWith(unlocked: false, notes: []);
  }

  void _loadNotes() {
    final list = _box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = state.copyWith(notes: list);
  }

  Future<VaultNote> add({String title = '', String body = ''}) async {
    final note = VaultNote(title: title, body: body);
    await _box.put(note.id, note);
    _loadNotes();
    return note;
  }

  Future<void> update(VaultNote note) async {
    note.updatedAt = DateTime.now();
    await _box.put(note.id, note);
    _loadNotes();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _loadNotes();
  }

  VaultNote? getById(String id) => _box.get(id);
}
