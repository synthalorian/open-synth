#include "fx_maximizer.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

MaximizerProcessor::MaximizerProcessor()
    : FxProcessor(FxType::Maximizer) {}

void MaximizerProcessor::reset() {
    envelope_ = 0.0f;
    gainReduction_ = 1.0f;
}

void MaximizerProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // Apply drive (input gain)
    float driveGain = 1.0f + drive_ * 9.0f;
    float gL = inL * driveGain;
    float gR = inR * driveGain;

    // Peak detection
    float peak = std::max(std::abs(gL), std::abs(gR));

    // Attack is instantaneous (brickwall), release is smoothed
    float attackCoeff = 0.99f; // very fast attack
    float releaseMs = 1.0f + release_ * 999.0f;
    float releaseCoeff = std::exp(-1.0f / (sampleRate_ * releaseMs * 0.001f));

    if (peak > envelope_) {
        envelope_ = attackCoeff * envelope_ + (1.0f - attackCoeff) * peak;
    } else {
        envelope_ = releaseCoeff * envelope_ + (1.0f - releaseCoeff) * peak;
    }

    // Ceiling in linear
    float ceilingLin = dbToLinear(ceiling_);

    // Compute gain reduction
    if (envelope_ > ceilingLin && envelope_ > 0.00001f) {
        gainReduction_ = ceilingLin / envelope_;
    } else {
        gainReduction_ = 1.0f;
    }

    // Apply limiting
    float outL = gL * gainReduction_;
    float outR = gR * gainReduction_;

    left = applyMix(inL, outL);
    right = applyMix(inR, outR);
}

void MaximizerProcessor::setParam(int index, float value) {
    switch (index) {
    case CEILING: ceiling_ = std::clamp(value, -12.0f, 0.0f); break;
    case RELEASE: release_ = std::clamp(value, 1.0f, 1000.0f); break;
    case DRIVE:   drive_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:     mix_ = value; break;
    default: break;
    }
}

float MaximizerProcessor::getParam(int index) const {
    switch (index) {
    case CEILING: return ceiling_;
    case RELEASE: return release_;
    case DRIVE:   return drive_;
    case MIX:     return mix_;
    default: return 0.0f;
    }
}

const char* MaximizerProcessor::paramName(int index) const {
    switch (index) {
    case CEILING: return "Ceiling";
    case RELEASE: return "Release";
    case DRIVE:   return "Drive";
    case MIX:     return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
