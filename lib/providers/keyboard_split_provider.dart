import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ffi/openamp_audio_stream.dart';
import '../ffi/openamp_synth.dart';
import '../models/keyboard_split.dart';
import '../models/synth_preset.dart';
import '../services/preset_loader.dart';
import 'settings_provider.dart';
import 'synth_providers.dart';

// ── Keyboard Split Config ─────────────────────────────────────────────────────

final keyboardSplitProvider =
    StateNotifierProvider<KeyboardSplitNotifier, KeyboardSplit>((ref) {
  return KeyboardSplitNotifier();
});

class KeyboardSplitNotifier extends StateNotifier<KeyboardSplit> {
  KeyboardSplitNotifier() : super(KeyboardSplit());

  void update(KeyboardSplit Function(KeyboardSplit) updater) {
    state = updater(state);
  }

  void setPresetA(SynthPreset preset) {
    state = state.copyWith(presetA: preset);
  }

  void setPresetB(SynthPreset preset) {
    state = state.copyWith(presetB: preset);
  }

  void toggle() {
    state = state.copyWith(enabled: !state.enabled);
  }

  void setSplitPoint(int note) {
    state = state.copyWith(splitPoint: note.clamp(24, 96));
  }

  void setVolumeA(double v) {
    state = state.copyWith(volumeA: v.clamp(0.0, 1.0));
  }

  void setVolumeB(double v) {
    state = state.copyWith(volumeB: v.clamp(0.0, 1.0));
  }
}

// ── Zone B Synth Engine ───────────────────────────────────────────────────────

/// Second native synth engine for zone B. Lazy-created, null if FFI unavailable.
final zoneBEngineProvider = Provider<OpenAmpSynth?>((ref) {
  if (!OpenAmpSynthBindings.available) return null;
  final synth = OpenAmpSynth();
  ref.onDispose(synth.dispose);
  return synth;
});

/// Zone B audio output stream bound to zone B engine.
final zoneBAudioStreamProvider = Provider<OpenAmpSynthAudioStream?>((ref) {
  final engine = ref.watch(zoneBEngineProvider);
  if (engine == null) return null;
  if (!OpenAmpAudioStreamBindings.available) return null;

  final bufferSize = ref.watch(audioBufferSizeProvider);

  final stream = OpenAmpSynthAudioStream(
    synthHandle: engine.nativeHandle,
    sampleRate: 48000.0,
    blockSize: bufferSize,
  );
  final ok = stream.start();
  if (!ok) {
    developer.log(
      'PortAudio failed to start for zone B: ${stream.lastError}',
      name: 'open_synth.split',
    );
    stream.dispose();
    return null;
  }
  ref.onDispose(stream.dispose);
  return stream;
});

// ── Zone B Playback State ───────────────────────────────────────────────────

/// Tracks which notes are active on zone B.
final zoneBPlaybackProvider =
    StateNotifierProvider<ZoneBPlaybackNotifier, Set<int>>((ref) {
  return ZoneBPlaybackNotifier(ref);
});

class ZoneBPlaybackNotifier extends StateNotifier<Set<int>> {
  ZoneBPlaybackNotifier(this._ref) : super({});

  final Ref _ref;

  OpenAmpSynth? get _engine => _ref.read(zoneBEngineProvider);

  void _ensureAudioRunning() {
    final stream = _ref.read(zoneBAudioStreamProvider);
    stream?.start();
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

// ── Zone B Preset Sync ───────────────────────────────────────────────────────

/// Side-effect provider: pushes zone B's preset to zone B's engine.
final zoneBPresetSyncProvider = Provider<void>((ref) {
  final engine = ref.watch(zoneBEngineProvider);
  final split = ref.watch(keyboardSplitProvider);
  if (engine == null) return;

  // Zone B uses its own preset directly (no morph/mod matrix for zone B in v1)
  final preset = split.presetB;
  applyPresetToSynth(engine, preset);
});

// ── Combined Note Router ──────────────────────────────────────────────────────

/// Converts a MIDI note into a (zone, noteOn, noteOff) triple based on
/// the current keyboard split configuration.
///
/// Returns -1 for zone when split is disabled (notes go to main engine).
class NoteRouter {
  NoteRouter(this._ref);

  final Ref _ref;

  int resolveZone(int midiNote) {
    final split = _ref.read(keyboardSplitProvider);
    return split.zoneForNote(midiNote);
  }

  void noteOn(int midiNote, {double velocity = 1.0}) {
    final zone = resolveZone(midiNote);
    if (zone == 0) {
      // Zone A — use main playback
      _ref.read(playbackStateProvider.notifier).noteOn(midiNote, velocity: velocity);
    } else if (zone == 1) {
      // Zone B — use zone B playback
      _ref.read(zoneBPlaybackProvider.notifier).noteOn(midiNote, velocity: velocity);
    } else {
      // Split disabled — main playback as usual
      _ref.read(playbackStateProvider.notifier).noteOn(midiNote, velocity: velocity);
    }
  }

  void noteOff(int midiNote) {
    final zone = resolveZone(midiNote);
    if (zone == 0) {
      _ref.read(playbackStateProvider.notifier).noteOff(midiNote);
    } else if (zone == 1) {
      _ref.read(zoneBPlaybackProvider.notifier).noteOff(midiNote);
    } else {
      _ref.read(playbackStateProvider.notifier).noteOff(midiNote);
    }
  }

  /// Returns the active notes across both zones (for UI display).
  Set<int> get allActiveNotes {
    final a = _ref.read(playbackStateProvider);
    final b = _ref.read(zoneBPlaybackProvider);
    return {...a, ...b};
  }
}
