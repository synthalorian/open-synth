import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ffi/sample_engine.dart';
import 'keyboard_split_provider.dart';
import 'sample_engine_provider.dart';
import 'synth_providers.dart';

/// Global master volume (0.0 - 1.0) that affects both synth and sample engines.
/// This is a user-facing control — the actual per-engine volumes are scaled
/// by this value.
final globalMasterVolumeProvider = StateProvider<double>((ref) => 1.0);

/// Side-effect provider: pushes the global master volume to both engines.
///
/// When a sample preset is active, the sample engine's volume is scaled by
/// the global master. The synth engine's master volume is also scaled.
///
/// This provider should be watched on every screen that has audio output.
final globalMixSyncProvider = Provider<void>((ref) {
  final globalVol = ref.watch(globalMasterVolumeProvider);

  // Scale synth engine master volume
  final synth = ref.watch(synthEngineProvider);
  if (synth != null) {
    synth.masterVolume = globalVol;
  }

  // Scale sample engine volume (convert linear 0-1 to dB: 0=-60dB, 1=0dB)
  final sampleEngine = ref.watch(sampleEngineProvider);
  final samplePreset = ref.watch(samplePresetProvider);
  if (sampleEngine != null && samplePreset != null) {
    final db = globalVol <= 0.001 ? -100.0 : (20.0 * log(globalVol) / ln10);
    sampleEngine.volumeDb = db.clamp(-60.0, 6.0);
  }

  // Scale pair engine volumes when split is active
  final pair = ref.watch(synthPairProvider);
  if (pair != null) {
    pair.setMixA(globalVol);
    pair.setMixB(globalVol);
  }
});
