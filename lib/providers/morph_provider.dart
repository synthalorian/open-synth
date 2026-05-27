import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/envelope.dart';
import '../models/filter_config.dart';
import '../models/fx_config.dart';
import '../models/lfo_config.dart';
import '../models/morph_config.dart';
import '../models/oscillator.dart';
import '../models/synth_preset.dart';
import 'synth_providers.dart';

// ── Morph State ─────────────────────────────────────────

final morphConfigProvider = StateNotifierProvider<MorphConfigNotifier, MorphConfig>((ref) {
  return MorphConfigNotifier();
});

class MorphConfigNotifier extends StateNotifier<MorphConfig> {
  Timer? _timer;

  MorphConfigNotifier() : super(const MorphConfig());

  void update(MorphConfig Function(MorphConfig) updater) {
    state = updater(state);
  }

  void setSource(String id) => state = state.copyWith(sourcePresetId: id);
  void setTarget(String id) => state = state.copyWith(targetPresetId: id);
  void setPosition(double pos) => state = state.copyWith(position: pos.clamp(0.0, 1.0));
  void setSpeed(double speed) => state = state.copyWith(speed: speed.clamp(0.01, 2.0));

  void play() {
    if (state.sourcePresetId.isEmpty || state.targetPresetId.isEmpty) return;
    state = state.copyWith(isPlaying: true);
    _startTimer();
  }

  void pause() {
    state = state.copyWith(isPlaying: false);
    _timer?.cancel();
  }

  void stop() {
    state = state.copyWith(isPlaying: false, position: 0.0);
    _timer?.cancel();
  }

  void toggle() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!state.isPlaying) return;
      var newPos = state.position + (state.speed * 0.05);
      if (newPos >= 1.0) {
        newPos = 1.0;
        state = state.copyWith(position: newPos, isPlaying: false);
        _timer?.cancel();
      } else {
        state = state.copyWith(position: newPos);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ── Morphed Preset ──────────────────────────────────────

/// Computes a live-interpolated preset between source and target.
/// When morph is inactive or presets are missing, returns the current preset.
final morphedPresetProvider = Provider<SynthPreset>((ref) {
  final currentPreset = ref.watch(currentPresetProvider);
  final morph = ref.watch(morphConfigProvider);

  if (!morph.isPlaying && morph.position <= 0.0) return currentPreset;
  if (morph.sourcePresetId.isEmpty || morph.targetPresetId.isEmpty) return currentPreset;

  final presets = ref.watch(presetListProvider);
  final source = presets.firstWhere(
    (p) => p.id == morph.sourcePresetId,
    orElse: () => currentPreset,
  );
  final target = presets.firstWhere(
    (p) => p.id == morph.targetPresetId,
    orElse: () => currentPreset,
  );

  return _lerpPreset(source, target, morph.position);
});

// ── Interpolation Helpers ───────────────────────────────

SynthPreset _lerpPreset(SynthPreset a, SynthPreset b, double t) {
  final clampedT = t.clamp(0.0, 1.0);
  return SynthPreset(
    name: '${a.name} → ${b.name}',
    category: a.category,
    osc1: _lerpOscillator(a.osc1, b.osc1, clampedT),
    osc2: _lerpOscillator(a.osc2, b.osc2, clampedT),
    filter: _lerpFilter(a.filter, b.filter, clampedT),
    ampEnvelope: _lerpEnvelope(a.ampEnvelope, b.ampEnvelope, clampedT),
    filterEnvelope: _lerpEnvelope(a.filterEnvelope, b.filterEnvelope, clampedT),
    lfo1: _lerpLfo(a.lfo1, b.lfo1, clampedT),
    lfo2: _lerpLfo(a.lfo2, b.lfo2, clampedT),
    chorus: _lerpChorus(a.chorus, b.chorus, clampedT),
    delay: _lerpDelay(a.delay, b.delay, clampedT),
    reverb: _lerpReverb(a.reverb, b.reverb, clampedT),
    phaser: _lerpPhaser(a.phaser, b.phaser, clampedT),
    drive: _lerpDrive(a.drive, b.drive, clampedT),
    masterVolume: _lerpDouble(a.masterVolume, b.masterVolume, clampedT),
    tags: a.tags,
    author: a.author,
    isBassPreset: a.isBassPreset,
  );
}

Oscillator _lerpOscillator(Oscillator a, Oscillator b, double t) {
  return Oscillator(
    waveform: t >= 0.5 ? b.waveform : a.waveform,
    octave: _lerpInt(a.octave, b.octave, t),
    detune: _lerpDouble(a.detune, b.detune, t),
    pulseWidth: _lerpDouble(a.pulseWidth, b.pulseWidth, t),
    volume: _lerpDouble(a.volume, b.volume, t),
    enabled: t >= 0.5 ? b.enabled : a.enabled,
  );
}

FilterConfig _lerpFilter(FilterConfig a, FilterConfig b, double t) {
  return FilterConfig(
    type: t >= 0.5 ? b.type : a.type,
    cutoff: _lerpDouble(a.cutoff, b.cutoff, t),
    resonance: _lerpDouble(a.resonance, b.resonance, t),
    envelopeAmount: _lerpDouble(a.envelopeAmount, b.envelopeAmount, t),
  );
}

Envelope _lerpEnvelope(Envelope a, Envelope b, double t) {
  return Envelope(
    attack: _lerpDouble(a.attack, b.attack, t),
    decay: _lerpDouble(a.decay, b.decay, t),
    sustain: _lerpDouble(a.sustain, b.sustain, t),
    release: _lerpDouble(a.release, b.release, t),
  );
}

LfoConfig _lerpLfo(LfoConfig a, LfoConfig b, double t) {
  return LfoConfig(
    waveform: t >= 0.5 ? b.waveform : a.waveform,
    rate: _lerpDouble(a.rate, b.rate, t),
    depth: _lerpDouble(a.depth, b.depth, t),
    target: t >= 0.5 ? b.target : a.target,
  );
}

ChorusConfig _lerpChorus(ChorusConfig a, ChorusConfig b, double t) {
  return ChorusConfig(
    enabled: t >= 0.5 ? b.enabled : a.enabled,
    rate: _lerpDouble(a.rate, b.rate, t),
    depth: _lerpDouble(a.depth, b.depth, t),
    mix: _lerpDouble(a.mix, b.mix, t),
  );
}

DelayConfig _lerpDelay(DelayConfig a, DelayConfig b, double t) {
  return DelayConfig(
    enabled: t >= 0.5 ? b.enabled : a.enabled,
    timeMs: _lerpDouble(a.timeMs, b.timeMs, t),
    feedback: _lerpDouble(a.feedback, b.feedback, t),
    mix: _lerpDouble(a.mix, b.mix, t),
  );
}

ReverbConfig _lerpReverb(ReverbConfig a, ReverbConfig b, double t) {
  return ReverbConfig(
    enabled: t >= 0.5 ? b.enabled : a.enabled,
    size: _lerpDouble(a.size, b.size, t),
    damping: _lerpDouble(a.damping, b.damping, t),
    mix: _lerpDouble(a.mix, b.mix, t),
  );
}

PhaserConfig _lerpPhaser(PhaserConfig a, PhaserConfig b, double t) {
  return PhaserConfig(
    enabled: t >= 0.5 ? b.enabled : a.enabled,
    rate: _lerpDouble(a.rate, b.rate, t),
    depth: _lerpDouble(a.depth, b.depth, t),
    feedback: _lerpDouble(a.feedback, b.feedback, t),
    mix: _lerpDouble(a.mix, b.mix, t),
  );
}

DriveConfig _lerpDrive(DriveConfig a, DriveConfig b, double t) {
  return DriveConfig(
    enabled: t >= 0.5 ? b.enabled : a.enabled,
    amount: _lerpDouble(a.amount, b.amount, t),
    type: t >= 0.5 ? b.type : a.type,
  );
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
int _lerpInt(int a, int b, double t) => (a + (b - a) * t).round();
