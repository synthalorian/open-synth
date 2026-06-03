#include "fx_limiter.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

LimiterProcessor::LimiterProcessor()
    : FxProcessor(FxType::Limiter) {}

void LimiterProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inputGain = std::pow(10.0f, inputGain_ / 20.0f);
    float thresholdLin = std::pow(10.0f, threshold_ / 20.0f);
    float ceilingLin = std::pow(10.0f, ceiling_ / 20.0f);

    // Apply input gain
    left *= inputGain;
    right *= inputGain;

    // Peak detection (stereo linked)
    float peak = std::max(std::abs(left), std::abs(right));

    // Compute gain reduction
    float targetGain = 1.0f;
    if (peak > thresholdLin) {
        targetGain = thresholdLin / (peak + 0.000001f);
    }

    // Apply ceiling as an absolute limit
    float ceilingGain = ceilingLin / (peak * targetGain + 0.000001f);
    if (ceilingGain < 1.0f) {
        targetGain *= ceilingGain;
    }

    // Smooth with release time
    float coeff = 1.0f - std::exp(-1.0f / (releaseMs_ * 0.001f * sampleRate_));
    if (targetGain < envelope_) {
        // Attack (immediate for brickwall)
        envelope_ = targetGain;
    } else {
        // Release (smooth)
        envelope_ += (targetGain - envelope_) * coeff;
    }

    // Clamp envelope to prevent runaway
    envelope_ = std::clamp(envelope_, 0.0f, 1.0f);

    // Apply gain reduction
    left *= envelope_;
    right *= envelope_;

    // Soft clip at ceiling for safety
    float clipLevel = ceilingLin * 1.05f;
    auto softClip = [clipLevel](float s) -> float {
        if (s > clipLevel) return clipLevel + (s - clipLevel) * 0.1f;
        if (s < -clipLevel) return -clipLevel + (s + clipLevel) * 0.1f;
        return s;
    };
    left = softClip(left);
    right = softClip(right);
}

void LimiterProcessor::reset() {
    envelope_ = 1.0f;
    gainReduction_ = 1.0f;
}

void LimiterProcessor::setParam(int index, float value) {
    switch (index) {
    case THRESHOLD: threshold_ = std::clamp(value, -60.0f, 0.0f); break;
    case RELEASE:   releaseMs_ = std::clamp(value, 1.0f, 500.0f); break;
    case CEILING:   ceiling_ = std::clamp(value, -12.0f, 0.0f); break;
    case INPUT_GAIN: inputGain_ = std::clamp(value, -12.0f, 12.0f); break;
    }
}

float LimiterProcessor::getParam(int index) const {
    switch (index) {
    case THRESHOLD: return threshold_;
    case RELEASE:   return releaseMs_;
    case CEILING:   return ceiling_;
    case INPUT_GAIN: return inputGain_;
    }
    return 0.0f;
}

const char* LimiterProcessor::paramName(int index) const {
    switch (index) {
    case THRESHOLD: return "Threshold";
    case RELEASE:   return "Release";
    case CEILING:   return "Ceiling";
    case INPUT_GAIN: return "In Gain";
    }
    return "";
}

} // namespace opensynth
