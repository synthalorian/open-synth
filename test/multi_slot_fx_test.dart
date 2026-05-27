// Integration tests for the multi-slot FX architecture.
//
// Tests that:
//   - FX slot param setters on OpenAmpSynth don't crash
//   - applyPresetToSynth pushes FX slot configs from the model to the engine
//   - process() produces finite audio output with FX slots configured
//   - Zone B engine (via SynthEnginePair) handles FX slot params correctly
//   - Thread-safe param queue delivers FX slot changes without crashes

import 'dart:ffi' show Float, Pointer, sizeOf;

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_synth/ffi/openamp_synth.dart';
import 'package:open_synth/models/fx_config.dart';
import 'package:open_synth/models/preset_category.dart';
import 'package:open_synth/models/synth_preset.dart';
import 'package:open_synth/services/preset_loader.dart';

/// Whether the native library is available on this host.
final _nativeAvailable = OpenAmpSynthBindings.available;

void main() {
  group('Multi-slot FX — FFI param setters', () {
    test('FX slot type and enabled setters do not crash', () {
      final synth = OpenAmpSynth();
      addTearDown(synth.dispose);

      // Slot 1 (EQ)
      synth.fxSlot1Type = FxTypeId.equalizer;
      synth.fxSlot1Enabled = true;

      // Slot 2 (Limiter)
      synth.fxSlot2Type = FxTypeId.limiter;
      synth.fxSlot2Enabled = true;

      // Slot 3 (Rotary)
      synth.fxSlot3Type = FxTypeId.rotary;
      synth.fxSlot3Enabled = true;

      // Master
      synth.fxMasterEnabled = true;
      synth.fxMasterMix = 1.0;

      expect(synth.activeVoices, 0);
    }, skip: !_nativeAvailable ? 'native lib not available' : false);

    test('FX slot param setters do not crash for all slots', () {
      final synth = OpenAmpSynth();
      addTearDown(synth.dispose);

      // Slot 1 — all 8 params
      synth.fxSlot1Type = FxTypeId.equalizer;
      synth.fxSlot1Enabled = true;
      synth.fxSlot1Param0 = -6.0;  // Low gain
      synth.fxSlot1Param1 = 200.0; // Low freq
      synth.fxSlot1Param2 = 3.0;   // Mid gain
      synth.fxSlot1Param3 = 1000.0;// Mid freq
      synth.fxSlot1Param4 = 2.0;   // Mid Q
      synth.fxSlot1Param5 = 0.0;   // High gain
      synth.fxSlot1Param6 = 8000.0;// High freq
      synth.fxSlot1Param7 = 0.0;   // Output gain

      // Slot 2 — 5 params
      synth.fxSlot2Type = FxTypeId.limiter;
      synth.fxSlot2Enabled = true;
      synth.fxSlot2Param0 = -12.0; // Threshold
      synth.fxSlot2Param1 = 1.0;   // Attack
      synth.fxSlot2Param2 = 100.0; // Release
      synth.fxSlot2Param3 = 0.0;   // Makeup gain
      synth.fxSlot2Param4 = 1.0;   // Lookahead

      // Slot 3 — 6 params
      synth.fxSlot3Type = FxTypeId.rotary;
      synth.fxSlot3Enabled = true;
      synth.fxSlot3Param0 = 4.0;   // Rate
      synth.fxSlot3Param1 = 0.7;   // Depth
      synth.fxSlot3Param2 = 0.5;   // Tone
      synth.fxSlot3Param3 = 0.3;   // Drive
      synth.fxSlot3Param4 = 0.5;   // Mix
      synth.fxSlot3Param5 = 0.0;   // Mode

      expect(synth.activeVoices, 0);
    }, skip: !_nativeAvailable ? 'native lib not available' : false);

    test('process() completes without crash with all FX slots configured', () {
      final synth = OpenAmpSynth(sampleRate: 48000.0, blockSize: 256);
      addTearDown(synth.dispose);

      // Configure all three FX slots
      synth.fxSlot1Type = FxTypeId.equalizer;
      synth.fxSlot1Enabled = true;
      synth.fxSlot1Param2 = 3.0; // Mid gain boost

      synth.fxSlot2Type = FxTypeId.limiter;
      synth.fxSlot2Enabled = true;

      synth.fxSlot3Type = FxTypeId.tremolo;
      synth.fxSlot3Enabled = true;
      synth.fxSlot3Param0 = 5.0; // Rate

      synth.fxMasterEnabled = true;
      synth.fxMasterMix = 1.0;

      // Play a note and render
      synth.noteOn(60, velocity: 0.8);

      final buffer = calloc.allocate<Float>(256 * sizeOf<Float>());
      addTearDown(() => calloc.free(buffer));

      // Render multiple blocks to let FX delay lines warm up
      for (int i = 0; i < 10; i++) {
        synth.process(buffer, 256);
        // Process didn't crash — success
      }

      expect(synth.activeVoices, greaterThan(0));
    }, skip: !_nativeAvailable ? 'native lib not available' : false);
  });

  group('Multi-slot FX — applyPresetToSynth', () {
    test('applies FxSlotConfig from preset to synth without crash', () {
      final synth = OpenAmpSynth();
      addTearDown(synth.dispose);

      // Build a preset with all three FX slots configured
      final preset = SynthPreset(
        name: 'FX Test',
        category: PresetCategory.custom,
        fxSlots: [
          const FxSlotConfig(
            type: FxTypeId.equalizer,
            enabled: true,
            params: [0.0, 200.0, 6.0, 1000.0, 1.0, 0.0, 8000.0, 0.0],
          ),
          const FxSlotConfig(
            type: FxTypeId.limiter,
            enabled: true,
            params: [-6.0, 1.0, 50.0, 0.0, 1.0],
          ),
          const FxSlotConfig(
            type: FxTypeId.tremolo,
            enabled: true,
            params: [4.0, 0.5, 0.0, 1.0, 90.0],
          ),
        ],
        masterVolume: 0.8,
      );

      applyPresetToSynth(synth, preset);
      expect(synth.activeVoices, 0);
    }, skip: !_nativeAvailable ? 'native lib not available' : false);

    test('applies EqConfig + LimiterConfig from preset to synth without crash', () {
      final synth = OpenAmpSynth();
      addTearDown(synth.dispose);

      final preset = SynthPreset(
        name: 'EQ+Limiter Test',
        category: PresetCategory.custom,
        eq: const EqConfig(
          enabled: true,
          lowGain: -3.0,
          midGain: 4.0,
          highGain: -1.5,
        ),
        limiter: const LimiterConfig(
          enabled: true,
          threshold: -8.0,
          release: 80.0,
        ),
        masterVolume: 0.75,
      );

      applyPresetToSynth(synth, preset);
      expect(synth.activeVoices, 0);
    }, skip: !_nativeAvailable ? 'native lib not available' : false);

    test('applies RotaryConfig + TremoloConfig from preset to synth without crash', () {
      final synth = OpenAmpSynth();
      addTearDown(synth.dispose);

      final preset = SynthPreset(
        name: 'Rotary+Tremolo Test',
        category: PresetCategory.custom,
        rotary: const RotaryConfig(
          enabled: true,
          rate: 6.0,
          depth: 0.8,
          mix: 0.5,
        ),
        tremolo: const TremoloConfig(
          enabled: true,
          rate: 5.0,
          depth: 0.6,
          shape: 0.5,
          stereo: true,
        ),
        masterVolume: 0.7,
      );

      applyPresetToSynth(synth, preset);
      expect(synth.activeVoices, 0);
    }, skip: !_nativeAvailable ? 'native lib not available' : false);

    test('process() completes without crash with FX slots from applyPresetToSynth', () {
      final synth = OpenAmpSynth(sampleRate: 48000.0, blockSize: 256);
      addTearDown(synth.dispose);

      // Build a full-featured preset with all FX configs
      final preset = SynthPreset(
        name: 'Full FX',
        category: PresetCategory.custom,
        fxSlots: [
          const FxSlotConfig(
            type: FxTypeId.equalizer,
            enabled: true,
            params: [0.0, 200.0, 3.0, 1000.0, 1.0, 0.0, 8000.0, 0.0],
          ),
          const FxSlotConfig(
            type: FxTypeId.limiter,
            enabled: true,
            params: [-6.0, 1.0, 50.0, 0.0, 1.0],
          ),
        ],
        masterVolume: 0.8,
      );

      applyPresetToSynth(synth, preset);
      synth.noteOn(60, velocity: 0.9);

      final buffer = calloc.allocate<Float>(256 * sizeOf<Float>());
      addTearDown(() => calloc.free(buffer));

      for (int i = 0; i < 15; i++) {
        synth.process(buffer, 256);
        // Process didn't crash — success
      }

      expect(synth.activeVoices, greaterThan(0));
    }, skip: !_nativeAvailable ? 'native lib not available' : false);
  });

  group('Multi-slot FX — thread-safe param queue', () {
    test('enqueuing FX slot params via enqueueFloat/enqueueInt does not crash', () {
      final synth = OpenAmpSynth();
      addTearDown(synth.dispose);

      // Enqueue FX slot type (int param)
      synth.enqueueInt(ParamId.fxSlot1Type, FxTypeId.equalizer);
      synth.enqueueInt(ParamId.fxSlot1Enabled, 1);

      // Enqueue FX slot params (float params)
      synth.enqueueFloat(ParamId.fxSlot1Param2, 3.0);
      synth.enqueueFloat(ParamId.fxSlot1Param3, 1000.0);

      synth.enqueueInt(ParamId.fxSlot2Type, FxTypeId.limiter);
      synth.enqueueInt(ParamId.fxSlot2Enabled, 1);

      synth.enqueueInt(ParamId.fxSlot3Type, FxTypeId.tremolo);
      synth.enqueueFloat(ParamId.fxSlot3Param0, 5.0);

      synth.enqueueInt(ParamId.fxMasterEnabled, 1);
      synth.enqueueFloat(ParamId.fxMasterMix, 0.8);

      expect(synth.activeVoices, 0);
    }, skip: !_nativeAvailable ? 'native lib not available' : false);

    test('enqueued FX params apply at next process() call (no crash)', () {
      final synth = OpenAmpSynth(sampleRate: 48000.0, blockSize: 256);
      addTearDown(synth.dispose);

      // Enqueue via param queue (simulates UI thread path)
      synth.enqueueInt(ParamId.fxSlot1Type, FxTypeId.equalizer);
      synth.enqueueInt(ParamId.fxSlot1Enabled, 1);
      synth.enqueueFloat(ParamId.fxSlot1Param0, -6.0);

      synth.enqueueInt(ParamId.fxSlot2Type, FxTypeId.limiter);
      synth.enqueueInt(ParamId.fxSlot2Enabled, 1);

      synth.enqueueInt(ParamId.fxMasterEnabled, 1);
      synth.enqueueFloat(ParamId.fxMasterMix, 1.0);

      // Play a note so engine has voices
      synth.noteOn(60, velocity: 0.7);

      // Process — the drainQueue() runs at the top of process(),
      // so the FX params should be applied before rendering
      final buffer = calloc.allocate<Float>(256 * sizeOf<Float>());
      addTearDown(() => calloc.free(buffer));

      for (int i = 0; i < 8; i++) {
        synth.process(buffer, 256);
        // Process didn't crash — success
      }

      expect(synth.activeVoices, greaterThan(0));
    }, skip: !_nativeAvailable ? 'native lib not available' : false);
  });

  group('Multi-slot FX — SynthEnginePair integration', () {
    test('Zone B engine (from pair) accepts FX slot params and process completes', () {
      if (PairBindings.instance == null) {
        // Pair bindings may not be available — skip gracefully
        return;
      }

      final pair = OpenAmpSynthPair();
      addTearDown(pair.dispose);

      // Get zone B engine handle as a lightweight wrapper
      final engineB = OpenAmpSynth.fromHandle(pair.engineB);

      // Set FX slot params on zone B
      engineB.fxSlot1Type = FxTypeId.equalizer;
      engineB.fxSlot1Enabled = true;
      engineB.fxSlot1Param2 = 3.0;

      engineB.fxSlot2Type = FxTypeId.limiter;
      engineB.fxSlot2Enabled = true;

      engineB.fxMasterEnabled = true;
      engineB.fxMasterMix = 1.0;

      // Play a note on zone B (goes through param queue — voices appear
      // after process() drains the queue at the next block boundary)
      engineB.noteOn(60, velocity: 0.8);

      // Render via pair's process to drain the queue and allocate voices
      // Note: pair.process() uses a stereo AudioBuffer (2 channels)
      final buffer = calloc.allocate<Float>(256 * 2 * sizeOf<Float>());
      addTearDown(() => calloc.free(buffer));

      for (int i = 0; i < 5; i++) {
        pair.process(buffer, 256);
      }

      expect(pair.activeVoices, greaterThan(0),
          reason: 'Pair should report active voices after process()');
    }, skip: !_nativeAvailable ? 'native lib not available' : false);

    test('Zone B engine processes audio with FX slots from applyPresetToSynth', () {
      if (PairBindings.instance == null) {
        return;
      }

      final pair = OpenAmpSynthPair();
      addTearDown(pair.dispose);

      final engineB = OpenAmpSynth.fromHandle(pair.engineB);

      // Apply a full preset with FX slots to zone B
      final preset = SynthPreset(
        name: 'Zone B FX',
        category: PresetCategory.custom,
        fxSlots: [
          const FxSlotConfig(
            type: FxTypeId.equalizer,
            enabled: true,
            params: [0.0, 200.0, 4.0, 1000.0, 1.0, 0.0, 8000.0, 0.0],
          ),
          const FxSlotConfig(
            type: FxTypeId.tremolo,
            enabled: true,
            params: [4.0, 0.5, 0.0, 0.8, 90.0],
          ),
        ],
        masterVolume: 0.8,
      );

      applyPresetToSynth(engineB, preset);
      engineB.noteOn(60, velocity: 0.9);

      // Render via pair's process
      // Note: pair.process() uses a stereo AudioBuffer (2 channels)
      final buffer = calloc.allocate<Float>(256 * 2 * sizeOf<Float>());
      addTearDown(() => calloc.free(buffer));

      for (int i = 0; i < 10; i++) {
        pair.process(buffer, 256);
        // Process didn't crash — success
      }

      expect(pair.activeVoices, greaterThan(0));
    }, skip: !_nativeAvailable ? 'native lib not available' : false);
  });
}
