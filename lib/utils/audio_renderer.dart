import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../ffi/openamp_synth.dart';
import '../models/midi_event.dart';
import '../models/synth_preset.dart';
import '../services/preset_loader.dart';
import 'error_handler.dart';
import 'logger.dart';
import 'wav_writer.dart';

/// Renders a [SynthPreset] with a list of playback [MidiEventRecord]s to a
/// 16-bit stereo WAV file by driving the native synth engine offline.
///
/// The renderer creates a temporary [OpenAmpSynth] (not connected to
/// PortAudio), applies the preset, plays through the MIDI events at
/// the correct timing, captures the audio output via [synth.process],
/// and writes it to a WAV file via [WavWriter].
///
/// Returns the path to the written WAV file, or null on failure.
Future<String?> renderMidiToWav({
  required SynthPreset preset,
  required List<MidiEventRecord> events,
  required String outputPath,
  double sampleRate = 48000.0,
  int blockSize = 256,
  double releaseTailMs = 500.0,
}) async {
  if (!OpenAmpSynthBindings.available) {
    appLogger.warning('renderMidiToWav: FFI bindings unavailable');
    return null;
  }
  if (events.isEmpty) {
    appLogger.warning('renderMidiToWav: no events to render');
    return null;
  }

  return guard<String?>(() async {
    final totalDurationMs = events.last.timestampMs + releaseTailMs;
    final totalFrames = (totalDurationMs * sampleRate / 1000).ceil();
    final blockFrames = blockSize;

    // Create the synth engine and apply the preset.
    final synth = OpenAmpSynth(sampleRate: sampleRate, blockSize: blockSize);
    try {
      applyPresetToSynth(synth, preset);
      appLogger.info(
        'Rendering ${events.length} events to WAV: $outputPath '
        '(${totalDurationMs.toStringAsFixed(1)}ms @ ${sampleRate}Hz)',
      );

      // Sort events by timestamp (should already be sorted, but be safe).
      final sorted = List<MidiEventRecord>.from(events)
        ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

      final writer = WavWriter(
        outputPath,
        sampleRate: sampleRate.round(),
        numChannels: 2,
      );

      // Mono output buffer from the synth engine.
      final monoBuffer = calloc<Float>(blockFrames);

      // Stereo interleaved output buffer for the WAV writer.
      final stereoBuffer = List<double>.filled(blockFrames * 2, 0.0);

      int eventIndex = 0;
      int frameIndex = 0;

      while (frameIndex < totalFrames) {
        final blockEndMs = ((frameIndex + blockFrames) / sampleRate) * 1000.0;

        // Fire any MIDI events that fall within this block's time window.
        while (eventIndex < sorted.length) {
          final event = sorted[eventIndex];
          if (event.timestampMs > blockEndMs) break;
          switch (event.type) {
            case MidiEventType.noteOn:
              synth.noteOn(event.note, velocity: event.velocity / 127.0);
              break;
            case MidiEventType.noteOff:
              synth.noteOff(event.note);
              break;
            case MidiEventType.cc:
            case MidiEventType.programChange:
              // Not applied during offline render; skip.
              break;
          }
          eventIndex++;
        }

        // Zero the mono buffer before rendering.
        for (int i = 0; i < blockFrames; i++) {
          monoBuffer[i] = 0.0;
        }

        // Render one block of mono audio.
        synth.process(monoBuffer, blockFrames);

        // Convert mono to stereo interleaved for the WAV writer.
        for (int i = 0; i < blockFrames; i++) {
          final sample = monoBuffer[i];
          final si = i * 2;
          stereoBuffer[si] = sample;     // left
          stereoBuffer[si + 1] = sample; // right
        }

        writer.writeFrames(stereoBuffer);
        frameIndex += blockFrames;
      }

      writer.close();
      calloc.free(monoBuffer);
      appLogger.info('WAV render complete: $outputPath');
      return outputPath;
    } finally {
      synth.dispose();
    }
  }, context: 'renderMidiToWav');
}
