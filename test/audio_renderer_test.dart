// Smoke tests for offline WAV audio rendering via
// [renderMidiToWav]. These create a real synth engine on the host
// and drive it through a short MIDI pattern, verifying the output
// WAV file is valid and the engine doesn't crash.
//
// The tests skip themselves when the native .so is missing (CI, etc.).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_synth/ffi/openamp_synth.dart';
import 'package:open_synth/models/midi_event.dart';
import 'package:open_synth/models/preset_category.dart';
import 'package:open_synth/models/synth_preset.dart';
import 'package:open_synth/utils/audio_renderer.dart';

void main() {
  group('renderMidiToWav', () {
    test('returns null when events list is empty', () async {
      final result = await renderMidiToWav(
        preset: SynthPreset(name: 'Test', category: PresetCategory.custom),
        events: [],
        outputPath: '/tmp/empty_test.wav',
      );
      expect(result, isNull);
    }, skip: !OpenAmpSynthBindings.available
        ? 'native lib not available on this host'
        : false);

    test('renders a short MIDI pattern to a valid WAV file', () async {
      final outPath = '/tmp/open_synth_render_test.wav';

      final events = [
        MidiEventRecord(
          type: MidiEventType.noteOn,
          note: 60,
          velocity: 100,
          timestampMs: 0,
        ),
        MidiEventRecord(
          type: MidiEventType.noteOff,
          note: 60,
          velocity: 0,
          timestampMs: 200,
        ),
      ];

      // Register cleanup before render so it runs even if render throws.
      addTearDown(() {
        if (File(outPath).existsSync()) File(outPath).deleteSync();
      });

      final result = await renderMidiToWav(
        preset: SynthPreset(name: 'Render Test', category: PresetCategory.custom),
        events: events,
        outputPath: outPath,
        releaseTailMs: 100.0,
      );

      expect(result, outPath);

      // Verify the file is a valid WAV (RIFF header + expected size).
      final file = File(outPath);
      expect(file.existsSync(), isTrue);
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(44), reason: 'WAV header + data');

      // RIFF marker
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      // WAVE format
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      // PCM (1) / stereo (2) / 48kHz / 16-bit
      expect(bytes[20], 1); // PCM
      expect(bytes[22], 2); // stereo channels
      expect(bytes[24], 0x80); // 48000 Hz LSB
      expect(bytes[25], 0xBB); // 48000 Hz
      // 16-bit samples -> block align = 4 (2 channels × 2 bytes)
      expect(bytes[32], 4); // block align
      expect(bytes[34], 16); // bits per sample

      // data chunk header
      expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');

      final dataSize = bytes.length - 44;
      expect(dataSize, greaterThan(0));

      // File should be roughly (300ms release × 48kHz × 2ch × 2 bytes)
      // ≈ 57 600 bytes, but we allow a generous margin.
      expect(file.lengthSync(), inInclusiveRange(200, 200000));
    }, skip: !OpenAmpSynthBindings.available
        ? 'native lib not available on this host'
        : false,
        timeout: const Timeout(Duration(seconds: 10)));

    test('renders multiple overlapping notes without crashing', () async {
      final outPath = '/tmp/open_synth_render_overlap_test.wav';

      // Play a chord: C major triad, staggered onset by 50 ms each.
      final events = [
        MidiEventRecord(
            type: MidiEventType.noteOn, note: 60, velocity: 90, timestampMs: 0),
        MidiEventRecord(
            type: MidiEventType.noteOn, note: 64, velocity: 90, timestampMs: 50),
        MidiEventRecord(
            type: MidiEventType.noteOn, note: 67, velocity: 90, timestampMs: 100),
        // Release them staggered.
        MidiEventRecord(
            type: MidiEventType.noteOff, note: 60, timestampMs: 300),
        MidiEventRecord(
            type: MidiEventType.noteOff, note: 64, timestampMs: 350),
        MidiEventRecord(
            type: MidiEventType.noteOff, note: 67, timestampMs: 400),
      ];
      addTearDown(() {
        if (File(outPath).existsSync()) File(outPath).deleteSync();
      });

      final result = await renderMidiToWav(
        preset: SynthPreset(name: 'Chord Test', category: PresetCategory.custom),
        events: events,
        outputPath: outPath,
        releaseTailMs: 200.0,
      );
      expect(result, outPath);
      final file = File(outPath);
      expect(file.existsSync(), isTrue);
      // Valid WAV header
      final bytes = await file.readAsBytes();
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(bytes.length, greaterThan(44));
    }, skip: !OpenAmpSynthBindings.available
        ? 'native lib not available on this host'
        : false,
        timeout: const Timeout(Duration(seconds: 10)));
  });
}
