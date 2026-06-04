#include "fx_transient_shaper.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

TransientShaperProcessor::TransientShaperProcessor()
    : FxProcessor(FxType::TransientShaper) {}

void TransientShaperProcessor::reset() {
    fastEnvL_ = fastEnvR_ = 0.0f;
    slowEnvL_ = slowEnvR_ = 0.0f;
}

float TransientShaperProcessor::processChannel(float sample, float& fastEnv, float& slowEnv) {
    float absSample = std::abs(sample);

    // Fast envelope (captures transients)
    float fastAttackCoeff = 0.0f;   // instant attack
    float fastReleaseCoeff = 0.85f; // fast release
    if (absSample > fastEnv) {
        fastEnv = absSample; // instant attack
    } else {
        fastEnv = fastReleaseCoeff * fastEnv + (1.0f - fastReleaseCoeff) * absSample;
    }

    // Slow envelope (captures sustain)
    float slowAttackCoeff = 0.95f;  // slow attack
    float slowReleaseCoeff = 0.995f; // very slow release
    if (absSample > slowEnv) {
        slowEnv = slowAttackCoeff * slowEnv + (1.0f - slowAttackCoeff) * absSample;
    } else {
        slowEnv = slowReleaseCoeff * slowEnv + (1.0f - slowReleaseCoeff) * absSample;
    }

    // Envelope difference = transient energy
    float envDiff = fastEnv - slowEnv;
    envDiff = std::max(envDiff, 0.0f);

    // Sensitivity scaling
    float sense = sensitivity_ * 4.0f + 0.5f;
    envDiff *= sense;

    // Attack shaping: boost or cut transients
    float attackGain = 1.0f;
    if (attack_ > 0.0f) {
        attackGain = 1.0f + attack_ * envDiff;
    } else if (attack_ < 0.0f) {
        attackGain = 1.0f + attack_ * envDiff; // attack_ is negative, so this reduces
        attackGain = std::max(attackGain, 0.1f);
    }

    // Sustain shaping: boost or cut sustained parts
    float sustainGain = 1.0f;
    if (sustain_ > 0.0f) {
        sustainGain = 1.0f + sustain_ * slowEnv * sense;
    } else if (sustain_ < 0.0f) {
        sustainGain = 1.0f + sustain_ * slowEnv * sense;
        sustainGain = std::max(sustainGain, 0.1f);
    }

    float out = sample * attackGain * sustainGain;
    return std::clamp(out, -2.0f, 2.0f);
}

void TransientShaperProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float outL = processChannel(left, fastEnvL_, slowEnvL_);
    float outR = processChannel(right, fastEnvR_, slowEnvR_);

    left = applyMix(left, outL);
    right = applyMix(right, outR);
}

void TransientShaperProcessor::setParam(int index, float value) {
    switch (index) {
    case ATTACK:      attack_ = std::clamp(value, -1.0f, 1.0f); break;
    case SUSTAIN:     sustain_ = std::clamp(value, -1.0f, 1.0f); break;
    case SENSITIVITY: sensitivity_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:         mix_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float TransientShaperProcessor::getParam(int index) const {
    switch (index) {
    case ATTACK:      return attack_;
    case SUSTAIN:     return sustain_;
    case SENSITIVITY: return sensitivity_;
    case MIX:         return mix_;
    default: return 0.0f;
    }
}

const char* TransientShaperProcessor::paramName(int index) const {
    switch (index) {
    case ATTACK:      return "Attack";
    case SUSTAIN:     return "Sustain";
    case SENSITIVITY: return "Sensitivity";
    case MIX:         return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
