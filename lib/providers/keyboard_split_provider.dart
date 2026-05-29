import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';
import 'package:hive/hive.dart';

import 'dart:ffi';

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
  KeyboardSplitNotifier() : super(KeyboardSplit()) {
    _load();
  }

  Box? _box;

  void _load() {
    _box = Hive.box('open_synth');
    final stored = _box?.get('keyboard_split');
    if (stored != null) {
      try {
        final json = jsonDecode(stored as String) as Map<String, dynamic>;
        state = KeyboardSplit.fromJson(json);
      } catch (e) {
        appLogger.warning('Failed to load keyboard split: $e');
      }
    }
  }

  void _save() {
    _box?.put('keyboard_split', jsonEncode(state.toJson()));
  }

  void update(KeyboardSplit Function(KeyboardSplit) updater) {
    state = updater(state);
    _save();
  }

  void setPresetA(SynthPreset preset) {
    state = state.copyWith(presetA: preset);
    _save();
  }

  void setPresetB(SynthPreset preset) {
    state = state.copyWith(presetB: preset);
    _save();
  }

  void setMode(SplitMode mode) {
    state = state.copyWith(mode: mode);
    _save();
  }

  void cycleMode() {
    final nextIndex = (state.mode.index + 1) % SplitMode.values.length;
    state = state.copyWith(mode: SplitMode.values[nextIndex]);
    _save();
  }

  void setSplitPoint(int note) {
    state = state.copyWith(splitPoint: note.clamp(24, 96));
    _save();
  }

  void setVolumeA(double v) {
    state = state.copyWith(volumeA: v.clamp(0.0, 1.0));
    _save();
  }

  void setVolumeB(double v) {
    state = state.copyWith(volumeB: v.clamp(0.0, 1.0));
    _save();
  }

  void setOctaveShiftA(int shift) {
    state = state.copyWith(octaveShiftA: shift.clamp(-2, 2));
    _save();
  }

  void setOctaveShiftB(int shift) {
    state = state.copyWith(octaveShiftB: shift.clamp(-2, 2));
    _save();
  }

  void setCrossfadeWidth(int width) {
    state = state.copyWith(crossfadeWidth: width.clamp(0, 12));
    _save();
  }
}

// ── SynthEnginePair (Zone A + Zone B Mixer) ───────────────────────────────────

/// Combined engine pair that wraps two SynthEngine instances and mixes
/// their audio outputs. Replaces the old separate zone B engine + stream.
final synthPairProvider = Provider<OpenAmpSynthPair?>((ref) {
  if (PairBindings.instance == null) return null;

  final pair = OpenAmpSynthPair();
  ref.onDispose(pair.dispose);
  return pair;
});

/// Audio stream bound to the SynthEnginePair. Only one audio stream
/// needed — the pair handles internal mixing of both zones.
final synthPairAudioStreamProvider = Provider<OpenAmpSynthAudioStream?>((ref) {
  final pair = ref.watch(synthPairProvider);
  if (pair == null) return null;
  if (!OpenAmpAudioStreamBindings.available) return null;

  final bufferSize = ref.watch(audioBufferSizeProvider);

  OpenAmpSynthAudioStream? stream;
  try {
    stream = OpenAmpSynthAudioStream.forPair(
      pairHandle: pair.nativeHandle as Pointer<Void>,
      sampleRate: 48000.0,
      blockSize: bufferSize,
    );
  } catch (e, st) {
    appLogger.severe(
      'Failed to create pair audio stream: $e',
      e,
      st,
    );
    return null;
  }

  final ok = stream.start();
  if (!ok) {
    appLogger.warning(
      'Audio stream failed to start for synth pair: ${stream.lastError}',
    );
    stream.dispose();
    return null;
  }

  ref.onDispose(stream.dispose);
  return stream;
});

// ── Zone B Playback State ───────────────────────────────────────────────────

/// Tracks which notes are active on zone B.
/// Uses the pair's engine B handle to noteOn/noteOff.
final zoneBPlaybackProvider =
    StateNotifierProvider<ZoneBPlaybackNotifier, Set<int>>((ref) {
  return ZoneBPlaybackNotifier(ref);
});

class ZoneBPlaybackNotifier extends StateNotifier<Set<int>> {
  ZoneBPlaybackNotifier(this._ref) : super({});

  final Ref _ref;

  /// Get the zone B engine handle from the pair.
  OpenAmpSynth? get _engineB {
    final pair = _ref.read(synthPairProvider);
    if (pair == null) return null;
    // Wrap the raw engine B handle in a lightweight wrapper for noteOn/noteOff
    // We use the main OpenAmpSynthBindings to send events to engine B's handle
    return OpenAmpSynth.fromHandle(pair.engineB);
  }

  void _ensureAudioRunning() {
    final stream = _ref.read(synthPairAudioStreamProvider);
    stream?.start();
  }

  void noteOn(int midiNote, {double velocity = 1.0}) {
    _ensureAudioRunning();
    _engineB?.noteOn(midiNote, velocity: velocity);
    state = {...state, midiNote};
  }

  void noteOff(int midiNote) {
    _engineB?.noteOff(midiNote);
    state = {...state}..remove(midiNote);
  }

  void allNotesOff() {
    _engineB?.allNotesOff();
    state = {};
  }
}

// ── Zone B Preset Sync ───────────────────────────────────────────────────────

/// Side-effect provider: pushes zone B's preset to zone B's engine.
final zoneBPresetSyncProvider = Provider<void>((ref) {
  final pair = ref.watch(synthPairProvider);
  final split = ref.watch(keyboardSplitProvider);
  if (pair == null) return;

  // Zone B uses its own preset directly (no morph/mod matrix for zone B in v1)
  final preset = split.presetB;
  final engineB = OpenAmpSynth.fromHandle(pair.engineB);
  applyPresetToSynth(engineB, preset);
});

// ── Zone B Mix Volume Sync ─────────────────────────────────────────────────────

/// Syncs the keyboard split volume to the SynthEnginePair's mix controls.
final zoneBMixSyncProvider = Provider<void>((ref) {
  final pair = ref.watch(synthPairProvider);
  final split = ref.watch(keyboardSplitProvider);
  if (pair == null) return;

  pair.setMixA(split.volumeA);
  pair.setMixB(split.volumeB);
});

// ── Combined Note Router ──────────────────────────────────────────────────────

/// Riverpod provider exposing the [NoteRouter] instance.
final noteRouterProvider = Provider<NoteRouter>((ref) => NoteRouter(ref));

/// Converts a MIDI note into a (zone, noteOn, noteOff) triple based on
/// the current keyboard split configuration.
///
/// Returns -1 for zone when split is disabled (notes go to main engine).
class NoteRouter {
  NoteRouter(this._ref);

  final Ref _ref;

  /// Tracks which zone each active note was routed to so note-off
  /// always targets the same engine, even if split config changes
  /// while the key is held.
  final Map<int, int> _activeNoteZones = {};

  int resolveZone(int midiNote) {
    final split = _ref.read(keyboardSplitProvider);
    return split.zoneForNote(midiNote);
  }

  void noteOn(int midiNote, {double velocity = 1.0}) {
    final zone = resolveZone(midiNote);
    _activeNoteZones[midiNote] = zone;

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
    // Use the *original* zone from note-on so the release goes to the
    // same engine even if the split point shifted while the key was held.
    final zone = _activeNoteZones.remove(midiNote) ?? resolveZone(midiNote);

    if (zone == 0) {
      _ref.read(playbackStateProvider.notifier).noteOff(midiNote);
    } else if (zone == 1) {
      _ref.read(zoneBPlaybackProvider.notifier).noteOff(midiNote);
    } else {
      _ref.read(playbackStateProvider.notifier).noteOff(midiNote);
    }
  }

  /// Release every tracked note (e.g. on panic / split mode change).
  void allNotesOff() {
    for (final entry in _activeNoteZones.entries) {
      final midiNote = entry.key;
      final zone = entry.value;
      if (zone == 0) {
        _ref.read(playbackStateProvider.notifier).noteOff(midiNote);
      } else if (zone == 1) {
        _ref.read(zoneBPlaybackProvider.notifier).noteOff(midiNote);
      } else {
        _ref.read(playbackStateProvider.notifier).noteOff(midiNote);
      }
    }
    _activeNoteZones.clear();
  }

  /// Returns the active notes across both zones (for UI display).
  Set<int> get allActiveNotes {
    final a = _ref.read(playbackStateProvider);
    final b = _ref.read(zoneBPlaybackProvider);
    return {...a, ...b};
  }
}
