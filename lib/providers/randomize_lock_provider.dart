import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Which parameter groups are locked during randomization.
/// When a group is locked, randomize/generative functions skip it.
enum LockableParam {
  osc1,
  osc2,
  unison,
  filter,
  ampEnvelope,
  filterEnvelope,
  lfo1,
  lfo2,
  chorus,
  delay,
  reverb,
  phaser,
  flanger,
  compressor,
  drive,
  masterVolume,
  modMatrix,
  sequencer,
}

final randomizeLockProvider =
    StateNotifierProvider<RandomizeLockNotifier, Set<LockableParam>>((ref) {
  return RandomizeLockNotifier();
});

class RandomizeLockNotifier extends StateNotifier<Set<LockableParam>> {
  RandomizeLockNotifier() : super({}) {
    _load();
  }

  Box? _box;

  Future<void> _load() async {
    _box = Hive.box('open_synth');
    final stored = _box?.get('randomizeLocks');
    if (stored != null) {
      try {
        final list = (jsonDecode(stored as String) as List).cast<int>();
        state = list.map((i) => LockableParam.values[i]).toSet();
      } catch (_) {
        // Fall back to empty
      }
    }
  }

  void _save() {
    final json = jsonEncode(state.map((e) => e.index).toList());
    _box?.put('randomizeLocks', json);
  }

  void toggle(LockableParam param) {
    final newState = Set<LockableParam>.from(state);
    if (newState.contains(param)) {
      newState.remove(param);
    } else {
      newState.add(param);
    }
    state = newState;
    _save();
  }

  void setLocked(LockableParam param, bool locked) {
    final newState = Set<LockableParam>.from(state);
    if (locked) {
      newState.add(param);
    } else {
      newState.remove(param);
    }
    state = newState;
    _save();
  }

  bool isLocked(LockableParam param) => state.contains(param);

  void resetAll() {
    state = {};
    _save();
  }
}
