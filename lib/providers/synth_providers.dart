import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../data/factory_presets.dart';
import '../models/synth_preset.dart';

// ── Preset Library ──────────────────────────────────────
final presetListProvider =
    StateNotifierProvider<PresetListNotifier, List<SynthPreset>>((ref) {
  return PresetListNotifier();
});

class PresetListNotifier extends StateNotifier<List<SynthPreset>> {
  PresetListNotifier() : super([]) {
    _load();
  }

  Box? _box;

  Future<void> _load() async {
    _box = Hive.box('open_synth');
    final stored = _box?.get('presets') as List?;
    if (stored != null && stored.isNotEmpty) {
      state = stored
          .map((e) => SynthPreset.fromJson(
              Map<String, dynamic>.from(jsonDecode(e as String))))
          .toList();
    } else {
      state = List.from(factoryPresets);
      _save();
    }
  }

  void _save() {
    _box?.put('presets', state.map((p) => jsonEncode(p.toJson())).toList());
  }

  void addPreset(SynthPreset preset) {
    state = [...state, preset];
    _save();
  }

  void updatePreset(SynthPreset preset) {
    state = [
      for (final p in state)
        if (p.id == preset.id) preset else p,
    ];
    _save();
  }

  void deletePreset(String id) {
    // Don't delete factory presets
    if (id.startsWith('factory-')) return;
    state = state.where((p) => p.id != id).toList();
    _save();
  }

  void resetToFactory() {
    state = List.from(factoryPresets);
    _save();
  }
}

// ── Current Preset (being edited / played) ──────────────
final currentPresetProvider =
    StateNotifierProvider<CurrentPresetNotifier, SynthPreset>((ref) {
  return CurrentPresetNotifier();
});

class CurrentPresetNotifier extends StateNotifier<SynthPreset> {
  CurrentPresetNotifier() : super(factoryPresets.first);

  void load(SynthPreset preset) => state = preset;

  void update(SynthPreset Function(SynthPreset) updater) {
    state = updater(state);
  }
}

// ── Playback State ──────────────────────────────────────
final playbackStateProvider =
    StateNotifierProvider<PlaybackStateNotifier, Set<int>>((ref) {
  return PlaybackStateNotifier();
});

class PlaybackStateNotifier extends StateNotifier<Set<int>> {
  PlaybackStateNotifier() : super({});

  void noteOn(int midiNote) {
    state = {...state, midiNote};
  }

  void noteOff(int midiNote) {
    state = {...state}..remove(midiNote);
  }

  void allNotesOff() {
    state = {};
  }
}

// ── Keyboard Octave ─────────────────────────────────────
final keyboardOctaveProvider = StateProvider<int>((ref) => 4);

// ── Search Query ────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');
