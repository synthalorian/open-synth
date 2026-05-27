import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mod_matrix.dart';

/// The modulation matrix state.
final modMatrixProvider =
    StateNotifierProvider<ModMatrixNotifier, ModMatrix>((ref) {
  return ModMatrixNotifier();
});

class ModMatrixNotifier extends StateNotifier<ModMatrix> {
  ModMatrixNotifier() : super(ModMatrix());

  void load(ModMatrix matrix) => state = matrix;

  void updateSlot(int index, ModMatrixSlot Function(ModMatrixSlot) updater) {
    final slots = List<ModMatrixSlot>.from(state.slots);
    slots[index] = updater(slots[index]);
    state = state.copyWith(slots: slots);
  }

  void setSlotSource(int index, ModSource source) {
    updateSlot(index, (s) => s.copyWith(source: source));
  }

  void setSlotDestination(int index, ModDestination dest) {
    updateSlot(index, (s) => s.copyWith(destination: dest));
  }

  void setSlotAmount(int index, double amount) {
    updateSlot(index, (s) => s.copyWith(amount: amount));
  }

  void toggleSlot(int index) {
    updateSlot(index, (s) => s.copyWith(enabled: !s.enabled));
  }

  void clearSlot(int index) {
    updateSlot(
      index,
      (s) => const ModMatrixSlot(
        source: ModSource.lfo1,
        destination: ModDestination.pitch,
        amount: 0.0,
        enabled: false,
      ),
    );
  }

}

/// Live modulation source values (updated by MIDI, envelopes, etc.)
final modSourceValuesProvider = StateProvider<Map<ModSource, double>>((ref) {
  return {
    for (final s in ModSource.values) s: 0.0,
  };
});

/// Which mod-matrix slot is currently in CC-learn mode (-1 = none).
final modMatrixLearnModeProvider = StateProvider<int>((ref) => -1);

/// CC-learned assignments: CC number -> ModSource
final ccAssignmentsProvider =
    StateNotifierProvider<CcAssignmentsNotifier, Map<int, ModSource>>((ref) {
  return CcAssignmentsNotifier();
});

class CcAssignmentsNotifier extends StateNotifier<Map<int, ModSource>> {
  CcAssignmentsNotifier() : super({});

  void assign(int ccNumber, ModSource source) {
    state = {...state, ccNumber: source};
  }

  void remove(int ccNumber) {
    final updated = Map<int, ModSource>.from(state);
    updated.remove(ccNumber);
    state = updated;
  }

  void clear() => state = {};
}


