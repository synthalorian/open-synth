#include "fx_exciter.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

ExciterProcessor::ExciterProcessor()
    : FxProcessor(FxType::Exciter) {}

void ExciterProcessor::reset() {
    hpL_ = hpR_ = 0.0f;
    bp1L_ = bp2L_ = 0.0f;
    bp1R_ = bp2R_ = 0.0f;
}

void ExciterProcessor::process(float& left, float& right, double sampleRate) {
    if (sampleRate != sampleRate_) {
        sampleRate_ = sampleRate;
        updateFilters(sampleRate_);
    }

    float inL = left;
    float inR = right;

    // Highpass to isolate high frequencies for excitation
    float hpCoeff = freq_ / static_cast<float>(sampleRate_);
    if (hpCoeff > 0.49f) hpCoeff = 0.49f;
    float hpOutL = highpass(inL, hpL_, hpCoeff);
    float hpOutR = highpass(inR, hpR_, hpCoeff);

    // Generate harmonics via tanh distortion
    // Even vs odd mix: even uses x^2-like (full-wave), odd uses tanh asymmetry
    float evenMix = harmonics_;
    float oddMix = 1.0f - harmonics_;

    float distL = std::tanh(hpOutL * 3.0f) * oddMix + (hpOutL * hpOutL) * evenMix * 0.5f;
    float distR = std::tanh(hpOutR * 3.0f) * oddMix + (hpOutR * hpOutR) * evenMix * 0.5f;

    // Bandpass to shape the generated harmonics
    float bpCoeff = freq_ / static_cast<float>(sampleRate_);
    if (bpCoeff > 0.49f) bpCoeff = 0.49f;
    float bpOutL = bandpass(distL, bp1L_, bp2L_, bpCoeff);
    float bpOutR = bandpass(distR, bp1R_, bp2R_, bpCoeff);

    // Scale by amount
    float wetL = bpOutL * amount_;
    float wetR = bpOutR * amount_;

    left = applyMix(inL, inL + wetL);
    right = applyMix(inR, inR + wetR);
}

void ExciterProcessor::updateFilters(double /*sr*/) {
    // Coefficients computed per-sample for simplicity
}

float ExciterProcessor::highpass(float in, float& state, float coeff) {
    // 1-pole highpass: y = x - state, state += coeff * y
    float out = in - state;
    state += coeff * out;
    return out;
}

float ExciterProcessor::bandpass(float in, float& s1, float& s2, float coeff) {
    // Simple 2-pole bandpass approximation
    float low = s1 + coeff * (in - s1);
    s1 = low;
    float band = s2 + coeff * (low - s2);
    s2 = band;
    return band;
}

void ExciterProcessor::setParam(int index, float value) {
    switch (index) {
    case AMOUNT:    amount_ = std::clamp(value, 0.0f, 1.0f); break;
    case FREQ:      freq_ = std::clamp(value, 1000.0f, 10000.0f); break;
    case HARMONICS: harmonics_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:       mix_ = value; break;
    default: break;
    }
}

float ExciterProcessor::getParam(int index) const {
    switch (index) {
    case AMOUNT:    return amount_;
    case FREQ:      return freq_;
    case HARMONICS: return harmonics_;
    case MIX:       return mix_;
    default: return 0.0f;
    }
}

const char* ExciterProcessor::paramName(int index) const {
    switch (index) {
    case AMOUNT:    return "Amount";
    case FREQ:      return "Freq";
    case HARMONICS: return "Harmonics";
    case MIX:       return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
