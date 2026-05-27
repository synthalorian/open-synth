// Platform detection helpers for audio subsystem.
//
// On Android the native .so is backed by Oboe (not PortAudio), but it
// exports the same FFI symbols so the Dart bindings in
// openamp_audio_stream.dart work unchanged.  The helpers below let
// callers skip desktop-only features like device enumeration.

import 'dart:io';

/// Whether the app is running on Android.
bool get isAndroid => Platform.isAndroid;

/// Whether the app is running on iOS.
bool get isIOS => Platform.isIOS;

/// Whether the app is running on a mobile platform.
bool get isMobile => Platform.isAndroid || Platform.isIOS;

/// Whether audio device enumeration is available (desktop only).
///
/// On Android / iOS there is exactly one output device chosen by the
/// OS, so enumeration is meaningless.  The native Oboe backend still
/// exports the enumeration symbols but they return a single "default"
/// entry — callers should simply use deviceIndex -1 on mobile.
bool get hasAudioDeviceEnumeration => !isMobile;

/// Human-readable name of the audio backend active on this platform.
String get audioBackendName {
  if (Platform.isAndroid) return 'Oboe';
  if (Platform.isIOS) return 'AudioUnits';
  return 'PortAudio';
}
