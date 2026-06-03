#include "fx_rotary.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

RotaryProcessor::RotaryProcessor()
    : FxProcessor(FxType::Rotary) {}

void RotaryProcessor::process(float& left, float& right, double sampleRate) {
    // Advance rotary phase
    phase_ += rate_ / sampleRate;
    if (phase_ >= 1.0) phase_ -= 1.0;

    const float twoPi = 6.283185307f;
    float hornPhase = static_cast<float>(phase_ * twoPi);
    float drumPhase = static_cast<float>(phase_ * twoPi * 0.6f); // drum rotates slower

    // Horn (high): Doppler pitch shift + tremolo
    float hornLfo = std::sin(hornPhase);
    float hornDelayOffset = (hornLfo * depth_ * 0.5f + 0.5f) * 200.0f; // 0-200 samples

    // Drum (low): slower modulation
    float drumLfo = std::sin(drumPhase);
    float drumDelayOffset = (drumLfo * depth_ * 0.3f + 0.3f) * 500.0f; // 0-500 samples

    // Tone filtering (low-pass on drum, high-pass on horn)
    float hornTone = tone_ * 0.8f + 0.2f;   // 0.2 - 1.0
    float drumTone = (1.0f - tone_) * 0.6f + 0.2f; // 0.2 - 0.8

    // Blend signal: horn (left channel bias) + drum (right channel bias)
    float input = (left + right) * 0.5f;

    // Horn path — write to delay line
    hornDelay_[hornWritePos_] = input;
    uint32_t hornReadPos = (hornWritePos_ >= static_cast<uint32_t>(hornDelayOffset + 1))
        ? hornWritePos_ - static_cast<uint32_t>(hornDelayOffset + 1)
        : 2048 + hornWritePos_ - static_cast<uint32_t>(hornDelayOffset + 1);
    hornReadPos = hornReadPos % 2048;
    float hornOut = hornDelay_[hornReadPos];

    // Apply horn tone (high-pass emphasis via LPF inversion)
    hornLpf_ += (hornOut - hornLpf_) * 0.3f;
    float hornHi = hornOut - hornLpf_ * (1.0f - hornTone);
    hornOut = hornOut * (1.0f - hornTone) + hornHi * hornTone;
    hornWritePos_ = (hornWritePos_ + 1) % 2048;

    // Drum path — write to delay line
    drumDelay_[drumWritePos_] = input;
    uint32_t drumReadPos = (drumWritePos_ >= static_cast<uint32_t>(drumDelayOffset + 1))
        ? drumWritePos_ - static_cast<uint32_t>(drumDelayOffset + 1)
        : 4096 + drumWritePos_ - static_cast<uint32_t>(drumDelayOffset + 1);
    drumReadPos = drumReadPos % 4096;
    float drumOut = drumDelay_[drumReadPos];

    // Apply drum tone (low-pass)
    drumLpf_ += (drumOut - drumLpf_) * drumTone * 0.5f;
    drumOut = drumLpf_;
    drumWritePos_ = (drumWritePos_ + 1) % 4096;

    // Mix horn (left) and drum (right) with tremolo
    float tremoloMod = 1.0f - std::abs(hornLfo) * depth_ * 0.3f;
    left = (hornOut * 0.7f + input * 0.3f) * tremoloMod;
    right = (drumOut * 0.7f + input * 0.3f) * tremoloMod;

    // Apply wet/dry mix
    left = applyMix(input, left);
    right = applyMix(input, right);
}

void RotaryProcessor::reset() {
    std::fill(std::begin(hornDelay_), std::end(hornDelay_), 0.0f);
    std::fill(std::begin(drumDelay_), std::end(drumDelay_), 0.0f);
    hornWritePos_ = 0;
    drumWritePos_ = 0;
    hornLpf_ = 0.0f;
    drumLpf_ = 0.0f;
    phase_ = 0.0;
}

void RotaryProcessor::setParam(int index, float value) {
    switch (index) {
    case RATE:  rate_ = std::clamp(value, 0.1f, 10.0f); break;
    case DEPTH: depth_ = std::clamp(value, 0.0f, 1.0f); break;
    case TONE:  tone_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:   mix_ = std::clamp(value, 0.0f, 1.0f); break;
    }
}

float RotaryProcessor::getParam(int index) const {
    switch (index) {
    case RATE:  return rate_;
    case DEPTH: return depth_;
    case TONE:  return tone_;
    case MIX:   return mix_;
    }
    return 0.0f;
}

const char* RotaryProcessor::paramName(int index) const {
    switch (index) {
    case RATE:  return "Rate";
    case DEPTH: return "Depth";
    case TONE:  return "Tone";
    case MIX:   return "Mix";
    }
    return "";
}

} // namespace opensynth
