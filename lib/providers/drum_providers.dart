import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/drum_kit_config.dart';
import 'synth_providers.dart';

/// Current drum kit configuration.
final drumKitConfigProvider =
    StateNotifierProvider<DrumKitConfigNotifier, DrumKitConfig>((ref) {
  return DrumKitConfigNotifier();
});

class DrumKitConfigNotifier extends StateNotifier<DrumKitConfig> {
  DrumKitConfigNotifier() : super(const DrumKitConfig());

  void setKit(int index) {
    state = state.copyWith(kitIndex: index.clamp(0, 9));
  }

  void setLevel(double level) {
    state = state.copyWith(level: level.clamp(0.0, 1.0));
  }
}

/// Bridges [DrumKitConfig] to the native SynthEngine's drum kit
/// through the thread-safe param queue.
///
/// Consumers just `ref.watch` it to keep the binding alive.
final drumKitNativeBridgeProvider = Provider<void>((ref) {
  final synth = ref.watch(synthEngineProvider);
  if (synth == null) return;

  final config = ref.watch(drumKitConfigProvider);

  synth.drumKitPreset = config.kitIndex;
  synth.drumLevel = config.level;
});

/// GM2 drum pad layout — 16 most useful drum hits arranged in a 4×4 grid.
///
/// Each entry: (midiNote, label, color hex).
/// MIDI notes follow the GM2 percussion map.
const drumPadGrid = [
  // Row 1: kick, snare, clap, rim
  (midi: 36, label: 'KICK', color: 0xFFFF3355),
  (midi: 38, label: 'SNARE', color: 0xFF4488FF),
  (midi: 39, label: 'CLAP', color: 0xFF44AAFF),
  (midi: 37, label: 'RIM', color: 0xFF6677CC),
  // Row 2: CHH, OHH, crash, ride
  (midi: 42, label: 'CHH', color: 0xFFFFCC00),
  (midi: 46, label: 'OHH', color: 0xFFFFAA00),
  (midi: 49, label: 'CRASH', color: 0xFFAA44FF),
  (midi: 51, label: 'RIDE', color: 0xFF9944DD),
  // Row 3: toms
  (midi: 48, label: 'TOM H', color: 0xFF33CC66),
  (midi: 45, label: 'TOM M', color: 0xFF33BB55),
  (midi: 41, label: 'TOM L', color: 0xFF33AA44),
  (midi: 56, label: 'BELL', color: 0xFFFF8844),
  // Row 4: shaker, conga H, conga L, SFX
  (midi: 54, label: 'SHAKE', color: 0xFF88CC44),
  (midi: 62, label: 'CONGA', color: 0xFFDD6644),
  (midi: 64, label: 'BONGO', color: 0xFFCC5533),
  (midi: 55, label: 'SPLASH', color: 0xFFDD77FF),
];

/// Triggers a drum note on the native engine.
void triggerDrumNote(WidgetRef ref, int midiNote, double velocity) {
  final synth = ref.read(synthEngineProvider);
  if (synth == null) return;
  synth.drumNoteOn(midiNote, velocity);
}