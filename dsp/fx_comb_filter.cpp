#include "fx_comb_filter.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

CombFilterProcessor::CombFilterProcessor()
    : FxProcessor(FxType::CombFilter) {}

void CombFilterProcessor::reset() {
    std::fill(delayL_.begin(), delayL_.end(), 0.0f);
    std::fill(delayR_.begin(), delayR_.end(), 0.0f);
    writeIdx_ = 0;
    dampL_ = 0.0f;
    dampR_ = 0.0f;
}

void CombFilterProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    // Ensure delay lines are large enough (max 100 ms)
    size_t maxSamples = static_cast<size_t>(sampleRate_ * MAX_DELAY_MS / 1000.0) + 1;
    if (delayL_.size() < maxSamples) {
        delayL_.resize(maxSamples, 0.0f);
        delayR_.resize(maxSamples, 0.0f);
    }

    float inL = left;
    float inR = right;

    // Delay length from frequency
    float delaySamples = static_cast<float>(sampleRate_) / std::clamp(freq_, 20.0f, 5000.0f);
    size_t delayInt = static_cast<size_t>(delaySamples);
    if (delayInt < 1) delayInt = 1;
    if (delayInt >= delayL_.size()) delayInt = delayL_.size() - 1;

    // Read from delay line
    size_t readIdx = (writeIdx_ + delayL_.size() - delayInt) % delayL_.size();
    float fbL = delayL_[readIdx];
    float fbR = delayR_[readIdx];

    // Damping: 1-pole LPF in feedback path.
    // Map damping param [0,1] to a cutoff frequency [~500 Hz, ~20 kHz].
    // Coefficient = 1 - exp(-2*pi*fc/sr)
    float dampingFc = 500.0f + damping_ * 19500.0f; // 500 Hz .. 20 kHz
    float dampCoeff = 1.0f - std::exp(-6.2831853f * dampingFc / static_cast<float>(sampleRate_));
    if (dampCoeff > 0.999f) dampCoeff = 0.999f;
    dampL_ += dampCoeff * (fbL - dampL_);
    dampR_ += dampCoeff * (fbR - dampR_);

    float fbGain = std::clamp(feedback_, 0.0f, 0.99f);
    float wetL = inL + dampL_ * fbGain;
    float wetR = inR + dampR_ * fbGain;

    // Write to delay line
    delayL_[writeIdx_] = wetL;
    delayR_[writeIdx_] = wetR;
    writeIdx_ = (writeIdx_ + 1) % delayL_.size();

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

void CombFilterProcessor::setParam(int index, float value) {
    switch (index) {
    case FREQ:      freq_ = std::clamp(value, 20.0f, 5000.0f); break;
    case FEEDBACK:  feedback_ = std::clamp(value, 0.0f, 0.99f); break;
    case DAMPING:   damping_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:       mix_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float CombFilterProcessor::getParam(int index) const {
    switch (index) {
    case FREQ:      return freq_;
    case FEEDBACK:  return feedback_;
    case DAMPING:   return damping_;
    case MIX:       return mix_;
    default: return 0.0f;
    }
}

const char* CombFilterProcessor::paramName(int index) const {
    switch (index) {
    case FREQ:      return "Freq";
    case FEEDBACK:  return "Feedback";
    case DAMPING:   return "Damping";
    case MIX:       return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
