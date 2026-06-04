#include "fx_auto_pan.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

static const double TWO_PI = 6.283185307179586;

AutoPanProcessor::AutoPanProcessor()
    : FxProcessor(FxType::AutoPan) {}

float AutoPanProcessor::lfoValue(double ph) const {
    double t = ph - std::floor(ph);
    switch (wave_) {
    case 0: // sine
        return static_cast<float>(std::sin(t * TWO_PI));
    case 1: { // triangle
        return (t < 0.5) ? static_cast<float>(4.0 * t - 1.0)
                         : static_cast<float>(3.0 - 4.0 * t);
    }
    case 2: // square
        return (t < 0.5) ? 1.0f : -1.0f;
    case 3: // saw
    default:
        return static_cast<float>(2.0 * t - 1.0);
    }
}

void AutoPanProcessor::process(float& left, float& right, double sampleRate) {
    // Advance LFO phase
    phase_ += rate_ / sampleRate;
    if (phase_ >= 1.0) phase_ -= 1.0;

    // Left channel LFO
    float lfoL = lfoValue(phase_);
    // Right channel with phase offset
    double rightPhase = phase_ + phaseOffset_;
    if (rightPhase >= 1.0) rightPhase -= 1.0;
    float lfoR = lfoValue(rightPhase);

    // Map LFO [-1,1] to gain [1-depth, 1]
    float gainL = 1.0f - (lfoL * 0.5f + 0.5f) * depth_;
    float gainR = 1.0f - (lfoR * 0.5f + 0.5f) * depth_;

    left *= gainL;
    right *= gainR;
}

void AutoPanProcessor::reset() {
    phase_ = 0.0;
}

void AutoPanProcessor::setParam(int index, float value) {
    switch (index) {
    case RATE:   rate_ = std::clamp(value, 0.1f, 20.0f); break;
    case DEPTH:  depth_ = std::clamp(value, 0.0f, 1.0f); break;
    case WAVE:   wave_ = std::clamp(static_cast<int>(value), 0, 3); break;
    case PHASE:  phaseOffset_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float AutoPanProcessor::getParam(int index) const {
    switch (index) {
    case RATE:   return rate_;
    case DEPTH:  return depth_;
    case WAVE:   return static_cast<float>(wave_);
    case PHASE:  return phaseOffset_;
    default: return 0.0f;
    }
}

const char* AutoPanProcessor::paramName(int index) const {
    switch (index) {
    case RATE:   return "Rate";
    case DEPTH:  return "Depth";
    case WAVE:   return "Wave";
    case PHASE:  return "Phase";
    default: return "Unknown";
    }
}

} // namespace opensynth
