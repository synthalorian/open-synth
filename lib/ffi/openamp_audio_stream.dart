// ignore_for_file: library_private_types_in_public_api
// Dart FFI bindings for libopenamp_dart_ffi.so audio_stream symbols.
//
// Native source:
//   ~/projects/openamp/dsp-core/dart_ffi/audio_stream_ffi.{h,cpp}
//   ~/projects/openamp/dsp-core/audio_io/audio_stream.{h,cpp}
//
// The native AudioStream owns a PortAudio output stream and an internal
// process callback. We bind it to a SynthEngine via
// `audio_stream_create_for_synth(synthRef, sr, blockSize)` so the audio
// thread renders directly from the engine — Dart never sees the
// realtime callback, which means there's no GC / isolate latency.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'openamp_synth.dart' show OpenAmpSynthBindings, SynthEngineRef;

// ── Opaque handle ────────────────────────────────────────────────────────────

final class _AudioStreamHandle extends Opaque {}

typedef AudioStreamRef = Pointer<_AudioStreamHandle>;

// ── Native typedefs ──────────────────────────────────────────────────────────

typedef _CreateForSynthNative = AudioStreamRef Function(
    SynthEngineRef, Double, Uint32);
typedef _CreateForSynthDart = AudioStreamRef Function(
    SynthEngineRef, double, int);

typedef _VoidNative = Void Function(AudioStreamRef);
typedef _VoidDart = void Function(AudioStreamRef);

typedef _IntNative = Int32 Function(AudioStreamRef);
typedef _IntDart = int Function(AudioStreamRef);

typedef _Uint64Native = Uint64 Function(AudioStreamRef);
typedef _Uint64Dart = int Function(AudioStreamRef);

typedef _LastErrorNative = Pointer<Utf8> Function(AudioStreamRef);
typedef _LastErrorDart = Pointer<Utf8> Function(AudioStreamRef);

// ── Bindings ─────────────────────────────────────────────────────────────────

class OpenAmpAudioStreamBindings {
  OpenAmpAudioStreamBindings._(DynamicLibrary lib)
      : createForSynth =
            lib.lookupFunction<_CreateForSynthNative, _CreateForSynthDart>(
                'audio_stream_create_for_synth'),
        destroy =
            lib.lookupFunction<_VoidNative, _VoidDart>('audio_stream_destroy'),
        start = lib.lookupFunction<_IntNative, _IntDart>('audio_stream_start'),
        stop = lib.lookupFunction<_VoidNative, _VoidDart>('audio_stream_stop'),
        isRunning = lib
            .lookupFunction<_IntNative, _IntDart>('audio_stream_is_running'),
        callbackCount = lib.lookupFunction<_Uint64Native, _Uint64Dart>(
            'audio_stream_callback_count'),
        lastError = lib.lookupFunction<_LastErrorNative, _LastErrorDart>(
            'audio_stream_last_error');

  static OpenAmpAudioStreamBindings? _instance;

  /// Resolve the audio-stream symbols out of the same DynamicLibrary
  /// the synth bindings opened. Cheaper than re-opening the .so and
  /// guarantees both binding tables share one library handle.
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

  final _CreateForSynthDart createForSynth;
  final _VoidDart destroy;
  final _IntDart start;
  final _VoidDart stop;
  final _IntDart isRunning;
  final _Uint64Dart callbackCount;
  final _LastErrorDart lastError;
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
  })  : _bindings = OpenAmpAudioStreamBindings.instance,
        _handle = OpenAmpAudioStreamBindings.instance
            .createForSynth(synthHandle, sampleRate, blockSize) {
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
    _check();
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
    _bindings.destroy(_handle);
    _handle = nullptr;
    _disposed = true;
  }
}
