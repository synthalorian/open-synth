#include "fx_tube_drive.h"
#include <algorithm>

namespace opensynth {

TubeDriveProcessor::TubeDriveProcessor()
    : FxProcessor(FxType::TubeDrive) {}

void TubeDriveProcessor::reset() {
    toneStateL_ = 0.0f;
    toneStateR_ = 0.0f;
}

void TubeDriveProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    float distL = distort(inL);
    float distR = distort(inR);

    float outL = toneFilter(distL, toneStateL_);
    float outR = toneFilter(distR, toneStateR_);

    outL *= output_;
    outR *= output_;

    left = applyMix(inL, outL);
    right = applyMix(inR, outR);
}

float TubeDriveProcessor::distort(float sample) {
    float preGain = 1.0f + drive_ * 24.0f; // 1x to 25x
    float x = sample * preGain;

    // Per-sample bias offset for asymmetry
    float biasOffset = (bias_ - 0.5f) * 0.6f;
    x += biasOffset;

    // Asymmetric tanh saturation
    if (x > 0.0f) {
        x = std::tanh(x * 1.5f);
    } else {
        x = std::tanh(x * 2.2f) * 0.8f;
    }

    x -= biasOffset * 0.4f; // Partial DC compensation
    return std::clamp(x, -1.0f, 1.0f);
}

float TubeDriveProcessor::toneFilter(float input, float& state) {
    // Simple 1-pole lowpass as tone control
    float freq = 600.0f + tone_ * 7500.0f; // 600 Hz - 8100 Hz
    float f = static_cast<float>(freq / sampleRate_);
    if (f > 0.49f) f = 0.49f;
    float coeff = 2.0f * 3.14159265f * f;
    state += coeff * (input - state);
    return state;
}

void TubeDriveProcessor::setParam(int index, float value) {
    switch (index) {
    case DRIVE:  drive_ = std::clamp(value, 0.0f, 1.0f); break;
    case BIAS:   bias_ = std::clamp(value, 0.0f, 1.0f); break;
    case TONE:   tone_ = std::clamp(value, 0.0f, 1.0f); break;
    case OUTPUT: output_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float TubeDriveProcessor::getParam(int index) const {
    switch (index) {
    case DRIVE:  return drive_;
    case BIAS:   return bias_;
    case TONE:   return tone_;
    case OUTPUT: return output_;
    default: return 0.0f;
    }
}

const char* TubeDriveProcessor::paramName(int index) const {
    switch (index) {
    case DRIVE:  return "Drive";
    case BIAS:   return "Bias";
    case TONE:   return "Tone";
    case OUTPUT: return "Output";
    default: return "Unknown";
    }
}

} // namespace opensynth
