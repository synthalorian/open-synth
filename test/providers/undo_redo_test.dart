import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_synth/providers/synth_providers.dart';
import 'package:open_synth/providers/undo_redo_provider.dart';

void main() {
  group('UndoRedoNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      // Eagerly create the notifier so its listeners are active before any state changes.
      container.read(undoRedoProvider);
    });

    tearDown(() {
      container.dispose();
    });

    UndoRedoNotifier getNotifier() =>
        container.read(undoRedoProvider.notifier);

    UndoRedoState getState() => container.read(undoRedoProvider);

    test('initial state has empty history and cannot undo/redo', () {
      final state = getState();
      expect(state.history, isEmpty);
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
    });

    test('save pushes current preset + mod matrix onto history', () {
      getNotifier().save();
      final state = getState();
      expect(state.history.length, 1);
      expect(state.currentIndex, 0);
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
    });

    test('undo restores previous state and redo restores it back', () {
      final preset = container.read(currentPresetProvider);

      // Push baseline
      getNotifier().save();

      // Change preset
      container
          .read(currentPresetProvider.notifier)
          .update((p) => p.copyWith(name: 'Changed'));
      getNotifier().save();

      expect(getState().history.length, 2);
      expect(getState().currentIndex, 1);
      expect(getState().canUndo, isTrue);

      // Undo
      getNotifier().undo();
      expect(container.read(currentPresetProvider).name, preset.name);
      expect(getState().currentIndex, 0);
      expect(getState().canRedo, isTrue);

      // Redo
      getNotifier().redo();
      expect(container.read(currentPresetProvider).name, 'Changed');
      expect(getState().currentIndex, 1);
      expect(getState().canRedo, isFalse);
    });

    test('multiple saves create multiple history entries', () {
      getNotifier().save();
      container
          .read(currentPresetProvider.notifier)
          .update((p) => p.copyWith(name: 'One'));
      getNotifier().save();
      container
          .read(currentPresetProvider.notifier)
          .update((p) => p.copyWith(name: 'Two'));
      getNotifier().save();

      expect(getState().history.length, 3);
      expect(getState().currentIndex, 2);
    });

    test('undo then new change drops redo branch', () {
      getNotifier().save();
      container
          .read(currentPresetProvider.notifier)
          .update((p) => p.copyWith(name: 'A'));
      getNotifier().save();
      container
          .read(currentPresetProvider.notifier)
          .update((p) => p.copyWith(name: 'B'));
      getNotifier().save();

      // Undo back to A
      getNotifier().undo();
      expect(getState().currentIndex, 1);

      // New change — should drop B
      container
          .read(currentPresetProvider.notifier)
          .update((p) => p.copyWith(name: 'C'));
      getNotifier().save();

      expect(getState().history.length, 3);
      expect(getState().currentIndex, 2);
      expect(getState().history.last.preset.name, 'C');
      expect(getState().canRedo, isFalse);
    });

    test('max history of 50 drops oldest entries', () {
      for (int i = 0; i < 55; i++) {
        container
            .read(currentPresetProvider.notifier)
            .update((p) => p.copyWith(name: 'V$i'));
        getNotifier().save();
      }

      expect(getState().history.length, 50);
      expect(getState().currentIndex, 49);
      // Oldest entry should have been dropped
      expect(getState().history.first.preset.name, 'V5');
    });

    test('duplicate guard prevents identical consecutive states', () {
      getNotifier().save();
      getNotifier().save();
      getNotifier().save();

      // No actual state change between saves, so only one entry
      expect(getState().history.length, 1);
    });

    test('undo and redo do not push to history', () {
      getNotifier().save();
      container
          .read(currentPresetProvider.notifier)
          .update((p) => p.copyWith(name: 'X'));
      getNotifier().save();

      // Undo should not create a new entry
      getNotifier().undo();
      expect(getState().history.length, 2);
      expect(getState().currentIndex, 0);

      // Redo should not create a new entry
      getNotifier().redo();
      expect(getState().history.length, 2);
      expect(getState().currentIndex, 1);
    });

    test('first change saves immediately, subsequent changes are debounced',
        () async {
      // First change — history is empty, so it saves immediately
      container
          .read(currentPresetProvider.notifier)
          .update((p) => p.copyWith(name: 'Immediate'));
      expect(getState().history.length, 1);
      expect(getState().history.last.preset.name, 'Immediate');

      // Second change — debounced because history is no longer empty
      container
          .read(currentPresetProvider.notifier)
          .update((p) => p.copyWith(name: 'Debounced'));
      expect(getState().history.length, 1); // still 1, debounce hasn't fired

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 700));

      expect(getState().history.length, 2);
      expect(getState().history.last.preset.name, 'Debounced');
    });
  });
}
