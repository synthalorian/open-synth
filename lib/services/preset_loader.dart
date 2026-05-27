// Walks a [SynthPreset] and pushes every parameter into a live
// [OpenAmpSynth] via the FFI bindings. Lives in services/ rather than
// on OpenAmpSynth itself to keep the FFI binding layer free of model
// imports — that layer should only know about primitives.
//
// This is the bridge between Open Synth's UI/preset model and the
// native synth_engine. Anywhere a preset is loaded (factory bank,
// user save, MIDI program change, etc.) it should funnel through
// here so the engine state stays in lockstep with what the UI shows.

import '../ffi/openamp_synth.dart';
import '../models/mod_target.dart';
import '../models/synth_preset.dart';
import '../models/waveform.dart';

/// Apply every parameter from [preset] to [synth] in one shot.
///
/// Order matters: clears engine state first, then pushes oscillators / mix
/// first, then filter, then envelopes, then LFOs, then master volume.
///
/// Clearing state before applying ensures old voices, stale FX delay buffers,
/// and leftover envelope states from the previous preset don't bleed through.
void applyPresetToSynth(OpenAmpSynth synth, SynthPreset preset) {
  // ── Clear engine state ─────────────────────────────────────────────────────
  // All active voices release and FX delay buffers zero. Goes through the
  // thread-safe param queue so the audio callback drains them at the next
  // block boundary, BEFORE any of the new param changes below.
  synth.allNotesOff();
  synth.enqueueInt(ParamId.reset, 1);
  // ── Oscillator 1 ────────────────────────────────────────────────────────
  synth.osc1Waveform = _waveformToInt(preset.osc1.waveform);
  synth.osc1Octave = preset.osc1.octave;
  synth.osc1Detune = preset.osc1.detune;
  synth.osc1PulseWidth = preset.osc1.pulseWidth;
  synth.osc1Volume = preset.osc1.enabled ? preset.osc1.volume : 0.0;
  // Wavetable position is an extension — if the native engine doesn't
  // support wavetable, the waveform maps to index 5 which is a no-op
  // on older builds. The UI parameter still travels faithfully.
  if (preset.osc1.waveform == Waveform.wavetable) {
    synth.osc1PulseWidth = preset.osc1.wavetablePosition;
  }

  // ── Oscillator 2 ────────────────────────────────────────────────────────
  synth.osc2Waveform = _waveformToInt(preset.osc2.waveform);
  synth.osc2Octave = preset.osc2.octave;
  synth.osc2Detune = preset.osc2.detune;
  synth.osc2PulseWidth = preset.osc2.pulseWidth;
  synth.osc2Volume = preset.osc2.enabled ? preset.osc2.volume : 0.0;
  if (preset.osc2.waveform == Waveform.wavetable) {
    synth.osc2PulseWidth = preset.osc2.wavetablePosition;
  }

  // ── Unison ────────────────────────────────────────────────────────────────
  // Pushes unison parameters to the native engine. The FFI bindings use
  // lazy lookup — if the native .so doesn't have the unison symbols yet
  // (older build), the calls are safely skipped.
  synth.osc1UnisonVoiceCount   = preset.osc1.unisonVoiceCount;
  synth.osc1UnisonDetuneSpread = preset.osc1.unisonDetuneSpread;
  synth.osc1UnisonStereoSpread = preset.osc1.unisonStereoSpread;
  synth.osc1UnisonMix          = preset.osc1.unisonMix;

  synth.osc2UnisonVoiceCount   = preset.osc2.unisonVoiceCount;
  synth.osc2UnisonDetuneSpread = preset.osc2.unisonDetuneSpread;
  synth.osc2UnisonStereoSpread = preset.osc2.unisonStereoSpread;
  synth.osc2UnisonMix          = preset.osc2.unisonMix;

  // OSC mix is implicit in the per-oscillator volumes (the engine
  // sums osc1 + osc2 at full level). Push 0.5 as a stable default
  // so any prior nudge to setOscMix doesn't carry over between
  // preset loads.
  synth.oscMix = 0.5;

  // ── Filter ──────────────────────────────────────────────────────────────
  synth.filterType = preset.filter.type.index;
  synth.filterCutoff = preset.filter.cutoff;
  synth.filterResonance = preset.filter.resonance;
  synth.filterEnvAmount = preset.filter.envelopeAmount;

  // ── Amp envelope ────────────────────────────────────────────────────────
  synth.ampAttack = preset.ampEnvelope.attack;
  synth.ampDecay = preset.ampEnvelope.decay;
  synth.ampSustain = preset.ampEnvelope.sustain;
  synth.ampRelease = preset.ampEnvelope.release;

  // ── Filter envelope ─────────────────────────────────────────────────────
  synth.filterAttack = preset.filterEnvelope.attack;
  synth.filterDecay = preset.filterEnvelope.decay;
  synth.filterSustain = preset.filterEnvelope.sustain;
  synth.filterRelease = preset.filterEnvelope.release;

  // ── LFO 1 ───────────────────────────────────────────────────────────────
  synth.lfo1Waveform = _waveformToInt(preset.lfo1.waveform);
  synth.lfo1Rate = preset.lfo1.rate;
  synth.lfo1Depth = preset.lfo1.depth;
  synth.lfo1Target = _lfoTargetToInt(preset.lfo1.target);

  // ── LFO 2 ───────────────────────────────────────────────────────────────
  synth.lfo2Waveform = _waveformToInt(preset.lfo2.waveform);
  synth.lfo2Rate = preset.lfo2.rate;
  synth.lfo2Depth = preset.lfo2.depth;
  synth.lfo2Target = _lfoTargetToInt(preset.lfo2.target);

  // ── FX ──────────────────────────────────────────────────────────────────
  synth.chorusEnabled = preset.chorus.enabled;
  synth.chorusRate = preset.chorus.rate;
  synth.chorusDepth = preset.chorus.depth;
  synth.chorusMix = preset.chorus.mix;

  synth.delayEnabled = preset.delay.enabled;
  synth.delayTime = preset.delay.timeMs;
  synth.delayFeedback = preset.delay.feedback;
  synth.delayMix = preset.delay.mix;

  synth.reverbEnabled = preset.reverb.enabled;
  synth.reverbSize = preset.reverb.size;
  synth.reverbDamping = preset.reverb.damping;
  synth.reverbMix = preset.reverb.mix;

  synth.phaserEnabled = preset.phaser.enabled;
  synth.phaserRate = preset.phaser.rate;
  synth.phaserDepth = preset.phaser.depth;
  synth.phaserFeedback = preset.phaser.feedback;
  synth.phaserMix = preset.phaser.mix;

  // ── Flanger ────────────────────────────────────────────────────────────────
  synth.flangerEnabled   = preset.flanger.enabled;
  synth.flangerRate      = preset.flanger.rate;
  synth.flangerDepth     = preset.flanger.depth;
  synth.flangerFeedback  = preset.flanger.feedback;
  synth.flangerMix       = preset.flanger.mix;

  // ── Compressor ─────────────────────────────────────────────────────────────
  synth.compressorEnabled    = preset.compressor.enabled;
  synth.compressorThreshold  = preset.compressor.threshold;
  synth.compressorRatio      = preset.compressor.ratio;
  synth.compressorAttack     = preset.compressor.attack;
  synth.compressorRelease    = preset.compressor.release;
  synth.compressorMakeupGain = preset.compressor.makeupGain;

  synth.driveEnabled = preset.drive.enabled;
  synth.driveAmount = preset.drive.amount;
  synth.driveType = preset.drive.type.index;

  // ── Master ──────────────────────────────────────────────────────────────
  synth.masterVolume = preset.masterVolume;
}

/// Native synth_engine waveform indices. Must match the enum order
/// expected by `synth_engine_set_oscX_waveform` (synth_engine.cpp). The
/// engine treats the int as `WaveformType { Sine=0, Saw=1, Square=2,
/// Triangle=3, Noise=4 }` so the Dart [Waveform] enum order has to
/// stay in sync — it currently does, but go through this helper rather
/// than `.index` so a future reorder fails loudly here.
int _waveformToInt(Waveform w) {
  switch (w) {
    case Waveform.sine:
      return 0;
    case Waveform.saw:
      return 1;
    case Waveform.square:
      return 2;
    case Waveform.triangle:
      return 3;
    case Waveform.noise:
      return 4;
    case Waveform.wavetable:
      return 5;
  }
}

/// Native LFO target indices, mirroring `LfoTargetType` in
/// synth_engine.cpp. Same enforcement reason as [_waveformToInt] —
/// route through the switch instead of `.index`.
int _lfoTargetToInt(LfoTarget t) {
  switch (t) {
    case LfoTarget.pitch:
      return 0;
    case LfoTarget.filter:
      return 1;
    case LfoTarget.amplitude:
      return 2;
    case LfoTarget.pan:
      return 3;
  }
}
