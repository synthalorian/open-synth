import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mod_matrix.dart';
import '../models/synth_preset.dart';
import 'mod_matrix_provider.dart';
import 'synth_providers.dart';

/// Undo/redo manager for the core synth state (preset + modulation matrix).
///
/// Auto-saves after 600 ms of inactivity on [currentPresetProvider] or
/// [modMatrixProvider] changes. Discrete destructive actions should call
/// [save] explicitly so the pre-action state is captured before the change.
final undoRedoProvider =
    StateNotifierProvider<UndoRedoNotifier, UndoRedoState>((ref) {
  return UndoRedoNotifier(ref);
});

/// A single point in the undo history.
class UndoSnapshot {
  const UndoSnapshot({
    required this.preset,
    required this.modMatrix,
    this.createdAt,
    this.bookmarkName,
  });

  final SynthPreset preset;
  final ModMatrix modMatrix;
  final DateTime? createdAt;
  final String? bookmarkName;

  /// Robust value comparison using JSON so duplicate detection works
  /// even when model classes only implement identity equality.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UndoSnapshot) return false;
    return _jsonEq(preset.toJson(), other.preset.toJson()) &&
        _jsonEq(modMatrix.toJson(), other.modMatrix.toJson());
  }

  UndoSnapshot copyWith({
    SynthPreset? preset,
    ModMatrix? modMatrix,
    DateTime? createdAt,
    String? bookmarkName,
  }) {
    return UndoSnapshot(
      preset: preset ?? this.preset,
      modMatrix: modMatrix ?? this.modMatrix,
      createdAt: createdAt ?? this.createdAt,
      bookmarkName: bookmarkName ?? this.bookmarkName,
    );
  }

  @override
  int get hashCode => Object.hash(
        preset.name,
        preset.masterVolume,
        modMatrix.slots.length,
        bookmarkName,
      );

  static bool _jsonEq(dynamic a, dynamic b) {
    if (a.runtimeType != b.runtimeType) return false;
    if (a is Map) {
      if (a.length != (b as Map).length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_jsonEq(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List) {
      if (a.length != (b as List).length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_jsonEq(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }
}

/// Immutable undo/redo metadata.
class UndoRedoState {
  const UndoRedoState(this.history, this.currentIndex);

  final List<UndoSnapshot> history;
  final int currentIndex;

  bool get canUndo => currentIndex > 0;
  bool get canRedo => currentIndex < history.length - 1;

  UndoRedoState copyWith({
    List<UndoSnapshot>? history,
    int? currentIndex,
  }) {
    return UndoRedoState(
      history ?? this.history,
      currentIndex ?? this.currentIndex,
    );
  }
}

class UndoRedoNotifier extends StateNotifier<UndoRedoState> {
  UndoRedoNotifier(this._ref) : super(const UndoRedoState([], -1)) {
    _ref.listen<SynthPreset>(
      currentPresetProvider,
      (previous, next) => _onPresetChanged(previous, next),
    );
    _ref.listen<ModMatrix>(
      modMatrixProvider,
      (previous, next) => _onModMatrixChanged(previous, next),
    );
  }

  final Ref _ref;
  Timer? _debounceTimer;
  bool _suppressSave = false;

  void _onPresetChanged(SynthPreset? previous, SynthPreset next) {
    if (previous == null) return; // skip initial load
    _onStateChanged();
  }

  void _onModMatrixChanged(ModMatrix? previous, ModMatrix next) {
    if (previous == null) return; // skip initial load
    _onStateChanged();
  }

  void _onStateChanged() {
    if (_suppressSave) return;

    // Capture baseline immediately on first user change.
    if (state.history.isEmpty) {
      _pushState();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), _pushState);
  }

  /// Manually push the current state onto the undo stack.
  /// Does nothing if the current state is already the most recent entry.
  void save() {
    if (_suppressSave) return;
    _debounceTimer?.cancel();
    _pushState();
  }

  void _pushState() {
    final preset = _ref.read(currentPresetProvider);
    final modMatrix = _ref.read(modMatrixProvider);
    final snapshot = UndoSnapshot(
      preset: preset,
      modMatrix: modMatrix,
      createdAt: DateTime.now(),
    );

    // Don't push duplicates.
    if (state.currentIndex >= 0) {
      final current = state.history[state.currentIndex];
      if (current == snapshot) return;
    }

    // Trim any redo history if we're not at the tip.
    final newHistory = state.currentIndex < state.history.length - 1
        ? state.history.sublist(0, state.currentIndex + 1)
        : List<UndoSnapshot>.from(state.history);

    newHistory.add(snapshot);
    if (newHistory.length > 50) {
      newHistory.removeAt(0);
      // currentIndex stays the same because we removed from the front
      // and we're about to set it to newHistory.length - 1.
    }

    state = UndoRedoState(newHistory, newHistory.length - 1);
  }

  void undo() {
    if (!state.canUndo) return;
    _debounceTimer?.cancel();
    final targetIndex = state.currentIndex - 1;
    final snapshot = state.history[targetIndex];

    _suppressSave = true;
    _ref.read(currentPresetProvider.notifier).load(snapshot.preset);
    _ref.read(modMatrixProvider.notifier).load(snapshot.modMatrix);
    state = state.copyWith(currentIndex: targetIndex);
    _suppressSave = false;
  }

  void redo() {
    if (!state.canRedo) return;
    _debounceTimer?.cancel();
    final targetIndex = state.currentIndex + 1;
    final snapshot = state.history[targetIndex];

    _suppressSave = true;
    _ref.read(currentPresetProvider.notifier).load(snapshot.preset);
    _ref.read(modMatrixProvider.notifier).load(snapshot.modMatrix);
    state = state.copyWith(currentIndex: targetIndex);
    _suppressSave = false;
  }

  void bookmark(int index, String name) {
    if (index < 0 || index >= state.history.length) return;
    final newHistory = List<UndoSnapshot>.from(state.history);
    newHistory[index] = newHistory[index].copyWith(bookmarkName: name);
    state = UndoRedoState(newHistory, state.currentIndex);
  }

  void removeBookmark(int index) {
    if (index < 0 || index >= state.history.length) return;
    final newHistory = List<UndoSnapshot>.from(state.history);
    newHistory[index] = newHistory[index].copyWith(bookmarkName: null);
    state = UndoRedoState(newHistory, state.currentIndex);
  }

  void clear() {
    _debounceTimer?.cancel();
    state = const UndoRedoState([], -1);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
