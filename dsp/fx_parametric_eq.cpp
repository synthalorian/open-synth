#include "fx_parametric_eq.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

ParametricEQProcessor::ParametricEQProcessor()
    : FxProcessor(FxType::ParametricEQ) {}

void ParametricEQProcessor::reset() {
    lowShelf_.reset();
    peak_.reset();
    highShelf_.reset();
}

void ParametricEQProcessor::process(float& left, float& right, double sampleRate) {
    if (sampleRate != sampleRate_) {
        sampleRate_ = sampleRate;
        coeffsDirty_ = true;
    }
    if (coeffsDirty_) {
        updateCoeffs();
        coeffsDirty_ = false;
    }

    float inL = left;
    float inR = right;

    float outL = lowShelf_.processL(inL);
    outL = peak_.processL(outL);
    outL = highShelf_.processL(outL);

    float outR = lowShelf_.processR(inR);
    outR = peak_.processR(outR);
    outR = highShelf_.processR(outR);

    left = applyMix(inL, outL);
    right = applyMix(inR, outR);
}

void ParametricEQProcessor::updateCoeffs() {
    calcLowShelf(lowShelf_, lowFreq_, lowGain_, sampleRate_);
    calcPeaking(peak_, midFreq_, midGain_, midQ_, sampleRate_);
    calcHighShelf(highShelf_, highFreq_, highGain_, sampleRate_);
}

void ParametricEQProcessor::calcLowShelf(Biquad& b, float freq, float gainDb, double sr) {
    float A = std::pow(10.0f, gainDb / 40.0f);
    float w0 = 2.0f * 3.14159265f * freq / static_cast<float>(sr);
    float cosw0 = std::cos(w0);
    float sinw0 = std::sin(w0);
    float S = 1.0f; // shelf slope
    float alpha = sinw0 * 0.5f * std::sqrt((A + 1.0f / A) * (1.0f / S - 1.0f) + 2.0f);

    float sqrtA2alpha = 2.0f * std::sqrt(A) * alpha;
    b.b0 = A * ((A + 1.0f) - (A - 1.0f) * cosw0 + sqrtA2alpha);
    b.b1 = 2.0f * A * ((A - 1.0f) - (A + 1.0f) * cosw0);
    b.b2 = A * ((A + 1.0f) - (A - 1.0f) * cosw0 - sqrtA2alpha);
    b.a0 = (A + 1.0f) + (A - 1.0f) * cosw0 + sqrtA2alpha;
    b.a1 = -2.0f * ((A - 1.0f) + (A + 1.0f) * cosw0);
    b.a2 = (A + 1.0f) + (A - 1.0f) * cosw0 - sqrtA2alpha;

    float invA0 = 1.0f / b.a0;
    b.b0 *= invA0; b.b1 *= invA0; b.b2 *= invA0;
    b.a1 *= invA0; b.a2 *= invA0;
    b.a0 = 1.0f;
}

void ParametricEQProcessor::calcPeaking(Biquad& b, float freq, float gainDb, float q, double sr) {
    float A = std::pow(10.0f, gainDb / 40.0f);
    float w0 = 2.0f * 3.14159265f * freq / static_cast<float>(sr);
    float cosw0 = std::cos(w0);
    float sinw0 = std::sin(w0);
    float alpha = sinw0 / (2.0f * q);

    b.b0 = 1.0f + alpha * A;
    b.b1 = -2.0f * cosw0;
    b.b2 = 1.0f - alpha * A;
    b.a0 = 1.0f + alpha / A;
    b.a1 = -2.0f * cosw0;
    b.a2 = 1.0f - alpha / A;

    float invA0 = 1.0f / b.a0;
    b.b0 *= invA0; b.b1 *= invA0; b.b2 *= invA0;
    b.a1 *= invA0; b.a2 *= invA0;
    b.a0 = 1.0f;
}

void ParametricEQProcessor::calcHighShelf(Biquad& b, float freq, float gainDb, double sr) {
    float A = std::pow(10.0f, gainDb / 40.0f);
    float w0 = 2.0f * 3.14159265f * freq / static_cast<float>(sr);
    float cosw0 = std::cos(w0);
    float sinw0 = std::sin(w0);
    float S = 1.0f;
    float alpha = sinw0 * 0.5f * std::sqrt((A + 1.0f / A) * (1.0f / S - 1.0f) + 2.0f);

    float sqrtA2alpha = 2.0f * std::sqrt(A) * alpha;
    b.b0 = A * ((A + 1.0f) + (A - 1.0f) * cosw0 + sqrtA2alpha);
    b.b1 = -2.0f * A * ((A - 1.0f) + (A + 1.0f) * cosw0);
    b.b2 = A * ((A + 1.0f) + (A - 1.0f) * cosw0 - sqrtA2alpha);
    b.a0 = (A + 1.0f) - (A - 1.0f) * cosw0 + sqrtA2alpha;
    b.a1 = 2.0f * ((A - 1.0f) - (A + 1.0f) * cosw0);
    b.a2 = (A + 1.0f) - (A - 1.0f) * cosw0 - sqrtA2alpha;

    float invA0 = 1.0f / b.a0;
    b.b0 *= invA0; b.b1 *= invA0; b.b2 *= invA0;
    b.a1 *= invA0; b.a2 *= invA0;
    b.a0 = 1.0f;
}

void ParametricEQProcessor::setParam(int index, float value) {
    switch (index) {
    case LOW_FREQ:  lowFreq_ = std::clamp(value, 20.0f, 500.0f); coeffsDirty_ = true; break;
    case LOW_GAIN:  lowGain_ = std::clamp(value, -18.0f, 18.0f); coeffsDirty_ = true; break;
    case MID_FREQ:  midFreq_ = std::clamp(value, 200.0f, 8000.0f); coeffsDirty_ = true; break;
    case MID_GAIN:  midGain_ = std::clamp(value, -18.0f, 18.0f); coeffsDirty_ = true; break;
    case MID_Q:     midQ_ = std::clamp(value, 0.1f, 10.0f); coeffsDirty_ = true; break;
    case HIGH_FREQ: highFreq_ = std::clamp(value, 1000.0f, 20000.0f); coeffsDirty_ = true; break;
    case HIGH_GAIN: highGain_ = std::clamp(value, -18.0f, 18.0f); coeffsDirty_ = true; break;
    case MIX:       mix_ = value; break;
    default: break;
    }
}

float ParametricEQProcessor::getParam(int index) const {
    switch (index) {
    case LOW_FREQ:  return lowFreq_;
    case LOW_GAIN:  return lowGain_;
    case MID_FREQ:  return midFreq_;
    case MID_GAIN:  return midGain_;
    case MID_Q:     return midQ_;
    case HIGH_FREQ: return highFreq_;
    case HIGH_GAIN: return highGain_;
    case MIX:       return mix_;
    default: return 0.0f;
    }
}

const char* ParametricEQProcessor::paramName(int index) const {
    switch (index) {
    case LOW_FREQ:  return "Low Freq";
    case LOW_GAIN:  return "Low Gain";
    case MID_FREQ:  return "Mid Freq";
    case MID_GAIN:  return "Mid Gain";
    case MID_Q:     return "Mid Q";
    case HIGH_FREQ: return "High Freq";
    case HIGH_GAIN: return "High Gain";
    case MIX:       return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
