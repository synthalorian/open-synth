#include "fx_harmonizer.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

HarmonizerProcessor::HarmonizerProcessor()
    : FxProcessor(FxType::Harmonizer) {
    delayL_.fill(0.0f);
    delayR_.fill(0.0f);
}

void HarmonizerProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;
    updateWindowSize();

    float inL = left;
    float inR = right;

    // Write to delay line
    delayL_[writePos_] = inL;
    delayR_[writePos_] = inR;

    // Total pitch ratio: 2^((interval + fine/100)/12)
    float totalSemitones = interval_ + fine_ * 0.01f;
    float ratio = std::pow(2.0f, totalSemitones / 12.0f);

    // Two-tap crossfade for smooth pitch shifting
    float wetL = 0.0f;
    float wetR = 0.0f;

    float pos1L = readPosL_;
    float pos1R = readPosR_;
    float pos2L = pos1L + windowSize_ * 0.5f;
    float pos2R = pos1R + windowSize_ * 0.5f;

    if (pos2L >= windowSize_) pos2L -= windowSize_;
    if (pos2R >= windowSize_) pos2R -= windowSize_;

    float crossfade = pos1L / (windowSize_ * 0.5f);
    if (crossfade > 1.0f) crossfade = 2.0f - crossfade;

    wetL = readDelay(delayL_, pos1L) * (1.0f - crossfade)
         + readDelay(delayL_, pos2L) * crossfade;
    wetR = readDelay(delayR_, pos1R) * (1.0f - crossfade)
         + readDelay(delayR_, pos2R) * crossfade;

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);

    readPosL_ += ratio;
    readPosR_ += ratio;

    if (readPosL_ >= windowSize_) readPosL_ -= windowSize_;
    if (readPosR_ >= windowSize_) readPosR_ -= windowSize_;

    writePos_ = (writePos_ + 1) % windowSize_;
}

float HarmonizerProcessor::readDelay(const std::array<float, MAX_DELAY>& buf, float pos) {
    int i = static_cast<int>(pos);
    float frac = pos - i;
    int i1 = i % windowSize_;
    int i2 = (i1 + 1) % windowSize_;
    return buf[i1] * (1.0f - frac) + buf[i2] * frac;
}

void HarmonizerProcessor::updateWindowSize() {
    // Quality maps to window size: low quality = small window (64-512), high = large (4096-8192)
    int minSize = 512;
    int maxSize = 4096;
    int target = minSize + static_cast<int>((maxSize - minSize) * quality_);
    if (target < 64) target = 64;
    if (target > MAX_DELAY) target = MAX_DELAY;
    windowSize_ = target;
}

void HarmonizerProcessor::reset() {
    delayL_.fill(0.0f);
    delayR_.fill(0.0f);
    readPosL_ = 0.0f;
    readPosR_ = 0.0f;
    writePos_ = 0;
}

void HarmonizerProcessor::setParam(int index, float value) {
    switch (index) {
    case INTERVAL: interval_ = std::clamp(value, -12.0f, 12.0f); break;
    case FINE:     fine_ = std::clamp(value, -100.0f, 100.0f); break;
    case MIX:      mix_ = value; break;
    case QUALITY:  quality_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float HarmonizerProcessor::getParam(int index) const {
    switch (index) {
    case INTERVAL: return interval_;
    case FINE:     return fine_;
    case MIX:      return mix_;
    case QUALITY:  return quality_;
    default: return 0.0f;
    }
}

const char* HarmonizerProcessor::paramName(int index) const {
    switch (index) {
    case INTERVAL: return "Interval";
    case FINE:     return "Fine";
    case MIX:      return "Mix";
    case QUALITY:  return "Quality";
    default: return "Unknown";
    }
}

} // namespace opensynth
