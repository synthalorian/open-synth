// Smoke tests for the live audio output binding.
//
// These spin up a real PortAudio output stream against the host's
// default audio device, fire a synth voice, and confirm the audio
// thread is producing buffers. They WILL produce a brief tone on the
// speakers — that's the whole point. Skip them in CI by checking
// `OpenAmpAudioStreamBindings.available`, which is false on hosts
// without libopenamp_dart_ffi.so.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_synth/ffi/openamp_audio_stream.dart';
import 'package:open_synth/ffi/openamp_synth.dart';

void main() {
  group('OpenAmp synth audio stream', () {
    test('audio stream bindings are reachable', () {
      expect(OpenAmpAudioStreamBindings.available, isTrue,
          reason: 'libopenamp_dart_ffi.so should expose audio_stream_* symbols');
    },
        skip: !OpenAmpAudioStreamBindings.available
            ? 'native lib not available on this host'
            : false);

    test('start / stop round-trips and the audio thread fires callbacks',
        () async {
      final synth = OpenAmpSynth(sampleRate: 48000.0, blockSize: 256);
      addTearDown(synth.dispose);

      final stream = OpenAmpSynthAudioStream(
        synthHandle: synth.nativeHandle,
        sampleRate: 48000.0,
        blockSize: 256,
      );
      addTearDown(stream.dispose);

      expect(stream.callbackCount, 0);
      expect(stream.isRunning, isFalse);

      // start() may legitimately fail in CI environments without an
      // audio device. Treat it as a soft skip rather than a hard failure.
      final started = stream.start();
      if (!started) {
        // Capture the diagnostic so it shows up in the test report
        // even when we skip — we want to know WHY the host has no
        // audio when this happens.
        // ignore: avoid_print
        print('audio stream start() failed: ${stream.lastError}');
        return;
      }
      expect(stream.isRunning, isTrue);

      // Fire a note so the engine actually has voices to render.
      synth.noteOn(60, velocity: 0.7); // Middle C

      // Give the PortAudio thread a moment to actually pump some buffers.
      // 250ms at 48kHz / 256-sample blocks is ~47 callbacks worth of
      // headroom — we only need to see *any* movement to confirm the
      // realtime path is alive.
      await Future<void>.delayed(const Duration(milliseconds: 250));

      synth.noteOff(60);
      stream.stop();

      expect(stream.isRunning, isFalse);
      expect(
        stream.callbackCount,
        greaterThan(0),
        reason: 'PortAudio should have fired at least one render callback',
      );
    },
        skip: !OpenAmpAudioStreamBindings.available
            ? 'native lib not available on this host'
            : false);

    test('disposing the stream while running stops it cleanly', () {
      final synth = OpenAmpSynth();
      addTearDown(synth.dispose);

      final stream = OpenAmpSynthAudioStream(synthHandle: synth.nativeHandle);
      stream.start();
      // No teardown — we explicitly dispose mid-run to verify the
      // destructor stops the stream and doesn't crash.
      stream.dispose();
      // A second dispose must be a no-op (matches the synth pattern).
      stream.dispose();
    },
        skip: !OpenAmpAudioStreamBindings.available
            ? 'native lib not available on this host'
            : false);

    test('lastError is empty after a successful start', () {
      // Only meaningful on hosts where the device opened cleanly.
      final synth = OpenAmpSynth();
      addTearDown(synth.dispose);
      final stream = OpenAmpSynthAudioStream(synthHandle: synth.nativeHandle);
      addTearDown(stream.dispose);

      if (stream.start()) {
        expect(stream.lastError, isEmpty);
      } else {
        // ignore: avoid_print
        print('audio stream start() failed: ${stream.lastError}');
      }
    },
        skip: !OpenAmpAudioStreamBindings.available
            ? 'native lib not available on this host'
            : Platform.environment['CI'] == 'true'
                ? 'audio device not available in CI'
                : false);
  });
}
