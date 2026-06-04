#include "fx_telephone_simulator.h"
#include <algorithm>

namespace opensynth {

TelephoneSimulatorProcessor::TelephoneSimulatorProcessor()
    : FxProcessor(FxType::TelephoneSimulator) {}

void TelephoneSimulatorProcessor::reset() {
    z1L_ = z2L_ = 0.0f;
    z1R_ = z2R_ = 0.0f;
}

void TelephoneSimulatorProcessor::process(float& left, float& right, double sampleRate) {
    nativeSampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // Telephone band: 300Hz - 3.4kHz with resonance
    float q = 0.5f + quality_ * 4.5f; // Q 0.5 - 5.0
    float bpL = bandpassSVF(inL, z1L_, z2L_, 1000.0f, q, nativeSampleRate_);
    float bpR = bandpassSVF(inR, z1R_, z2R_, 1000.0f, q, nativeSampleRate_);

    // Optional clipping distortion
    float wetL = distort(bpL);
    float wetR = distort(bpR);

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

float TelephoneSimulatorProcessor::bandpassSVF(float input, float& z1, float& z2, float freq, float q, double sr) {
    float f = 2.0f * std::sin(3.14159265f * freq / static_cast<float>(sr));
    if (f > 1.0f) f = 1.0f;
    float r = 1.0f / q;

    float low = z2 + f * z1;
    float band = z1 - f * low;
    float high = input - low - r * band;
    band += f * high;
    low += f * band;

    z1 = band;
    z2 = low;

    return band;
}

float TelephoneSimulatorProcessor::distort(float sample) {
    float amt = distortion_ * 10.0f;
    float x = sample * (1.0f + amt);
    return std::tanh(x) * 0.95f;
}

void TelephoneSimulatorProcessor::setParam(int index, float value) {
    switch (index) {
    case QUALITY:    quality_ = std::clamp(value, 0.0f, 1.0f); break;
    case DISTORTION: distortion_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:        mix_ = value; break;
    default: break;
    }
}

float TelephoneSimulatorProcessor::getParam(int index) const {
    switch (index) {
    case QUALITY:    return quality_;
    case DISTORTION: return distortion_;
    case MIX:        return mix_;
    default: return 0.0f;
    }
}

const char* TelephoneSimulatorProcessor::paramName(int index) const {
    switch (index) {
    case QUALITY:    return "Quality";
    case DISTORTION: return "Distortion";
    case MIX:        return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
