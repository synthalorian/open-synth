import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../data/factory_presets.dart';
import '../ffi/openamp_audio_stream.dart';
import '../ffi/openamp_synth.dart';
import '../models/mod_matrix.dart';
import '../models/synth_preset.dart';
import '../services/preset_loader.dart';
import 'mod_matrix_provider.dart';
import 'morph_provider.dart';
import 'settings_provider.dart';

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
  // Use the Init Patch (factory-15) as default for instant sound at startup.
  // factoryPresets.first (Blade Runner Pad) has a 1500ms amp attack which
  // makes it feel like there's no audio output.
  CurrentPresetNotifier() : super(factoryPresets[14]);

  void load(SynthPreset preset) => state = preset;

  void update(SynthPreset Function(SynthPreset) updater) {
    state = updater(state);
  }
}

// ── Native synth engine ─────────────────────────────────
/// Backing native SynthEngine, lazily created. Returns null when the
/// FFI library can't be loaded (tests, web, missing native/.so) so the
/// UI degrades gracefully.
///
/// IMPORTANT: This provider also initializes the PortAudio audio system
/// via AudioSystem::init() on first access, and shuts it down on dispose.
/// All other audio providers depend on this one so the lifecycle is correct.
final synthEngineProvider = Provider<OpenAmpSynth?>((ref) {
  if (!OpenAmpSynthBindings.available) return null;

  // Initialize PortAudio singleton before creating any engine/stream.
  // The AudioSystem C++ singleton ref-counts, so multiple inits are safe.
  if (OpenAmpAudioStreamBindings.available) {
    OpenAmpAudioStreamBindings.instance.init();
  }

  final synth = OpenAmpSynth();
  ref.onDispose(() {
    synth.dispose();
    // Shut down PortAudio singleton (ref-counted, so only terminates
    // when the last init is matched by a shutdown).
    if (OpenAmpAudioStreamBindings.available) {
      OpenAmpAudioStreamBindings.instance.shutdown();
    }
  });
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
  final morphed = ref.watch(morphedPresetProvider);
  final morphConfig = ref.watch(morphConfigProvider);
  final modMatrix = ref.watch(modMatrixProvider);
  final modValues = ref.watch(modSourceValuesProvider);
  if (synth == null) return;

  // Use morphed preset when morphing is active, otherwise current preset.
  final basePreset = (morphConfig.isPlaying || morphConfig.position > 0.0)
      ? morphed
      : preset;

  // Compute modulated preset
  final modulated = _applyModulation(basePreset, modMatrix, modValues);
  applyPresetToSynth(synth, modulated);
});

/// Apply modulation matrix to a preset, returning a new preset with
/// modulated parameter values.
SynthPreset _applyModulation(
  SynthPreset preset,
  ModMatrix matrix,
  Map<ModSource, double> sourceValues,
) {
  double pitchOffset = 0.0;
  double cutoffOffset = 0.0;
  double resonanceOffset = 0.0;
  double osc2DetuneOffset = 0.0;
  double lfo1RateOffset = 0.0;
  double lfo2RateOffset = 0.0;
  double masterVolOffset = 0.0;

  for (final slot in matrix.slots) {
    if (!slot.enabled) continue;
    final sourceValue = sourceValues[slot.source] ?? 0.0;
    if (!slot.bipolar && sourceValue < 0) continue;

    final range = slot.destination.maxAmount - slot.destination.minAmount;
    final modulated = slot.amount * sourceValue * range * 0.5;

    switch (slot.destination) {
      case ModDestination.pitch:
        pitchOffset += modulated;
        break;
      case ModDestination.filterCutoff:
        cutoffOffset += modulated;
        break;
      case ModDestination.filterResonance:
        resonanceOffset += modulated;
        break;
      case ModDestination.amplitude:
        // Amplitude modulation not yet wired to engine
        break;
      case ModDestination.pan:
        // Pan modulation not yet wired to engine
        break;
      case ModDestination.osc2Detune:
        osc2DetuneOffset += modulated;
        break;
      case ModDestination.lfo1Rate:
        lfo1RateOffset += modulated;
        break;
      case ModDestination.lfo2Rate:
        lfo2RateOffset += modulated;
        break;
      case ModDestination.masterVolume:
        masterVolOffset += modulated;
        break;
    }
  }

  return preset.copyWith(
    osc1: pitchOffset != 0.0
        ? preset.osc1.copyWith(detune: preset.osc1.detune + pitchOffset)
        : preset.osc1,
    osc2: osc2DetuneOffset != 0.0
        ? preset.osc2.copyWith(detune: preset.osc2.detune + osc2DetuneOffset)
        : preset.osc2,
    filter: cutoffOffset != 0.0 || resonanceOffset != 0.0
        ? preset.filter.copyWith(
            cutoff: (preset.filter.cutoff + cutoffOffset).clamp(20.0, 20000.0),
            resonance: (preset.filter.resonance + resonanceOffset).clamp(0.0, 1.0),
          )
        : preset.filter,
    masterVolume: (preset.masterVolume + masterVolOffset).clamp(0.0, 1.0),
    lfo1: lfo1RateOffset != 0.0
        ? preset.lfo1.copyWith(rate: (preset.lfo1.rate + lfo1RateOffset).clamp(0.01, 20.0))
        : preset.lfo1,
    lfo2: lfo2RateOffset != 0.0
        ? preset.lfo2.copyWith(rate: (preset.lfo2.rate + lfo2RateOffset).clamp(0.01, 20.0))
        : preset.lfo2,
  );
}

/// Live audio output stream bound to the native synth engine.
///
/// Created lazily the first time it's read, started immediately, and
/// disposed when dependencies change or the container tears down.
/// Watches [audioBufferSizeProvider] and [selectedAudioDeviceProvider]
/// so changing buffer size or output device recreates the stream.
/// Returns null when the FFI library or PortAudio device is unavailable
/// so the rest of the UI keeps working as a silent demo.
///
/// Disposal order is critical:
///   1. Stop the audio stream (halts the callback)
///   2. Destroy the stream (closes PortAudio device)
///   3. The synth engine disposal happens after (different provider)
final synthAudioStreamProvider = Provider<OpenAmpSynthAudioStream?>((ref) {
  final synth = ref.watch(synthEngineProvider);
  if (synth == null) return null;
  if (!OpenAmpAudioStreamBindings.available) return null;

  final bufferSize = ref.watch(audioBufferSizeProvider);
  final deviceIndex = ref.watch(selectedAudioDeviceProvider);

  OpenAmpSynthAudioStream? stream;
  try {
    stream = OpenAmpSynthAudioStream(
      synthHandle: synth.nativeHandle,
      sampleRate: 48000.0,
      blockSize: bufferSize,
      deviceIndex: deviceIndex,
    );
  } catch (e, st) {
    developer.log(
      'Failed to create audio stream: $e',
      name: 'open_synth.audio',
      error: e,
      stackTrace: st,
    );
    return null;
  }

  bool ok;
  try {
    ok = stream.start();
  } catch (e, st) {
    developer.log(
      'Failed to start audio stream: $e',
      name: 'open_synth.audio',
      error: e,
      stackTrace: st,
    );
    stream.dispose();
    return null;
  }

  if (!ok) {
    developer.log(
      'PortAudio failed to start: ${stream.lastError}',
      name: 'open_synth.audio',
    );
    stream.dispose();
    return null;
  }

  ref.onDispose(() {
    // Explicit stop-then-dispose to guarantee the callback is halted
    // before the PortAudio stream is closed.
    stream!.dispose();
  });
  return stream;
});

/// Cached list of available audio output devices. Enumerated once via
/// FFI; null if enumeration fails or the FFI library is unavailable.
final audioDevicesProvider = Provider<List<AudioDeviceInfo>?>((ref) {
  if (!OpenAmpAudioStreamBindings.available) return null;

  try {
    final bindings = OpenAmpAudioStreamBindings.instance;
    return bindings.enumerateDevices();
  } catch (e, st) {
    developer.log(
      'Audio device enumeration failed: $e',
      name: 'open_synth.audio',
      error: e,
      stackTrace: st,
    );
    return null;
  }
});

/// Exposes audio stream diagnostics — device info, callback count,
/// error state, running state — for the UI to display.
final audioStreamDiagnosticsProvider =
    Provider<AudioStreamDiagnostics>((ref) {
  final stream = ref.watch(synthAudioStreamProvider);
  final deviceIndex = ref.watch(selectedAudioDeviceProvider);
  final devices = ref.watch(audioDevicesProvider);

  if (stream == null) {
    final errorMsg = _errorMessage(deviceIndex, devices);
    return AudioStreamDiagnostics(
      deviceIndex: deviceIndex,
      isRunning: false,
      callbackCount: 0,
      lastError: errorMsg,
    );
  }

  return AudioStreamDiagnostics(
    deviceIndex: deviceIndex,
    isRunning: stream.isRunning,
    callbackCount: stream.callbackCount,
    lastError: stream.lastError,
  );
});

String _errorMessage(int deviceIndex, List<AudioDeviceInfo>? devices) {
  if (!OpenAmpAudioStreamBindings.available) {
    return 'Audio engine unavailable — FFI library not loaded';
  }
  if (devices == null) {
    return 'Audio device enumeration failed (PortAudio error)';
  }
  if (devices.isEmpty) {
    return 'No audio output devices found';
  }
  if (deviceIndex >= 0 && !devices.any((d) => d.index == deviceIndex)) {
    return 'Selected device (index $deviceIndex) no longer available';
  }
  return 'Audio stream not available (PortAudio could not open device)';
}

/// Snapshot of audio stream state for display in the UI.
class AudioStreamDiagnostics {
  final int deviceIndex;
  final bool isRunning;
  final int callbackCount;
  final String lastError;

  AudioStreamDiagnostics({
    required this.deviceIndex,
    required this.isRunning,
    required this.callbackCount,
    required this.lastError,
  });
}

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

// ── Voice Priority ──────────────────────────────────────
/// 0 = steal oldest, 1 = steal quietest, 2 = steal lowest
final voicePriorityProvider = StateProvider<int>((ref) => 0);
