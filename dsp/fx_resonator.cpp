#include "fx_resonator.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

ResonatorProcessor::ResonatorProcessor()
    : FxProcessor(FxType::Resonator) {}

void ResonatorProcessor::reset() {
    for (int i = 0; i < 4; ++i) {
        bp_[i].reset();
    }
}

void ResonatorProcessor::process(float& left, float& right, double sampleRate) {
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

    float outL = 0.0f;
    float outR = 0.0f;

    // Sum 4 parallel bandpass filters
    for (int i = 0; i < 4; ++i) {
        outL += bp_[i].processL(inL);
        outR += bp_[i].processR(inR);
    }

    // Normalize by number of voices
    outL *= 0.25f;
    outR *= 0.25f;

    left = applyMix(inL, outL);
    right = applyMix(inR, outR);
}

void ResonatorProcessor::updateCoeffs() {
    // Material controls detune amount
    float detune = 1.0f + material_ * 0.05f;
    float freqs[4] = {
        freq_ * (1.0f / detune),
        freq_,
        freq_ * detune,
        freq_ * (detune * detune)
    };

    // Decay controls bandwidth (Q): higher decay = narrower bandwidth
    float q = 5.0f + decay_ * 45.0f;

    for (int i = 0; i < 4; ++i) {
        bp_[i].setCoeffs(freqs[i], q, sampleRate_);
    }
}

void ResonatorProcessor::Bandpass::setCoeffs(float freq, float q, double sr) {
    float w0 = 2.0f * 3.14159265f * freq / static_cast<float>(sr);
    float cosw0 = std::cos(w0);
    float sinw0 = std::sin(w0);
    float alpha = sinw0 / (2.0f * q);

    b0 = alpha;
    b1 = 0.0f;
    b2 = -alpha;
    a0 = 1.0f + alpha;
    a1 = -2.0f * cosw0;
    a2 = 1.0f - alpha;

    float invA0 = 1.0f / a0;
    b0 *= invA0;
    b1 *= invA0;
    b2 *= invA0;
    a1 *= invA0;
    a2 *= invA0;
    a0 = 1.0f;
}

void ResonatorProcessor::setParam(int index, float value) {
    switch (index) {
    case FREQ:     freq_ = std::clamp(value, 20.0f, 5000.0f); coeffsDirty_ = true; break;
    case DECAY:    decay_ = std::clamp(value, 0.0f, 1.0f); coeffsDirty_ = true; break;
    case MATERIAL: material_ = std::clamp(value, 0.0f, 1.0f); coeffsDirty_ = true; break;
    case MIX:      mix_ = value; break;
    default: break;
    }
}

float ResonatorProcessor::getParam(int index) const {
    switch (index) {
    case FREQ:     return freq_;
    case DECAY:    return decay_;
    case MATERIAL: return material_;
    case MIX:      return mix_;
    default: return 0.0f;
    }
}

const char* ResonatorProcessor::paramName(int index) const {
    switch (index) {
    case FREQ:     return "Freq";
    case DECAY:    return "Decay";
    case MATERIAL: return "Material";
    case MIX:      return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
