// ignore_for_file: library_private_types_in_public_api
// Dart FFI bindings for libopenamp_dart_ffi.so audio_stream symbols.
//
// The native AudioStream owns a PortAudio output stream and an internal
// process callback. We bind it to a SynthEngine via
// `audio_stream_create_for_synth(synthRef, sr, blockSize, deviceIndex)` so
// the audio thread renders directly from the engine — Dart never sees the
// realtime callback, which means there's no GC / isolate latency.
//
// IMPORTANT: audio_system_init() must be called before any other audio
// function. audio_system_shutdown() must be called at app exit.
// Device enumeration reads from a cache and never calls Pa_Init/Term.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'openamp_synth.dart' show OpenAmpSynthBindings, SynthEngineRef;

// ── Opaque handle ────────────────────────────────────────────────────────────

final class _AudioStreamHandle extends Opaque {}

typedef AudioStreamRef = Pointer<_AudioStreamHandle>;

// ── Native typedefs ──────────────────────────────────────────────────────────

// Audio system lifecycle (no args)
typedef _InitNative = Int32 Function();
typedef _InitDart = int Function();

typedef _VoidNoArgNative = Void Function();
typedef _VoidNoArgDart = void Function();

// Audio stream (takes AudioStreamRef)
typedef _CreateForSynthNative = AudioStreamRef Function(
    SynthEngineRef, Double, Uint32, Int32);
typedef _CreateForSynthDart = AudioStreamRef Function(
    SynthEngineRef, double, int, int);

typedef _VoidStreamNative = Void Function(AudioStreamRef);
typedef _VoidStreamDart = void Function(AudioStreamRef);

typedef _IntStreamNative = Int32 Function(AudioStreamRef);
typedef _IntStreamDart = int Function(AudioStreamRef);

typedef _Uint64StreamNative = Uint64 Function(AudioStreamRef);
typedef _Uint64StreamDart = int Function(AudioStreamRef);

typedef _LastErrorNative = Pointer<Utf8> Function(AudioStreamRef);
typedef _LastErrorDart = Pointer<Utf8> Function(AudioStreamRef);

// Device enumeration (no-arg or int-arg, all cached)
typedef _GetDeviceCountNative = Int32 Function();
typedef _GetDeviceCountDart = int Function();

typedef _GetDeviceNameNative = Pointer<Utf8> Function(Int32);
typedef _GetDeviceNameDart = Pointer<Utf8> Function(int);

typedef _GetDefaultOutputNative = Int32 Function();
typedef _GetDefaultOutputDart = int Function();

typedef _GetDeviceChannelsNative = Int32 Function(Int32);
typedef _GetDeviceChannelsDart = int Function(int);

typedef _GetDeviceSampleRateNative = Double Function(Int32);
typedef _GetDeviceSampleRateDart = double Function(int);

// ── Audio device info ────────────────────────────────────────────────────────

/// Information about a single audio output device.
class AudioDeviceInfo {
  final int index;
  final String name;
  final int maxOutputChannels;
  final double defaultSampleRate;
  final bool isDefault;

  AudioDeviceInfo({
    required this.index,
    required this.name,
    required this.maxOutputChannels,
    required this.defaultSampleRate,
    this.isDefault = false,
  });
}

// ── Bindings ─────────────────────────────────────────────────────────────────

class OpenAmpAudioStreamBindings {
  OpenAmpAudioStreamBindings._(DynamicLibrary lib)
      : systemInit = lib.lookupFunction<_InitNative, _InitDart>(
            'audio_system_init'),
        systemShutdown = lib.lookupFunction<_VoidNoArgNative, _VoidNoArgDart>(
            'audio_system_shutdown'),
        systemIsInitialized = lib.lookupFunction<_InitNative, _InitDart>(
            'audio_system_is_initialized'),
        createForSynth =
            lib.lookupFunction<_CreateForSynthNative, _CreateForSynthDart>(
                'audio_stream_create_for_synth'),
        destroy =
            lib.lookupFunction<_VoidStreamNative, _VoidStreamDart>('audio_stream_destroy'),
        start = lib.lookupFunction<_IntStreamNative, _IntStreamDart>('audio_stream_start'),
        stop = lib.lookupFunction<_VoidStreamNative, _VoidStreamDart>('audio_stream_stop'),
        isRunning = lib
            .lookupFunction<_IntStreamNative, _IntStreamDart>('audio_stream_is_running'),
        callbackCount = lib.lookupFunction<_Uint64StreamNative, _Uint64StreamDart>(
            'audio_stream_callback_count'),
        lastError = lib.lookupFunction<_LastErrorNative, _LastErrorDart>(
            'audio_stream_last_error'),
        getDeviceCount = lib.lookupFunction<_GetDeviceCountNative,
            _GetDeviceCountDart>('audio_get_device_count'),
        getDeviceName = lib.lookupFunction<_GetDeviceNameNative,
            _GetDeviceNameDart>('audio_get_device_name'),
        getDefaultOutputDevice = lib.lookupFunction<_GetDefaultOutputNative,
            _GetDefaultOutputDart>('audio_get_default_output_device'),
        getDeviceMaxOutputChannels =
            lib.lookupFunction<_GetDeviceChannelsNative,
                _GetDeviceChannelsDart>(
                'audio_get_device_max_output_channels'),
        getDeviceDefaultSampleRate =
            lib.lookupFunction<_GetDeviceSampleRateNative,
                _GetDeviceSampleRateDart>(
                'audio_get_device_default_sample_rate');

  static OpenAmpAudioStreamBindings? _instance;

  /// Resolve the audio-stream symbols out of the same DynamicLibrary
  /// the synth bindings opened.
  static OpenAmpAudioStreamBindings get instance => _instance ??=
      OpenAmpAudioStreamBindings._(OpenAmpSynthBindings.instance.lib);

  static bool get available {
    if (!OpenAmpSynthBindings.available) return false;
    try {
      instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  // Audio system lifecycle
  final _InitDart systemInit;
  final _VoidNoArgDart systemShutdown;
  final _InitDart systemIsInitialized;

  // Audio stream lifecycle
  final _CreateForSynthDart createForSynth;
  final _VoidStreamDart destroy;
  final _IntStreamDart start;
  final _VoidStreamDart stop;
  final _IntStreamDart isRunning;
  final _Uint64StreamDart callbackCount;
  final _LastErrorDart lastError;

  // Device enumeration (cached)
  final _GetDeviceCountDart getDeviceCount;
  final _GetDeviceNameDart getDeviceName;
  final _GetDefaultOutputDart getDefaultOutputDevice;
  final _GetDeviceChannelsDart getDeviceMaxOutputChannels;
  final _GetDeviceSampleRateDart getDeviceDefaultSampleRate;

  /// Initialize the audio system (PortAudio). Must be called before any
  /// other audio function. Safe to call multiple times (ref-counted).
  bool init() {
    return systemInit() != 0;
  }

  /// Shutdown the audio system. Call at app exit. Safe to call multiple times.
  void shutdown() {
    systemShutdown();
  }

  /// Whether PortAudio is currently initialized.
  bool get isAudioSystemInitialized => systemIsInitialized() != 0;

  /// Enumerate all available audio output devices from cache.
  List<AudioDeviceInfo> enumerateDevices() {
    final count = getDeviceCount();
    final defaultIdx = getDefaultOutputDevice();
    final devices = <AudioDeviceInfo>[];

    for (int i = 0; i < count; i++) {
      final namePtr = getDeviceName(i);
      final name = namePtr == nullptr ? 'Device $i' : namePtr.toDartString();
      final channels = getDeviceMaxOutputChannels(i);
      final sampleRate = getDeviceDefaultSampleRate(i);

      if (channels > 0) {
        devices.add(AudioDeviceInfo(
          index: i,
          name: name,
          maxOutputChannels: channels,
          defaultSampleRate: sampleRate,
          isDefault: i == defaultIdx,
        ));
      }
    }
    return devices;
  }
}

// ── High-level Dart wrapper ──────────────────────────────────────────────────

/// Idiomatic Dart wrapper around a native [AudioStream] bound to a
/// synth engine. Owns the native handle; call [dispose] to free it.
///
/// The synth engine MUST outlive this audio stream. The recommended
/// pattern is to dispose the audio stream first, then the synth.
class OpenAmpSynthAudioStream {
  OpenAmpSynthAudioStream({
    required SynthEngineRef synthHandle,
    double sampleRate = 48000.0,
    int blockSize = 256,
    int deviceIndex = -1, // -1 = default device
  })  : _bindings = OpenAmpAudioStreamBindings.instance,
        _handle = OpenAmpAudioStreamBindings.instance
            .createForSynth(synthHandle, sampleRate, blockSize, deviceIndex) {
    if (_handle == nullptr) {
      throw StateError(
          'audio_stream_create_for_synth returned null — out of memory or null synth handle');
    }
  }

  final OpenAmpAudioStreamBindings _bindings;
  AudioStreamRef _handle;
  bool _disposed = false;

  void _check() {
    if (_disposed) {
      throw StateError('OpenAmpSynthAudioStream already disposed');
    }
  }

  /// Open the PortAudio device and start the audio thread. Returns
  /// true on success. On failure, [lastError] holds the message.
  bool start() {
    _check();
    return _bindings.start(_handle) != 0;
  }

  /// Halt the audio thread and close the device. Idempotent.
  void stop() {
    if (_disposed) return;
    _bindings.stop(_handle);
  }

  bool get isRunning => !_disposed && _bindings.isRunning(_handle) != 0;

  /// Number of audio buffer callbacks fired since the last successful
  /// [start]. Useful for smoke-testing that audio is actually flowing.
  int get callbackCount =>
      _disposed ? 0 : _bindings.callbackCount(_handle);

  /// Latest PortAudio error string, or empty if everything is fine.
  String get lastError {
    if (_disposed) return '';
    final ptr = _bindings.lastError(_handle);
    if (ptr == nullptr) return '';
    return ptr.toDartString();
  }

  void dispose() {
    if (_disposed) return;
    // Stop BEFORE marking disposed so the stop() call works
    _bindings.stop(_handle);
    _bindings.destroy(_handle);
    _handle = nullptr;
    _disposed = true;
  }
}
