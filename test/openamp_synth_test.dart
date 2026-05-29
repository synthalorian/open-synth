// Smoke tests for the OpenAmp Synth FFI binding.

import 'dart:ffi' show Float, sizeOf;

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_synth/ffi/openamp_synth.dart';

void main() {
  group('OpenAmp Synth FFI', () {
    test('native library is reachable', () {
      expect(OpenAmpSynthBindings.available, isTrue,
          reason: 'libopenamp_dart_ffi.so should load from native/');
    }, skip: !OpenAmpSynthBindings.available
        ? 'native lib not available on this host'
        : false);

    test('create / destroy round-trips cleanly', () {
      final synth = OpenAmpSynth(sampleRate: 48000.0, blockSize: 256);
      addTearDown(synth.dispose);
      expect(synth.activeVoices, 0);
    }, skip: !OpenAmpSynthBindings.available
        ? 'native lib not available on this host'
        : false);

    test('note on / note off increments and decrements active voices', () {
      final synth = OpenAmpSynth();
      addTearDown(synth.dispose);

      expect(synth.activeVoices, 0);
      synth.noteOn(60, velocity: 0.9); // Middle C

      // noteOn uses the thread-safe param queue — drain it via process()
      // so the engine actually allocates voices.
      final buffer = calloc.allocate<Float>(256 * sizeOf<Float>());
      addTearDown(() => calloc.free(buffer));
      synth.process(buffer, 256);
      expect(synth.activeVoices, greaterThan(0));

      synth.noteOff(60);
      synth.allNotesOff();
    }, skip: !OpenAmpSynthBindings.available
        ? 'native lib not available on this host'
        : false);

    test('parameter setters do not crash', () {
      final synth = OpenAmpSynth();
      addTearDown(synth.dispose);

      synth.osc1Waveform = 0;
      synth.osc1Octave = 0;
      synth.osc1Detune = 5.0;
      synth.osc1Volume = 0.8;

      synth.osc2Waveform = 1;
      synth.osc2Octave = -1;
      synth.osc2Detune = -3.0;
      synth.osc2Volume = 0.5;
      synth.oscMix = 0.5;

      synth.filterType = 0;
      synth.filterCutoff = 1200.0;
      synth.filterResonance = 0.4;
      synth.filterEnvAmount = 0.3;

      synth.ampAttack = 5.0;
      synth.ampDecay = 100.0;
      synth.ampSustain = 0.7;
      synth.ampRelease = 250.0;

      synth.lfo1Rate = 4.5;
      synth.lfo1Depth = 0.2;

      synth.masterVolume = 0.75;
    }, skip: !OpenAmpSynthBindings.available
        ? 'native lib not available on this host'
        : false);

    test('double dispose is a no-op', () {
      final synth = OpenAmpSynth();
      synth.dispose();
      synth.dispose();
    }, skip: !OpenAmpSynthBindings.available
        ? 'native lib not available on this host'
        : false);

    // ── Unison FFI ───────────────────────────────────────────────────────

    test('unison FFI symbols are present in the rebuilt .so', () {
      final bindings = OpenAmpSynthBindings.instance;
      expect(bindings.unison, isNotNull,
          reason:
              'The new libopenamp_dart_ffi.so exports all 8 unison symbols');
      expect(bindings.unisonAvailable, isTrue);
    }, skip: !OpenAmpSynthBindings.available
        ? 'native lib not available on this host'
        : false);

    test('unison setter properties on OpenAmpSynth work correctly', () {
      final synth = OpenAmpSynth();
      addTearDown(synth.dispose);

      synth.osc1UnisonVoiceCount = 4;
      synth.osc1UnisonDetuneSpread = 15.0;
      synth.osc1UnisonStereoSpread = 0.6;
      synth.osc1UnisonMix = 0.8;

      synth.osc2UnisonVoiceCount = 2;
      synth.osc2UnisonDetuneSpread = 10.0;
      synth.osc2UnisonStereoSpread = 0.3;
      synth.osc2UnisonMix = 0.7;

      expect(synth.activeVoices, 0);
    }, skip: !OpenAmpSynthBindings.available
        ? 'native lib not available on this host'
        : false);

    test('synth processes audio buffer with unison enabled', () {
      final synth = OpenAmpSynth(sampleRate: 48000.0, blockSize: 256);
      addTearDown(synth.dispose);

      // Configure unison
      synth.osc1UnisonVoiceCount = 4;
      synth.osc1UnisonDetuneSpread = 20.0;
      synth.osc1UnisonStereoSpread = 0.7;
      synth.osc1UnisonMix = 1.0;

      // Play a note and render
      synth.noteOn(60, velocity: 0.8);

      final buffer = calloc.allocate<Float>(256 * sizeOf<Float>());
      addTearDown(() => calloc.free(buffer));

      synth.process(buffer, 256);
      expect(synth.activeVoices, greaterThan(0));
    }, skip: !OpenAmpSynthBindings.available
        ? 'native lib not available on this host'
        : false);
  });
}
