import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/arpeggiator_config.dart';
import 'clock_provider.dart';
import 'synth_providers.dart';

/// Holds the currently pressed notes (from the user or keyboard).
final arpNotesProvider = StateProvider<Set<int>>((ref) => {});

/// Current arpeggiator configuration.
final arpeggiatorConfigProvider =
    StateNotifierProvider<ArpeggiatorConfigNotifier, ArpeggiatorConfig>((ref) {
  return ArpeggiatorConfigNotifier();
});

class ArpeggiatorConfigNotifier extends StateNotifier<ArpeggiatorConfig> {
  ArpeggiatorConfigNotifier() : super(const ArpeggiatorConfig());

  void update(ArpeggiatorConfig Function(ArpeggiatorConfig) updater) {
    state = updater(state);
  }
}

/// Maps an [ArpPattern] to the native engine's pattern int.
int _patternToNative(ArpPattern p) {
  switch (p) {
    case ArpPattern.up:     return 0; // UP
    case ArpPattern.down:   return 1; // DOWN
    case ArpPattern.upDown: return 2; // UP_DOWN
    case ArpPattern.random: return 3; // RANDOM
    case ArpPattern.chord:  return 4; // CHORD
    case ArpPattern.off:    return 0; // Treated as disabled
  }
}

/// Maps an [ArpRate] to the native engine's resolution int + BPM multiplier.
/// Returns (resolution, noteDivisor) where noteDivisor is the fraction of
/// a quarter note — e.g. 16th = 0.25.
(int resolution, double noteDivisor) _rateToNative(ArpRate r) {
  switch (r) {
    case ArpRate.one4th:    return (0, 1.0);     // Quarter
    case ArpRate.one8th:    return (1, 0.5);     // Eighth
    case ArpRate.one8thT:   return (1, 0.5 / 3 * 2); // Eighth triplet
    case ArpRate.one16th:   return (2, 0.25);    // Sixteenth
    case ArpRate.one16thT:  return (2, 0.25 / 3 * 2); // Sixteenth triplet
    case ArpRate.one32nd:   return (3, 0.125);   // Thirty-second
  }
}

/// Bridges the Dart [arpeggiatorConfigProvider] to the native C++
/// arpeggiator engine. Watches config changes and pushes every param
/// through the thread-safe param queue.
///
/// Returns void; consumers just `ref.watch` it to keep the binding alive.
final arpeggiatorNativeBridgeProvider = Provider<void>((ref) {
  final synth = ref.watch(synthEngineProvider);
  if (synth == null) return;

  final config = ref.watch(arpeggiatorConfigProvider);
  final clockMode = ref.watch(clockModeProvider);
  final clockBpm = ref.watch(clockBpmProvider);

  // Enable/disable the native arpeggiator
  synth.arpEnabled = config.enabled && config.pattern != ArpPattern.off;

  if (!config.enabled || config.pattern == ArpPattern.off) {
    return;
  }

  // Push pattern
  synth.arpPattern = _patternToNative(config.pattern);

  // Calculate tempo from clock or default 120
  final bpm = clockMode != ClockMode.off ? clockBpm : 120.0;
  synth.arpTempo = bpm;

  // Push resolution and octave range
  final (resolution, _) = _rateToNative(config.rate);
  synth.arpResolution = resolution;
  synth.arpOctaveRange = config.octaveRange;

  // Gate: the Dart model has gateVariation (randomness). The C++ engine
  // uses a fixed gate. Map 0.5 as base, with variation pulling it toward
  // 0.3–0.7 range depending on gateVariation setting.
  double gate = 0.5;
  if (config.gateVariation > 0.0) {
    gate = 0.5 - config.gateVariation * 0.25;
  }
  synth.arpGate = gate.clamp(0.1, 1.0);
});
