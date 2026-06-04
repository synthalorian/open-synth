#include "fx_uni_vibe.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

static const double TWO_PI = 6.283185307179586;

UniVibeProcessor::UniVibeProcessor()
    : FxProcessor(FxType::UniVibe) {
    for (int i = 0; i < NUM_PHASES; ++i) {
        delayLines_[i].fill(0.0f);
        writeIndices_[i] = 0;
    }
}

float UniVibeProcessor::readDelay(const std::array<float, MAX_DELAY>& line, int writeIdx, float delaySamples) {
    float readPos = static_cast<float>(writeIdx) - delaySamples;
    while (readPos < 0.0f) readPos += MAX_DELAY;
    int i0 = static_cast<int>(readPos) % MAX_DELAY;
    int i1 = (i0 + 1) % MAX_DELAY;
    float frac = readPos - std::floor(readPos);
    return line[i0] * (1.0f - frac) + line[i1] * frac;
}

void UniVibeProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    // Advance LFO phase
    phase_ += rate_ / sampleRate;
    if (phase_ >= 1.0) phase_ -= 1.0;

    // Base delay ~ 2ms, modulation up to ~4ms
    float baseDelayMs = 2.0f;
    float maxModMs = 4.0f;

    float wetL = 0.0f;
    float wetR = 0.0f;

    // 4-phase LFO: 0, 90, 180, 270 degrees
    for (int i = 0; i < NUM_PHASES; ++i) {
        double lfoPhase = phase_ + i * 0.25;
        if (lfoPhase >= 1.0) lfoPhase -= 1.0;
        float lfo = static_cast<float>(std::sin(lfoPhase * TWO_PI));

        float delayMs = baseDelayMs + maxModMs * depth_ * (0.5f + 0.5f * lfo);
        float delaySamples = static_cast<float>(delayMs * 0.001 * sampleRate);
        delaySamples = std::clamp(delaySamples, 1.0f, static_cast<float>(MAX_DELAY - 1));

        // Write input to each delay line
        delayLines_[i][writeIndices_[i]] = (left + right) * 0.5f;

        // Read modulated position
        float tap = readDelay(delayLines_[i], writeIndices_[i], delaySamples);

        // Advance write pointer
        writeIndices_[i] = (writeIndices_[i] + 1) % MAX_DELAY;

        // Mix voices with stereo spread
        float pan = static_cast<float>(i) / static_cast<float>(NUM_PHASES - 1); // 0 to 1
        wetL += tap * (1.0f - pan);
        wetR += tap * pan;
    }

    // Normalize
    wetL *= 2.0f / NUM_PHASES;
    wetR *= 2.0f / NUM_PHASES;

    if (mode_ == 0) {
        // Vibrato: wet only
        left = applyMix(left, wetL);
        right = applyMix(right, wetR);
    } else {
        // Chorus: mix dry + wet
        left = applyMix(left, (left + wetL) * 0.5f);
        right = applyMix(right, (right + wetR) * 0.5f);
    }
}

void UniVibeProcessor::reset() {
    for (int i = 0; i < NUM_PHASES; ++i) {
        delayLines_[i].fill(0.0f);
        writeIndices_[i] = 0;
    }
    phase_ = 0.0;
}

void UniVibeProcessor::setParam(int index, float value) {
    switch (index) {
    case RATE:  rate_ = std::clamp(value, 0.1f, 10.0f); break;
    case DEPTH: depth_ = std::clamp(value, 0.0f, 1.0f); break;
    case MODE:  mode_ = std::clamp(static_cast<int>(value), 0, 1); break;
    case MIX:   mix_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float UniVibeProcessor::getParam(int index) const {
    switch (index) {
    case RATE:  return rate_;
    case DEPTH: return depth_;
    case MODE:  return static_cast<float>(mode_);
    case MIX:   return mix_;
    default: return 0.0f;
    }
}

const char* UniVibeProcessor::paramName(int index) const {
    switch (index) {
    case RATE:  return "Rate";
    case DEPTH: return "Depth";
    case MODE:  return "Mode";
    case MIX:   return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
