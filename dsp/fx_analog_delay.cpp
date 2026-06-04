#include "fx_analog_delay.h"
#include <algorithm>

namespace opensynth {

AnalogDelayProcessor::AnalogDelayProcessor()
    : FxProcessor(FxType::AnalogDelay) {
    delayL_.fill(0.0f);
    delayR_.fill(0.0f);
}

void AnalogDelayProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    float delaySamples = timeMs_ * 0.001f * static_cast<float>(sampleRate_);
    if (delaySamples < 1.0f) delaySamples = 1.0f;
    if (delaySamples > MAX_DELAY - 1) delaySamples = MAX_DELAY - 1;

    // Read from delay line
    float wetL = readDelay(delayL_, delaySamples);
    float wetR = readDelay(delayR_, delaySamples);

    // 1-pole LPF in feedback path (tone control)
    float lpfCoeff = 0.05f + tone_ * 0.9f; // 0.05..0.95
    lpfL_ += lpfCoeff * (wetL - lpfL_);
    lpfR_ += lpfCoeff * (wetR - lpfR_);

    // Saturated feedback
    float fbL = saturate(lpfL_ * feedback_);
    float fbR = saturate(lpfR_ * feedback_);

    // Write input + feedback to delay line
    delayL_[writePos_] = inL + fbL;
    delayR_[writePos_] = inR + fbR;

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);

    writePos_ = (writePos_ + 1) % MAX_DELAY;
}

float AnalogDelayProcessor::readDelay(const std::array<float, MAX_DELAY>& line, float delaySamples) {
    float pos = static_cast<float>(writePos_) - delaySamples;
    while (pos < 0.0f) pos += MAX_DELAY;

    int i = static_cast<int>(pos);
    float frac = pos - i;
    int i1 = i % MAX_DELAY;
    int i2 = (i1 + 1) % MAX_DELAY;
    return line[i1] * (1.0f - frac) + line[i2] * frac;
}

float AnalogDelayProcessor::saturate(float x) {
    // Soft clip like a BBD chip
    return std::tanh(x * 1.2f) * 0.85f;
}

void AnalogDelayProcessor::reset() {
    delayL_.fill(0.0f);
    delayR_.fill(0.0f);
    writePos_ = 0;
    lpfL_ = 0.0f;
    lpfR_ = 0.0f;
}

void AnalogDelayProcessor::setParam(int index, float value) {
    switch (index) {
    case TIME:     timeMs_ = std::clamp(value, 50.0f, 1000.0f); break;
    case FEEDBACK: feedback_ = std::clamp(value, 0.0f, 0.95f); break;
    case TONE:     tone_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:      mix_ = value; break;
    default: break;
    }
}

float AnalogDelayProcessor::getParam(int index) const {
    switch (index) {
    case TIME:     return timeMs_;
    case FEEDBACK: return feedback_;
    case TONE:     return tone_;
    case MIX:      return mix_;
    default: return 0.0f;
    }
}

const char* AnalogDelayProcessor::paramName(int index) const {
    switch (index) {
    case TIME:     return "Time";
    case FEEDBACK: return "Feedback";
    case TONE:     return "Tone";
    case MIX:      return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
