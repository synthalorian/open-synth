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
import '../utils/logger.dart';

/// Apply every parameter from [preset] to [synth] in one shot.
///
/// Order matters: clears engine state first, then pushes oscillators / mix
/// first, then filter, then envelopes, then LFOs, then master volume.
///
/// Clearing state before applying ensures old voices, stale FX delay buffers,
/// and leftover envelope states from the previous preset don't bleed through.
void applyPresetToSynth(OpenAmpSynth synth, SynthPreset preset) {
  appLogger.info('Applying preset "${preset.name}" (${preset.id}) to synth engine');
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
  synth.osc1NoiseType = preset.osc1.noiseType;
  synth.osc1SubOscMode = preset.osc1.subOscMode;
  synth.osc1SubOscVolume = preset.osc1.subOscVolume;
  synth.osc1FmEnabled = preset.osc1.fmEnabled;
  synth.osc1FmAmount = preset.osc1.fmAmount;
  // Wavetable position is an extension — if the native engine doesn't
  // support wavetable, the waveform maps to index 5 which is a no-op
  // on older builds. The UI parameter still travels faithfully.
  // Instrument-specific wavetable variants get a default position so
  // piano / guitar / choir presets don't all sound identical.
  final wtPos1 = _resolveWavetablePosition(preset.osc1.waveform, preset.osc1.wavetablePosition);
  if (preset.osc1.waveform == Waveform.wavetable ||
      preset.osc1.waveform == Waveform.wtPiano ||
      preset.osc1.waveform == Waveform.wtGuitar ||
      preset.osc1.waveform == Waveform.wtChoir) {
    synth.osc1PulseWidth = wtPos1;
  }

  // ── Oscillator 2 ────────────────────────────────────────────────────────
  synth.osc2Waveform = _waveformToInt(preset.osc2.waveform);
  synth.osc2Octave = preset.osc2.octave;
  synth.osc2Detune = preset.osc2.detune;
  synth.osc2PulseWidth = preset.osc2.pulseWidth;
  synth.osc2Volume = preset.osc2.enabled ? preset.osc2.volume : 0.0;
  synth.osc2NoiseType = preset.osc2.noiseType;
  synth.osc2SubOscMode = preset.osc2.subOscMode;
  synth.osc2SubOscVolume = preset.osc2.subOscVolume;
  synth.osc2FmEnabled = preset.osc2.fmEnabled;
  synth.osc2FmAmount = preset.osc2.fmAmount;
  final wtPos2 = _resolveWavetablePosition(preset.osc2.waveform, preset.osc2.wavetablePosition);
  if (preset.osc2.waveform == Waveform.wavetable ||
      preset.osc2.waveform == Waveform.wtPiano ||
      preset.osc2.waveform == Waveform.wtGuitar ||
      preset.osc2.waveform == Waveform.wtChoir) {
    synth.osc2PulseWidth = wtPos2;
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
  synth.filterKeyTracking = preset.filter.keyTracking;
  synth.filterDrive = preset.filter.drive;

  // ── Amp envelope ────────────────────────────────────────────────────────
  synth.ampAttack = preset.ampEnvelope.attack;
  synth.ampDecay = preset.ampEnvelope.decay;
  synth.ampSustain = preset.ampEnvelope.sustain;
  synth.ampRelease = preset.ampEnvelope.release;
  synth.ampDelay = preset.ampEnvelope.delay;
  synth.ampHold = preset.ampEnvelope.hold;
  synth.ampAttackCurve = preset.ampEnvelope.attackCurve;
  synth.ampDecayCurve = preset.ampEnvelope.decayCurve;
  synth.ampReleaseCurve = preset.ampEnvelope.releaseCurve;

  // ── Filter envelope ─────────────────────────────────────────────────────
  synth.filterAttack = preset.filterEnvelope.attack;
  synth.filterDecay = preset.filterEnvelope.decay;
  synth.filterSustain = preset.filterEnvelope.sustain;
  synth.filterRelease = preset.filterEnvelope.release;
  synth.filterDelay = preset.filterEnvelope.delay;
  synth.filterHold = preset.filterEnvelope.hold;
  synth.filterAttackCurve = preset.filterEnvelope.attackCurve;
  synth.filterDecayCurve = preset.filterEnvelope.decayCurve;
  synth.filterReleaseCurve = preset.filterEnvelope.releaseCurve;

  // ── LFO 1 ───────────────────────────────────────────────────────────────
  synth.lfo1Waveform = _waveformToInt(preset.lfo1.waveform);
  synth.lfo1Rate = preset.lfo1.rate;
  synth.lfo1Depth = preset.lfo1.depth;
  synth.lfo1Target = _lfoTargetToInt(preset.lfo1.target);
  synth.lfo1FadeIn = preset.lfo1.fadeIn;
  synth.lfo1TempoSync = preset.lfo1.tempoSync;
  synth.lfo1TempoDivision = preset.lfo1.tempoDivision;

  // ── LFO 2 ───────────────────────────────────────────────────────────────
  synth.lfo2Waveform = _waveformToInt(preset.lfo2.waveform);
  synth.lfo2Rate = preset.lfo2.rate;
  synth.lfo2Depth = preset.lfo2.depth;
  synth.lfo2Target = _lfoTargetToInt(preset.lfo2.target);
  synth.lfo2FadeIn = preset.lfo2.fadeIn;
  synth.lfo2TempoSync = preset.lfo2.tempoSync;
  synth.lfo2TempoDivision = preset.lfo2.tempoDivision;

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

  // ── Multi-Slot FX (slots 1-3) ───────────────────────────────────────────
  // Slot 1 is typically EQ, Slot 2 is Limiter, Slot 3 is Rotary/Tremolo.
  // Each slot can be configured to any type via the FxSlotConfig model.
  // Slot 0 is always the LegacyFxProcessor (handled above).
  //
  // Note: uses direct switch/assign rather than referencing setters as values
  // because Dart setters aren't first-class (can't do `fn = synth.fxSlot1Type`).
  if (preset.fxSlots.isNotEmpty) {
    for (int i = 0; i < preset.fxSlots.length && i < 3; i++) {
      final slot = preset.fxSlots[i];
      final slotIndex = i + 1; // slots 1, 2, 3

      // ── Set slot type & enabled ────────────────────────────────────────
      switch (slotIndex) {
        case 1:
          synth.fxSlot1Type = slot.type;
          synth.fxSlot1Enabled = slot.enabled;
        case 2:
          synth.fxSlot2Type = slot.type;
          synth.fxSlot2Enabled = slot.enabled;
        case 3:
          synth.fxSlot3Type = slot.type;
          synth.fxSlot3Enabled = slot.enabled;
      }

      // ── Set per-slot params ───────────────────────────────────────────
      // Each slot type has a fixed number of params. Slot 1 (EQ) = 8,
      // slot 2 (Limiter) = 5, slot 3 (Rotary/Tremolo) = 6.
      final maxParams = switch (slotIndex) {
        1 => 8,
        2 => 5,
        3 => 6,
        _ => 0,
      };
      for (int p = 0; p < slot.params.length && p < maxParams; p++) {
        final value = slot.params[p];
        if (slotIndex == 1) {
          switch (p) {
            case 0: synth.fxSlot1Param0 = value;
            case 1: synth.fxSlot1Param1 = value;
            case 2: synth.fxSlot1Param2 = value;
            case 3: synth.fxSlot1Param3 = value;
            case 4: synth.fxSlot1Param4 = value;
            case 5: synth.fxSlot1Param5 = value;
            case 6: synth.fxSlot1Param6 = value;
            case 7: synth.fxSlot1Param7 = value;
          }
        } else if (slotIndex == 2) {
          switch (p) {
            case 0: synth.fxSlot2Param0 = value;
            case 1: synth.fxSlot2Param1 = value;
            case 2: synth.fxSlot2Param2 = value;
            case 3: synth.fxSlot2Param3 = value;
            case 4: synth.fxSlot2Param4 = value;
          }
        } else if (slotIndex == 3) {
          switch (p) {
            case 0: synth.fxSlot3Param0 = value;
            case 1: synth.fxSlot3Param1 = value;
            case 2: synth.fxSlot3Param2 = value;
            case 3: synth.fxSlot3Param3 = value;
            case 4: synth.fxSlot3Param4 = value;
            case 5: synth.fxSlot3Param5 = value;
          }
        }
      }
    }
  }

  // Also push standalone EQ/Limiter/Rotary/Tremolo configs (for UI panels
  // that map directly to specific slot types). These are synced to the
  // appropriate slot when the FxPanel changes the slot type.
  synth.fxMasterEnabled = true;
  synth.fxMasterMix = 1.0;

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
    case Waveform.wtPiano:
      return 5; // Wavetable slot with position 0.1
    case Waveform.wtGuitar:
      return 5; // Wavetable slot with position 0.5
    case Waveform.wtChoir:
      return 5; // Wavetable slot with position 0.9
    case Waveform.random:
      return 5; // Map to wavetable slot
  }
}

/// Returns a stable default wavetable position for instrument-specific
/// waveforms so the engine can differentiate piano / guitar / choir.
/// If the preset already sets a non-zero position, that value is respected.
double _resolveWavetablePosition(Waveform waveform, double presetPosition) {
  if (presetPosition != 0.0) return presetPosition;
  switch (waveform) {
    case Waveform.wtPiano:
      return 0.10;
    case Waveform.wtGuitar:
      return 0.50;
    case Waveform.wtChoir:
      return 0.90;
    case Waveform.wavetable:
      return 0.0;
    default:
      return 0.0;
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
