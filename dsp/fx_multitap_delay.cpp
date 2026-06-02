#include "fx_multitap_delay.h"
#include <algorithm>

namespace openamp {

MultitapDelayProcessor::MultitapDelayProcessor()
    : FxProcessor(FxType::MultitapDelay) {
    delayL_.fill(0.0f);
    delayR_.fill(0.0f);
}

void MultitapDelayProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    int baseSamples = static_cast<int>(timeMs_ * 0.001f * sampleRate_);
    if (baseSamples < 1) baseSamples = 1;
    if (baseSamples >= MAX_DELAY) baseSamples = MAX_DELAY - 1;

    // Read 4 taps with spread
    float wetL = 0.0f;
    float wetR = 0.0f;

    for (int t = 0; t < 4; ++t) {
        int offset = tapOffset(t);
        int rp = writePos_ - offset;
        if (rp < 0) rp += MAX_DELAY;

        wetL += delayL_[rp] * 0.25f;
        wetR += delayR_[rp] * 0.25f;
    }

    // Feedback with tone control
    float fbL = wetL * feedback_;
    float fbR = wetR * feedback_;

    float lpfCoeff = 0.1f + tone_ * 0.8f;
    lpfL_ += lpfCoeff * (fbL - lpfL_);
    lpfR_ += lpfCoeff * (fbR - lpfR_);

    // Write input + feedback
    delayL_[writePos_] = inL + lpfL_;
    delayR_[writePos_] = inR + lpfR_;

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);

    writePos_ = (writePos_ + 1) % MAX_DELAY;
}

int MultitapDelayProcessor::tapOffset(int tapIndex) const {
    int base = static_cast<int>(timeMs_ * 0.001f * sampleRate_);
    float spacing = 1.0f + tapIndex * spread_ * 0.5f;
    int offset = static_cast<int>(base * spacing);
    if (offset < 1) offset = 1;
    if (offset >= MAX_DELAY) offset = MAX_DELAY - 1;
    return offset;
}

void MultitapDelayProcessor::reset() {
    delayL_.fill(0.0f);
    delayR_.fill(0.0f);
    writePos_ = 0;
    lpfL_ = lpfR_ = 0.0f;
}

void MultitapDelayProcessor::setParam(int index, float value) {
    switch (index) {
    case TIME:     timeMs_ = value; break;
    case SPREAD:   spread_ = value; break;
    case FEEDBACK: feedback_ = std::clamp(value, 0.0f, 0.95f); break;
    case TONE:     tone_ = value; break;
    case MIX:      mix_ = value; break;
    default: break;
    }
}

float MultitapDelayProcessor::getParam(int index) const {
    switch (index) {
    case TIME:     return timeMs_;
    case SPREAD:   return spread_;
    case FEEDBACK: return feedback_;
    case TONE:     return tone_;
    case MIX:      return mix_;
    default: return 0.0f;
    }
}

const char* MultitapDelayProcessor::paramName(int index) const {
    switch (index) {
    case TIME:     return "Time";
    case SPREAD:   return "Spread";
    case FEEDBACK: return "Feedback";
    case TONE:     return "Tone";
    case MIX:      return "Mix";
    default: return "Unknown";
    }
}

} // namespace openamp
