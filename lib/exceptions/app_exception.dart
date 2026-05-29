/// Base class for all domain-specific exceptions thrown by the app.
///
/// Prefer creating specific subclasses over throwing raw [Exception] or
/// [String] objects so that UI layers can present human-friendly messages.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Object? originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final parts = <String>[
      if (code != null) '[$code]',
      message,
    ];
    return parts.join(' ');
  }
}

/// Thrown when a required native library (e.g. the FFI .so) is missing or
/// cannot be loaded.
class NativeLibraryException extends AppException {
  const NativeLibraryException(super.message, {super.originalError, super.stackTrace})
      : super(code: 'NATIVE_LIB_MISSING');
}

/// Thrown when audio subsystem initialization fails (PortAudio, ALSA, etc.).
class AudioInitException extends AppException {
  const AudioInitException(super.message, {super.originalError, super.stackTrace})
      : super(code: 'AUDIO_INIT_FAILED');
}

/// Thrown when a preset cannot be loaded, saved, or parsed.
class PresetException extends AppException {
  const PresetException(super.message, {super.originalError, super.stackTrace})
      : super(code: 'PRESET_ERROR');
}

/// Thrown when a MIDI operation fails.
class MidiException extends AppException {
  const MidiException(super.message, {super.originalError, super.stackTrace})
      : super(code: 'MIDI_ERROR');
}

/// Thrown when a file I/O operation fails.
class FileSystemException extends AppException {
  const FileSystemException(super.message, {super.originalError, super.stackTrace})
      : super(code: 'FS_ERROR');
}
