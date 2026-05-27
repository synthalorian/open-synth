#include "legacy_fx.h"
#include <cstring>
#include <cmath>

namespace openamp {

// ── Construction ─────────────────────────────────────────────────────────────

LegacyFxProcessor::LegacyFxProcessor()
    : FxProcessor(FxType::None) // slot 0 is a composite of many types
{
    // Zero out all delay buffers
    std::memset(delayBuffer_, 0, sizeof(delayBuffer_));
    std::memset(flangerDelayL_, 0, sizeof(flangerDelayL_));
    std::memset(flangerDelayR_, 0, sizeof(flangerDelayR_));
    for (int i = 0; i < REVERB_TAPS; i++) {
        std::memset(reverbDelay_[i], 0, sizeof(reverbDelay_[i]));
    }
    enabled_ = true; // Legacy FX slot is enabled by default
}

// ── Process ───────────────────────────────────────────────────────────────────

void LegacyFxProcessor::process(float& left, float& right, double sampleRate) {
    // Drive (pre-effects)
    if (driveEnabled_ && driveAmount_ > 0.01f) {
        left = applyDistortion(left);
        right = applyDistortion(right);
    }

    // Chorus
    processChorus(left, right, sampleRate);

    // Delay
    processDelay(left, right, sampleRate);

    // Reverb
    processReverb(left, right, sampleRate);

    // Flanger
    processFlanger(left, right, sampleRate);

    // Compressor (post-effects, before phaser)
    processCompressor(left, right);

    // Phaser (last in chain)
    processPhaser(left, right, sampleRate);
}

// ── Reset ─────────────────────────────────────────────────────────────────────

void LegacyFxProcessor::reset() {
    std::memset(delayBuffer_, 0, sizeof(delayBuffer_));
    delayWritePos_ = 0;
    chorusPhase_ = 0.0f;
    phaserPhase_ = 0.0f;
    flangerPhase_ = 0.0f;
    flangerWritePos_ = 0;
    phaserState1L_ = phaserState2L_ = 0.0f;
    phaserState1R_ = phaserState2R_ = 0.0f;
    compressorEnvelope_ = 1.0f;
    for (int i = 0; i < REVERB_TAPS; i++) {
        reverbPos_[i] = 0;
        reverbState_[i] = 0.0f;
        std::memset(reverbDelay_[i], 0, sizeof(reverbDelay_[i]));
    }
    std::memset(flangerDelayL_, 0, sizeof(flangerDelayL_));
    std::memset(flangerDelayR_, 0, sizeof(flangerDelayR_));
}

// ── Param access ──────────────────────────────────────────────────────────────

void LegacyFxProcessor::setParam(int index, float value) {
    switch (static_cast<LegacyParam>(index)) {
    case LEGACY_CHORUS_ENABLED:    chorusEnabled_ = (value != 0.0f); break;
    case LEGACY_CHORUS_RATE:       chorusRate_ = value; break;
    case LEGACY_CHORUS_DEPTH:      chorusDepth_ = value; break;
    case LEGACY_CHORUS_MIX:        chorusMix_ = value; break;
    case LEGACY_DELAY_ENABLED:     delayEnabled_ = (value != 0.0f); break;
    case LEGACY_DELAY_TIME:
        delayTimeMs_ = value;
        updateDelayBufferSize(sampleRate_);
        break;
    case LEGACY_DELAY_FEEDBACK:    delayFeedback_ = value; break;
    case LEGACY_DELAY_MIX:         delayMix_ = value; break;
    case LEGACY_REVERB_ENABLED:    reverbEnabled_ = (value != 0.0f); break;
    case LEGACY_REVERB_SIZE:       reverbSize_ = value; break;
    case LEGACY_REVERB_DAMPING:    reverbDamping_ = value; break;
    case LEGACY_REVERB_MIX:        reverbMix_ = value; break;
    case LEGACY_PHASER_ENABLED:    phaserEnabled_ = (value != 0.0f); break;
    case LEGACY_PHASER_RATE:       phaserRate_ = value; break;
    case LEGACY_PHASER_DEPTH:      phaserDepth_ = value; break;
    case LEGACY_PHASER_FEEDBACK:   phaserFeedback_ = value; break;
    case LEGACY_PHASER_MIX:        phaserMix_ = value; break;
    case LEGACY_DRIVE_ENABLED:     driveEnabled_ = (value != 0.0f); break;
    case LEGACY_DRIVE_AMOUNT:      driveAmount_ = value; break;
    case LEGACY_DRIVE_TYPE:        driveType_ = static_cast<int>(value); break;
    case LEGACY_FLANGER_ENABLED:   flangerEnabled_ = (value != 0.0f); break;
    case LEGACY_FLANGER_RATE:      flangerRate_ = value; break;
    case LEGACY_FLANGER_DEPTH:     flangerDepth_ = value; break;
    case LEGACY_FLANGER_FEEDBACK:  flangerFeedback_ = value; break;
    case LEGACY_FLANGER_MIX:       flangerMix_ = value; break;
    case LEGACY_COMPRESSOR_ENABLED:     compressorEnabled_ = (value != 0.0f); break;
    case LEGACY_COMPRESSOR_THRESHOLD:   compressorThreshold_ = value; break;
    case LEGACY_COMPRESSOR_RATIO:       compressorRatio_ = value; break;
    case LEGACY_COMPRESSOR_ATTACK:      compressorAttack_ = value; break;
    case LEGACY_COMPRESSOR_RELEASE:     compressorRelease_ = value; break;
    case LEGACY_COMPRESSOR_MAKEUP_GAIN: compressorMakeupGain_ = value; break;
    default: break;
    }
}

float LegacyFxProcessor::getParam(int index) const {
    switch (static_cast<LegacyParam>(index)) {
    case LEGACY_CHORUS_ENABLED:    return chorusEnabled_ ? 1.0f : 0.0f;
    case LEGACY_CHORUS_RATE:       return chorusRate_;
    case LEGACY_CHORUS_DEPTH:      return chorusDepth_;
    case LEGACY_CHORUS_MIX:        return chorusMix_;
    case LEGACY_DELAY_ENABLED:     return delayEnabled_ ? 1.0f : 0.0f;
    case LEGACY_DELAY_TIME:        return delayTimeMs_;
    case LEGACY_DELAY_FEEDBACK:    return delayFeedback_;
    case LEGACY_DELAY_MIX:         return delayMix_;
    case LEGACY_REVERB_ENABLED:    return reverbEnabled_ ? 1.0f : 0.0f;
    case LEGACY_REVERB_SIZE:       return reverbSize_;
    case LEGACY_REVERB_DAMPING:    return reverbDamping_;
    case LEGACY_REVERB_MIX:        return reverbMix_;
    case LEGACY_PHASER_ENABLED:    return phaserEnabled_ ? 1.0f : 0.0f;
    case LEGACY_PHASER_RATE:       return phaserRate_;
    case LEGACY_PHASER_DEPTH:      return phaserDepth_;
    case LEGACY_PHASER_FEEDBACK:   return phaserFeedback_;
    case LEGACY_PHASER_MIX:        return phaserMix_;
    case LEGACY_DRIVE_ENABLED:     return driveEnabled_ ? 1.0f : 0.0f;
    case LEGACY_DRIVE_AMOUNT:      return driveAmount_;
    case LEGACY_DRIVE_TYPE:        return static_cast<float>(driveType_);
    case LEGACY_FLANGER_ENABLED:   return flangerEnabled_ ? 1.0f : 0.0f;
    case LEGACY_FLANGER_RATE:      return flangerRate_;
    case LEGACY_FLANGER_DEPTH:     return flangerDepth_;
    case LEGACY_FLANGER_FEEDBACK:  return flangerFeedback_;
    case LEGACY_FLANGER_MIX:       return flangerMix_;
    case LEGACY_COMPRESSOR_ENABLED:     return compressorEnabled_ ? 1.0f : 0.0f;
    case LEGACY_COMPRESSOR_THRESHOLD:   return compressorThreshold_;
    case LEGACY_COMPRESSOR_RATIO:       return compressorRatio_;
    case LEGACY_COMPRESSOR_ATTACK:      return compressorAttack_;
    case LEGACY_COMPRESSOR_RELEASE:     return compressorRelease_;
    case LEGACY_COMPRESSOR_MAKEUP_GAIN: return compressorMakeupGain_;
    default: return 0.0f;
    }
}

const char* LegacyFxProcessor::paramName(int index) const {
    switch (static_cast<LegacyParam>(index)) {
    case LEGACY_CHORUS_ENABLED:    return "Chorus Enabled";
    case LEGACY_CHORUS_RATE:       return "Chorus Rate";
    case LEGACY_CHORUS_DEPTH:      return "Chorus Depth";
    case LEGACY_CHORUS_MIX:        return "Chorus Mix";
    case LEGACY_DELAY_ENABLED:     return "Delay Enabled";
    case LEGACY_DELAY_TIME:        return "Delay Time";
    case LEGACY_DELAY_FEEDBACK:    return "Delay Feedback";
    case LEGACY_DELAY_MIX:         return "Delay Mix";
    case LEGACY_REVERB_ENABLED:    return "Reverb Enabled";
    case LEGACY_REVERB_SIZE:       return "Reverb Size";
    case LEGACY_REVERB_DAMPING:    return "Reverb Damping";
    case LEGACY_REVERB_MIX:        return "Reverb Mix";
    case LEGACY_PHASER_ENABLED:    return "Phaser Enabled";
    case LEGACY_PHASER_RATE:       return "Phaser Rate";
    case LEGACY_PHASER_DEPTH:      return "Phaser Depth";
    case LEGACY_PHASER_FEEDBACK:   return "Phaser Feedback";
    case LEGACY_PHASER_MIX:        return "Phaser Mix";
    case LEGACY_DRIVE_ENABLED:     return "Drive Enabled";
    case LEGACY_DRIVE_AMOUNT:      return "Drive Amount";
    case LEGACY_DRIVE_TYPE:        return "Drive Type";
    case LEGACY_FLANGER_ENABLED:   return "Flanger Enabled";
    case LEGACY_FLANGER_RATE:      return "Flanger Rate";
    case LEGACY_FLANGER_DEPTH:     return "Flanger Depth";
    case LEGACY_FLANGER_FEEDBACK:  return "Flanger Feedback";
    case LEGACY_FLANGER_MIX:       return "Flanger Mix";
    case LEGACY_COMPRESSOR_ENABLED:     return "Compressor Enabled";
    case LEGACY_COMPRESSOR_THRESHOLD:   return "Compressor Threshold";
    case LEGACY_COMPRESSOR_RATIO:       return "Compressor Ratio";
    case LEGACY_COMPRESSOR_ATTACK:      return "Compressor Attack";
    case LEGACY_COMPRESSOR_RELEASE:     return "Compressor Release";
    case LEGACY_COMPRESSOR_MAKEUP_GAIN: return "Compressor Makeup Gain";
    default: return "Unknown";
    }
}

// ── Distortion ────────────────────────────────────────────────────────────────

float LegacyFxProcessor::applyDistortion(float sample) {
    if (driveAmount_ < 0.01f) return sample;
    switch (driveType_) {
    case DRIVE_SOFT_CLIP:
        return std::tanh(sample * (1.0f + driveAmount_ * 4.0f)) /
               std::tanh(1.0f + driveAmount_ * 4.0f);
    case DRIVE_HARD_CLIP:
        return clamp(sample * (1.0f + driveAmount_ * 2.0f), -1.0f, 1.0f);
    case DRIVE_ASYMMETRIC:
        if (sample > 0)
            return std::tanh(sample * (1.0f + driveAmount_ * 3.0f));
        else
            return clamp(sample * (1.0f + driveAmount_ * 1.5f), -1.0f, 0.0f);
    default:
        return sample;
    }
}

// ── Chorus ────────────────────────────────────────────────────────────────────

void LegacyFxProcessor::processChorus(float& left, float& right, double sampleRate) {
    if (!chorusEnabled_ || chorusMix_ <= 0.0f) return;

    chorusPhase_ += static_cast<float>(chorusRate_ / sampleRate);
    if (chorusPhase_ >= 1.0f) chorusPhase_ -= 1.0f;
    float offset = std::sin(2.0f * M_PI * chorusPhase_) * chorusDepth_ * 0.005f;
    left  = left  * (1.0f - chorusMix_) + left  * chorusMix_ * (1.0f + offset * 0.5f);
    right = right * (1.0f - chorusMix_) + right * chorusMix_ * (1.0f - offset * 0.5f);
}

// ── Delay ─────────────────────────────────────────────────────────────────────

void LegacyFxProcessor::updateDelayBufferSize(double sampleRate) {
    uint32_t newSize = static_cast<uint32_t>(delayTimeMs_ * 0.001 * sampleRate);
    if (newSize < 1) newSize = 1;
    if (newSize > MAX_DELAY_SAMPLES) newSize = MAX_DELAY_SAMPLES;
    delayBufferSize_ = newSize;
}

void LegacyFxProcessor::processDelay(float& left, float& right, double /*sampleRate*/) {
    if (!delayEnabled_ || delayMix_ <= 0.0f) return;

    // Note: delayBufferSize_ is pre-computed by setSampleRate(),
    // so we don't call updateDelayBufferSize() here every frame.

    uint32_t readPos = (delayWritePos_ >= delayBufferSize_)
        ? delayWritePos_ - delayBufferSize_
        : MAX_DELAY_SAMPLES + delayWritePos_ - delayBufferSize_;
    float delayedL = delayBuffer_[readPos];
    float delayedR = (readPos + 1 < MAX_DELAY_SAMPLES) ? delayBuffer_[readPos + 1] : 0.0f;

    float fbL = clamp(left + delayedL * delayFeedback_, -2.0f, 2.0f);
    float fbR = clamp(right + delayedR * delayFeedback_, -2.0f, 2.0f);
    delayBuffer_[delayWritePos_] = fbL;
    delayWritePos_ = (delayWritePos_ + 1) % MAX_DELAY_SAMPLES;
    delayBuffer_[delayWritePos_] = fbR;
    delayWritePos_ = (delayWritePos_ + 1) % MAX_DELAY_SAMPLES;

    left  = left  * (1.0f - delayMix_) + clamp(delayedL, -2.0f, 2.0f) * delayMix_;
    right = right * (1.0f - delayMix_) + clamp(delayedR, -2.0f, 2.0f) * delayMix_;
}

// ── Reverb (Schroeder all-pass) ───────────────────────────────────────────────

void LegacyFxProcessor::processReverb(float& left, float& right, double sampleRate) {
    if (!reverbEnabled_ || reverbMix_ <= 0.0f) return;

    float wetL = 0.0f, wetR = 0.0f;
    float fb = reverbDamping_ * 0.7f;
    for (int i = 0; i < REVERB_TAPS; i++) {
        uint32_t delayLen = static_cast<uint32_t>(1200 + i * 800); // ~25–90ms at 48k
        delayLen = std::min(delayLen, static_cast<uint32_t>(4800));
        float in = (i == 0) ? (left + right) * 0.5f : reverbState_[i - 1];
        in = clamp(in, -2.0f, 2.0f);
        uint32_t pos = reverbPos_[i];
        if (pos >= delayLen) pos = 0;
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
    left  = left  * (1.0f - reverbMix_) + clamp(wetL, -2.0f, 2.0f) * reverbMix_;
    right = right * (1.0f - reverbMix_) + clamp(wetR, -2.0f, 2.0f) * reverbMix_;
}

// ── Phaser (stereo 2-stage all-pass) ──────────────────────────────────────────

void LegacyFxProcessor::processPhaser(float& left, float& right, double sampleRate) {
    if (!phaserEnabled_ || phaserMix_ <= 0.0f) return;

    phaserPhase_ += static_cast<float>(phaserRate_ / sampleRate);
    if (phaserPhase_ >= 1.0f) phaserPhase_ -= 1.0f;
    float freq = 200.0f + std::sin(2.0f * M_PI * phaserPhase_) * phaserDepth_ * 1900.0f;
    float coeff = std::min(static_cast<float>(std::tan(M_PI * freq / sampleRate)), 10.0f);
    float damp = 1.0f / (1.0f + coeff * phaserFeedback_ * 0.5f);

    // Left channel
    float inL = left + clamp(phaserState1L_, -2.0f, 2.0f) * phaserFeedback_ * 0.3f;
    float outL = phaserState1L_ + coeff * inL;
    phaserState1L_ = clamp(outL - coeff * phaserState1L_ * damp, -2.0f, 2.0f);
    inL = outL + clamp(phaserState2L_, -2.0f, 2.0f) * phaserFeedback_ * 0.3f;
    outL = phaserState2L_ + coeff * inL;
    phaserState2L_ = clamp(outL - coeff * phaserState2L_ * damp, -2.0f, 2.0f);
    left = left * (1.0f - phaserMix_) + clamp(outL, -2.0f, 2.0f) * phaserMix_;

    // Right channel
    float inR = right + clamp(phaserState1R_, -2.0f, 2.0f) * phaserFeedback_ * 0.3f;
    float outR = phaserState1R_ + coeff * inR;
    phaserState1R_ = clamp(outR - coeff * phaserState1R_ * damp, -2.0f, 2.0f);
    inR = outR + clamp(phaserState2R_, -2.0f, 2.0f) * phaserFeedback_ * 0.3f;
    outR = phaserState2R_ + coeff * inR;
    phaserState2R_ = clamp(outR - coeff * phaserState2R_ * damp, -2.0f, 2.0f);
    right = right * (1.0f - phaserMix_) + clamp(outR, -2.0f, 2.0f) * phaserMix_;
}

// ── Flanger (stereo delay lines) ──────────────────────────────────────────────

void LegacyFxProcessor::processFlanger(float& left, float& right, double sampleRate) {
    if (!flangerEnabled_ || flangerMix_ <= 0.0f) return;

    flangerPhase_ += static_cast<float>(flangerRate_ / sampleRate);
    if (flangerPhase_ >= 1.0f) flangerPhase_ -= 1.0f;
    float lfo = std::sin(2.0f * M_PI * flangerPhase_);
    float delaySamples = 1.0f + (lfo * 0.5f + 0.5f) * flangerDepth_ * FLANGER_DELAY_SAMPLES * 0.25f;
    uint32_t readPos = (flangerWritePos_ >= static_cast<uint32_t>(delaySamples))
        ? flangerWritePos_ - static_cast<uint32_t>(delaySamples)
        : FLANGER_DELAY_SAMPLES + flangerWritePos_ - static_cast<uint32_t>(delaySamples);
    if (readPos >= FLANGER_DELAY_SAMPLES) readPos = 0;

    float delayedL = clamp(flangerDelayL_[readPos], -2.0f, 2.0f);
    float delayedR = clamp(flangerDelayR_[readPos], -2.0f, 2.0f);

    flangerDelayL_[flangerWritePos_] = clamp(left + delayedL * flangerFeedback_, -2.0f, 2.0f);
    flangerDelayR_[flangerWritePos_] = clamp(right + delayedR * flangerFeedback_, -2.0f, 2.0f);
    flangerWritePos_ = (flangerWritePos_ + 1) % FLANGER_DELAY_SAMPLES;

    left  = left  * (1.0f - flangerMix_) + delayedL * flangerMix_;
    right = right * (1.0f - flangerMix_) + delayedR * flangerMix_;
}

// ── Compressor (stereo linked) ────────────────────────────────────────────────

void LegacyFxProcessor::processCompressor(float& left, float& right) {
    if (!compressorEnabled_) return;

    float inputLevel = std::max(std::abs(left), std::abs(right));
    float gainReduction = 1.0f;
    if (inputLevel > compressorThreshold_) {
        float overThreshold = (inputLevel - compressorThreshold_) / (1.0f - compressorThreshold_);
        float targetGain = 1.0f - overThreshold * (1.0f - 1.0f / compressorRatio_);
        gainReduction = targetGain / (inputLevel + 0.0001f);
    }
    float attackCoeff = 1.0f - std::exp(-1.0f / (compressorAttack_ * 0.001f * static_cast<float>(44100.0)));
    float releaseCoeff = 1.0f - std::exp(-1.0f / (compressorRelease_ * 0.001f * static_cast<float>(44100.0)));
    if (gainReduction < compressorEnvelope_) {
        compressorEnvelope_ += (gainReduction - compressorEnvelope_) * attackCoeff;
    } else {
        compressorEnvelope_ += (gainReduction - compressorEnvelope_) * releaseCoeff;
    }
    left  *= compressorEnvelope_ * (1.0f + compressorMakeupGain_);
    right *= compressorEnvelope_ * (1.0f + compressorMakeupGain_);
}

} // namespace openamp
