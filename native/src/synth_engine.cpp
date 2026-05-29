#include "synth_engine.h"
#include "legacy_fx.h"
#include "fx_eq.h"
#include "fx_limiter.h"
#include "fx_rotary.h"
#include "fx_tremolo.h"
#include <cmath>
#include <cstring>
#include <algorithm>
#include <fstream>
#include <sstream>
#include <iostream>
#include <chrono>

namespace openamp {

// ── Helpers ───────────────────────────────────────────────────────────────────

static float midiNoteToFreq(int note) {
    return 440.0f * std::pow(2.0f, (note - 69) / 12.0f);
}

// ── Construction / destruction ────────────────────────────────────────────────

SynthEngine::SynthEngine(double sampleRate, uint32_t blockSize)
    : sampleRate_(sampleRate), blockSize_(blockSize), drumKit_(sampleRate) {
    lfo1_.prepare(sampleRate_);
    lfo2_.prepare(sampleRate_);

    // Initialize the legacy FX (slot 0) with all the old inline effects.
    // New FX slots (1-3) are left empty for the user to assign via the FxEngine.
    initLegacyFxSlot();

    // Pre-register the new FX processors for slots 1-3 as available types.
    // Users configure them via the FX panel UI; by default they're empty.
    // Slot 1: EQ, Slot 2: Limiter, Slot 3: can be swapped at runtime.
}

SynthEngine::~SynthEngine() = default;

// ── Reset ─────────────────────────────────────────────────────────────────────

void SynthEngine::reset() {
    allocator_.allNotesOff();
    drumKit_.allNotesOff();
    osc1_.reset();
    osc2_.reset();
    filter_.reset();
    lfo1_.reset();
    lfo2_.reset();
    fxEngine_.reset();
    // Reset per-voice filter states
    for (int v = 0; v < VoiceAllocator::MAX_VOICES; v++) {
        Voice* voice = allocator_.voice(v);
        if (voice) {
            voice->filterState.lp = 0.0f;
            voice->filterState.bp = 0.0f;
            voice->filterState.hp = 0.0f;
            voice->noteAge = 0.0f;
        }
    }
}

// ── MIDI ──────────────────────────────────────────────────────────────────────

void SynthEngine::noteOn(int midiNote, float velocity) {
    arpeggiator_.noteOn(midiNote, velocity);
    if (!arpeggiator_.enabled()) {
        allocator_.noteOn(midiNote, velocity);
    }
}

void SynthEngine::noteOff(int midiNote) {
    arpeggiator_.noteOff(midiNote);
    if (!arpeggiator_.enabled()) {
        allocator_.noteOff(midiNote);
    }
}

void SynthEngine::allNotesOff() {
    arpeggiator_.allNotesOff();
    allocator_.allNotesOff();
}

// ── Process ───────────────────────────────────────────────────────────────────

void SynthEngine::process(AudioBuffer& output) {
    using Clock = std::chrono::high_resolution_clock;
    auto blockStart = Clock::now();

    const uint32_t numFrames = output.numFrames;
    const bool stereo = output.numChannels >= 2;

    // Drain the parameter queue at block boundaries (thread-safe).
    drainQueue();

    // Let the arpeggiator generate note events (if enabled).
    arpeggiator_.process(numFrames, sampleRate_, allocator_);

    // Update per-block LFO
    float lfo1Val = lfo1_.process();
    float lfo2Val = lfo2_.process();

    for (uint32_t frame = 0; frame < numFrames; frame++) {
        float leftOut = 0.0f;
        float rightOut = 0.0f;

        // Process each active voice
        for (int v = 0; v < VoiceAllocator::MAX_VOICES; v++) {
            Voice* voice = allocator_.voice(v);
            if (!voice->active) continue;

            // Process envelopes
            float ampEnv = voice->ampEnv.process(sampleRate_);
            float filterEnv = voice->filterEnv.process(sampleRate_);
            float pitchEnv = voice->pitchEnv.process(sampleRate_);

            // Check if voice is done
            if (voice->ampEnv.state() == Envelope::IDLE) {
                voice->active = false;
                continue;
            }

            // Apply pitch modulation (LFO + pitch envelope)
            float pitchMod = 0.0f;
            if (lfoPerVoice_) {
                // Per-voice LFO: advance each voice's own LFO phase
                if (lfo1_.target() == LFO::Target::PITCH) {
                    voice->lfo1Phase += lfo1_.rate() / sampleRate_;
                    if (voice->lfo1Phase >= 1.0) voice->lfo1Phase -= 1.0;
                    pitchMod += std::sin(2.0 * M_PI * voice->lfo1Phase) * lfo1_.depth();
                }
                if (lfo2_.target() == LFO::Target::PITCH) {
                    voice->lfo2Phase += lfo2_.rate() / sampleRate_;
                    if (voice->lfo2Phase >= 1.0) voice->lfo2Phase -= 1.0;
                    pitchMod += std::sin(2.0 * M_PI * voice->lfo2Phase) * lfo2_.depth();
                }
            } else {
                if (lfo1_.target() == LFO::Target::PITCH) pitchMod += lfo1Val;
                if (lfo2_.target() == LFO::Target::PITCH) pitchMod += lfo2Val;
            }
            // Apply pitch envelope (in semitones)
            pitchMod += pitchEnv * pitchEnvAmount_;
            float modFreq = voice->baseFreq * std::pow(2.0f, pitchMod * 2.0f);

            // Get unison configs (they are per-oscillator and apply per-voice)
            const UnisonConfig& u1 = osc1_.unison();
            const UnisonConfig& u2 = osc2_.unison();
            int maxVoices = std::max(u1.voiceCount, u2.voiceCount);
            if (maxVoices < 1) maxVoices = 1;

            float voiceLeft = 0.0f;
            float voiceRight = 0.0f;

            // Render each unison voice
            for (int uv = 0; uv < maxVoices; uv++) {
                bool osc1Active = uv < u1.voiceCount;
                bool osc2Active = uv < u2.voiceCount;

                float sample = 0.0f;

                // Oscillator 1
                if (osc1Active) {
                    float inc = osc1_.phaseIncrement(modFreq, uv);
                    voice->osc1Phase[uv] += inc;
                    if (voice->osc1Phase[uv] >= 1.0f) voice->osc1Phase[uv] -= 1.0f;
                    sample += osc1_.process(voice->osc1Phase[uv], uv, modFreq, sampleRate_);
                }

                // Oscillator 2
                if (osc2Active) {
                    float inc = osc2_.phaseIncrement(modFreq, uv);
                    voice->osc2Phase[uv] += inc;
                    if (voice->osc2Phase[uv] >= 1.0f) voice->osc2Phase[uv] -= 1.0f;
                    sample += osc2_.process(voice->osc2Phase[uv], uv, modFreq, sampleRate_);
                }

                // Apply oscillator mix
                sample *= oscMix_;

                // Apply unison stereo panning
                float pan;
                if (uv == 0) {
                    pan = 0.0f; // center
                } else {
                    pan = (u1.stereoSpread * 0.5f) * (uv % 2 == 0 ? -1.0f : 1.0f);
                }
                float panL = std::cos((pan + 1.0f) * M_PI / 4.0f);
                float panR = std::sin((pan + 1.0f) * M_PI / 4.0f);
                voiceLeft += sample * panL;
                voiceRight += sample * panR;
            }

            // Apply amp envelope with velocity
            float ampGain = ampEnv * voice->velocity;

            // Apply filter
            float filterMod = 0.0f;
            if (lfo1_.target() == LFO::Target::FILTER) filterMod += lfo1Val;
            if (lfo2_.target() == LFO::Target::FILTER) filterMod += lfo2Val;

            // Mix down to mono for filter, then re-pan
            float monoMix = (voiceLeft + voiceRight) * 0.5f;

            // Piano hammer transient: brief noise burst + high click at note start
            float filtered = filter_.process(monoMix, filterEnv + filterMod, sampleRate_, voice->midiNote, voice->filterState);

            // Piano hammer transient: brief bright click added AFTER filter so it stays sharp
            bool isPiano = (osc1_.waveform() == 6) || (osc2_.waveform() == 6);
            if (isPiano && voice->noteAge < 0.015f) {
                float clickDecay = std::exp(-voice->noteAge * 300.0f);
                float clickAmt = clickDecay * 0.25f * voice->velocity;
                float hammerNoise = (std::sin(voice->noteAge * 12000.0f) * 0.7f +
                                     std::sin(voice->noteAge * 18432.0f) * 0.3f) * clickAmt;
                filtered += hammerNoise;
            }

            voiceLeft = filtered * ampGain * (1.0f - voice->pan) * 0.5f;
            voiceRight = filtered * ampGain * (1.0f + voice->pan) * 0.5f;

            leftOut += voiceLeft;
            rightOut += voiceRight;

            // Advance note age
            voice->noteAge += 1.0f / static_cast<float>(sampleRate_);
        }

        // Apply LFO amplitude modulation
        float ampMod = 0.0f;
        if (lfo1_.target() == LFO::Target::AMPLITUDE) ampMod += lfo1Val;
        if (lfo2_.target() == LFO::Target::AMPLITUDE) ampMod += lfo2Val;
        ampMod = 1.0f - std::abs(ampMod) * 0.5f;

        leftOut *= ampMod;
        rightOut *= ampMod;

            // Apply FX engine (multi-FX slots processed in series)
        // Slot 0 is the LegacyFxProcessor, slots 1-3 are user-assignable types
        fxEngine_.process(leftOut, rightOut, sampleRate_);

        // Master volume
        leftOut *= masterVolume_;
        rightOut *= masterVolume_;

        // NaN/inf guard — if anything went sideways, zero it out
        if (!std::isfinite(leftOut)) leftOut = 0.0f;
        if (!std::isfinite(rightOut)) rightOut = 0.0f;

        // Soft clipper (tanh) — smooth limiting that doesn't produce DC flatlines
        leftOut = std::tanh(leftOut);
        rightOut = std::tanh(rightOut);

        // Write to output buffer
        if (stereo) {
            output.data[frame * 2] = leftOut;
            output.data[frame * 2 + 1] = rightOut;
        } else {
            output.data[frame] = (leftOut + rightOut) * 0.5f;
        }
    }

    // CPU profiling — measure block time vs. real-time budget
    auto blockEnd = Clock::now();
    double elapsedUs = std::chrono::duration<double, std::micro>(blockEnd - blockStart).count();
    double budgetUs = (numFrames / sampleRate_) * 1e6;
    float instantLoad = static_cast<float>(elapsedUs / budgetUs);
    // Exponential moving average with ~1s time constant at 48k/256 (~187 blocks/sec)
    float alpha = 0.005f;
    cpuLoad_ = cpuLoad_ * (1.0f - alpha) + instantLoad * alpha;

    // ── Drum Kit ── process block of drum audio and mix into output
    static constexpr uint32_t kDrumBufMax = 2048;
    float drumLeft[kDrumBufMax] = {};
    float drumRight[kDrumBufMax] = {};
    uint32_t nf = numFrames < kDrumBufMax ? numFrames : kDrumBufMax;
    drumKit_.process(drumLeft, drumRight, nf);
    for (uint32_t frame = 0; frame < nf; frame++) {
        float dl = drumLeft[frame];
        float dr = drumRight[frame];
        if (!std::isfinite(dl)) dl = 0.0f;
        if (!std::isfinite(dr)) dr = 0.0f;
        if (stereo) {
            output.data[frame * 2] = std::tanh(output.data[frame * 2] + dl);
            output.data[frame * 2 + 1] = std::tanh(output.data[frame * 2 + 1] + dr);
        } else {
            output.data[frame] = std::tanh(output.data[frame] + (dl + dr) * 0.5f);
        }
    }
}

// ── Parameter Queue ──────────────────────────────────────────────────────────

void SynthEngine::drainQueue() {
    paramQueue_.drainAll([this](const ParamQueue::Entry& e) {
        applyParam(e);
    });
}

void SynthEngine::applyParam(const ParamQueue::Entry& e) {
    using P = ParamQueue::ParamId;
    auto id = static_cast<P>(e.paramId);

    switch (id) {
    // MIDI
    case P::NOTE_ON:
        allocator_.noteOn(e.intData, e.floatData);
        break;
    case P::NOTE_OFF:
        allocator_.noteOff(e.intData);
        break;
    case P::ALL_NOTES_OFF:
        allocator_.allNotesOff();
        break;
    case P::RESET:
        reset();
        break;

    // ── Drum Kit ──
    case P::DRUM_KIT_PRESET:
        drumKit_.setKitPreset(static_cast<int>(e.floatData));
        break;
    case P::DRUM_LEVEL:
        drumKit_.setLevel(e.floatData);
        break;
    case P::DRUM_NOTE_ON: {
        // floatData encoding: midiNote in upper 16 bits, velocity in lower
        int midiNote = static_cast<int>(e.floatData);
        float velocity = e.floatData - static_cast<float>(midiNote);
        if (velocity <= 0.0f) velocity = 0.8f;
        drumKit_.noteOn(midiNote, velocity);
        break;
    }
    case P::DRUM_NOTE_OFF:
        drumKit_.noteOff(static_cast<int>(e.floatData));
        break;

    // Osc 1
    case P::OSC1_WAVEFORM: osc1_.setWaveform(e.intData); break;
    case P::OSC1_OCTAVE:   osc1_.setOctave(e.intData); break;
    case P::OSC1_DETUNE:   osc1_.setDetune(e.floatData); break;
    case P::OSC1_PULSE_WIDTH: osc1_.setPulseWidth(e.floatData); break;
    case P::OSC1_VOLUME:   osc1_.setVolume(e.floatData); break;
    case P::OSC1_NOISE_TYPE: osc1_.setNoiseType(e.intData); break;
    case P::OSC1_SUB_OSC_MODE: osc1_.setSubOscMode(e.intData); break;
    case P::OSC1_SUB_OSC_VOLUME: osc1_.setSubOscVolume(e.floatData); break;
    case P::OSC1_FM_ENABLED: osc1_.setFmEnabled(e.intData != 0); break;
    case P::OSC1_FM_AMOUNT: osc1_.setFmAmount(e.floatData); break;

    // Osc 2
    case P::OSC2_WAVEFORM: osc2_.setWaveform(e.intData); break;
    case P::OSC2_OCTAVE:   osc2_.setOctave(e.intData); break;
    case P::OSC2_DETUNE:   osc2_.setDetune(e.floatData); break;
    case P::OSC2_PULSE_WIDTH: osc2_.setPulseWidth(e.floatData); break;
    case P::OSC2_VOLUME:   osc2_.setVolume(e.floatData); break;
    case P::OSC2_NOISE_TYPE: osc2_.setNoiseType(e.intData); break;
    case P::OSC2_SUB_OSC_MODE: osc2_.setSubOscMode(e.intData); break;
    case P::OSC2_SUB_OSC_VOLUME: osc2_.setSubOscVolume(e.floatData); break;
    case P::OSC2_FM_ENABLED: osc2_.setFmEnabled(e.intData != 0); break;
    case P::OSC2_FM_AMOUNT: osc2_.setFmAmount(e.floatData); break;
    case P::OSC_MIX:       oscMix_ = e.floatData; break;

    // Filter
    case P::FILTER_TYPE:     filter_.setType(e.intData); break;
    case P::FILTER_CUTOFF:   filter_.setCutoff(e.floatData); break;
    case P::FILTER_RESONANCE: filter_.setResonance(e.floatData); break;
    case P::FILTER_ENV_AMOUNT: filter_.setEnvAmount(e.floatData); break;
    case P::FILTER_KEY_TRACKING: filter_.setKeyTracking(e.floatData); break;
    case P::FILTER_DRIVE: filter_.setDrive(e.floatData); break;

    // Amp envelope
    case P::AMP_ATTACK:  ampAttack_ = e.floatData; break;
    case P::AMP_DECAY:   ampDecay_ = e.floatData; break;
    case P::AMP_SUSTAIN: ampSustain_ = e.floatData; break;
    case P::AMP_RELEASE: ampRelease_ = e.floatData; break;
    case P::AMP_DELAY:   ampDelay_ = e.floatData; break;
    case P::AMP_HOLD:    ampHold_ = e.floatData; break;
    case P::AMP_ATTACK_CURVE:  ampAttackCurve_ = e.intData; break;
    case P::AMP_DECAY_CURVE:   ampDecayCurve_ = e.intData; break;
    case P::AMP_RELEASE_CURVE:
        ampReleaseCurve_ = e.intData;
        // Apply to all active voices
        for (int v = 0; v < VoiceAllocator::MAX_VOICES; v++) {
            Voice* voice = allocator_.voice(v);
            if (!voice->active) continue;
            voice->ampEnv.setDelay(ampDelay_);
            voice->ampEnv.setHold(ampHold_);
            voice->ampEnv.setAttack(ampAttack_);
            voice->ampEnv.setDecay(ampDecay_);
            voice->ampEnv.setSustain(ampSustain_);
            voice->ampEnv.setRelease(ampRelease_);
        }
        break;

    // Filter envelope
    case P::FILTER_ATTACK:  filterAttack_ = e.floatData; break;
    case P::FILTER_DECAY:   filterDecay_ = e.floatData; break;
    case P::FILTER_SUSTAIN: filterSustain_ = e.floatData; break;
    case P::FILTER_RELEASE: filterRelease_ = e.floatData; break;
    case P::FILTER_DELAY:   filterDelay_ = e.floatData; break;
    case P::FILTER_HOLD:    filterHold_ = e.floatData; break;
    case P::FILTER_ATTACK_CURVE:  filterAttackCurve_ = e.intData; break;
    case P::FILTER_DECAY_CURVE:   filterDecayCurve_ = e.intData; break;
    case P::FILTER_RELEASE_CURVE:
        filterReleaseCurve_ = e.intData;
        // Apply to all active voices
        for (int v = 0; v < VoiceAllocator::MAX_VOICES; v++) {
            Voice* voice = allocator_.voice(v);
            if (!voice->active) continue;
            voice->filterEnv.setDelay(filterDelay_);
            voice->filterEnv.setHold(filterHold_);
            voice->filterEnv.setAttack(filterAttack_);
            voice->filterEnv.setDecay(filterDecay_);
            voice->filterEnv.setSustain(filterSustain_);
            voice->filterEnv.setRelease(filterRelease_);
        }
        break;

    // LFO 1
    case P::LFO1_WAVEFORM: lfo1_.setWaveform(e.intData); break;
    case P::LFO1_RATE:     lfo1_.setRate(e.floatData); break;
    case P::LFO1_DEPTH:    lfo1_.setDepth(e.floatData); break;
    case P::LFO1_TARGET:   lfo1_.setTarget(e.intData); break;
    case P::LFO1_FADE_IN:  lfo1_.setFadeIn(e.floatData); break;
    case P::LFO1_TEMPO_SYNC: lfo1_.setTempoSync(e.intData != 0); break;
    case P::LFO1_TEMPO_DIVISION: lfo1_.setTempoNoteDivision(e.intData); break;

    // LFO 2
    case P::LFO2_WAVEFORM: lfo2_.setWaveform(e.intData); break;
    case P::LFO2_RATE:     lfo2_.setRate(e.floatData); break;
    case P::LFO2_DEPTH:    lfo2_.setDepth(e.floatData); break;
    case P::LFO2_TARGET:   lfo2_.setTarget(e.intData); break;
    case P::LFO2_FADE_IN:  lfo2_.setFadeIn(e.floatData); break;
    case P::LFO2_TEMPO_SYNC: lfo2_.setTempoSync(e.intData != 0); break;
    case P::LFO2_TEMPO_DIVISION: lfo2_.setTempoNoteDivision(e.intData); break;

    // FX: Chorus (routed to LegacyFxProcessor slot 0)
    case P::CHORUS_ENABLED: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setChorusEnabled(e.intData != 0);
        break;
    }
    case P::CHORUS_RATE: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setChorusRate(e.floatData);
        break;
    }
    case P::CHORUS_DEPTH: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setChorusDepth(e.floatData);
        break;
    }
    case P::CHORUS_MIX: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setChorusMix(e.floatData);
        break;
    }

    // FX: Delay
    case P::DELAY_ENABLED: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setDelayEnabled(e.intData != 0);
        break;
    }
    case P::DELAY_TIME: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setDelayTime(e.floatData);
        break;
    }
    case P::DELAY_FEEDBACK: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setDelayFeedback(e.floatData);
        break;
    }
    case P::DELAY_MIX: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setDelayMix(e.floatData);
        break;
    }

    // FX: Reverb
    case P::REVERB_ENABLED: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setReverbEnabled(e.intData != 0);
        break;
    }
    case P::REVERB_SIZE: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setReverbSize(e.floatData);
        break;
    }
    case P::REVERB_DAMPING: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setReverbDamping(e.floatData);
        break;
    }
    case P::REVERB_MIX: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setReverbMix(e.floatData);
        break;
    }

    // FX: Phaser
    case P::PHASER_ENABLED: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setPhaserEnabled(e.intData != 0);
        break;
    }
    case P::PHASER_RATE: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setPhaserRate(e.floatData);
        break;
    }
    case P::PHASER_DEPTH: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setPhaserDepth(e.floatData);
        break;
    }
    case P::PHASER_FEEDBACK: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setPhaserFeedback(e.floatData);
        break;
    }
    case P::PHASER_MIX: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setPhaserMix(e.floatData);
        break;
    }

    // FX: Drive
    case P::DRIVE_ENABLED: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setDriveEnabled(e.intData != 0);
        break;
    }
    case P::DRIVE_AMOUNT: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setDriveAmount(e.floatData);
        break;
    }
    case P::DRIVE_TYPE: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setDriveType(e.intData);
        break;
    }

    // FX: Flanger
    case P::FLANGER_ENABLED: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setFlangerEnabled(e.intData != 0);
        break;
    }
    case P::FLANGER_RATE: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setFlangerRate(e.floatData);
        break;
    }
    case P::FLANGER_DEPTH: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setFlangerDepth(e.floatData);
        break;
    }
    case P::FLANGER_FEEDBACK: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setFlangerFeedback(e.floatData);
        break;
    }
    case P::FLANGER_MIX: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setFlangerMix(e.floatData);
        break;
    }

    // FX: Compressor
    case P::COMPRESSOR_ENABLED: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setCompressorEnabled(e.intData != 0);
        break;
    }
    case P::COMPRESSOR_THRESHOLD: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setCompressorThreshold(e.floatData);
        break;
    }
    case P::COMPRESSOR_RATIO: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setCompressorRatio(e.floatData);
        break;
    }
    case P::COMPRESSOR_ATTACK: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setCompressorAttack(e.floatData);
        break;
    }
    case P::COMPRESSOR_RELEASE: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setCompressorRelease(e.floatData);
        break;
    }
    case P::COMPRESSOR_MAKEUP_GAIN: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setCompressorMakeupGain(e.floatData);
        break;
    }        // New FX: EQ (slot 1)
    case P::FX_SLOT1_TYPE: fxEngine_.setSlotProcessor(1, createFxProcessor(e.intData)); break;
    case P::FX_SLOT1_ENABLED: fxEngine_.setSlotEnabled(1, e.intData != 0); break;
    case P::FX_SLOT1_PARAM0: fxEngine_.setSlotParam(1, 0, e.floatData); break;
    case P::FX_SLOT1_PARAM1: fxEngine_.setSlotParam(1, 1, e.floatData); break;
    case P::FX_SLOT1_PARAM2: fxEngine_.setSlotParam(1, 2, e.floatData); break;
    case P::FX_SLOT1_PARAM3: fxEngine_.setSlotParam(1, 3, e.floatData); break;
    case P::FX_SLOT1_PARAM4: fxEngine_.setSlotParam(1, 4, e.floatData); break;
    case P::FX_SLOT1_PARAM5: fxEngine_.setSlotParam(1, 5, e.floatData); break;
    case P::FX_SLOT1_PARAM6: fxEngine_.setSlotParam(1, 6, e.floatData); break;
    case P::FX_SLOT1_PARAM7: fxEngine_.setSlotParam(1, 7, e.floatData); break;

        // New FX: Limiter (slot 2)
    case P::FX_SLOT2_TYPE: fxEngine_.setSlotProcessor(2, createFxProcessor(e.intData)); break;
    case P::FX_SLOT2_ENABLED: fxEngine_.setSlotEnabled(2, e.intData != 0); break;
    case P::FX_SLOT2_PARAM0: fxEngine_.setSlotParam(2, 0, e.floatData); break;
    case P::FX_SLOT2_PARAM1: fxEngine_.setSlotParam(2, 1, e.floatData); break;
    case P::FX_SLOT2_PARAM2: fxEngine_.setSlotParam(2, 2, e.floatData); break;
    case P::FX_SLOT2_PARAM3: fxEngine_.setSlotParam(2, 3, e.floatData); break;
    case P::FX_SLOT2_PARAM4: fxEngine_.setSlotParam(2, 4, e.floatData); break;

        // New FX: Rotary (slot 3)
    case P::FX_SLOT3_TYPE: fxEngine_.setSlotProcessor(3, createFxProcessor(e.intData)); break;
    case P::FX_SLOT3_ENABLED: fxEngine_.setSlotEnabled(3, e.intData != 0); break;
    case P::FX_SLOT3_PARAM0: fxEngine_.setSlotParam(3, 0, e.floatData); break;
    case P::FX_SLOT3_PARAM1: fxEngine_.setSlotParam(3, 1, e.floatData); break;
    case P::FX_SLOT3_PARAM2: fxEngine_.setSlotParam(3, 2, e.floatData); break;
    case P::FX_SLOT3_PARAM3: fxEngine_.setSlotParam(3, 3, e.floatData); break;
    case P::FX_SLOT3_PARAM4: fxEngine_.setSlotParam(3, 4, e.floatData); break;
    case P::FX_SLOT3_PARAM5: fxEngine_.setSlotParam(3, 5, e.floatData); break;

        // FX Engine master control
    case P::FX_MASTER_ENABLED: fxEngine_.setMasterEnabled(e.intData != 0); break;
    case P::FX_MASTER_MIX: fxEngine_.setMasterMix(e.floatData); break;

    // Master
    case P::MASTER_VOLUME: masterVolume_ = e.floatData; break;

    // Unison 1
    case P::OSC1_UNISON_VOICE_COUNT:    osc1_.setUnisonVoiceCount(e.intData); break;
    case P::OSC1_UNISON_DETUNE_SPREAD:  osc1_.setUnisonDetuneSpread(e.floatData); break;
    case P::OSC1_UNISON_STEREO_SPREAD:  osc1_.setUnisonStereoSpread(e.floatData); break;
    case P::OSC1_UNISON_MIX:            osc1_.setUnisonMix(e.floatData); break;

    // Unison 2
    case P::OSC2_UNISON_VOICE_COUNT:    osc2_.setUnisonVoiceCount(e.intData); break;
    case P::OSC2_UNISON_DETUNE_SPREAD:  osc2_.setUnisonDetuneSpread(e.floatData); break;
    case P::OSC2_UNISON_STEREO_SPREAD:  osc2_.setUnisonStereoSpread(e.floatData); break;
    case P::OSC2_UNISON_MIX:            osc2_.setUnisonMix(e.floatData); break;

    // Arpeggiator
    case P::ARP_ENABLED:       arpeggiator_.setEnabled(e.intData != 0); break;
    case P::ARP_TEMPO:         arpeggiator_.setTempo(e.floatData); break;
    case P::ARP_PATTERN:       arpeggiator_.setPattern(e.intData); break;
    case P::ARP_OCTAVE_RANGE:  arpeggiator_.setOctaveRange(e.intData); break;
    case P::ARP_GATE:          arpeggiator_.setGate(e.floatData); break;
    case P::ARP_RESOLUTION:    arpeggiator_.setResolution(e.intData); break;
    case P::ARP_SWING:         arpeggiator_.setSwing(e.floatData); break;
    case P::ARP_HOLD:          arpeggiator_.setHold(e.intData != 0); break;

    // Voice priority
    case P::VOICE_PRIORITY_MODE: allocator_.setPriorityMode(static_cast<VoicePriorityMode>(e.intData)); break;

    default: break; // Unknown param — ignore
    }
}

// ── Legacy FX slot initialization ───────────────────────────────────────────

void SynthEngine::initLegacyFxSlot() {
    auto* legacy = new LegacyFxProcessor();
    fxEngine_.setSlotProcessor(0, legacy);
    fxEngine_.setSlotEnabled(0, true);
}

LegacyFxProcessor* SynthEngine::getLegacyFx() const {
    // Slot 0 always holds the LegacyFxProcessor (type None)
    if (fxEngine_.slot(0).processor &&
        fxEngine_.slotType(0) == FxType::None) {
        return static_cast<LegacyFxProcessor*>(fxEngine_.slot(0).processor);
    }
    return nullptr;
}

FxProcessor* SynthEngine::createFxProcessor(int fxTypeId) {
    FxProcessor* proc = nullptr;
    switch (fxTypeId) {
    case 8:  proc = new EqProcessor();       break; // Equalizer
    case 9:  proc = new LimiterProcessor();  break; // Limiter
    case 10: proc = new RotaryProcessor();   break; // Rotary speaker
    case 11: proc = new TremoloProcessor();  break; // Tremolo
    default: return nullptr;
    }
    // Forward the actual sample rate so processors can pre-compute
    // sample-rate-dependent coefficients before the first process() call.
    if (proc) {
        proc->setSampleRate(sampleRate_);
    }
    return proc;
}

// ── Legacy FX setters ────────────────────────────────────────────────────────

void SynthEngine::setChorusEnabled(bool e) {
    if (auto* legacy = getLegacyFx()) legacy->setChorusEnabled(e);
}
void SynthEngine::setChorusRate(float hz) {
    if (auto* legacy = getLegacyFx()) legacy->setChorusRate(hz);
}
void SynthEngine::setChorusDepth(float d) {
    if (auto* legacy = getLegacyFx()) legacy->setChorusDepth(d);
}
void SynthEngine::setChorusMix(float m) {
    if (auto* legacy = getLegacyFx()) legacy->setChorusMix(m);
}

void SynthEngine::setDelayEnabled(bool e) {
    if (auto* legacy = getLegacyFx()) legacy->setDelayEnabled(e);
}
void SynthEngine::setDelayTime(float ms) {
    if (auto* legacy = getLegacyFx()) legacy->setDelayTime(ms);
}
void SynthEngine::setDelayFeedback(float fb) {
    if (auto* legacy = getLegacyFx()) legacy->setDelayFeedback(fb);
}
void SynthEngine::setDelayMix(float m) {
    if (auto* legacy = getLegacyFx()) legacy->setDelayMix(m);
}

void SynthEngine::setReverbEnabled(bool e) {
    if (auto* legacy = getLegacyFx()) legacy->setReverbEnabled(e);
}
void SynthEngine::setReverbSize(float s) {
    if (auto* legacy = getLegacyFx()) legacy->setReverbSize(s);
}
void SynthEngine::setReverbDamping(float d) {
    if (auto* legacy = getLegacyFx()) legacy->setReverbDamping(d);
}
void SynthEngine::setReverbMix(float m) {
    if (auto* legacy = getLegacyFx()) legacy->setReverbMix(m);
}

void SynthEngine::setPhaserEnabled(bool e) {
    if (auto* legacy = getLegacyFx()) legacy->setPhaserEnabled(e);
}
void SynthEngine::setPhaserRate(float hz) {
    if (auto* legacy = getLegacyFx()) legacy->setPhaserRate(hz);
}
void SynthEngine::setPhaserDepth(float d) {
    if (auto* legacy = getLegacyFx()) legacy->setPhaserDepth(d);
}
void SynthEngine::setPhaserFeedback(float fb) {
    if (auto* legacy = getLegacyFx()) legacy->setPhaserFeedback(fb);
}
void SynthEngine::setPhaserMix(float m) {
    if (auto* legacy = getLegacyFx()) legacy->setPhaserMix(m);
}

void SynthEngine::setDriveEnabled(bool e) {
    if (auto* legacy = getLegacyFx()) legacy->setDriveEnabled(e);
}
void SynthEngine::setDriveAmount(float a) {
    if (auto* legacy = getLegacyFx()) legacy->setDriveAmount(a);
}
void SynthEngine::setDriveType(int t) {
    if (auto* legacy = getLegacyFx()) legacy->setDriveType(t);
}

void SynthEngine::setFlangerEnabled(bool e) {
    if (auto* legacy = getLegacyFx()) legacy->setFlangerEnabled(e);
}
void SynthEngine::setFlangerRate(float hz) {
    if (auto* legacy = getLegacyFx()) legacy->setFlangerRate(hz);
}
void SynthEngine::setFlangerDepth(float d) {
    if (auto* legacy = getLegacyFx()) legacy->setFlangerDepth(d);
}
void SynthEngine::setFlangerFeedback(float fb) {
    if (auto* legacy = getLegacyFx()) legacy->setFlangerFeedback(fb);
}
void SynthEngine::setFlangerMix(float m) {
    if (auto* legacy = getLegacyFx()) legacy->setFlangerMix(m);
}

void SynthEngine::setCompressorEnabled(bool e) {
    if (auto* legacy = getLegacyFx()) legacy->setCompressorEnabled(e);
}
void SynthEngine::setCompressorThreshold(float t) {
    if (auto* legacy = getLegacyFx()) legacy->setCompressorThreshold(t);
}
void SynthEngine::setCompressorRatio(float r) {
    if (auto* legacy = getLegacyFx()) legacy->setCompressorRatio(r);
}
void SynthEngine::setCompressorAttack(float a) {
    if (auto* legacy = getLegacyFx()) legacy->setCompressorAttack(a);
}
void SynthEngine::setCompressorRelease(float r) {
    if (auto* legacy = getLegacyFx()) legacy->setCompressorRelease(r);
}
void SynthEngine::setCompressorMakeupGain(float g) {
    if (auto* legacy = getLegacyFx()) legacy->setCompressorMakeupGain(g);
}

// ── Preset ────────────────────────────────────────────────────────────────────

int SynthEngine::loadPreset(const char* path) {
    std::ifstream file(path);
    if (!file.is_open()) return -1;
    // Simple preset loading — parse key=value pairs
    std::string line;
    while (std::getline(file, line)) {
        // Preset format: param_name=value
        auto eq = line.find('=');
        if (eq == std::string::npos) continue;
        std::string key = line.substr(0, eq);
        std::string val = line.substr(eq + 1);
        // Parse known params
        try {
            if (key == "osc1_waveform") setOsc1Waveform(std::stoi(val));
            else if (key == "osc1_octave") setOsc1Octave(std::stoi(val));
            else if (key == "osc1_detune") setOsc1Detune(std::stof(val));
            else if (key == "osc1_pulse_width") setOsc1PulseWidth(std::stof(val));
            else if (key == "osc1_volume") setOsc1Volume(std::stof(val));
            else if (key == "osc2_waveform") setOsc2Waveform(std::stoi(val));
            else if (key == "osc2_octave") setOsc2Octave(std::stoi(val));
            else if (key == "osc2_detune") setOsc2Detune(std::stof(val));
            else if (key == "osc2_pulse_width") setOsc2PulseWidth(std::stof(val));
            else if (key == "osc2_volume") setOsc2Volume(std::stof(val));
            else if (key == "osc_mix") setOscMix(std::stof(val));
            else if (key == "filter_type") setFilterType(std::stoi(val));
            else if (key == "filter_cutoff") setFilterCutoff(std::stof(val));
            else if (key == "filter_resonance") setFilterResonance(std::stof(val));
            else if (key == "filter_env_amount") setFilterEnvAmount(std::stof(val));
            else if (key == "amp_attack") setAmpAttack(std::stof(val));
            else if (key == "amp_decay") setAmpDecay(std::stof(val));
            else if (key == "amp_sustain") setAmpSustain(std::stof(val));
            else if (key == "amp_release") setAmpRelease(std::stof(val));
            else if (key == "filter_attack") setFilterAttack(std::stof(val));
            else if (key == "filter_decay") setFilterDecay(std::stof(val));
            else if (key == "filter_sustain") setFilterSustain(std::stof(val));
            else if (key == "filter_release") setFilterRelease(std::stof(val));
            else if (key == "master_volume") setMasterVolume(std::stof(val));
            else if (key == "osc1_unison_voice_count") setOsc1UnisonVoiceCount(std::stoi(val));
            else if (key == "osc1_unison_detune_spread") setOsc1UnisonDetuneSpread(std::stof(val));
            else if (key == "osc1_unison_stereo_spread") setOsc1UnisonStereoSpread(std::stof(val));
            else if (key == "osc1_unison_mix") setOsc1UnisonMix(std::stof(val));
            else if (key == "osc2_unison_voice_count") setOsc2UnisonVoiceCount(std::stoi(val));
            else if (key == "osc2_unison_detune_spread") setOsc2UnisonDetuneSpread(std::stof(val));
            else if (key == "osc2_unison_stereo_spread") setOsc2UnisonStereoSpread(std::stof(val));
            else if (key == "osc2_unison_mix") setOsc2UnisonMix(std::stof(val));
        } catch (...) {
            // skip invalid lines
        }
    }
    return 0;
}

int SynthEngine::savePreset(const char* path) const {
    std::ofstream file(path);
    if (!file.is_open()) return -1;

    // Oscillator 1
    file << "osc1_waveform=" << osc1_.waveform() << "\n";
    file << "osc1_octave=" << osc1_.octave() << "\n";
    file << "osc1_detune=" << osc1_.detune() << "\n";
    file << "osc1_pulse_width=" << osc1_.pulseWidth() << "\n";
    file << "osc1_volume=" << osc1_.volume() << "\n";

    // Oscillator 2
    file << "osc2_waveform=" << osc2_.waveform() << "\n";
    file << "osc2_octave=" << osc2_.octave() << "\n";
    file << "osc2_detune=" << osc2_.detune() << "\n";
    file << "osc2_pulse_width=" << osc2_.pulseWidth() << "\n";
    file << "osc2_volume=" << osc2_.volume() << "\n";

    file << "osc_mix=" << oscMix_ << "\n";

    // Unison 1
    file << "osc1_unison_voice_count=" << osc1_.unison().voiceCount << "\n";
    file << "osc1_unison_detune_spread=" << osc1_.unison().detuneSpread << "\n";
    file << "osc1_unison_stereo_spread=" << osc1_.unison().stereoSpread << "\n";
    file << "osc1_unison_mix=" << osc1_.unison().mix << "\n";

    // Unison 2
    file << "osc2_unison_voice_count=" << osc2_.unison().voiceCount << "\n";
    file << "osc2_unison_detune_spread=" << osc2_.unison().detuneSpread << "\n";
    file << "osc2_unison_stereo_spread=" << osc2_.unison().stereoSpread << "\n";
    file << "osc2_unison_mix=" << osc2_.unison().mix << "\n";

    // Filter
    file << "filter_type=" << filter_.type() << "\n";
    file << "filter_cutoff=" << filter_.cutoff() << "\n";
    file << "filter_resonance=" << filter_.resonance() << "\n";
    file << "filter_env_amount=" << filter_.envAmount() << "\n";

    // Amplifier envelope
    file << "amp_attack=" << ampAttack_ << "\n";
    file << "amp_decay=" << ampDecay_ << "\n";
    file << "amp_sustain=" << ampSustain_ << "\n";
    file << "amp_release=" << ampRelease_ << "\n";

    // Filter envelope
    file << "filter_attack=" << filterAttack_ << "\n";
    file << "filter_decay=" << filterDecay_ << "\n";
    file << "filter_sustain=" << filterSustain_ << "\n";
    file << "filter_release=" << filterRelease_ << "\n";

    // LFO 1
    file << "lfo1_waveform=" << lfo1_.waveform() << "\n";
    file << "lfo1_rate=" << lfo1_.rate() << "\n";
    file << "lfo1_depth=" << lfo1_.depth() << "\n";
    file << "lfo1_target=" << static_cast<int>(lfo1_.target()) << "\n";

    // LFO 2
    file << "lfo2_waveform=" << lfo2_.waveform() << "\n";
    file << "lfo2_rate=" << lfo2_.rate() << "\n";
    file << "lfo2_depth=" << lfo2_.depth() << "\n";
    file << "lfo2_target=" << static_cast<int>(lfo2_.target()) << "\n";

    // Master volume
    file << "master_volume=" << masterVolume_ << "\n";

    return 0;
}

} // namespace openamp
