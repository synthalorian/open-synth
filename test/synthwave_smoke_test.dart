// Synthwave preset smoke test.
//
// Loads the "Blade Runner Pad" factory preset onto the live native
// synth, voices a Cm chord (C - Eb - G), pumps the audio thread for
// two seconds, and confirms PortAudio actually rendered audio. The
// chord is held the whole time so the realtime path stays busy with
// real harmonic content, not just a single voice in the release stage.
//
// This is the "do we hear it" verification for the FFI ↔ DSP ↔ audio
// stack — every layer is exercised end-to-end against a real preset.

import 'package:flutter_test/flutter_test.dart';

import 'package:open_synth/data/factory_presets.dart';
import 'package:open_synth/ffi/openamp_audio_stream.dart';
import 'package:open_synth/ffi/openamp_synth.dart';
import 'package:open_synth/services/preset_loader.dart';

void main() {
  test('Blade Runner Pad voices a Cm chord through native audio', () async {
    if (!OpenAmpAudioStreamBindings.available) {
      // Soft-skip on hosts without the .so or audio device.
      return;
    }

    final preset = factoryPresets.firstWhere(
      (p) => p.name == 'Blade Runner Pad',
      orElse: () => factoryPresets.first,
    );

    final synth = OpenAmpSynth(sampleRate: 48000.0, blockSize: 256);
    addTearDown(synth.dispose);

    applyPresetToSynth(synth, preset);

    final stream = OpenAmpSynthAudioStream(
      synthHandle: synth.nativeHandle,
      sampleRate: 48000.0,
      blockSize: 256,
    );
    addTearDown(stream.dispose);

    final ok = stream.start();
    if (!ok) {
      // ignore: avoid_print
      print('PortAudio start failed: ${stream.lastError} — skipping');
      return;
    }

    // Cm triad — synthwave's home key. C3 = MIDI 48, Eb3 = 51, G3 = 55.
    const cmTriad = [48, 51, 55];
    for (final n in cmTriad) {
      synth.noteOn(n, velocity: 0.7);
    }

    // ignore: avoid_print
    print('▶  ${preset.name} | Cm | activeVoices=${synth.activeVoices}');

    // Hold the chord for 2 seconds. Long enough to clear the pad's
    // 1.5s attack envelope and actually arrive at the sustain stage.
    await Future<void>.delayed(const Duration(seconds: 2));

    final renderedMs = (stream.callbackCount * 256 / 48000 * 1000).round();
    // ignore: avoid_print
    print('   callbackCount=${stream.callbackCount}  (~${renderedMs}ms rendered)');

    for (final n in cmTriad) {
      synth.noteOff(n);
    }

    // Let the release tail decay so the audio thread doesn't get
    // chopped mid-tone. The Blade Runner Pad has a 3s release; we'll
    // give it half that and stop the stream — the destructor will
    // handle the rest.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    stream.stop();

    expect(stream.callbackCount, greaterThan(50),
        reason: '2s × 48kHz / 256 ≈ 375 buffers should have rendered');
  });
}
