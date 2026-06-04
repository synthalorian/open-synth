#include "fx_lo_fi.h"
#include <algorithm>
#include <cstdlib>

namespace opensynth {

LoFiProcessor::LoFiProcessor()
    : FxProcessor(FxType::LoFi) {}

void LoFiProcessor::reset() {
    phase_ = 0.0f;
    holdL_ = 0.0f;
    holdR_ = 0.0f;
    wowPhase_ = 0.0f;
    wowSampleL_ = 0.0f;
    wowSampleR_ = 0.0f;
    noiseStateL_ = 0.0f;
    noiseStateR_ = 0.0f;
}

void LoFiProcessor::process(float& left, float& right, double sampleRate) {
    nativeSampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // --- Sample rate reduction ---
    // sampleRateNorm_ maps 0.01-1 to 400Hz - native rate
    float targetRate = 400.0f + sampleRateNorm_ * static_cast<float>(nativeSampleRate_ - 400.0);
    float step = targetRate / static_cast<float>(nativeSampleRate_);
    phase_ += step;
    if (phase_ >= 1.0f) {
        phase_ -= 1.0f;
        holdL_ = crush(inL);
        holdR_ = crush(inR);
    }

    // --- Wow pitch wobble (LFO-modulated delay line approximation) ---
    float wowFreq = 0.5f; // ~0.5Hz wow
    wowPhase_ += wowFreq / static_cast<float>(nativeSampleRate_);
    if (wowPhase_ >= 1.0f) wowPhase_ -= 1.0f;
    float wowLfo = std::sin(wowPhase_ * 2.0f * 3.14159265f);
    float wowOffset = wowLfo * wow_ * 0.02f; // max 20ms variation

    // Simple linear interpolation for wow delay
    float wowMixL = holdL_ + (inL - holdL_) * wowOffset;
    float wowMixR = holdR_ + (inR - holdR_) * wowOffset;

    // --- Tape hiss ---
    float hissL = filteredNoise(noiseStateL_) * noise_ * 0.05f;
    float hissR = filteredNoise(noiseStateR_) * noise_ * 0.05f;

    float wetL = wowMixL + hissL;
    float wetR = wowMixR + hissR;

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

float LoFiProcessor::crush(float sample) {
    float levels = std::pow(2.0f, bitDepth_ - 1.0f);
    float quantized = std::round(sample * levels) / levels;
    return std::clamp(quantized, -1.0f, 1.0f);
}

float LoFiProcessor::filteredNoise(float& state) {
    // White noise through 1-pole lowpass for pink-ish hiss
    float white = (static_cast<float>(std::rand()) / static_cast<float>(RAND_MAX)) * 2.0f - 1.0f;
    state += 0.1f * (white - state);
    return state;
}

void LoFiProcessor::setParam(int index, float value) {
    switch (index) {
    case SAMPLE_RATE: sampleRateNorm_ = std::clamp(value, 0.01f, 1.0f); break;
    case BIT_DEPTH:   bitDepth_ = std::clamp(value, 1.0f, 16.0f); break;
    case NOISE:       noise_ = std::clamp(value, 0.0f, 1.0f); break;
    case WOW:         wow_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float LoFiProcessor::getParam(int index) const {
    switch (index) {
    case SAMPLE_RATE: return sampleRateNorm_;
    case BIT_DEPTH:   return bitDepth_;
    case NOISE:       return noise_;
    case WOW:         return wow_;
    default: return 0.0f;
    }
}

const char* LoFiProcessor::paramName(int index) const {
    switch (index) {
    case SAMPLE_RATE: return "Sample Rate";
    case BIT_DEPTH:   return "Bit Depth";
    case NOISE:       return "Noise";
    case WOW:         return "Wow";
    default: return "Unknown";
    }
}

} // namespace opensynth
