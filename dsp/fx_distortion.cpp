#include "fx_distortion.h"
#include <algorithm>

namespace opensynth {

DistortionProcessor::DistortionProcessor()
    : FxProcessor(FxType::Distortion) {}

void DistortionProcessor::reset() {
    toneStateL_ = 0.0f;
    toneStateR_ = 0.0f;
}

void DistortionProcessor::process(float& left, float& right, double sampleRate) {
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

float DistortionProcessor::distort(float sample) {
    float preGain = 1.0f + drive_ * 49.0f; // 1x to 50x
    float x = sample * preGain;

    switch (type_) {
    case 0: // Soft - tanh
        x = std::tanh(x);
        break;
    case 1: // Hard - clamp
        x = std::clamp(x, -1.0f, 1.0f);
        break;
    case 2: { // Fold - foldback
        float threshold = 1.0f;
        if (x > threshold || x < -threshold) {
            x = std::abs(std::abs(std::fmod(x - threshold, threshold * 4.0f)) - threshold * 2.0f) - threshold;
        }
        x = std::clamp(x, -1.0f, 1.0f);
        break;
    }
    case 3: // Asymmetric - asym tanh
        if (x > 0.0f) {
            x = std::tanh(x * 1.2f);
        } else {
            x = std::tanh(x * 2.5f) * 0.7f;
        }
        break;
    default:
        x = std::tanh(x);
        break;
    }
    return x;
}

float DistortionProcessor::toneFilter(float input, float& state) {
    // Simple 1-pole lowpass as tone control
    float freq = 800.0f + tone_ * 8000.0f; // 800 Hz - 8800 Hz
    float f = static_cast<float>(freq / sampleRate_);
    if (f > 0.49f) f = 0.49f;
    float coeff = 2.0f * 3.14159265f * f;
    state += coeff * (input - state);
    return state;
}

void DistortionProcessor::setParam(int index, float value) {
    switch (index) {
    case DRIVE: drive_ = std::clamp(value, 0.0f, 1.0f); break;
    case TONE:  tone_ = std::clamp(value, 0.0f, 1.0f); break;
    case LEVEL: level_ = std::clamp(value, 0.0f, 1.0f); break;
    case TYPE:  type_ = static_cast<int>(std::clamp(value, 0.0f, 3.0f)); break;
    default: break;
    }
}

float DistortionProcessor::getParam(int index) const {
    switch (index) {
    case DRIVE: return drive_;
    case TONE:  return tone_;
    case LEVEL: return level_;
    case TYPE:  return static_cast<float>(type_);
    default: return 0.0f;
    }
}

const char* DistortionProcessor::paramName(int index) const {
    switch (index) {
    case DRIVE: return "Drive";
    case TONE:  return "Tone";
    case LEVEL: return "Level";
    case TYPE:  return "Type";
    default: return "Unknown";
    }
}

} // namespace opensynth
