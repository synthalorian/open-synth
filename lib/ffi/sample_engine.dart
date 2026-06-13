// ignore_for_file: library_private_types_in_public_api
// High-level Dart wrapper around the sfizz SampleEngine FFI.

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'openamp_synth.dart';

/// Opaque handle for the native SampleEngine.
final class _SampleEngineHandle extends Opaque {}
typedef SampleEngineRef = Pointer<_SampleEngineHandle>;

/// Dart wrapper around the native sfizz SampleEngine.
///
/// This engine plays back SFZ sample instruments. It operates alongside
/// the synthesizer engine (OpenAmpSynth) and can be mixed in the audio
/// callback for realistic instrument sounds.
class SampleEngine {
  SampleEngine._(this._handle);

  /// Create a new SampleEngine instance.
  /// Call [loadSfzFile] or [loadSfzString] before playing.
  factory SampleEngine.create() {
    final handle = OpenAmpSynthBindings.instance.sampleEngineCreate();
    return SampleEngine._(handle);
  }

  final Pointer<Void> _handle;
  bool _disposed = false;

  void _check() {
    if (_disposed) throw StateError('SampleEngine already disposed');
  }

  /// Load an SFZ file from disk.
  /// Returns true on success.
  bool loadSfzFile(String path) {
    _check();
    final pathPtr = path.toNativeUtf8();
    try {
      final result = OpenAmpSynthBindings.instance.sampleEngineLoadFile(_handle, pathPtr.cast<Char>());
      return result != 0;
    } finally {
      calloc.free(pathPtr);
    }
  }

  /// Load an SFZ from a string (for embedded presets).
  /// [virtualPath] is used to resolve relative sample paths.
  /// Returns true on success.
  bool loadSfzString(String virtualPath, String text) {
    _check();
    final pathPtr = virtualPath.toNativeUtf8();
    final textPtr = text.toNativeUtf8();
    try {
      final result = OpenAmpSynthBindings.instance.sampleEngineLoadString(
        _handle, pathPtr.cast<Char>(), textPtr.cast<Char>(),
      );
      return result != 0;
    } finally {
      calloc.free(pathPtr);
      calloc.free(textPtr);
    }
  }

  /// Set the sample rate (must match the audio stream).
  void setSampleRate(double sampleRate) {
    _check();
    OpenAmpSynthBindings.instance.sampleEngineSetSampleRate(_handle, sampleRate);
  }

  /// Set the maximum block size for rendering.
  void setBlockSize(int blockSize) {
    _check();
    OpenAmpSynthBindings.instance.sampleEngineSetBlockSize(_handle, blockSize);
  }

  /// Set volume in dB.
  set volumeDb(double db) {
    _check();
    OpenAmpSynthBindings.instance.sampleEngineSetVolume(_handle, db);
  }

  /// Get volume in dB.
  double get volumeDb {
    if (_disposed) return 0.0;
    return OpenAmpSynthBindings.instance.sampleEngineGetVolume(_handle);
  }

  /// Send note-on event.
  void noteOn(int delay, int noteNumber, int velocity) {
    _check();
    OpenAmpSynthBindings.instance.sampleEngineNoteOn(_handle, delay, noteNumber, velocity);
  }

  /// Send note-off event.
  void noteOff(int delay, int noteNumber, int velocity) {
    _check();
    OpenAmpSynthBindings.instance.sampleEngineNoteOff(_handle, delay, noteNumber, velocity);
  }

  /// Send CC event.
  void cc(int delay, int ccNumber, int ccValue) {
    _check();
    OpenAmpSynthBindings.instance.sampleEngineCc(_handle, delay, ccNumber, ccValue);
  }

  /// Send pitch wheel event.
  void pitchWheel(int delay, int pitch) {
    _check();
    OpenAmpSynthBindings.instance.sampleEnginePitchWheel(_handle, delay, pitch);
  }

  /// Send aftertouch event.
  void aftertouch(int delay, int value) {
    _check();
    OpenAmpSynthBindings.instance.sampleEngineAftertouch(_handle, delay, value);
  }

  /// Render audio into the output buffer (stereo interleaved).
  void render(Pointer<Float> output, int numFrames) {
    _check();
    OpenAmpSynthBindings.instance.sampleEngineRender(_handle, output, numFrames);
  }

  /// Number of currently active voices.
  int get activeVoices {
    if (_disposed) return 0;
    return OpenAmpSynthBindings.instance.sampleEngineGetNumActiveVoices(_handle);
  }

  /// Total polyphony.
  int get numVoices {
    if (_disposed) return 0;
    return OpenAmpSynthBindings.instance.sampleEngineGetNumVoices(_handle);
  }

  set numVoices(int n) {
    _check();
    OpenAmpSynthBindings.instance.sampleEngineSetNumVoices(_handle, n);
  }

  /// Number of regions in the loaded SFZ.
  int get numRegions {
    if (_disposed) return 0;
    return OpenAmpSynthBindings.instance.sampleEngineGetNumRegions(_handle);
  }

  /// Number of preloaded samples.
  int get numPreloadedSamples {
    if (_disposed) return 0;
    return OpenAmpSynthBindings.instance.sampleEngineGetNumPreloadedSamples(_handle);
  }

  /// Whether an SFZ is currently loaded.
  bool get isLoaded {
    if (_disposed) return false;
    return OpenAmpSynthBindings.instance.sampleEngineIsLoaded(_handle) != 0;
  }

  /// Stop all sounds and reset.
  void allSoundOff() {
    _check();
    OpenAmpSynthBindings.instance.sampleEngineAllSoundOff(_handle);
  }

  /// Raw native handle. Exposed for audio stream binding.
  Pointer<Void> get nativeHandle => _handle;

  /// Release the native engine.
  void dispose() {
    if (_disposed) return;
    OpenAmpSynthBindings.instance.sampleEngineDestroy(_handle);
    _disposed = true;
  }
}
