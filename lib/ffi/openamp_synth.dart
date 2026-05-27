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

typedef SynthEngineRef = Pointer<_SynthHandle>;

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

  // Thread-safe queue
  final _SetFloatIntDart enqueueFloat;
  final _SetInt2Dart enqueueInt;
  final _NoteOnDart enqueueNoteOnFn;
  final _NoteOffDart enqueueNoteOffFn;
  final _VoidDart enqueueAllNotesOffFn;
  final _VoidDart enqueueResetFn;
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

  // Osc 2
  static const int osc2Waveform = 20;
  static const int osc2Octave = 21;
  static const int osc2Detune = 22;
  static const int osc2PulseWidth = 23;
  static const int osc2Volume = 24;
  static const int oscMix = 25;

  // Filter
  static const int filterType = 30;
  static const int filterCutoff = 31;
  static const int filterResonance = 32;
  static const int filterEnvAmount = 33;

  // Amp envelope
  static const int ampAttack = 40;
  static const int ampDecay = 41;
  static const int ampSustain = 42;
  static const int ampRelease = 43;

  // Filter envelope
  static const int filterAttack = 50;
  static const int filterDecay = 51;
  static const int filterSustain = 52;
  static const int filterRelease = 53;

  // LFO 1
  static const int lfo1Waveform = 60;
  static const int lfo1Rate = 61;
  static const int lfo1Depth = 62;
  static const int lfo1Target = 63;

  // LFO 2
  static const int lfo2Waveform = 70;
  static const int lfo2Rate = 71;
  static const int lfo2Depth = 72;
  static const int lfo2Target = 73;

  // FX: Chorus
  static const int chorusEnabled = 80;
  static const int chorusRate = 81;
  static const int chorusDepth = 82;
  static const int chorusMix = 83;

  // FX: Delay
  static const int delayEnabled = 84;
  static const int delayTime = 85;
  static const int delayFeedback = 86;
  static const int delayMix = 87;

  // FX: Reverb
  static const int reverbEnabled = 88;
  static const int reverbSize = 89;
  static const int reverbDamping = 90;
  static const int reverbMix = 91;

  // FX: Phaser
  static const int phaserEnabled = 92;
  static const int phaserRate = 93;
  static const int phaserDepth = 94;
  static const int phaserFeedback = 95;
  static const int phaserMix = 96;

  // FX: Drive
  static const int driveEnabled = 97;
  static const int driveAmount = 98;
  static const int driveType = 99;

  // FX: Flanger
  static const int flangerEnabled = 100;
  static const int flangerRate = 101;
  static const int flangerDepth = 102;
  static const int flangerFeedback = 103;
  static const int flangerMix = 104;

  // FX: Compressor
  static const int compressorEnabled = 105;
  static const int compressorThreshold = 106;
  static const int compressorRatio = 107;
  static const int compressorAttack = 108;
  static const int compressorRelease = 109;
  static const int compressorMakeupGain = 110;

  // Master
  static const int masterVolume = 120;

  // Unison 1
  static const int osc1UnisonVoiceCount = 130;
  static const int osc1UnisonDetuneSpread = 131;
  static const int osc1UnisonStereoSpread = 132;
  static const int osc1UnisonMix = 133;

  // Unison 2
  static const int osc2UnisonVoiceCount = 140;
  static const int osc2UnisonDetuneSpread = 141;
  static const int osc2UnisonStereoSpread = 142;
  static const int osc2UnisonMix = 143;

  // Arpeggiator
  static const int arpEnabled = 150;
  static const int arpTempo = 151;
  static const int arpPattern = 152;
  static const int arpOctaveRange = 153;
  static const int arpGate = 154;
  static const int arpResolution = 155;

  // Reset
  static const int reset = 200;
}

/// Idiomatic Dart wrapper around the native SynthEngine.
class OpenAmpSynth {
  OpenAmpSynth({double sampleRate = 48000.0, int blockSize = 256})
      : _bindings = OpenAmpSynthBindings.instance,
        _handle =
            OpenAmpSynthBindings.instance.create(sampleRate, blockSize);

  final OpenAmpSynthBindings _bindings;
  SynthEngineRef _handle;
  bool _disposed = false;

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

  // ── Osc 2 (queue-based) ─────────────────────────────────────────────────

  set osc2Waveform(int w) { enqueueInt(ParamId.osc2Waveform, w); }
  set osc2Octave(int o) { enqueueInt(ParamId.osc2Octave, o); }
  set osc2Detune(double cents) { enqueueFloat(ParamId.osc2Detune, cents); }
  set osc2PulseWidth(double pw) { enqueueFloat(ParamId.osc2PulseWidth, pw); }
  set osc2Volume(double v) { enqueueFloat(ParamId.osc2Volume, v); }
  set oscMix(double m) { enqueueFloat(ParamId.oscMix, m); }

  // ── Filter (queue-based) ────────────────────────────────────────────────

  set filterType(int t) { enqueueInt(ParamId.filterType, t); }
  set filterCutoff(double hz) { enqueueFloat(ParamId.filterCutoff, hz); }
  set filterResonance(double q) { enqueueFloat(ParamId.filterResonance, q); }
  set filterEnvAmount(double a) { enqueueFloat(ParamId.filterEnvAmount, a); }

  // ── Amp envelope (queue-based) ──────────────────────────────────────────

  set ampAttack(double ms) { enqueueFloat(ParamId.ampAttack, ms); }
  set ampDecay(double ms) { enqueueFloat(ParamId.ampDecay, ms); }
  set ampSustain(double level) { enqueueFloat(ParamId.ampSustain, level); }
  set ampRelease(double ms) { enqueueFloat(ParamId.ampRelease, ms); }

  // ── Filter envelope (queue-based) ────────────────────────────────────────

  set filterAttack(double ms) { enqueueFloat(ParamId.filterAttack, ms); }
  set filterDecay(double ms) { enqueueFloat(ParamId.filterDecay, ms); }
  set filterSustain(double level) { enqueueFloat(ParamId.filterSustain, level); }
  set filterRelease(double ms) { enqueueFloat(ParamId.filterRelease, ms); }

  // ── LFO 1 (queue-based) ──────────────────────────────────────────────────

  set lfo1Waveform(int w) { enqueueInt(ParamId.lfo1Waveform, w); }
  set lfo1Rate(double hz) { enqueueFloat(ParamId.lfo1Rate, hz); }
  set lfo1Depth(double d) { enqueueFloat(ParamId.lfo1Depth, d); }
  set lfo1Target(int t) { enqueueInt(ParamId.lfo1Target, t); }

  // ── LFO 2 (queue-based) ──────────────────────────────────────────────────

  set lfo2Waveform(int w) { enqueueInt(ParamId.lfo2Waveform, w); }
  set lfo2Rate(double hz) { enqueueFloat(ParamId.lfo2Rate, hz); }
  set lfo2Depth(double d) { enqueueFloat(ParamId.lfo2Depth, d); }
  set lfo2Target(int t) { enqueueInt(ParamId.lfo2Target, t); }

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

  // ── Master (queue-based) ─────────────────────────────────────────────────

  set masterVolume(double v) { enqueueFloat(ParamId.masterVolume, v); }

  // ── Arpeggiator (queue-based) ──────────────────────────────────────────────

  set arpEnabled(bool e) { enqueueInt(ParamId.arpEnabled, e ? 1 : 0); }
  set arpTempo(double bpm) { enqueueFloat(ParamId.arpTempo, bpm); }
  set arpPattern(int p) { enqueueInt(ParamId.arpPattern, p); }
  set arpOctaveRange(int o) { enqueueInt(ParamId.arpOctaveRange, o); }
  set arpGate(double g) { enqueueFloat(ParamId.arpGate, g); }
  set arpResolution(int r) { enqueueInt(ParamId.arpResolution, r); }

  int get activeVoices {
    if (_disposed) return 0;
    return _bindings.getActiveVoices(_handle);
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
    _bindings.destroy(_handle);
    _handle = nullptr;
    _disposed = true;
  }
}
