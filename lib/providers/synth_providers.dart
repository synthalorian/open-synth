import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../data/factory_presets.dart';
import '../ffi/openamp_audio_stream.dart';
import '../ffi/openamp_synth.dart';
import '../models/synth_preset.dart';
import '../services/preset_loader.dart';

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

// ── Native synth engine ─────────────────────────────────
/// Backing native SynthEngine, lazily created. Returns null when the
/// FFI library can't be loaded (tests, web, missing native/.so) so the
/// UI degrades gracefully.
final synthEngineProvider = Provider<OpenAmpSynth?>((ref) {
  if (!OpenAmpSynthBindings.available) return null;
  final synth = OpenAmpSynth();
  ref.onDispose(synth.dispose);
  return synth;
});

/// Side-effect provider: pushes the current preset's parameters to the
/// native engine whenever the preset changes. This is what makes the
/// "play a key in the UI" path actually sound like the loaded preset
/// instead of the engine's defaults.
///
/// Returns void; consumers don't read it directly. The synth screen
/// just `ref.watch`es it to keep the binding alive for the lifetime of
/// the screen.
final livePresetSyncProvider = Provider<void>((ref) {
  final synth = ref.watch(synthEngineProvider);
  final preset = ref.watch(currentPresetProvider);
  if (synth == null) return;
  applyPresetToSynth(synth, preset);
});

/// Live audio output stream bound to the native synth engine.
///
/// Created lazily the first time it's read, started immediately, and
/// disposed when the [ProviderContainer] tears down. Returns null when
/// the FFI library or PortAudio device is unavailable so the rest of
/// the UI keeps working as a silent demo.
///
/// Important: this provider depends on [synthEngineProvider] so it
/// always lives at least as long as the engine it borrows from. Disposal
/// order is the reverse: the audio stream's onDispose runs before the
/// synth's, satisfying the "stream must outlive engine" contract from
/// the native side.
final synthAudioStreamProvider = Provider<OpenAmpSynthAudioStream?>((ref) {
  final synth = ref.watch(synthEngineProvider);
  if (synth == null) return null;
  if (!OpenAmpAudioStreamBindings.available) return null;

  final stream = OpenAmpSynthAudioStream(
    synthHandle: synth.nativeHandle,
    sampleRate: 48000.0,
    blockSize: 256,
  );
  final ok = stream.start();
  if (!ok) {
    developer.log(
      'PortAudio failed to start: ${stream.lastError}',
      name: 'open_synth.audio',
    );
    stream.dispose();
    return null;
  }
  ref.onDispose(stream.dispose);
  return stream;
});

// ── Playback State ──────────────────────────────────────
final playbackStateProvider =
    StateNotifierProvider<PlaybackStateNotifier, Set<int>>((ref) {
  return PlaybackStateNotifier(ref);
});

class PlaybackStateNotifier extends StateNotifier<Set<int>> {
  PlaybackStateNotifier(this._ref) : super({});

  final Ref _ref;

  OpenAmpSynth? get _engine => _ref.read(synthEngineProvider);

  /// Reading the audio-stream provider lazily creates and starts the
  /// PortAudio output stream. We touch it on first noteOn so the audio
  /// device only opens when the user actually wants sound.
  void _ensureAudioRunning() {
    _ref.read(synthAudioStreamProvider);
  }

  void noteOn(int midiNote, {double velocity = 1.0}) {
    _ensureAudioRunning();
    _engine?.noteOn(midiNote, velocity: velocity);
    state = {...state, midiNote};
  }

  void noteOff(int midiNote) {
    _engine?.noteOff(midiNote);
    state = {...state}..remove(midiNote);
  }

  void allNotesOff() {
    _engine?.allNotesOff();
    state = {};
  }
}

// ── Keyboard Octave ─────────────────────────────────────
final keyboardOctaveProvider = StateProvider<int>((ref) => 4);

// ── Search Query ────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');
