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
        // Master
        setMasterVolume = lib.lookupFunction<_SetFloatNative, _SetFloatDart>(
            'synth_engine_set_master_volume'),
        getActiveVoices = lib.lookupFunction<_GetIntNative, _GetIntDart>(
            'synth_engine_get_active_voices');

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

  // Master
  final _SetFloatDart setMasterVolume;
  final _GetIntDart getActiveVoices;
}

// ── High-level Dart wrapper ──────────────────────────────────────────────────

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

  // ── MIDI ───────────────────────────────────────────────────────────────────

  void noteOn(int midiNote, {double velocity = 1.0}) {
    _check();
    _bindings.noteOn(_handle, midiNote, velocity);
  }

  void noteOff(int midiNote) {
    _check();
    _bindings.noteOff(_handle, midiNote);
  }

  void allNotesOff() {
    _check();
    _bindings.allNotesOff(_handle);
  }

  // ── Osc 1 ──────────────────────────────────────────────────────────────────

  set osc1Waveform(int w) { _check(); _bindings.setOsc1Waveform(_handle, w); }
  set osc1Octave(int o) { _check(); _bindings.setOsc1Octave(_handle, o); }
  set osc1Detune(double cents) { _check(); _bindings.setOsc1Detune(_handle, cents); }
  set osc1PulseWidth(double pw) { _check(); _bindings.setOsc1PulseWidth(_handle, pw); }
  set osc1Volume(double v) { _check(); _bindings.setOsc1Volume(_handle, v); }

  // ── Osc 2 ──────────────────────────────────────────────────────────────────

  set osc2Waveform(int w) { _check(); _bindings.setOsc2Waveform(_handle, w); }
  set osc2Octave(int o) { _check(); _bindings.setOsc2Octave(_handle, o); }
  set osc2Detune(double cents) { _check(); _bindings.setOsc2Detune(_handle, cents); }
  set osc2PulseWidth(double pw) { _check(); _bindings.setOsc2PulseWidth(_handle, pw); }
  set osc2Volume(double v) { _check(); _bindings.setOsc2Volume(_handle, v); }
  set oscMix(double m) { _check(); _bindings.setOscMix(_handle, m); }

  // ── Filter ─────────────────────────────────────────────────────────────────

  set filterType(int t) { _check(); _bindings.setFilterType(_handle, t); }
  set filterCutoff(double hz) { _check(); _bindings.setFilterCutoff(_handle, hz); }
  set filterResonance(double q) { _check(); _bindings.setFilterResonance(_handle, q); }
  set filterEnvAmount(double a) { _check(); _bindings.setFilterEnvAmount(_handle, a); }

  // ── Amp envelope ───────────────────────────────────────────────────────────

  set ampAttack(double ms) { _check(); _bindings.setAmpAttack(_handle, ms); }
  set ampDecay(double ms) { _check(); _bindings.setAmpDecay(_handle, ms); }
  set ampSustain(double level) { _check(); _bindings.setAmpSustain(_handle, level); }
  set ampRelease(double ms) { _check(); _bindings.setAmpRelease(_handle, ms); }

  // ── Filter envelope ────────────────────────────────────────────────────────

  set filterAttack(double ms) { _check(); _bindings.setFilterAttack(_handle, ms); }
  set filterDecay(double ms) { _check(); _bindings.setFilterDecay(_handle, ms); }
  set filterSustain(double level) { _check(); _bindings.setFilterSustain(_handle, level); }
  set filterRelease(double ms) { _check(); _bindings.setFilterRelease(_handle, ms); }

  // ── LFO 1 ──────────────────────────────────────────────────────────────────

  set lfo1Waveform(int w) { _check(); _bindings.setLfo1Waveform(_handle, w); }
  set lfo1Rate(double hz) { _check(); _bindings.setLfo1Rate(_handle, hz); }
  set lfo1Depth(double d) { _check(); _bindings.setLfo1Depth(_handle, d); }
  set lfo1Target(int t) { _check(); _bindings.setLfo1Target(_handle, t); }

  // ── LFO 2 ──────────────────────────────────────────────────────────────────

  set lfo2Waveform(int w) { _check(); _bindings.setLfo2Waveform(_handle, w); }
  set lfo2Rate(double hz) { _check(); _bindings.setLfo2Rate(_handle, hz); }
  set lfo2Depth(double d) { _check(); _bindings.setLfo2Depth(_handle, d); }
  set lfo2Target(int t) { _check(); _bindings.setLfo2Target(_handle, t); }

  // ── FX ─────────────────────────────────────────────────────────────────────

  set chorusEnabled(bool e) { _check(); _bindings.setChorusEnabled(_handle, e ? 1 : 0); }
  set chorusRate(double hz) { _check(); _bindings.setChorusRate(_handle, hz); }
  set chorusDepth(double d) { _check(); _bindings.setChorusDepth(_handle, d); }
  set chorusMix(double m) { _check(); _bindings.setChorusMix(_handle, m); }

  set delayEnabled(bool e) { _check(); _bindings.setDelayEnabled(_handle, e ? 1 : 0); }
  set delayTime(double ms) { _check(); _bindings.setDelayTime(_handle, ms); }
  set delayFeedback(double fb) { _check(); _bindings.setDelayFeedback(_handle, fb); }
  set delayMix(double m) { _check(); _bindings.setDelayMix(_handle, m); }

  set reverbEnabled(bool e) { _check(); _bindings.setReverbEnabled(_handle, e ? 1 : 0); }
  set reverbSize(double s) { _check(); _bindings.setReverbSize(_handle, s); }
  set reverbDamping(double d) { _check(); _bindings.setReverbDamping(_handle, d); }
  set reverbMix(double m) { _check(); _bindings.setReverbMix(_handle, m); }

  set phaserEnabled(bool e) { _check(); _bindings.setPhaserEnabled(_handle, e ? 1 : 0); }
  set phaserRate(double hz) { _check(); _bindings.setPhaserRate(_handle, hz); }
  set phaserDepth(double d) { _check(); _bindings.setPhaserDepth(_handle, d); }
  set phaserFeedback(double fb) { _check(); _bindings.setPhaserFeedback(_handle, fb); }
  set phaserMix(double m) { _check(); _bindings.setPhaserMix(_handle, m); }

  // ── Drive ──────────────────────────────────────────────────────────────────

  set driveEnabled(bool e) { _check(); _bindings.setDriveEnabled(_handle, e ? 1 : 0); }
  set driveAmount(double a) { _check(); _bindings.setDriveAmount(_handle, a); }
  set driveType(int t) { _check(); _bindings.setDriveType(_handle, t); }

  // ── Master ─────────────────────────────────────────────────────────────────

  set masterVolume(double v) { _check(); _bindings.setMasterVolume(_handle, v); }

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
