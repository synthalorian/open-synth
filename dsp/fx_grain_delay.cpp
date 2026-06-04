#include "fx_grain_delay.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

GrainDelayProcessor::GrainDelayProcessor()
    : FxProcessor(FxType::GrainDelay) {
    bufL_.fill(0.0f);
    bufR_.fill(0.0f);
    for (auto& g : grains_) g = {};
}

void GrainDelayProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    int delaySamples = static_cast<int>(timeMs_ * 0.001f * sampleRate_);
    if (delaySamples < 1) delaySamples = 1;
    if (delaySamples > MAX_DELAY - 1) delaySamples = MAX_DELAY - 1;

    int sizeSamples = static_cast<int>(sizeMs_ * 0.001f * sampleRate_);
    if (sizeSamples < 4) sizeSamples = 4;
    if (sizeSamples > MAX_DELAY / 4) sizeSamples = MAX_DELAY / 4;

    // Write input to buffer
    bufL_[writePos_] = inL;
    bufR_[writePos_] = inR;

    float wetL = 0.0f;
    float wetR = 0.0f;

    // Process active grains
    for (auto& g : grains_) {
        if (!g.active) continue;

        float t = static_cast<float>(g.age) / static_cast<float>(g.sizeSamples);
        float w = grainWindow(t);

        float pos = static_cast<float>(g.startPos - g.delaySamples + g.age);
        while (pos < 0.0f) pos += MAX_DELAY;

        float sL = readDelay(bufL_, pos);
        float sR = readDelay(bufR_, pos);

        wetL += sL * w * g.pan;
        wetR += sR * w * (1.0f - g.pan);

        g.age++;
        if (g.age >= g.sizeSamples) {
            g.active = false;
        }
    }

    // Spawn new grain periodically
    int grainSpacing = sizeSamples / 2;
    if (grainSpacing < 1) grainSpacing = 1;
    grainCounter_++;
    if (grainCounter_ >= grainSpacing) {
        grainCounter_ = 0;
        spawnGrain(inL, inR);
    }

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);

    // Feedback into buffer
    bufL_[writePos_] = inL + wetL * feedback_;
    bufR_[writePos_] = inR + wetR * feedback_;

    writePos_ = (writePos_ + 1) % MAX_DELAY;
}

float GrainDelayProcessor::readDelay(const std::array<float, MAX_DELAY>& line, float pos) {
    int i = static_cast<int>(pos);
    float frac = pos - i;
    int i1 = i % MAX_DELAY;
    int i2 = (i1 + 1) % MAX_DELAY;
    return line[i1] * (1.0f - frac) + line[i2] * frac;
}

void GrainDelayProcessor::spawnGrain(float inL, float inR) {
    auto& g = grains_[nextGrain_];
    nextGrain_ = (nextGrain_ + 1) % MAX_GRAINS;

    g.startPos = writePos_;
    g.delaySamples = static_cast<int>(timeMs_ * 0.001f * sampleRate_);
    g.sizeSamples = static_cast<int>(sizeMs_ * 0.001f * sampleRate_);
    if (g.sizeSamples < 4) g.sizeSamples = 4;
    if (g.delaySamples < 1) g.delaySamples = 1;

    // Randomize start position slightly (+/- 10% of delay time)
    float jitter = (static_cast<float>(rand()) / RAND_MAX - 0.5f) * 0.2f;
    g.delaySamples += static_cast<int>(g.delaySamples * jitter);
    if (g.delaySamples < 1) g.delaySamples = 1;
    if (g.delaySamples > MAX_DELAY - 1) g.delaySamples = MAX_DELAY - 1;

    g.age = 0;
    g.pan = 0.3f + (static_cast<float>(rand()) / RAND_MAX) * 0.4f; // centered
    g.active = true;
}

float GrainDelayProcessor::grainWindow(float t) {
    // Hann window
    return 0.5f * (1.0f - std::cos(t * 3.14159265f * 2.0f));
}

void GrainDelayProcessor::reset() {
    bufL_.fill(0.0f);
    bufR_.fill(0.0f);
    writePos_ = 0;
    grainCounter_ = 0;
    nextGrain_ = 0;
    for (auto& g : grains_) g = {};
}

void GrainDelayProcessor::setParam(int index, float value) {
    switch (index) {
    case TIME:     timeMs_ = std::clamp(value, 50.0f, 1000.0f); break;
    case FEEDBACK: feedback_ = std::clamp(value, 0.0f, 0.95f); break;
    case SIZE:     sizeMs_ = std::clamp(value, 1.0f, 100.0f); break;
    case MIX:      mix_ = value; break;
    default: break;
    }
}

float GrainDelayProcessor::getParam(int index) const {
    switch (index) {
    case TIME:     return timeMs_;
    case FEEDBACK: return feedback_;
    case SIZE:     return sizeMs_;
    case MIX:      return mix_;
    default: return 0.0f;
    }
}

const char* GrainDelayProcessor::paramName(int index) const {
    switch (index) {
    case TIME:     return "Time";
    case FEEDBACK: return "Feedback";
    case SIZE:     return "Size";
    case MIX:      return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
