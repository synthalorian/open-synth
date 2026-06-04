#include "fx_radio_simulator.h"
#include <algorithm>
#include <cstdlib>

namespace opensynth {

RadioSimulatorProcessor::RadioSimulatorProcessor()
    : FxProcessor(FxType::RadioSimulator) {}

void RadioSimulatorProcessor::reset() {
    hpL_ = hpR_ = 0.0f;
    lpL_ = lpR_ = 0.0f;
    noiseStateL_ = noiseStateR_ = 0.0f;
}

void RadioSimulatorProcessor::process(float& left, float& right, double sampleRate) {
    nativeSampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // Bandpass: highpass 300Hz -> lowpass 1-4kHz
    float lpFreq = 1000.0f + bandwidth_ * 3000.0f;
    float bpL = highpass(inL, hpL_, 300.0f, nativeSampleRate_);
    float bpR = highpass(inR, hpR_, 300.0f, nativeSampleRate_);
    bpL = lowpass(bpL, lpL_, lpFreq, nativeSampleRate_);
    bpR = lowpass(bpR, lpR_, lpFreq, nativeSampleRate_);

    // Distortion
    float distL = distort(bpL);
    float distR = distort(bpR);

    // Noise
    float nL = filteredNoise(noiseStateL_) * noise_ * 0.08f;
    float nR = filteredNoise(noiseStateR_) * noise_ * 0.08f;

    float wetL = distL + nL;
    float wetR = distR + nR;

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

float RadioSimulatorProcessor::highpass(float input, float& state, float freq, double sr) {
    float f = freq / static_cast<float>(sr);
    if (f > 0.49f) f = 0.49f;
    float coeff = 2.0f * 3.14159265f * f;
    state += coeff * (input - state);
    return input - state;
}

float RadioSimulatorProcessor::lowpass(float input, float& state, float freq, double sr) {
    float f = freq / static_cast<float>(sr);
    if (f > 0.49f) f = 0.49f;
    float coeff = 2.0f * 3.14159265f * f;
    state += coeff * (input - state);
    return state;
}

float RadioSimulatorProcessor::distort(float sample) {
    float amt = distortion_ * 8.0f;
    float x = sample * (1.0f + amt);
    return std::tanh(x) * 0.9f;
}

float RadioSimulatorProcessor::filteredNoise(float& state) {
    float white = (static_cast<float>(std::rand()) / static_cast<float>(RAND_MAX)) * 2.0f - 1.0f;
    state += 0.15f * (white - state);
    return state;
}

void RadioSimulatorProcessor::setParam(int index, float value) {
    switch (index) {
    case BANDWIDTH:  bandwidth_ = std::clamp(value, 0.0f, 1.0f); break;
    case NOISE:      noise_ = std::clamp(value, 0.0f, 1.0f); break;
    case DISTORTION: distortion_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:        mix_ = value; break;
    default: break;
    }
}

float RadioSimulatorProcessor::getParam(int index) const {
    switch (index) {
    case BANDWIDTH:  return bandwidth_;
    case NOISE:      return noise_;
    case DISTORTION: return distortion_;
    case MIX:        return mix_;
    default: return 0.0f;
    }
}

const char* RadioSimulatorProcessor::paramName(int index) const {
    switch (index) {
    case BANDWIDTH:  return "Bandwidth";
    case NOISE:      return "Noise";
    case DISTORTION: return "Distortion";
    case MIX:        return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
