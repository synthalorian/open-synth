#include "fx_octaver.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

OctaverProcessor::OctaverProcessor()
    : FxProcessor(FxType::Octaver) {
}

void OctaverProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // Octave down: half-wave rectification on zero-crossing segments
    bool posL = inL >= 0.0f;
    bool posR = inR >= 0.0f;

    float octaveDownL = 0.0f;
    float octaveDownR = 0.0f;

    if (posL == posL_) {
        // Same half-cycle: accumulate
        hwL_ += std::abs(inL);
    } else {
        // Zero crossing: reset
        hwL_ = std::abs(inL);
    }

    if (posR == posR_) {
        hwR_ += std::abs(inR);
    } else {
        hwR_ = std::abs(inR);
    }

    // Half-wave rectified output (only positive half)
    octaveDownL = posL ? hwL_ * 0.5f : 0.0f;
    octaveDownR = posR ? hwR_ * 0.5f : 0.0f;

    posL_ = posL;
    posR_ = posR;

    // Octave up: full-wave rectification + DC block
    float fwL = std::abs(inL);
    float fwR = std::abs(inR);

    // Smooth full-wave for cleaner octave-up
    float smooth = 0.3f + tracking_ * 0.6f;
    fwL_ += smooth * (fwL - fwL_);
    fwR_ += smooth * (fwR - fwR_);

    float octaveUpL = dcBlock(fwL_ * 2.0f - 1.0f, dcL_);
    float octaveUpR = dcBlock(fwR_ * 2.0f - 1.0f, dcR_);

    // Tone filter on octave signals
    octaveDownL = toneFilter(octaveDownL, toneL_);
    octaveDownR = toneFilter(octaveDownR, toneR_);
    octaveUpL = toneFilter(octaveUpL, toneL_);
    octaveUpR = toneFilter(octaveUpR, toneR_);

    // Mix based on octave param
    float wetL = 0.0f;
    float wetR = 0.0f;

    if (octave_ < 0.0f) {
        // Octave down
        float amt = std::min(-octave_ / 2.0f, 1.0f);
        wetL = octaveDownL * amt;
        wetR = octaveDownR * amt;
    } else if (octave_ > 0.0f) {
        // Octave up
        float amt = std::min(octave_ / 2.0f, 1.0f);
        wetL = octaveUpL * amt;
        wetR = octaveUpR * amt;
    } else {
        // Subtle both
        wetL = (octaveDownL + octaveUpL) * 0.3f;
        wetR = (octaveDownR + octaveUpR) * 0.3f;
    }

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);

    prevL_ = inL;
    prevR_ = inR;
}

float OctaverProcessor::toneFilter(float input, float& state) {
    // 1-pole lowpass, cutoff controlled by tone_
    float freq = 200.0f + tone_ * 3000.0f;
    float f = freq / static_cast<float>(sampleRate_);
    if (f > 0.49f) f = 0.49f;
    float coeff = 2.0f * 3.14159265f * f;
    state += coeff * (input - state);
    return state;
}

float OctaverProcessor::dcBlock(float input, float& state) {
    // Simple DC blocking filter
    float out = input - state;
    state = input * 0.995f;
    return out;
}

void OctaverProcessor::reset() {
    prevL_ = prevR_ = 0.0f;
    posL_ = posR_ = false;
    hwL_ = hwR_ = 0.0f;
    fwL_ = fwR_ = 0.0f;
    dcL_ = dcR_ = 0.0f;
    toneL_ = toneR_ = 0.0f;
}

void OctaverProcessor::setParam(int index, float value) {
    switch (index) {
    case OCTAVE:   octave_ = std::clamp(value, -2.0f, 2.0f); break;
    case MIX:      mix_ = value; break;
    case TONE:     tone_ = std::clamp(value, 0.0f, 1.0f); break;
    case TRACKING: tracking_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float OctaverProcessor::getParam(int index) const {
    switch (index) {
    case OCTAVE:   return octave_;
    case MIX:      return mix_;
    case TONE:     return tone_;
    case TRACKING: return tracking_;
    default: return 0.0f;
    }
}

const char* OctaverProcessor::paramName(int index) const {
    switch (index) {
    case OCTAVE:   return "Octave";
    case MIX:      return "Mix";
    case TONE:     return "Tone";
    case TRACKING: return "Tracking";
    default: return "Unknown";
    }
}

} // namespace opensynth
