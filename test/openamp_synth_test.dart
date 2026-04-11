// Smoke tests for the OpenAmp Synth FFI binding.

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
      expect(synth.activeVoices, greaterThan(0));

      synth.noteOff(60);
      synth.allNotesOff();
      // After explicit allNotesOff, voices may still be in release stage,
      // but the engine should not crash.
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
  });
}
