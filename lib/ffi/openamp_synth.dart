// ignore_for_file: library_private_types_in_public_api
// Dart FFI bindings for libopenamp_dart_ffi.so (synth_engine symbols).
//
// Native source:
//   ~/projects/openamp/dsp-core/plugins/synth_engine/synth_ffi.{h,cpp}
// Built into the shared library by:
//   ~/projects/openamp/dsp-core/dart_ffi/CMakeLists.txt
// Shipped at native/libopenamp_dart_ffi.so relative to project root.

import 'dart:ffi';
import 'dart:io';

// ── Opaque handle ────────────────────────────────────────────────────────────

final class _SynthHandle extends Opaque {}

final class _PairHandle extends Opaque {}

typedef SynthEngineRef = Pointer<_SynthHandle>;
typedef SynthPairRef = Pointer<_PairHandle>;

// ── Native typedefs ──────────────────────────────────────────────────────────

typedef _CreateNative = SynthEngineRef Function(Double, Uint32);
typedef _CreateDart = SynthEngineRef Function(double, int);

typedef _VoidNative = Void Function(SynthEngineRef);
typedef _VoidDart = void Function(SynthEngineRef);

typedef _ProcessNative = Void Function(SynthEngineRef, Pointer<Float>, Uint32);
typedef _ProcessDart = void Function(SynthEngineRef, Pointer<Float>, int);

typedef _NoteOnNative = Void Function(SynthEngineRef, Int32, Float);
typedef _NoteOnDart = void Function(SynthEngineRef, int, double);

typedef _NoteOffNative = Void Function(SynthEngineRef, Int32);
typedef _NoteOffDart = void Function(SynthEngineRef, int);

typedef _SetIntNative = Void Function(SynthEngineRef, Int32);
typedef _SetIntDart = void Function(SynthEngineRef, int);

typedef _SetFloatNative = Void Function(SynthEngineRef, Float);
typedef _SetFloatDart = void Function(SynthEngineRef, double);

typedef _GetIntNative = Int32 Function(SynthEngineRef);
typedef _GetIntDart = int Function(SynthEngineRef);

// Queue FFI types
typedef _SetFloatIntNative = Void Function(SynthEngineRef, Int32, Float);
typedef _SetFloatIntDart = void Function(SynthEngineRef, int, double);

typedef _SetInt2Native = Void Function(SynthEngineRef, Int32, Int32);
typedef _SetInt2Dart = void Function(SynthEngineRef, int, int);

// ── Library loader ───────────────────────────────────────────────────────────

DynamicLibrary _openLibrary() {
  if (Platform.isLinux) {
    final candidates = [
      'native/libopenamp_dart_ffi.so',
      './native/libopenamp_dart_ffi.so',
      '${Directory.current.path}/native/libopenamp_dart_ffi.so',
      'libopenamp_dart_ffi.so',
    ];
    for (final path in candidates) {
      try {
        return DynamicLibrary.open(path);
      } catch (_) {
        // try next
      }
    }
    return DynamicLibrary.open('libopenamp_dart_ffi.so');
  }
  if (Platform.isMacOS) {
    return DynamicLibrary.open('libopenamp_dart_ffi.dylib');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('openamp_dart_ffi.dll');
  }
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libopenamp_dart_ffi.so');
  }
  throw UnsupportedError(
      'OpenAmp synth FFI not supported on ${Platform.operatingSystem}');
}

// ── Bindings ─────────────────────────────────────────────────────────────────

class OpenAmpSynthBindings {
  OpenAmpSynthBindings._(DynamicLibrary lib)
      : lib = lib, // ignore: prefer_initializing_formals
        create = lib
            .lookupFunction<_CreateNative, _CreateDart>('synth_engine_create'),
        destroy = lib
            .lookupFunction<_VoidNative, _VoidDart>('synth_engine_destroy'),
        process = lib
            .lookupFunction<_ProcessNative, _ProcessDart>('synth_engine_process'),
        reset =
            lib.lookupFunction<_VoidNative, _VoidDart>('synth_engine_reset'),
        noteOn = lib.lookupFunction<_NoteOnNative, _NoteOnDart>(
            'synth_engine_note_on'),
        noteOff = lib.lookupFunction<_NoteOffNative, _NoteOffDart>(
            'synth_engine_note_off'),
        allNotesOff = lib.lookupFunction<_VoidNative, _VoidDart>(
            'synth_engine_all_notes_off'),
        // Osc 1
        setOsc1Waveform = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_osc1_waveform'),
        setOsc1Octave = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_osc1_octave'),
        setOsc1Detune = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_osc1_detune'),
        setOsc1PulseWidth = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_osc1_pulse_width'),
        setOsc1Volume = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_osc1_volume'),
        // Osc 2
        setOsc2Waveform = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_osc2_waveform'),
        setOsc2Octave = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_osc2_octave'),
        setOsc2Detune = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_osc2_detune'),
        setOsc2PulseWidth = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_osc2_pulse_width'),
        setOsc2Volume = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_osc2_volume'),
        setOscMix = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_osc_mix'),
        // Filter
        setFilterType = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_filter_type'),
        setFilterCutoff = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_filter_cutoff'),
        setFilterResonance = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_filter_resonance'),
        setFilterEnvAmount = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_filter_env_amount'),
        // Amp envelope
        setAmpAttack = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_amp_attack'),
        setAmpDecay = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_amp_decay'),
        setAmpSustain = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_amp_sustain'),
        setAmpRelease = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_amp_release'),
        // Filter envelope
        setFilterAttack = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_filter_attack'),
        setFilterDecay = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_filter_decay'),
        setFilterSustain = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_filter_sustain'),
        setFilterRelease = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_filter_release'),
        // LFO 1
        setLfo1Waveform = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_lfo1_waveform'),
        setLfo1Rate = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_lfo1_rate'),
        setLfo1Depth = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_lfo1_depth'),
        setLfo1Target = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_lfo1_target'),
        // LFO 2
        setLfo2Waveform = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_lfo2_waveform'),
        setLfo2Rate = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_lfo2_rate'),
        setLfo2Depth = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_lfo2_depth'),
        setLfo2Target = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_lfo2_target'),
        // FX: Chorus
        setChorusEnabled = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_chorus_enabled'),
        setChorusRate = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_chorus_rate'),
        setChorusDepth = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_chorus_depth'),
        setChorusMix = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_chorus_mix'),
        // FX: Delay
        setDelayEnabled = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_delay_enabled'),
        setDelayTime = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_delay_time'),
        setDelayFeedback = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_delay_feedback'),
        setDelayMix = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_delay_mix'),
        // FX: Reverb
        setReverbEnabled = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_reverb_enabled'),
        setReverbSize = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_reverb_size'),
        setReverbDamping = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_reverb_damping'),
        setReverbMix = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_reverb_mix'),
        // FX: Phaser
        setPhaserEnabled = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_phaser_enabled'),
        setPhaserRate = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_phaser_rate'),
        setPhaserDepth = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_phaser_depth'),
        setPhaserFeedback = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_phaser_feedback'),
        setPhaserMix = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_phaser_mix'),
        // FX: Drive
        setDriveEnabled = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_drive_enabled'),
        setDriveAmount = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_drive_amount'),
        setDriveType = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_drive_type'),
        // FX: Flanger
        setFlangerEnabled = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_flanger_enabled'),
        setFlangerRate = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_flanger_rate'),
        setFlangerDepth = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_flanger_depth'),
        setFlangerFeedback = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_flanger_feedback'),
        setFlangerMix = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_flanger_mix'),
        // FX: Compressor
        setCompressorEnabled = lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_compressor_enabled'),
        setCompressorThreshold = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_compressor_threshold'),
        setCompressorRatio = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_compressor_ratio'),
        setCompressorAttack = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_compressor_attack'),
        setCompressorRelease = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_compressor_release'),
        setCompressorMakeupGain = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_compressor_makeup_gain'),
        // Master
        setMasterVolume = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_master_volume'),
        getActiveVoices = lib.lookupFunction<_GetIntNative, _GetIntDart>(
            'synth_engine_get_active_voices'),
        getCpuLoad = lib.lookupFunction<
            Float Function(SynthEngineRef),
            double Function(SynthEngineRef)>('synth_engine_get_cpu_load'),

        // Thread-safe queue
        enqueueFloat = lib.lookupFunction<_SetFloatIntNative, _SetFloatIntDart>(
            'synth_engine_enqueue_float'),
        enqueueInt = lib.lookupFunction<_SetInt2Native, _SetInt2Dart>(
            'synth_engine_enqueue_int'),
        enqueueNoteOnFn = lib.lookupFunction<_NoteOnNative, _NoteOnDart>(
            'synth_engine_enqueue_note_on'),
        enqueueNoteOffFn = lib.lookupFunction<_NoteOffNative, _NoteOffDart>(
            'synth_engine_enqueue_note_off'),
        enqueueAllNotesOffFn = lib.lookupFunction<_VoidNative, _VoidDart>(
            'synth_engine_enqueue_all_notes_off'),
        enqueueResetFn = lib.lookupFunction<_VoidNative, _VoidDart>(
            'synth_engine_enqueue_reset');
        // Arpeggiator getters
        getArpCurrentStep = lib.lookupFunction<_GetIntNative, _GetIntDart>(
            'synth_engine_get_arp_current_step'),
        getArpTotalSteps = lib.lookupFunction<_GetIntNative, _GetIntDart>(
            'synth_engine_get_arp_total_steps');

  // ── Unison bindings (lazy, may not be available in older .so builds) ──

  UnisonBindings? _unisonBindings;

  /// Returns the unison bindings if available, or null if the native .so
  /// doesn't export the unison symbols yet. Callers should null-check
  /// before accessing methods on the returned value.
  UnisonBindings? get unison {
    _unisonBindings ??= UnisonBindings._tryLookup(lib);
    return _unisonBindings;
  }

  /// Whether the unison FFI symbols are present in the loaded .so.
  bool get unisonAvailable => _unisonBindings != null;

  static OpenAmpSynthBindings? _instance;
  static OpenAmpSynthBindings get instance =>
      _instance ??= OpenAmpSynthBindings._(_openLibrary());

  static bool get available {
    try {
      instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The DynamicLibrary handle the synth bindings opened. Exposed so
  /// sibling FFI binding tables (e.g. audio stream) can resolve their
  /// own symbols out of the same .so without re-opening it.
  final DynamicLibrary lib;

  // Lifecycle
  final _CreateDart create;
  final _VoidDart destroy;
  final _ProcessDart process;
  final _VoidDart reset;

  // MIDI
  final _NoteOnDart noteOn;
  final _NoteOffDart noteOff;
  final _VoidDart allNotesOff;

  // Osc 1
  final _SetIntDart setOsc1Waveform;
  final _SetIntDart setOsc1Octave;
  final _SetFloatDart setOsc1Detune;
  final _SetFloatDart setOsc1PulseWidth;
  final _SetFloatDart setOsc1Volume;

  // Osc 2
  final _SetIntDart setOsc2Waveform;
  final _SetIntDart setOsc2Octave;
  final _SetFloatDart setOsc2Detune;
  final _SetFloatDart setOsc2PulseWidth;
  final _SetFloatDart setOsc2Volume;
  final _SetFloatDart setOscMix;

  // Filter
  final _SetIntDart setFilterType;
  final _SetFloatDart setFilterCutoff;
  final _SetFloatDart setFilterResonance;
  final _SetFloatDart setFilterEnvAmount;

  // Amp envelope
  final _SetFloatDart setAmpAttack;
  final _SetFloatDart setAmpDecay;
  final _SetFloatDart setAmpSustain;
  final _SetFloatDart setAmpRelease;

  // Filter envelope
  final _SetFloatDart setFilterAttack;
  final _SetFloatDart setFilterDecay;
  final _SetFloatDart setFilterSustain;
  final _SetFloatDart setFilterRelease;

  // LFO 1
  final _SetIntDart setLfo1Waveform;
  final _SetFloatDart setLfo1Rate;
  final _SetFloatDart setLfo1Depth;
  final _SetIntDart setLfo1Target;

  // LFO 2
  final _SetIntDart setLfo2Waveform;
  final _SetFloatDart setLfo2Rate;
  final _SetFloatDart setLfo2Depth;
  final _SetIntDart setLfo2Target;

  // FX: Chorus
  final _SetIntDart setChorusEnabled;
  final _SetFloatDart setChorusRate;
  final _SetFloatDart setChorusDepth;
  final _SetFloatDart setChorusMix;

  // FX: Delay
  final _SetIntDart setDelayEnabled;
  final _SetFloatDart setDelayTime;
  final _SetFloatDart setDelayFeedback;
  final _SetFloatDart setDelayMix;

  // FX: Reverb
  final _SetIntDart setReverbEnabled;
  final _SetFloatDart setReverbSize;
  final _SetFloatDart setReverbDamping;
  final _SetFloatDart setReverbMix;

  // FX: Phaser
  final _SetIntDart setPhaserEnabled;
  final _SetFloatDart setPhaserRate;
  final _SetFloatDart setPhaserDepth;
  final _SetFloatDart setPhaserFeedback;
  final _SetFloatDart setPhaserMix;

  // FX: Drive
  final _SetIntDart setDriveEnabled;
  final _SetFloatDart setDriveAmount;
  final _SetIntDart setDriveType;

  // FX: Flanger
  final _SetIntDart setFlangerEnabled;
  final _SetFloatDart setFlangerRate;
  final _SetFloatDart setFlangerDepth;
  final _SetFloatDart setFlangerFeedback;
  final _SetFloatDart setFlangerMix;

  // FX: Compressor
  final _SetIntDart setCompressorEnabled;
  final _SetFloatDart setCompressorThreshold;
  final _SetFloatDart setCompressorRatio;
  final _SetFloatDart setCompressorAttack;
  final _SetFloatDart setCompressorRelease;
  final _SetFloatDart setCompressorMakeupGain;

  // Master
  final _SetFloatDart setMasterVolume;
  final _GetIntDart getActiveVoices;
  final double Function(SynthEngineRef) getCpuLoad;

  // Thread-safe queue
  final _SetFloatIntDart enqueueFloat;
  final _SetInt2Dart enqueueInt;
  final _NoteOnDart enqueueNoteOnFn;
  final _NoteOffDart enqueueNoteOffFn;
  final _VoidDart enqueueAllNotesOffFn;
  final _VoidDart enqueueResetFn;

  // Arpeggiator getters
  final _GetIntDart getArpCurrentStep;
  final _GetIntDart getArpTotalSteps;
}

// ── Unison FFI bindings (lazy; may be absent on older .so builds) ──────

class UnisonBindings {
  UnisonBindings._({
    required this.setOsc1UnisonVoiceCount,
    required this.setOsc1UnisonDetuneSpread,
    required this.setOsc1UnisonStereoSpread,
    required this.setOsc1UnisonMix,
    required this.setOsc2UnisonVoiceCount,
    required this.setOsc2UnisonDetuneSpread,
    required this.setOsc2UnisonStereoSpread,
    required this.setOsc2UnisonMix,
  });

  /// Try to look up all 8 unison FFI symbols. Returns null if any are
  /// missing — the caller should check [available] before calling them.
  static UnisonBindings? _tryLookup(DynamicLibrary lib) {
    try {
      return UnisonBindings._(
        setOsc1UnisonVoiceCount: lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_osc1_unison_voice_count'),
        setOsc1UnisonDetuneSpread: lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_osc1_unison_detune_spread'),
        setOsc1UnisonStereoSpread: lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_osc1_unison_stereo_spread'),
        setOsc1UnisonMix: lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_osc1_unison_mix'),
        setOsc2UnisonVoiceCount: lib.lookupFunction<_SetIntNative, _SetIntDart>(
            'synth_engine_set_osc2_unison_voice_count'),
        setOsc2UnisonDetuneSpread: lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_osc2_unison_detune_spread'),
        setOsc2UnisonStereoSpread: lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_osc2_unison_stereo_spread'),
        setOsc2UnisonMix: lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_osc2_unison_mix'),
      );
    } catch (_) {
      return null;
    }
  }

  bool get available => true; // non-null if construction succeeded

  final _SetIntDart setOsc1UnisonVoiceCount;
  final _SetFloatDart setOsc1UnisonDetuneSpread;
  final _SetFloatDart setOsc1UnisonStereoSpread;
  final _SetFloatDart setOsc1UnisonMix;

  final _SetIntDart setOsc2UnisonVoiceCount;
  final _SetFloatDart setOsc2UnisonDetuneSpread;
  final _SetFloatDart setOsc2UnisonStereoSpread;
  final _SetFloatDart setOsc2UnisonMix;
}

// ── SynthPair FFI bindings (lazy; for Zone A + B mixer) ─────────────────

/// Pair-specific FFI types.

typedef _PairCreateNative = SynthPairRef Function(Double, Uint32);
typedef _PairCreateDart = SynthPairRef Function(double, int);

typedef _VoidPairNative = Void Function(SynthPairRef);
typedef _VoidPairDart = void Function(SynthPairRef);

typedef _ProcessPairNative = Void Function(SynthPairRef, Pointer<Float>, Uint32);
typedef _ProcessPairDart = void Function(SynthPairRef, Pointer<Float>, int);

typedef _PairGetEngineNative = SynthEngineRef Function(SynthPairRef);
typedef _PairGetEngineDart = SynthEngineRef Function(SynthPairRef);

typedef _PairSetMixNative = Void Function(SynthPairRef, Float);
typedef _PairSetMixDart = void Function(SynthPairRef, double);

typedef _PairGetIntNative = Int32 Function(SynthPairRef);
typedef _PairGetIntDart = int Function(SynthPairRef);

class PairBindings {
  PairBindings._({
    required this.create,
    required this.destroy,
    required this.process,
    required this.engineA,
    required this.engineB,
    required this.setMixA,
    required this.setMixB,
    required this.reset,
    required this.getActiveVoices,
    required this.getZoneAVoices,
    required this.getZoneBVoices,
  });

  static PairBindings? _instance;

  static PairBindings? get instance {
    if (_instance != null) return _instance;
    if (!OpenAmpSynthBindings.available) return null;
    try {
      final lib = OpenAmpSynthBindings.instance.lib;
      _instance = PairBindings._(
        create: lib.lookupFunction<_PairCreateNative, _PairCreateDart>('synth_pair_create'),
        destroy: lib.lookupFunction<_VoidPairNative, _VoidPairDart>('synth_pair_destroy'),
        process: lib.lookupFunction<_ProcessPairNative, _ProcessPairDart>('synth_pair_process'),
        engineA: lib.lookupFunction<_PairGetEngineNative, _PairGetEngineDart>('synth_pair_engine_a'),
        engineB: lib.lookupFunction<_PairGetEngineNative, _PairGetEngineDart>('synth_pair_engine_b'),
        setMixA: lib.lookupFunction<_PairSetMixNative, _PairSetMixDart>('synth_pair_set_mix_a'),
        setMixB: lib.lookupFunction<_PairSetMixNative, _PairSetMixDart>('synth_pair_set_mix_b'),
        reset: lib.lookupFunction<_VoidPairNative, _VoidPairDart>('synth_pair_reset'),
        getActiveVoices: lib.lookupFunction<_PairGetIntNative, _PairGetIntDart>('synth_pair_get_active_voices'),
        getZoneAVoices: lib.lookupFunction<_PairGetIntNative, _PairGetIntDart>('synth_pair_get_zone_a_voices'),
        getZoneBVoices: lib.lookupFunction<_PairGetIntNative, _PairGetIntDart>('synth_pair_get_zone_b_voices'),
      );
      return _instance;
    } catch (_) {
      return null;
    }
  }

  bool get available => _instance != null;

  final _PairCreateDart create;
  final _VoidPairDart destroy;
  final _ProcessPairDart process;
  final _PairGetEngineDart engineA;
  final _PairGetEngineDart engineB;
  final _PairSetMixDart setMixA;
  final _PairSetMixDart setMixB;
  final _VoidPairDart reset;
  final _PairGetIntDart getActiveVoices;
  final _PairGetIntDart getZoneAVoices;
  final _PairGetIntDart getZoneBVoices;
}

/// High-level Dart wrapper around a native SynthEnginePair.
/// Manages two SynthEngine instances (Zone A and Zone B) that are
/// mixed together with per-zone volume control.
class OpenAmpSynthPair {
  OpenAmpSynthPair({double sampleRate = 48000.0, int blockSize = 256})
      : _bindings = PairBindings.instance!,
        _handle = PairBindings.instance!
            .create(sampleRate, blockSize);

  final PairBindings _bindings;
  SynthPairRef _handle;
  bool _disposed = false;

  SynthPairRef get nativeHandle => _handle;

  void _check() {
    if (_disposed) throw StateError('OpenAmpSynthPair already disposed');
  }

  /// Access individual engine handles for note routing.
  SynthEngineRef get engineA => _bindings.engineA(_handle);
  SynthEngineRef get engineB => _bindings.engineB(_handle);

  /// Zone mix volumes (0.0-1.0).
  void setMixA(double mix) { _check(); _bindings.setMixA(_handle, mix); }
  void setMixB(double mix) { _check(); _bindings.setMixB(_handle, mix); }

  /// Render a buffer of audio through both engines (mixed).
  void process(Pointer<Float> output, int numFrames) {
    _check();
    _bindings.process(_handle, output, numFrames);
  }

  /// Reset both engines.
  void reset() { _check(); _bindings.reset(_handle); }

  /// Voice counts.
  int get activeVoices => _disposed ? 0 : _bindings.getActiveVoices(_handle);
  int get zoneAVoices => _disposed ? 0 : _bindings.getZoneAVoices(_handle);
  int get zoneBVoices => _disposed ? 0 : _bindings.getZoneBVoices(_handle);

  void dispose() {
    if (_disposed) return;
    _bindings.destroy(_handle);
    _handle = nullptr;
    _disposed = true;
  }
}

// ── High-level Dart wrapper ──────────────────────────────────────────────────

/// Parameter IDs matching the native ParamQueue::ParamId enum.
/// Used for thread-safe parameter changes via the lock-free queue.
class ParamId {
  // MIDI
  static const int noteOn = 0;
  static const int noteOff = 1;
  static const int allNotesOff = 2;

  // Osc 1
  static const int osc1Waveform = 10;
  static const int osc1Octave = 11;
  static const int osc1Detune = 12;
  static const int osc1PulseWidth = 13;
  static const int osc1Volume = 14;
  static const int osc1NoiseType = 15;
  static const int osc1SubOscMode = 16;
  static const int osc1SubOscVolume = 17;
  static const int osc1FmEnabled = 18;
  static const int osc1FmAmount = 19;

  // Osc 2
  static const int osc2Waveform = 20;
  static const int osc2Octave = 21;
  static const int osc2Detune = 22;
  static const int osc2PulseWidth = 23;
  static const int osc2Volume = 24;
  static const int oscMix = 25;
  static const int osc2NoiseType = 26;
  static const int osc2SubOscMode = 27;
  static const int osc2SubOscVolume = 28;
  static const int osc2FmEnabled = 29;
  static const int osc2FmAmount = 30;

  // Filter
  static const int filterType = 40;
  static const int filterCutoff = 41;
  static const int filterResonance = 42;
  static const int filterEnvAmount = 43;
  static const int filterKeyTracking = 44;
  static const int filterDrive = 45;

  // Amp envelope
  static const int ampAttack = 50;
  static const int ampDecay = 51;
  static const int ampSustain = 52;
  static const int ampRelease = 53;
  static const int ampDelay = 54;
  static const int ampHold = 55;
  static const int ampAttackCurve = 56;
  static const int ampDecayCurve = 57;
  static const int ampReleaseCurve = 58;

  // Filter envelope
  static const int filterAttack = 60;
  static const int filterDecay = 61;
  static const int filterSustain = 62;
  static const int filterRelease = 63;
  static const int filterDelay = 64;
  static const int filterHold = 65;
  static const int filterAttackCurve = 66;
  static const int filterDecayCurve = 67;
  static const int filterReleaseCurve = 68;

  // LFO 1
  static const int lfo1Waveform = 70;
  static const int lfo1Rate = 71;
  static const int lfo1Depth = 72;
  static const int lfo1Target = 73;
  static const int lfo1FadeIn = 74;
  static const int lfo1TempoSync = 75;
  static const int lfo1TempoDivision = 76;

  // LFO 2
  static const int lfo2Waveform = 80;
  static const int lfo2Rate = 81;
  static const int lfo2Depth = 82;
  static const int lfo2Target = 83;
  static const int lfo2FadeIn = 84;
  static const int lfo2TempoSync = 85;
  static const int lfo2TempoDivision = 86;

  // FX: Chorus
  static const int chorusEnabled = 90;
  static const int chorusRate = 91;
  static const int chorusDepth = 92;
  static const int chorusMix = 93;

  // FX: Delay
  static const int delayEnabled = 94;
  static const int delayTime = 95;
  static const int delayFeedback = 96;
  static const int delayMix = 97;

  // FX: Reverb
  static const int reverbEnabled = 98;
  static const int reverbSize = 99;
  static const int reverbDamping = 100;
  static const int reverbMix = 101;

  // FX: Phaser
  static const int phaserEnabled = 102;
  static const int phaserRate = 103;
  static const int phaserDepth = 104;
  static const int phaserFeedback = 105;
  static const int phaserMix = 106;

  // FX: Drive
  static const int driveEnabled = 107;
  static const int driveAmount = 108;
  static const int driveType = 109;

  // FX: Flanger
  static const int flangerEnabled = 110;
  static const int flangerRate = 111;
  static const int flangerDepth = 112;
  static const int flangerFeedback = 113;
  static const int flangerMix = 114;

  // FX: Compressor
  static const int compressorEnabled = 115;
  static const int compressorThreshold = 116;
  static const int compressorRatio = 117;
  static const int compressorAttack = 118;
  static const int compressorRelease = 119;
  static const int compressorMakeupGain = 120;

  // Master
  static const int masterVolume = 130;

  // Unison 1
  static const int osc1UnisonVoiceCount = 140;
  static const int osc1UnisonDetuneSpread = 141;
  static const int osc1UnisonStereoSpread = 142;
  static const int osc1UnisonMix = 143;

  // Unison 2
  static const int osc2UnisonVoiceCount = 150;
  static const int osc2UnisonDetuneSpread = 151;
  static const int osc2UnisonStereoSpread = 152;
  static const int osc2UnisonMix = 153;

  // Arpeggiator
  static const int arpEnabled = 160;
  static const int arpTempo = 161;
  static const int arpPattern = 162;
  static const int arpOctaveRange = 163;
  static const int arpGate = 164;
  static const int arpResolution = 165;
  static const int arpSwing = 166;
  static const int arpHold = 167;

  // Voice priority
  static const int voicePriorityMode = 170;

  // New FX: EQ (slot 1)
  static const int fxSlot1Type = 180;
  static const int fxSlot1Enabled = 181;
  static const int fxSlot1Param0 = 182;
  static const int fxSlot1Param1 = 183;
  static const int fxSlot1Param2 = 184;
  static const int fxSlot1Param3 = 185;
  static const int fxSlot1Param4 = 186;
  static const int fxSlot1Param5 = 187;
  static const int fxSlot1Param6 = 188;
  static const int fxSlot1Param7 = 189;

  // New FX: Limiter (slot 2)
  static const int fxSlot2Type = 190;
  static const int fxSlot2Enabled = 191;
  static const int fxSlot2Param0 = 192;
  static const int fxSlot2Param1 = 193;
  static const int fxSlot2Param2 = 194;
  static const int fxSlot2Param3 = 195;
  static const int fxSlot2Param4 = 196;

  // New FX: Rotary / Tremolo (slot 3)
  static const int fxSlot3Type = 197;
  static const int fxSlot3Enabled = 198;
  static const int fxSlot3Param0 = 199;
  static const int fxSlot3Param1 = 200;
  static const int fxSlot3Param2 = 201;
  static const int fxSlot3Param3 = 202;
  static const int fxSlot3Param4 = 203;
  static const int fxSlot3Param5 = 204;

  // FX Engine master
  static const int fxMasterEnabled = 205;
  static const int fxMasterMix = 206;

  // Reset
  static const int reset = 250;
}

/// Idiomatic Dart wrapper around the native SynthEngine.
class OpenAmpSynth {
  OpenAmpSynth({double sampleRate = 48000.0, int blockSize = 256})
      : _bindings = OpenAmpSynthBindings.instance,
        _handle =
            OpenAmpSynthBindings.instance.create(sampleRate, blockSize);

  /// Create an OpenAmpSynth wrapping an existing native handle.
  /// Used when accessing engine B from a SynthEnginePair.    /// Does NOT own the handle — dispose() will NOT destroy it.
  OpenAmpSynth.fromHandle(SynthEngineRef handle)
      : _bindings = OpenAmpSynthBindings.instance,
        _handle = handle,
        _ownsHandle = false;

  final OpenAmpSynthBindings _bindings;
  SynthEngineRef _handle;
  bool _disposed = false;
  bool _ownsHandle = true;

  /// Raw native handle. Exposed so the audio-stream binding can bind a
  /// realtime PortAudio callback directly to this engine. Treat as
  /// opaque — never store it past the lifetime of this OpenAmpSynth.
  SynthEngineRef get nativeHandle => _handle;

  void _check() {
    if (_disposed) {
      throw StateError('OpenAmpSynth already disposed');
    }
  }

  // ── MIDI (thread-safe via queue) ──────────────────────────────────────────

  void noteOn(int midiNote, {double velocity = 1.0}) {
    _check();
    _bindings.enqueueNoteOnFn(_handle, midiNote, velocity);
  }

  void noteOff(int midiNote) {
    _check();
    _bindings.enqueueNoteOffFn(_handle, midiNote);
  }

  void allNotesOff() {
    _check();
    _bindings.enqueueAllNotesOffFn(_handle);
  }

  // ── Thread-safe parameter enqueue ───────────────────────────────────────

  /// Enqueue a float parameter change. Takes effect at next block boundary.
  void enqueueFloat(int paramId, double value) {
    _check();
    _bindings.enqueueFloat(_handle, paramId, value);
  }

  /// Enqueue an int parameter change. Takes effect at next block boundary.
  void enqueueInt(int paramId, int value) {
    _check();
    _bindings.enqueueInt(_handle, paramId, value);
  }

  // ── Osc 1 (queue-based) ─────────────────────────────────────────────────

  set osc1Waveform(int w) { enqueueInt(ParamId.osc1Waveform, w); }
  set osc1Octave(int o) { enqueueInt(ParamId.osc1Octave, o); }
  set osc1Detune(double cents) { enqueueFloat(ParamId.osc1Detune, cents); }
  set osc1PulseWidth(double pw) { enqueueFloat(ParamId.osc1PulseWidth, pw); }
  set osc1Volume(double v) { enqueueFloat(ParamId.osc1Volume, v); }
  set osc1NoiseType(int t) { enqueueInt(ParamId.osc1NoiseType, t); }
  set osc1SubOscMode(int m) { enqueueInt(ParamId.osc1SubOscMode, m); }
  set osc1SubOscVolume(double v) { enqueueFloat(ParamId.osc1SubOscVolume, v); }
  set osc1FmEnabled(bool e) { enqueueInt(ParamId.osc1FmEnabled, e ? 1 : 0); }
  set osc1FmAmount(double a) { enqueueFloat(ParamId.osc1FmAmount, a); }

  // ── Osc 2 (queue-based) ─────────────────────────────────────────────────

  set osc2Waveform(int w) { enqueueInt(ParamId.osc2Waveform, w); }
  set osc2Octave(int o) { enqueueInt(ParamId.osc2Octave, o); }
  set osc2Detune(double cents) { enqueueFloat(ParamId.osc2Detune, cents); }
  set osc2PulseWidth(double pw) { enqueueFloat(ParamId.osc2PulseWidth, pw); }
  set osc2Volume(double v) { enqueueFloat(ParamId.osc2Volume, v); }
  set osc2NoiseType(int t) { enqueueInt(ParamId.osc2NoiseType, t); }
  set osc2SubOscMode(int m) { enqueueInt(ParamId.osc2SubOscMode, m); }
  set osc2SubOscVolume(double v) { enqueueFloat(ParamId.osc2SubOscVolume, v); }
  set osc2FmEnabled(bool e) { enqueueInt(ParamId.osc2FmEnabled, e ? 1 : 0); }
  set osc2FmAmount(double a) { enqueueFloat(ParamId.osc2FmAmount, a); }
  set oscMix(double m) { enqueueFloat(ParamId.oscMix, m); }

  // ── Filter (queue-based) ────────────────────────────────────────────────

  set filterType(int t) { enqueueInt(ParamId.filterType, t); }
  set filterCutoff(double hz) { enqueueFloat(ParamId.filterCutoff, hz); }
  set filterResonance(double q) { enqueueFloat(ParamId.filterResonance, q); }
  set filterEnvAmount(double a) { enqueueFloat(ParamId.filterEnvAmount, a); }
  set filterKeyTracking(double k) { enqueueFloat(ParamId.filterKeyTracking, k); }
  set filterDrive(double d) { enqueueFloat(ParamId.filterDrive, d); }

  // ── Amp envelope (queue-based) ──────────────────────────────────────────

  set ampAttack(double ms) { enqueueFloat(ParamId.ampAttack, ms); }
  set ampDecay(double ms) { enqueueFloat(ParamId.ampDecay, ms); }
  set ampSustain(double level) { enqueueFloat(ParamId.ampSustain, level); }
  set ampRelease(double ms) { enqueueFloat(ParamId.ampRelease, ms); }
  set ampDelay(double ms) { enqueueFloat(ParamId.ampDelay, ms); }
  set ampHold(double ms) { enqueueFloat(ParamId.ampHold, ms); }
  set ampAttackCurve(int c) { enqueueInt(ParamId.ampAttackCurve, c); }
  set ampDecayCurve(int c) { enqueueInt(ParamId.ampDecayCurve, c); }
  set ampReleaseCurve(int c) { enqueueInt(ParamId.ampReleaseCurve, c); }

  // ── Filter envelope (queue-based) ────────────────────────────────────────

  set filterAttack(double ms) { enqueueFloat(ParamId.filterAttack, ms); }
  set filterDecay(double ms) { enqueueFloat(ParamId.filterDecay, ms); }
  set filterSustain(double level) { enqueueFloat(ParamId.filterSustain, level); }
  set filterRelease(double ms) { enqueueFloat(ParamId.filterRelease, ms); }
  set filterDelay(double ms) { enqueueFloat(ParamId.filterDelay, ms); }
  set filterHold(double ms) { enqueueFloat(ParamId.filterHold, ms); }
  set filterAttackCurve(int c) { enqueueInt(ParamId.filterAttackCurve, c); }
  set filterDecayCurve(int c) { enqueueInt(ParamId.filterDecayCurve, c); }
  set filterReleaseCurve(int c) { enqueueInt(ParamId.filterReleaseCurve, c); }

  // ── LFO 1 (queue-based) ──────────────────────────────────────────────────

  set lfo1Waveform(int w) { enqueueInt(ParamId.lfo1Waveform, w); }
  set lfo1Rate(double hz) { enqueueFloat(ParamId.lfo1Rate, hz); }
  set lfo1Depth(double d) { enqueueFloat(ParamId.lfo1Depth, d); }
  set lfo1Target(int t) { enqueueInt(ParamId.lfo1Target, t); }
  set lfo1FadeIn(double s) { enqueueFloat(ParamId.lfo1FadeIn, s); }
  set lfo1TempoSync(bool e) { enqueueInt(ParamId.lfo1TempoSync, e ? 1 : 0); }
  set lfo1TempoDivision(int d) { enqueueInt(ParamId.lfo1TempoDivision, d); }

  // ── LFO 2 (queue-based) ──────────────────────────────────────────────────

  set lfo2Waveform(int w) { enqueueInt(ParamId.lfo2Waveform, w); }
  set lfo2Rate(double hz) { enqueueFloat(ParamId.lfo2Rate, hz); }
  set lfo2Depth(double d) { enqueueFloat(ParamId.lfo2Depth, d); }
  set lfo2Target(int t) { enqueueInt(ParamId.lfo2Target, t); }
  set lfo2FadeIn(double s) { enqueueFloat(ParamId.lfo2FadeIn, s); }
  set lfo2TempoSync(bool e) { enqueueInt(ParamId.lfo2TempoSync, e ? 1 : 0); }
  set lfo2TempoDivision(int d) { enqueueInt(ParamId.lfo2TempoDivision, d); }

  // ── FX (queue-based) ──────────────────────────────────────────────────────

  set chorusEnabled(bool e) { enqueueInt(ParamId.chorusEnabled, e ? 1 : 0); }
  set chorusRate(double hz) { enqueueFloat(ParamId.chorusRate, hz); }
  set chorusDepth(double d) { enqueueFloat(ParamId.chorusDepth, d); }
  set chorusMix(double m) { enqueueFloat(ParamId.chorusMix, m); }

  set delayEnabled(bool e) { enqueueInt(ParamId.delayEnabled, e ? 1 : 0); }
  set delayTime(double ms) { enqueueFloat(ParamId.delayTime, ms); }
  set delayFeedback(double fb) { enqueueFloat(ParamId.delayFeedback, fb); }
  set delayMix(double m) { enqueueFloat(ParamId.delayMix, m); }

  set reverbEnabled(bool e) { enqueueInt(ParamId.reverbEnabled, e ? 1 : 0); }
  set reverbSize(double s) { enqueueFloat(ParamId.reverbSize, s); }
  set reverbDamping(double d) { enqueueFloat(ParamId.reverbDamping, d); }
  set reverbMix(double m) { enqueueFloat(ParamId.reverbMix, m); }

  set phaserEnabled(bool e) { enqueueInt(ParamId.phaserEnabled, e ? 1 : 0); }
  set phaserRate(double hz) { enqueueFloat(ParamId.phaserRate, hz); }
  set phaserDepth(double d) { enqueueFloat(ParamId.phaserDepth, d); }
  set phaserFeedback(double fb) { enqueueFloat(ParamId.phaserFeedback, fb); }
  set phaserMix(double m) { enqueueFloat(ParamId.phaserMix, m); }

  // ── Drive (queue-based) ──────────────────────────────────────────────────

  set driveEnabled(bool e) { enqueueInt(ParamId.driveEnabled, e ? 1 : 0); }
  set driveAmount(double a) { enqueueFloat(ParamId.driveAmount, a); }
  set driveType(int t) { enqueueInt(ParamId.driveType, t); }

  // ── Flanger (queue-based) ────────────────────────────────────────────────

  set flangerEnabled(bool e) { enqueueInt(ParamId.flangerEnabled, e ? 1 : 0); }
  set flangerRate(double hz) { enqueueFloat(ParamId.flangerRate, hz); }
  set flangerDepth(double d) { enqueueFloat(ParamId.flangerDepth, d); }
  set flangerFeedback(double fb) { enqueueFloat(ParamId.flangerFeedback, fb); }
  set flangerMix(double m) { enqueueFloat(ParamId.flangerMix, m); }

  // ── Compressor (queue-based) ─────────────────────────────────────────────

  set compressorEnabled(bool e) { enqueueInt(ParamId.compressorEnabled, e ? 1 : 0); }
  set compressorThreshold(double t) { enqueueFloat(ParamId.compressorThreshold, t); }
  set compressorRatio(double r) { enqueueFloat(ParamId.compressorRatio, r); }
  set compressorAttack(double a) { enqueueFloat(ParamId.compressorAttack, a); }
  set compressorRelease(double r) { enqueueFloat(ParamId.compressorRelease, r); }
  set compressorMakeupGain(double g) { enqueueFloat(ParamId.compressorMakeupGain, g); }

  // ── Unison (queue-based) ─────────────────────────────────────────────────

  set osc1UnisonVoiceCount(int v) { enqueueInt(ParamId.osc1UnisonVoiceCount, v); }
  set osc1UnisonDetuneSpread(double v) { enqueueFloat(ParamId.osc1UnisonDetuneSpread, v); }
  set osc1UnisonStereoSpread(double v) { enqueueFloat(ParamId.osc1UnisonStereoSpread, v); }
  set osc1UnisonMix(double v) { enqueueFloat(ParamId.osc1UnisonMix, v); }

  set osc2UnisonVoiceCount(int v) { enqueueInt(ParamId.osc2UnisonVoiceCount, v); }
  set osc2UnisonDetuneSpread(double v) { enqueueFloat(ParamId.osc2UnisonDetuneSpread, v); }
  set osc2UnisonStereoSpread(double v) { enqueueFloat(ParamId.osc2UnisonStereoSpread, v); }
  set osc2UnisonMix(double v) { enqueueFloat(ParamId.osc2UnisonMix, v); }

  // ── Voice Priority (queue-based) ─────────────────────────────────────────

  set voicePriorityMode(int m) { enqueueInt(ParamId.voicePriorityMode, m); }

  // ── Multi-Slot FX (queue-based) ───────────────────────────────────────────

  set fxSlot1Type(int t) { enqueueInt(ParamId.fxSlot1Type, t); }
  set fxSlot1Enabled(bool e) { enqueueInt(ParamId.fxSlot1Enabled, e ? 1 : 0); }
  set fxSlot1Param0(double v) { enqueueFloat(ParamId.fxSlot1Param0, v); }
  set fxSlot1Param1(double v) { enqueueFloat(ParamId.fxSlot1Param1, v); }
  set fxSlot1Param2(double v) { enqueueFloat(ParamId.fxSlot1Param2, v); }
  set fxSlot1Param3(double v) { enqueueFloat(ParamId.fxSlot1Param3, v); }
  set fxSlot1Param4(double v) { enqueueFloat(ParamId.fxSlot1Param4, v); }
  set fxSlot1Param5(double v) { enqueueFloat(ParamId.fxSlot1Param5, v); }
  set fxSlot1Param6(double v) { enqueueFloat(ParamId.fxSlot1Param6, v); }
  set fxSlot1Param7(double v) { enqueueFloat(ParamId.fxSlot1Param7, v); }

  set fxSlot2Type(int t) { enqueueInt(ParamId.fxSlot2Type, t); }
  set fxSlot2Enabled(bool e) { enqueueInt(ParamId.fxSlot2Enabled, e ? 1 : 0); }
  set fxSlot2Param0(double v) { enqueueFloat(ParamId.fxSlot2Param0, v); }
  set fxSlot2Param1(double v) { enqueueFloat(ParamId.fxSlot2Param1, v); }
  set fxSlot2Param2(double v) { enqueueFloat(ParamId.fxSlot2Param2, v); }
  set fxSlot2Param3(double v) { enqueueFloat(ParamId.fxSlot2Param3, v); }
  set fxSlot2Param4(double v) { enqueueFloat(ParamId.fxSlot2Param4, v); }

  set fxSlot3Type(int t) { enqueueInt(ParamId.fxSlot3Type, t); }
  set fxSlot3Enabled(bool e) { enqueueInt(ParamId.fxSlot3Enabled, e ? 1 : 0); }
  set fxSlot3Param0(double v) { enqueueFloat(ParamId.fxSlot3Param0, v); }
  set fxSlot3Param1(double v) { enqueueFloat(ParamId.fxSlot3Param1, v); }
  set fxSlot3Param2(double v) { enqueueFloat(ParamId.fxSlot3Param2, v); }
  set fxSlot3Param3(double v) { enqueueFloat(ParamId.fxSlot3Param3, v); }
  set fxSlot3Param4(double v) { enqueueFloat(ParamId.fxSlot3Param4, v); }
  set fxSlot3Param5(double v) { enqueueFloat(ParamId.fxSlot3Param5, v); }

  set fxMasterEnabled(bool e) { enqueueInt(ParamId.fxMasterEnabled, e ? 1 : 0); }
  set fxMasterMix(double v) { enqueueFloat(ParamId.fxMasterMix, v); }

  // ── Master (queue-based) ─────────────────────────────────────────────────

  set masterVolume(double v) { enqueueFloat(ParamId.masterVolume, v); }

  // ── Arpeggiator (queue-based) ──────────────────────────────────────────────

  set arpEnabled(bool e) { enqueueInt(ParamId.arpEnabled, e ? 1 : 0); }
  set arpTempo(double bpm) { enqueueFloat(ParamId.arpTempo, bpm); }
  set arpPattern(int p) { enqueueInt(ParamId.arpPattern, p); }
  set arpOctaveRange(int o) { enqueueInt(ParamId.arpOctaveRange, o); }
  set arpGate(double g) { enqueueFloat(ParamId.arpGate, g); }
  set arpResolution(int r) { enqueueInt(ParamId.arpResolution, r); }
   set arpSwing(double v) { enqueueFloat(ParamId.arpSwing, v); }
   set arpHold(bool v) { enqueueInt(ParamId.arpHold, v ? 1 : 0); }

  int get activeVoices {
    if (_disposed) return 0;
    return _bindings.getActiveVoices(_handle);
  }

  /// Returns 0.0–1.0+ representing the fraction of real-time budget used.
  double get cpuLoad {
    if (_disposed) return 0.0;
    return _bindings.getCpuLoad(_handle);
  }

  /// Render a buffer of mono audio in-place.
  /// [output] must contain at least [numFrames] floats.
  void process(Pointer<Float> output, int numFrames) {
    _check();
    _bindings.process(_handle, output, numFrames);
  }

  void reset() {
    _check();
    _bindings.reset(_handle);
  }

  void dispose() {
    if (_disposed) return;
    if (_ownsHandle) {
      _bindings.destroy(_handle);
    }
    _handle = nullptr;
    _disposed = true;
  }
}
