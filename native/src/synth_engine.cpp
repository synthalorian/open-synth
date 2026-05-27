#include "synth_engine.h"
#include <cmath>
#include <cstring>
#include <algorithm>
#include <fstream>
#include <sstream>
#include <iostream>

namespace openamp {

// ── Helpers ───────────────────────────────────────────────────────────────────

static float midiNoteToFreq(int note) {
    return 440.0f * std::pow(2.0f, (note - 69) / 12.0f);
}

// ── Construction / destruction ────────────────────────────────────────────────

SynthEngine::SynthEngine(double sampleRate, uint32_t blockSize)
    : sampleRate_(sampleRate), blockSize_(blockSize) {
    delayBuffer_ = new float[MAX_DELAY_SAMPLES]();
    delayBufferSize_ = static_cast<uint32_t>(delayTimeMs_ * 0.001f * sampleRate_);
    if (delayBufferSize_ < 1) delayBufferSize_ = 1;

    lfo1_.prepare(sampleRate_);
    lfo2_.prepare(sampleRate_);
}

SynthEngine::~SynthEngine() {
    delete[] delayBuffer_;
}

// ── Reset ─────────────────────────────────────────────────────────────────────

void SynthEngine::reset() {
    allocator_.allNotesOff();
    osc1_.reset();
    osc2_.reset();
    filter_.reset();
    lfo1_.reset();
    lfo2_.reset();
    std::memset(delayBuffer_, 0, MAX_DELAY_SAMPLES * sizeof(float));
    delayWritePos_ = 0;
    // Clear reverb state
    for (auto& s : reverbState_) s = 0.0f;
    for (auto& p : reverbPos_) p = 0;
    // Clear flanger delay lines
    std::memset(flangerDelayL_, 0, FLANGER_DELAY_SAMPLES * sizeof(float));
    std::memset(flangerDelayR_, 0, FLANGER_DELAY_SAMPLES * sizeof(float));
    flangerWritePos_ = 0;
    flangerPhase_ = 0.0f;
    // Reset compressor envelope
    compressorEnvelope_ = 0.0f;
    // Reset phaser state
    phaserPhase_ = 0.0f;
    phaserState1L_ = 0.0f; phaserState2L_ = 0.0f;
    phaserState1R_ = 0.0f; phaserState2R_ = 0.0f;
    // Reset chorus phase
    chorusPhase_ = 0.0f;
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
    const uint32_t numFrames = output.numFrames;
    const bool stereo = output.numChannels >= 2;

    // Drain the parameter queue at block boundaries (thread-safe).
    drainQueue();

    // Let the arpeggiator generate note events (if enabled).
    arpeggiator_.process(numFrames, sampleRate_, allocator_);

    // Update per-block LFO
    float lfo1Val = lfo1_.process();
    float lfo2Val = lfo2_.process();

    updateDelayBufferSize();

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

            // Check if voice is done
            if (voice->ampEnv.state() == Envelope::IDLE) {
                voice->active = false;
                continue;
            }

            // Apply pitch LFO modulation
            float pitchMod = 0.0f;
            if (lfo1_.target() == LFO::Target::PITCH) pitchMod += lfo1Val;
            if (lfo2_.target() == LFO::Target::PITCH) pitchMod += lfo2Val;
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
            float filtered = filter_.process(monoMix, filterEnv + filterMod, sampleRate_);

            voiceLeft = filtered * ampGain * (1.0f - voice->pan) * 0.5f;
            voiceRight = filtered * ampGain * (1.0f + voice->pan) * 0.5f;

            leftOut += voiceLeft;
            rightOut += voiceRight;
        }

        // Apply LFO amplitude modulation
        float ampMod = 0.0f;
        if (lfo1_.target() == LFO::Target::AMPLITUDE) ampMod += lfo1Val;
        if (lfo2_.target() == LFO::Target::AMPLITUDE) ampMod += lfo2Val;
        ampMod = 1.0f - std::abs(ampMod) * 0.5f;

        leftOut *= ampMod;
        rightOut *= ampMod;

        // Apply effects
        applyEffects(leftOut, rightOut);

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

    // Osc 1
    case P::OSC1_WAVEFORM: osc1_.setWaveform(e.intData); break;
    case P::OSC1_OCTAVE:   osc1_.setOctave(e.intData); break;
    case P::OSC1_DETUNE:   osc1_.setDetune(e.floatData); break;
    case P::OSC1_PULSE_WIDTH: osc1_.setPulseWidth(e.floatData); break;
    case P::OSC1_VOLUME:   osc1_.setVolume(e.floatData); break;

    // Osc 2
    case P::OSC2_WAVEFORM: osc2_.setWaveform(e.intData); break;
    case P::OSC2_OCTAVE:   osc2_.setOctave(e.intData); break;
    case P::OSC2_DETUNE:   osc2_.setDetune(e.floatData); break;
    case P::OSC2_PULSE_WIDTH: osc2_.setPulseWidth(e.floatData); break;
    case P::OSC2_VOLUME:   osc2_.setVolume(e.floatData); break;
    case P::OSC_MIX:       oscMix_ = e.floatData; break;

    // Filter
    case P::FILTER_TYPE:     filter_.setType(e.intData); break;
    case P::FILTER_CUTOFF:   filter_.setCutoff(e.floatData); break;
    case P::FILTER_RESONANCE: filter_.setResonance(e.floatData); break;
    case P::FILTER_ENV_AMOUNT: filter_.setEnvAmount(e.floatData); break;

    // Amp envelope
    case P::AMP_ATTACK:  ampAttack_ = e.floatData; break;
    case P::AMP_DECAY:   ampDecay_ = e.floatData; break;
    case P::AMP_SUSTAIN: ampSustain_ = e.floatData; break;
    case P::AMP_RELEASE: ampRelease_ = e.floatData; break;

    // Filter envelope
    case P::FILTER_ATTACK:  filterAttack_ = e.floatData; break;
    case P::FILTER_DECAY:   filterDecay_ = e.floatData; break;
    case P::FILTER_SUSTAIN: filterSustain_ = e.floatData; break;
    case P::FILTER_RELEASE: filterRelease_ = e.floatData; break;

    // LFO 1
    case P::LFO1_WAVEFORM: lfo1_.setWaveform(e.intData); break;
    case P::LFO1_RATE:     lfo1_.setRate(e.floatData); break;
    case P::LFO1_DEPTH:    lfo1_.setDepth(e.floatData); break;
    case P::LFO1_TARGET:   lfo1_.setTarget(e.intData); break;

    // LFO 2
    case P::LFO2_WAVEFORM: lfo2_.setWaveform(e.intData); break;
    case P::LFO2_RATE:     lfo2_.setRate(e.floatData); break;
    case P::LFO2_DEPTH:    lfo2_.setDepth(e.floatData); break;
    case P::LFO2_TARGET:   lfo2_.setTarget(e.intData); break;

    // FX: Chorus
    case P::CHORUS_ENABLED: chorusEnabled_ = (e.intData != 0); break;
    case P::CHORUS_RATE:    chorusRate_ = e.floatData; break;
    case P::CHORUS_DEPTH:   chorusDepth_ = e.floatData; break;
    case P::CHORUS_MIX:     chorusMix_ = e.floatData; break;

    // FX: Delay
    case P::DELAY_ENABLED:  delayEnabled_ = (e.intData != 0); break;
    case P::DELAY_TIME:     delayTimeMs_ = e.floatData; break;
    case P::DELAY_FEEDBACK: delayFeedback_ = e.floatData; break;
    case P::DELAY_MIX:      delayMix_ = e.floatData; break;

    // FX: Reverb
    case P::REVERB_ENABLED: reverbEnabled_ = (e.intData != 0); break;
    case P::REVERB_SIZE:    reverbSize_ = e.floatData; break;
    case P::REVERB_DAMPING: reverbDamping_ = e.floatData; break;
    case P::REVERB_MIX:     reverbMix_ = e.floatData; break;

    // FX: Phaser
    case P::PHASER_ENABLED:  phaserEnabled_ = (e.intData != 0); break;
    case P::PHASER_RATE:     phaserRate_ = e.floatData; break;
    case P::PHASER_DEPTH:    phaserDepth_ = e.floatData; break;
    case P::PHASER_FEEDBACK: phaserFeedback_ = e.floatData; break;
    case P::PHASER_MIX:      phaserMix_ = e.floatData; break;

    // FX: Drive
    case P::DRIVE_ENABLED: driveEnabled_ = (e.intData != 0); break;
    case P::DRIVE_AMOUNT:  driveAmount_ = e.floatData; break;
    case P::DRIVE_TYPE:    driveType_ = e.intData; break;

    // FX: Flanger
    case P::FLANGER_ENABLED:  flangerEnabled_ = (e.intData != 0); break;
    case P::FLANGER_RATE:     flangerRate_ = e.floatData; break;
    case P::FLANGER_DEPTH:    flangerDepth_ = e.floatData; break;
    case P::FLANGER_FEEDBACK: flangerFeedback_ = e.floatData; break;
    case P::FLANGER_MIX:      flangerMix_ = e.floatData; break;

    // FX: Compressor
    case P::COMPRESSOR_ENABLED:      compressorEnabled_ = (e.intData != 0); break;
    case P::COMPRESSOR_THRESHOLD:    compressorThreshold_ = e.floatData; break;
    case P::COMPRESSOR_RATIO:        compressorRatio_ = e.floatData; break;
    case P::COMPRESSOR_ATTACK:       compressorAttack_ = e.floatData; break;
    case P::COMPRESSOR_RELEASE:      compressorRelease_ = e.floatData; break;
    case P::COMPRESSOR_MAKEUP_GAIN:  compressorMakeupGain_ = e.floatData; break;

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

    default: break; // Unknown param — ignore
    }
}

// ── Effects ───────────────────────────────────────────────────────────────────

void SynthEngine::updateDelayBufferSize() {
    uint32_t newSize = static_cast<uint32_t>(delayTimeMs_ * 0.001f * sampleRate_);
    if (newSize < 1) newSize = 1;
    if (newSize > MAX_DELAY_SAMPLES) newSize = MAX_DELAY_SAMPLES;
    delayBufferSize_ = newSize;
}

float SynthEngine::applyDistortion(float sample) {
    if (driveAmount_ < 0.01f) return sample;
    switch (driveType_) {
    case 0: // Soft clip
        return std::tanh(sample * (1.0f + driveAmount_ * 4.0f)) / std::tanh(1.0f + driveAmount_ * 4.0f);
    case 1: // Hard clip
        return std::clamp(sample * (1.0f + driveAmount_ * 2.0f), -1.0f, 1.0f);
    case 2: // Asymmetric
        if (sample > 0)
            return std::tanh(sample * (1.0f + driveAmount_ * 3.0f));
        else
            return std::clamp(sample * (1.0f + driveAmount_ * 1.5f), -1.0f, 0.0f);
    default:
        return sample;
    }
}

void SynthEngine::applyEffects(float& left, float& right) {
    // Drive
    if (driveEnabled_) {
        left = applyDistortion(left);
        right = applyDistortion(right);
    }

    // Chorus (simple)
    if (chorusEnabled_ && chorusMix_ > 0.0f) {
        chorusPhase_ += chorusRate_ / sampleRate_;
        if (chorusPhase_ >= 1.0f) chorusPhase_ -= 1.0f;
        float chorusOffset = std::sin(2.0f * M_PI * chorusPhase_) * chorusDepth_ * 0.005f;
        left = left * (1.0f - chorusMix_) + left * chorusMix_ * (1.0f + chorusOffset * 0.5f);
        right = right * (1.0f - chorusMix_) + right * chorusMix_ * (1.0f - chorusOffset * 0.5f);
    }

    // Delay
    if (delayEnabled_ && delayMix_ > 0.0f) {
        uint32_t readPos = (delayWritePos_ >= delayBufferSize_)
            ? delayWritePos_ - delayBufferSize_
            : MAX_DELAY_SAMPLES + delayWritePos_ - delayBufferSize_;
        float delayedL = delayBuffer_[readPos];
        float delayedR = (readPos + 1 < MAX_DELAY_SAMPLES) ? delayBuffer_[readPos + 1] : 0.0f;

        // Clamp feedback input to prevent buffer runaway
        float fbL = clamp(left + delayedL * delayFeedback_, -2.0f, 2.0f);
        float fbR = clamp(right + delayedR * delayFeedback_, -2.0f, 2.0f);
        delayBuffer_[delayWritePos_] = fbL;
        delayWritePos_ = (delayWritePos_ + 1) % MAX_DELAY_SAMPLES;
        delayBuffer_[delayWritePos_] = fbR;
        delayWritePos_ = (delayWritePos_ + 1) % MAX_DELAY_SAMPLES;

        left = left * (1.0f - delayMix_) + clamp(delayedL, -2.0f, 2.0f) * delayMix_;
        right = right * (1.0f - delayMix_) + clamp(delayedR, -2.0f, 2.0f) * delayMix_;
    }

    // Reverb (simple Schroeder all-pass based)
    if (reverbEnabled_ && reverbMix_ > 0.0f) {
        float wetL = 0.0f, wetR = 0.0f;
        float fb = reverbDamping_ * 0.7f;
        for (int i = 0; i < 4; i++) {
            uint32_t delayLen = 1200 + i * 800; // ~25-90ms at 48k
            delayLen = std::min(delayLen, static_cast<uint32_t>(4800)); // Safety clamp
            float in = (i == 0) ? (left + right) * 0.5f : reverbState_[i - 1];
            // Clamp input to prevent reverb runaway
            in = clamp(in, -2.0f, 2.0f);
            uint32_t pos = reverbPos_[i];
            if (pos >= delayLen) pos = 0; // Safety clamp
            float delayed = clamp(reverbDelay_[i][pos], -2.0f, 2.0f);
            float out = in + delayed * fb;
            reverbDelay_[i][pos] = clamp(in - delayed * fb, -2.0f, 2.0f);
            reverbState_[i] = clamp(out, -2.0f, 2.0f);
            reverbPos_[i] = (pos + 1) % delayLen;
            if (i < 2) wetL += out * 0.5f;
            else wetR += out * 0.5f;
        }
        wetL *= reverbSize_ * 0.5f;
        wetR *= reverbSize_ * 0.5f;
        left = left * (1.0f - reverbMix_) + clamp(wetL, -2.0f, 2.0f) * reverbMix_;
        right = right * (1.0f - reverbMix_) + clamp(wetR, -2.0f, 2.0f) * reverbMix_;
    }

    // Flanger (stereo — separate L/R delay lines)
    if (flangerEnabled_ && flangerMix_ > 0.0f) {
        flangerPhase_ += flangerRate_ / sampleRate_;
        if (flangerPhase_ >= 1.0f) flangerPhase_ -= 1.0f;
        float lfo = std::sin(2.0f * M_PI * flangerPhase_);
        float delaySamples = 1.0f + (lfo * 0.5f + 0.5f) * flangerDepth_ * FLANGER_DELAY_SAMPLES * 0.25f;
        uint32_t readPos = (flangerWritePos_ >= static_cast<uint32_t>(delaySamples))
            ? flangerWritePos_ - static_cast<uint32_t>(delaySamples)
            : FLANGER_DELAY_SAMPLES + flangerWritePos_ - static_cast<uint32_t>(delaySamples);
        if (readPos >= FLANGER_DELAY_SAMPLES) readPos = 0;

        float delayedL = clamp(flangerDelayL_[readPos], -2.0f, 2.0f);
        float delayedR = clamp(flangerDelayR_[readPos], -2.0f, 2.0f);

        // Clamp feedback input to prevent buffer runaway
        flangerDelayL_[flangerWritePos_] = clamp(left + delayedL * flangerFeedback_, -2.0f, 2.0f);
        flangerDelayR_[flangerWritePos_] = clamp(right + delayedR * flangerFeedback_, -2.0f, 2.0f);
        flangerWritePos_ = (flangerWritePos_ + 1) % FLANGER_DELAY_SAMPLES;

        left = left * (1.0f - flangerMix_) + delayedL * flangerMix_;
        right = right * (1.0f - flangerMix_) + delayedR * flangerMix_;
    }

    // Compressor (stereo linked) — FIXED: makeup gain multiplies, not adds
    if (compressorEnabled_) {
        float inputLevel = std::max(std::abs(left), std::abs(right));
        float gainReduction = 1.0f;
        if (inputLevel > compressorThreshold_) {
            float overThreshold = (inputLevel - compressorThreshold_) / (1.0f - compressorThreshold_);
            float targetGain = 1.0f - overThreshold * (1.0f - 1.0f / compressorRatio_);
            gainReduction = targetGain / (inputLevel + 0.0001f);
        }
        float attackCoeff = 1.0f - std::exp(-1.0f / (compressorAttack_ * 0.001f * sampleRate_));
        float releaseCoeff = 1.0f - std::exp(-1.0f / (compressorRelease_ * 0.001f * sampleRate_));
        if (gainReduction < compressorEnvelope_) {
            compressorEnvelope_ += (gainReduction - compressorEnvelope_) * attackCoeff;
        } else {
            compressorEnvelope_ += (gainReduction - compressorEnvelope_) * releaseCoeff;
        }
        left *= compressorEnvelope_ * (1.0f + compressorMakeupGain_);
        right *= compressorEnvelope_ * (1.0f + compressorMakeupGain_);
    }

    // Phaser
    if (phaserEnabled_ && phaserMix_ > 0.0f) {
        phaserPhase_ += phaserRate_ / sampleRate_;
        if (phaserPhase_ >= 1.0f) phaserPhase_ -= 1.0f;
        float freq = 200.0f + std::sin(2.0f * M_PI * phaserPhase_) * phaserDepth_ * 1900.0f;
        // Clamp coeff to prevent tan() explosion at high freq/sampleRate ratios
        float coeff = std::min(static_cast<float>(std::tan(M_PI * freq / sampleRate_)), 10.0f);
        float damp = 1.0f / (1.0f + coeff * phaserFeedback_ * 0.5f);

        // Left channel all-pass
        float inL = left + clamp(phaserState1L_, -2.0f, 2.0f) * phaserFeedback_ * 0.3f;
        float outL = phaserState1L_ + coeff * inL;
        phaserState1L_ = clamp(outL - coeff * phaserState1L_ * damp, -2.0f, 2.0f);
        inL = outL + clamp(phaserState2L_, -2.0f, 2.0f) * phaserFeedback_ * 0.3f;
        outL = phaserState2L_ + coeff * inL;
        phaserState2L_ = clamp(outL - coeff * phaserState2L_ * damp, -2.0f, 2.0f);
        left = left * (1.0f - phaserMix_) + clamp(outL, -2.0f, 2.0f) * phaserMix_;

        // Right channel all-pass
        float inR = right + clamp(phaserState1R_, -2.0f, 2.0f) * phaserFeedback_ * 0.3f;
        float outR = phaserState1R_ + coeff * inR;
        phaserState1R_ = clamp(outR - coeff * phaserState1R_ * damp, -2.0f, 2.0f);
        inR = outR + clamp(phaserState2R_, -2.0f, 2.0f) * phaserFeedback_ * 0.3f;
        outR = phaserState2R_ + coeff * inR;
        phaserState2R_ = clamp(outR - coeff * phaserState2R_ * damp, -2.0f, 2.0f);
        right = right * (1.0f - phaserMix_) + clamp(outR, -2.0f, 2.0f) * phaserMix_;
    }
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
