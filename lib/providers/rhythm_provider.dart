import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ffi/openamp_synth.dart';
import '../models/rhythm_pattern.dart';
import '../providers/synth_providers.dart';

// ── Rhythm State ──────────────────────────────────────────────────────────────

class RhythmState {
  final bool isPlaying;
  final int patternIndex;
  final double tempo;
  final double volume;
  final PatternVariation variation;
  final bool songMode;
  final int currentStep;
  final int totalSteps;

  const RhythmState({
    this.isPlaying = false,
    this.patternIndex = 0,
    this.tempo = 120.0,
    this.volume = 0.8,
    this.variation = PatternVariation.mainA,
    this.songMode = false,
    this.currentStep = 0,
    this.totalSteps = 16,
  });

  RhythmState copyWith({
    bool? isPlaying,
    int? patternIndex,
    double? tempo,
    double? volume,
    PatternVariation? variation,
    bool? songMode,
    int? currentStep,
    int? totalSteps,
  }) {
    return RhythmState(
      isPlaying: isPlaying ?? this.isPlaying,
      patternIndex: patternIndex ?? this.patternIndex,
      tempo: tempo ?? this.tempo,
      volume: volume ?? this.volume,
      variation: variation ?? this.variation,
      songMode: songMode ?? this.songMode,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }
}

// ── Rhythm Notifier ───────────────────────────────────────────────────────────

final rhythmProvider = StateNotifierProvider<RhythmNotifier, RhythmState>((ref) {
  return RhythmNotifier(ref);
});

class RhythmNotifier extends StateNotifier<RhythmState> {
  RhythmNotifier(this._ref) : super(const RhythmState()) {
    _startPolling();
  }

  final Ref _ref;
  Timer? _pollTimer;

  OpenAmpSynth? get _synth {
    return _ref.read(synthEngineProvider);
  }

  void _startPolling() {
    // Poll current step from native engine at 50ms for UI updates
    _pollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final synth = _synth;
      if (synth == null) return;
      // FFI getter for rhythm current step
      // final step = synth.getRhythmCurrentStep();
      // final total = synth.getRhythmTotalSteps();
      // state = state.copyWith(currentStep: step, totalSteps: total);
    });
  }

  void play() {
    final synth = _synth;
    if (synth == null) return;
    synth.rhythmPlay();
    state = state.copyWith(isPlaying: true);
  }

  void stop() {
    final synth = _synth;
    if (synth == null) return;
    synth.rhythmStop();
    state = state.copyWith(isPlaying: false, currentStep: 0);
  }

  void toggle() {
    if (state.isPlaying) {
      stop();
    } else {
      play();
    }
  }

  void setPattern(int index) {
    final synth = _synth;
    if (synth == null) return;
    if (index < 0 || index >= kRhythmPatterns.length) return;

    final pattern = kRhythmPatterns[index];
    synth.rhythmSetPattern(index);
    state = state.copyWith(
      patternIndex: index,
      tempo: pattern.defaultTempo,
      totalSteps: pattern.steps,
    );
    // Update tempo on engine too
    synth.rhythmSetTempo(pattern.defaultTempo);
  }

  void setTempo(double bpm) {
    final synth = _synth;
    if (synth == null) return;
    final clamped = bpm.clamp(20.0, 300.0);
    synth.rhythmSetTempo(clamped);
    state = state.copyWith(tempo: clamped);
  }

  void setVolume(double vol) {
    final synth = _synth;
    if (synth == null) return;
    final clamped = vol.clamp(0.0, 1.0);
    synth.rhythmSetVolume(clamped);
    state = state.copyWith(volume: clamped);
  }

  void setVariation(PatternVariation variation) {
    final synth = _synth;
    if (synth == null) return;
    synth.rhythmSetVariation(variation.index);
    state = state.copyWith(variation: variation);
  }

  void setSongMode(bool enabled) {
    final synth = _synth;
    if (synth == null) return;
    synth.rhythmSetSongMode(enabled);
    state = state.copyWith(songMode: enabled);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
