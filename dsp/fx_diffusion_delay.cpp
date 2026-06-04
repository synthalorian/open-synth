#include "fx_diffusion_delay.h"
#include <algorithm>

namespace opensynth {

DiffusionDelayProcessor::DiffusionDelayProcessor()
    : FxProcessor(FxType::DiffusionDelay) {
    delayLineL_.fill(0.0f);
    delayLineR_.fill(0.0f);
    for (auto& ap : allpassesL_) ap.fill(0.0f);
    for (auto& ap : allpassesR_) ap.fill(0.0f);
    apPosL_.fill(0);
    apPosR_.fill(0);
}

float DiffusionDelayProcessor::readDelay(const std::array<float, MAX_DELAY>& line, float delaySamples) {
    float readPos = static_cast<float>(writeIndex_) - delaySamples;
    while (readPos < 0.0f) readPos += MAX_DELAY;
    int i0 = static_cast<int>(readPos) % MAX_DELAY;
    int i1 = (i0 + 1) % MAX_DELAY;
    float frac = readPos - std::floor(readPos);
    return line[i0] * (1.0f - frac) + line[i1] * frac;
}

int DiffusionDelayProcessor::apDelay(int index) const {
    static const float bases[AP_COUNT] = { 150.0f, 250.0f, 400.0f, 600.0f };
    return static_cast<int>(bases[index] * sampleRate_ / 48000.0f);
}

void DiffusionDelayProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    float delaySamples = static_cast<float>(timeMs_ * 0.001 * sampleRate);
    delaySamples = std::clamp(delaySamples, 1.0f, static_cast<float>(MAX_DELAY - 1));

    // Read delayed signal
    float wetL = readDelay(delayLineL_, delaySamples);
    float wetR = readDelay(delayLineR_, delaySamples);

    // Diffusion: 4 allpass filters in series smear the repeats
    float apCoeff = 0.3f + diffusion_ * 0.6f;
    for (int i = 0; i < AP_COUNT; ++i) {
        int d = apDelay(i);
        d = std::clamp(d, 1, MAX_AP - 1);

        int rpL = apPosL_[i] - d;
        if (rpL < 0) rpL += MAX_AP;
        float inApL = wetL;
        float outApL = allpassesL_[i][rpL];
        wetL = outApL - apCoeff * inApL;
        allpassesL_[i][apPosL_[i]] = inApL + apCoeff * outApL;
        apPosL_[i] = (apPosL_[i] + 1) % MAX_AP;

        int rpR = apPosR_[i] - d;
        if (rpR < 0) rpR += MAX_AP;
        float inApR = wetR;
        float outApR = allpassesR_[i][rpR];
        wetR = outApR - apCoeff * inApR;
        allpassesR_[i][apPosR_[i]] = inApR + apCoeff * outApR;
        apPosR_[i] = (apPosR_[i] + 1) % MAX_AP;
    }

    // Write input + feedback to delay lines
    delayLineL_[writeIndex_] = inL + wetL * feedback_;
    delayLineR_[writeIndex_] = inR + wetR * feedback_;

    writeIndex_ = (writeIndex_ + 1) % MAX_DELAY;

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

void DiffusionDelayProcessor::reset() {
    delayLineL_.fill(0.0f);
    delayLineR_.fill(0.0f);
    writeIndex_ = 0;
    for (auto& ap : allpassesL_) ap.fill(0.0f);
    for (auto& ap : allpassesR_) ap.fill(0.0f);
    apPosL_.fill(0);
    apPosR_.fill(0);
}

void DiffusionDelayProcessor::setParam(int index, float value) {
    switch (index) {
    case TIME:      timeMs_ = std::clamp(value, 50.0f, 1000.0f); break;
    case FEEDBACK:  feedback_ = std::clamp(value, 0.0f, 0.95f); break;
    case DIFFUSION: diffusion_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:       mix_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float DiffusionDelayProcessor::getParam(int index) const {
    switch (index) {
    case TIME:      return timeMs_;
    case FEEDBACK:  return feedback_;
    case DIFFUSION: return diffusion_;
    case MIX:       return mix_;
    default: return 0.0f;
    }
}

const char* DiffusionDelayProcessor::paramName(int index) const {
    switch (index) {
    case TIME:      return "Time";
    case FEEDBACK:  return "Feedback";
    case DIFFUSION: return "Diffusion";
    case MIX:       return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
