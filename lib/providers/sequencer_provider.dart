import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';
import 'package:hive/hive.dart';

import '../models/sequencer_config.dart';
import 'clock_provider.dart';
import 'synth_providers.dart';

// ── Sequencer State ─────────────────────────────────────

final sequencerPatternProvider =
    StateNotifierProvider<SequencerPatternNotifier, SequencerPattern>((ref) {
  return SequencerPatternNotifier();
});

class SequencerPatternNotifier extends StateNotifier<SequencerPattern> {
  SequencerPatternNotifier() : super(SequencerPattern.empty());

  void loadPattern(SequencerPattern pattern) => state = pattern;

  void updatePattern(SequencerPattern Function(SequencerPattern) updater) {
    state = updater(state);
  }

  void setStep(int trackIndex, int stepIndex, SequencerStep step) {
    final tracks = List<SequencerTrack>.from(state.tracks);
    final track = tracks[trackIndex];
    final steps = List<SequencerStep>.from(track.steps);
    steps[stepIndex] = step;
    tracks[trackIndex] = track.copyWith(steps: steps);
    state = state.copyWith(tracks: tracks);
  }

  void toggleStep(int trackIndex, int stepIndex) {
    final step = state.tracks[trackIndex].steps[stepIndex];
    setStep(
      trackIndex,
      stepIndex,
      step.copyWith(enabled: !step.enabled),
    );
  }

  void setStepNote(int trackIndex, int stepIndex, int note) {
    final step = state.tracks[trackIndex].steps[stepIndex];
    final quantized = state.scaleConfig.quantize(note);
    setStep(
      trackIndex,
      stepIndex,
      step.copyWith(note: quantized, enabled: true),
    );
  }

  void setBpm(double bpm) {
    state = state.copyWith(bpm: bpm.clamp(30.0, 300.0));
  }

  void clearTrack(int trackIndex) {
    final tracks = List<SequencerTrack>.from(state.tracks);
    tracks[trackIndex] = SequencerTrack.empty(
      name: tracks[trackIndex].name,
      midiChannel: tracks[trackIndex].midiChannel,
    );
    state = state.copyWith(tracks: tracks);
  }

  void addTrack() {
    final tracks = List<SequencerTrack>.from(state.tracks);
    tracks.add(SequencerTrack.empty(name: 'Track ${tracks.length + 1}'));
    state = state.copyWith(tracks: tracks);
  }

  void removeTrack(int index) {
    if (state.tracks.length <= 1) return;
    final tracks = List<SequencerTrack>.from(state.tracks)..removeAt(index);
    state = state.copyWith(tracks: tracks);
  }
}

// ── Playback State ──────────────────────────────────────

final sequencerPlayingProvider = StateProvider<bool>((ref) => false);
final sequencerCurrentStepProvider = StateProvider<int>((ref) => 0);
final sequencerRecordingProvider = StateProvider<bool>((ref) => false);

// ── Stored Patterns ───────────────────────────────────

final sequencerPatternsProvider =
    StateNotifierProvider<SequencerPatternsNotifier, List<SequencerPattern>>((ref) {
  return SequencerPatternsNotifier();
});

class SequencerPatternsNotifier extends StateNotifier<List<SequencerPattern>> {
  SequencerPatternsNotifier() : super([]) {
    _load();
  }

  Box? _box;

  Future<void> _load() async {
    _box = Hive.box('open_synth');
    final stored = _box?.get('sequencer_patterns') as List?;
    if (stored != null && stored.isNotEmpty) {
      try {
        state = stored
            .map((e) => SequencerPattern.fromJson(
                Map<String, dynamic>.from(jsonDecode(e as String))))
            .toList();
      } catch (e, st) {
        appLogger.severe('Failed to load sequencer patterns', e, st);
        state = [];
      }
    }
  }

  void _save() {
    _box?.put('sequencer_patterns',
        state.map((p) => jsonEncode(p.toJson())).toList());
  }

  void addPattern(SequencerPattern pattern) {
    state = [...state, pattern];
    _save();
  }

  void updatePattern(SequencerPattern pattern) {
    state = [
      for (final p in state)
        if (p.id == pattern.id) pattern else p,
    ];
    _save();
  }

  void deletePattern(String id) {
    state = state.where((p) => p.id != id).toList();
    _save();
  }
}

// ── Sequencer Engine ──────────────────────────────────

/// The sequencer playback engine. Watches pattern + play state,
/// fires noteOn/noteOff on a timer.
///
/// Returns void; consumers watch it to keep the engine alive.
final sequencerEngineProvider = Provider<void>((ref) {
  final pattern = ref.watch(sequencerPatternProvider);
  final isPlaying = ref.watch(sequencerPlayingProvider);
  final clockMode = ref.watch(clockModeProvider);
  final clockPlaying = ref.watch(clockPlayingProvider);
  final effectiveBpm = ref.watch(effectiveBpmProvider);

  final syncEnabled = clockMode != ClockMode.off;
  final transportPlaying = syncEnabled ? clockPlaying : isPlaying;

  if (!transportPlaying) return;

  final playback = ref.read(playbackStateProvider.notifier);
  final stepNotifier = ref.read(sequencerCurrentStepProvider.notifier);

  // Calculate step duration from BPM
  final beatDurationMs = 60000.0 / effectiveBpm;
  final stepDurationMs = beatDurationMs / 4; // 16th notes

  // Track which notes are currently held per track
  final heldNotes = <int, int>{}; // trackIndex -> midiNote
  final gateTimers = <Timer>[];

  Timer? timer;

  void tick() {
    final currentStep = ref.read(sequencerCurrentStepProvider);
    final nextStep = (currentStep + 1) % pattern.stepsPerBar;

    // Release previous step's notes
    for (int t = 0; t < pattern.tracks.length; t++) {
      final prevNote = heldNotes[t];
      if (prevNote != null) {
        playback.noteOff(prevNote);
        heldNotes.remove(t);
      }
    }

    // Fire current step's notes (with scale quantization)
    for (int t = 0; t < pattern.tracks.length; t++) {
      final step = pattern.tracks[t].steps[currentStep];
      if (step.enabled && step.note >= 0 && step.note <= 127) {
        final quantizedNote = pattern.scaleConfig.quantize(step.note);
        final gateMs = (stepDurationMs * step.gate).round();
        playback.noteOn(quantizedNote, velocity: step.velocity);
        heldNotes[t] = quantizedNote;

        // Auto-release after gate time
        if (gateMs < stepDurationMs.round()) {
          gateTimers.add(Timer(Duration(milliseconds: gateMs), () {
            playback.noteOff(quantizedNote);
            heldNotes.remove(t);
          }));
        }
      }
    }

    stepNotifier.state = nextStep;
  }

  // Internal timer for both internal and clock-sync modes.
  // In sync mode the BPM is driven by the clock provider (master or slave).
  final period = Duration(milliseconds: stepDurationMs.round().clamp(20, 5000));
  timer = Timer.periodic(period, (_) => tick());

  // Fire first step immediately
  tick();

  ref.onDispose(() {
    timer?.cancel();
    for (final t in gateTimers) {
      t.cancel();
    }
    gateTimers.clear();
    // Release all held notes
    for (final note in heldNotes.values) {
      playback.noteOff(note);
    }
    heldNotes.clear();
  });
});
