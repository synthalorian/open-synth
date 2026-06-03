#include "fx_pingpong_delay.h"
#include <algorithm>

namespace opensynth {

PingPongDelayProcessor::PingPongDelayProcessor()
    : FxProcessor(FxType::PingPongDelay) {
    delayL_.fill(0.0f);
    delayR_.fill(0.0f);
}

void PingPongDelayProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    int delaySamples = static_cast<int>(timeMs_ * 0.001f * sampleRate_);
    if (delaySamples < 1) delaySamples = 1;
    if (delaySamples >= MAX_DELAY) delaySamples = MAX_DELAY - 1;

    int rp = writePos_ - delaySamples;
    if (rp < 0) rp += MAX_DELAY;

    float wetL = delayL_[rp];
    float wetR = delayR_[rp];

    // Ping-pong: cross-feedback
    float fbL = wetR * feedback_ * width_ + wetL * feedback_ * (1.0f - width_);
    float fbR = wetL * feedback_ * width_ + wetR * feedback_ * (1.0f - width_);

    delayL_[writePos_] = inL + fbL;
    delayR_[writePos_] = inR + fbR;

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);

    writePos_ = (writePos_ + 1) % MAX_DELAY;
}

void PingPongDelayProcessor::reset() {
    delayL_.fill(0.0f);
    delayR_.fill(0.0f);
    writePos_ = 0;
}

void PingPongDelayProcessor::setParam(int index, float value) {
    switch (index) {
    case TIME:     timeMs_ = value; break;
    case FEEDBACK: feedback_ = std::clamp(value, 0.0f, 0.95f); break;
    case WIDTH:    width_ = value; break;
    case MIX:      mix_ = value; break;
    default: break;
    }
}

float PingPongDelayProcessor::getParam(int index) const {
    switch (index) {
    case TIME:     return timeMs_;
    case FEEDBACK: return feedback_;
    case WIDTH:    return width_;
    case MIX:      return mix_;
    default: return 0.0f;
    }
}

const char* PingPongDelayProcessor::paramName(int index) const {
    switch (index) {
    case TIME:     return "Time";
    case FEEDBACK: return "Feedback";
    case WIDTH:    return "Width";
    case MIX:      return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
