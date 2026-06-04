#include "fx_fuzz.h"
#include <algorithm>

namespace opensynth {

FuzzProcessor::FuzzProcessor()
    : FxProcessor(FxType::Fuzz) {}

void FuzzProcessor::reset() {
    toneStateL_ = 0.0f;
    toneStateR_ = 0.0f;
}

void FuzzProcessor::process(float& left, float& right, double sampleRate) {
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

float FuzzProcessor::distort(float sample) {
    // Classic fuzz: very high gain into hard clip
    float preGain = 1.0f + amount_ * 99.0f; // 1x to 100x
    float x = sample * preGain;

    // Sustain controls the clip threshold (lower = more compressed/sustained)
    float threshold = 0.05f + (1.0f - sustain_) * 0.95f;
    if (threshold < 0.01f) threshold = 0.01f;

    x = std::clamp(x, -threshold, threshold);
    // Normalize back
    x /= threshold;
    return std::clamp(x, -1.0f, 1.0f);
}

float FuzzProcessor::toneFilter(float input, float& state) {
    // Simple RC-style tone filter (1-pole lowpass)
    float freq = 400.0f + tone_ * 6000.0f; // 400 Hz - 6400 Hz
    float f = static_cast<float>(freq / sampleRate_);
    if (f > 0.49f) f = 0.49f;
    float coeff = 2.0f * 3.14159265f * f;
    state += coeff * (input - state);
    return state;
}

void FuzzProcessor::setParam(int index, float value) {
    switch (index) {
    case AMOUNT:  amount_ = std::clamp(value, 0.0f, 1.0f); break;
    case TONE:    tone_ = std::clamp(value, 0.0f, 1.0f); break;
    case LEVEL:   level_ = std::clamp(value, 0.0f, 1.0f); break;
    case SUSTAIN: sustain_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float FuzzProcessor::getParam(int index) const {
    switch (index) {
    case AMOUNT:  return amount_;
    case TONE:    return tone_;
    case LEVEL:   return level_;
    case SUSTAIN: return sustain_;
    default: return 0.0f;
    }
}

const char* FuzzProcessor::paramName(int index) const {
    switch (index) {
    case AMOUNT:  return "Amount";
    case TONE:    return "Tone";
    case LEVEL:   return "Level";
    case SUSTAIN: return "Sustain";
    default: return "Unknown";
    }
}

} // namespace opensynth
