#include "fx_overdrive.h"
#include <algorithm>

namespace opensynth {

OverdriveProcessor::OverdriveProcessor()
    : FxProcessor(FxType::Overdrive) {}

void OverdriveProcessor::reset() {
    toneStateL_ = 0.0f;
    toneStateR_ = 0.0f;
}

void OverdriveProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    float distL = distort(inL);
    float distR = distort(inR);

    float outL = toneFilter(distL, toneStateL_);
    float outR = toneFilter(distR, toneStateR_);

    outL *= level_;
    outR *= level_;

    left = applyMix(inL, outL);
    right = applyMix(inR, outR);
}

float OverdriveProcessor::distort(float sample) {
    float preGain = 1.0f + drive_ * 19.0f; // 1x to 20x
    float x = sample * preGain;

    // Even-harmonic bias based on warmth
    float bias = warmth_ * 0.3f;
    x += bias;

    // Asymmetric tanh for tube-like warmth
    if (x > 0.0f) {
        x = std::tanh(x * 1.4f);
    } else {
        x = std::tanh(x * 2.0f) * 0.85f;
    }

    x -= bias * 0.5f; // Compensate DC shift
    return std::clamp(x, -1.0f, 1.0f);
}

float OverdriveProcessor::toneFilter(float input, float& state) {
    // Simple 1-pole lowpass as tone control
    float freq = 500.0f + tone_ * 7000.0f; // 500 Hz - 7500 Hz
    float f = static_cast<float>(freq / sampleRate_);
    if (f > 0.49f) f = 0.49f;
    float coeff = 2.0f * 3.14159265f * f;
    state += coeff * (input - state);
    return state;
}

void OverdriveProcessor::setParam(int index, float value) {
    switch (index) {
    case DRIVE:  drive_ = std::clamp(value, 0.0f, 1.0f); break;
    case TONE:   tone_ = std::clamp(value, 0.0f, 1.0f); break;
    case LEVEL:  level_ = std::clamp(value, 0.0f, 1.0f); break;
    case WARMTH: warmth_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float OverdriveProcessor::getParam(int index) const {
    switch (index) {
    case DRIVE:  return drive_;
    case TONE:   return tone_;
    case LEVEL:  return level_;
    case WARMTH: return warmth_;
    default: return 0.0f;
    }
}

const char* OverdriveProcessor::paramName(int index) const {
    switch (index) {
    case DRIVE:  return "Drive";
    case TONE:   return "Tone";
    case LEVEL:  return "Level";
    case WARMTH: return "Warmth";
    default: return "Unknown";
    }
}

} // namespace opensynth
