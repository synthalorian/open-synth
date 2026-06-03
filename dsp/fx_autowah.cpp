#include "fx_autowah.h"
#include <algorithm>

namespace opensynth {

AutoWahProcessor::AutoWahProcessor()
    : FxProcessor(FxType::AutoWah) {}

void AutoWahProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // Envelope from average of both channels
    float avg = (std::abs(inL) + std::abs(inR)) * 0.5f;
    updateEnvelope(avg);

    // Map envelope to cutoff: base 200Hz + range up to 5000Hz
    float targetCutoff = 200.0f + envelope_ * range_ * 5000.0f;
    cutoff_ += (targetCutoff - cutoff_) * 0.1f; // smooth

    float q = 0.5f + resonance_ * 4.5f; // Q: 0.5 - 5.0

    float wetL = processFilter(inL, lpL_, bpL_, cutoff_, q);
    float wetR = processFilter(inR, lpR_, bpR_, cutoff_, q);

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

void AutoWahProcessor::updateEnvelope(float input) {
    float attackCoeff = std::exp(-1.0f / (attackMs_ * 0.001f * sampleRate_));
    float releaseCoeff = std::exp(-1.0f / (releaseMs_ * 0.001f * sampleRate_));

    if (input > envelope_) {
        envelope_ = attackCoeff * envelope_ + (1.0f - attackCoeff) * input;
    } else {
        envelope_ = releaseCoeff * envelope_ + (1.0f - releaseCoeff) * input;
    }
}

float AutoWahProcessor::processFilter(float input, float& lp, float& bp, float cutoff, float q) {
    float f = 2.0f * std::sin(3.14159265f * cutoff / sampleRate_);
    if (f > 1.0f) f = 1.0f;

    lp = lp + f * bp;
    bp = bp + f * (input - lp - bp * (1.0f / q));

    return lp;
}

void AutoWahProcessor::reset() {
    envelope_ = 0.0f;
    cutoff_ = 200.0f;
    lpL_ = bpL_ = 0.0f;
    lpR_ = bpR_ = 0.0f;
}

void AutoWahProcessor::setParam(int index, float value) {
    switch (index) {
    case SENSITIVITY: sensitivity_ = value; break;
    case RESONANCE:   resonance_ = value; break;
    case RANGE:       range_ = value; break;
    case ATTACK:      attackMs_ = value; break;
    case RELEASE:     releaseMs_ = value; break;
    case MIX:         mix_ = value; break;
    default: break;
    }
}

float AutoWahProcessor::getParam(int index) const {
    switch (index) {
    case SENSITIVITY: return sensitivity_;
    case RESONANCE:   return resonance_;
    case RANGE:       return range_;
    case ATTACK:      return attackMs_;
    case RELEASE:     return releaseMs_;
    case MIX:         return mix_;
    default: return 0.0f;
    }
}

const char* AutoWahProcessor::paramName(int index) const {
    switch (index) {
    case SENSITIVITY: return "Sensitivity";
    case RESONANCE:   return "Resonance";
    case RANGE:       return "Range";
    case ATTACK:      return "Attack";
    case RELEASE:     return "Release";
    case MIX:         return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
