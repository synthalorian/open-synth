#include "fx_vibrato.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

static const double TWO_PI = 6.283185307179586;

VibratoProcessor::VibratoProcessor()
    : FxProcessor(FxType::Vibrato) {
    delayLineL_.fill(0.0f);
    delayLineR_.fill(0.0f);
}

float VibratoProcessor::lfoValue(double ph) const {
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

float VibratoProcessor::readDelay(const std::array<float, MAX_DELAY>& line, float delaySamples) {
    float readPos = static_cast<float>(writeIndex_) - delaySamples;
    while (readPos < 0.0f) readPos += MAX_DELAY;
    int i0 = static_cast<int>(readPos) % MAX_DELAY;
    int i1 = (i0 + 1) % MAX_DELAY;
    float frac = readPos - std::floor(readPos);
    return line[i0] * (1.0f - frac) + line[i1] * frac;
}

void VibratoProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    // Advance LFO phase
    phase_ += rate_ / sampleRate;
    if (phase_ >= 1.0) phase_ -= 1.0;

    // Depth controls delay modulation amount: 0 - 20 ms
    float maxDelayMs = 20.0f;
    float lfo = lfoValue(phase_);
    float delayMs = maxDelayMs * 0.5f * (1.0f + lfo * depth_);
    float delaySamples = static_cast<float>(delayMs * 0.001 * sampleRate);
    delaySamples = std::clamp(delaySamples, 1.0f, static_cast<float>(MAX_DELAY - 1));

    // Write input to delay line
    delayLineL_[writeIndex_] = left;
    delayLineR_[writeIndex_] = right;

    // Read modulated position
    float wetL = readDelay(delayLineL_, delaySamples);
    float wetR = readDelay(delayLineR_, delaySamples);

    // Advance write pointer
    writeIndex_ = (writeIndex_ + 1) % MAX_DELAY;

    left = applyMix(left, wetL);
    right = applyMix(right, wetR);
}

void VibratoProcessor::reset() {
    delayLineL_.fill(0.0f);
    delayLineR_.fill(0.0f);
    writeIndex_ = 0;
    phase_ = 0.0;
}

void VibratoProcessor::setParam(int index, float value) {
    switch (index) {
    case RATE:  rate_ = std::clamp(value, 0.1f, 10.0f); break;
    case DEPTH: depth_ = std::clamp(value, 0.0f, 1.0f); break;
    case WAVE:  wave_ = std::clamp(static_cast<int>(value), 0, 3); break;
    case MIX:   mix_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float VibratoProcessor::getParam(int index) const {
    switch (index) {
    case RATE:  return rate_;
    case DEPTH: return depth_;
    case WAVE:  return static_cast<float>(wave_);
    case MIX:   return mix_;
    default: return 0.0f;
    }
}

const char* VibratoProcessor::paramName(int index) const {
    switch (index) {
    case RATE:  return "Rate";
    case DEPTH: return "Depth";
    case WAVE:  return "Wave";
    case MIX:   return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
