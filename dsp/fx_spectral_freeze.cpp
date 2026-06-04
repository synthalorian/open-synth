#include "fx_spectral_freeze.h"
#include <algorithm>
#include <cmath>
#include <cstring>

namespace opensynth {

SpectralFreezeProcessor::SpectralFreezeProcessor()
    : FxProcessor(FxType::SpectralFreeze) {
    bufL_.fill(0.0f);
    bufR_.fill(0.0f);
}

void SpectralFreezeProcessor::reset() {
    bufL_.fill(0.0f);
    bufR_.fill(0.0f);
    writePos_ = 0;
    loopStart_ = 0;
    loopLength_ = 0;
    readPos_ = 0;
    frozen_ = false;
    freezeEnv_ = 0.0f;
    xfPos_ = 0.0f;
}

float SpectralFreezeProcessor::envelopeFollower(float inL, float inR) {
    float peak = std::max(std::abs(inL), std::abs(inR));
    freezeEnv_ += 0.1f * (peak - freezeEnv_);
    return freezeEnv_;
}

void SpectralFreezeProcessor::enterFreeze(int length) {
    frozen_ = true;
    loopLength_ = length;
    loopStart_ = writePos_ - length;
    if (loopStart_ < 0) loopStart_ += MAX_BUFFER;
    readPos_ = loopStart_;
    xfPos_ = 0.0f;
}

void SpectralFreezeProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // Write to buffer
    bufL_[writePos_] = inL;
    bufR_[writePos_] = inR;

    float outL = inL;
    float outR = inR;

    if (!frozen_) {
        // Check if we should freeze
        float env = envelopeFollower(inL, inR);
        if (env > freezeThresh_) {
            int captureMs = 100 + static_cast<int>(decay_ * 400.0f); // 100-500ms
            int captureSamples = static_cast<int>(sampleRate_ * captureMs * 0.001);
            if (captureSamples < 256) captureSamples = 256;
            if (captureSamples > MAX_BUFFER / 2) captureSamples = MAX_BUFFER / 2;
            enterFreeze(captureSamples);
        }
    } else {
        // Read from frozen loop
        int idx = readPos_ % MAX_BUFFER;
        float sL = bufL_[idx];
        float sR = bufR_[idx];

        // Crossfade at loop boundary
        float xf = 1.0f;
        if (xfPos_ < static_cast<float>(xfLength_)) {
            xf = xfPos_ / static_cast<float>(xfLength_);
        }
        if (readPos_ >= loopStart_ + loopLength_ - xfLength_) {
            int dist = (loopStart_ + loopLength_) - readPos_;
            if (dist < xfLength_) {
                xf = static_cast<float>(dist) / static_cast<float>(xfLength_);
            }
        }

        outL = sL * xf;
        outR = sR * xf;

        // Decay
        float decayFactor = 1.0f - (1.0f - decay_) * 0.001f;
        bufL_[idx] *= decayFactor;
        bufR_[idx] *= decayFactor;

        // Advance read position with smear jitter
        ++readPos_;
        if (readPos_ >= loopStart_ + loopLength_) {
            readPos_ = loopStart_;
            xfPos_ = 0.0f;
        }
        xfPos_ += 1.0f;

        // Smear: add jitter to loop points
        if (smear_ > 0.0f) {
            int jitter = static_cast<int>((smear_ * 20.0f) * ((static_cast<float>(rand()) / RAND_MAX) - 0.5f));
            readPos_ += jitter;
            if (readPos_ < loopStart_) readPos_ = loopStart_;
            if (readPos_ >= loopStart_ + loopLength_) readPos_ = loopStart_ + loopLength_ - 1;
        }
    }

    ++writePos_;
    if (writePos_ >= MAX_BUFFER) writePos_ = 0;

    left = applyMix(inL, outL);
    right = applyMix(inR, outR);
}

void SpectralFreezeProcessor::setParam(int index, float value) {
    switch (index) {
    case FREEZE: freezeThresh_ = std::clamp(value, 0.0f, 1.0f); break;
    case DECAY:  decay_ = std::clamp(value, 0.0f, 1.0f); break;
    case SMEAR:  smear_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:    mix_ = value; break;
    default: break;
    }
}

float SpectralFreezeProcessor::getParam(int index) const {
    switch (index) {
    case FREEZE: return freezeThresh_;
    case DECAY:  return decay_;
    case SMEAR:  return smear_;
    case MIX:    return mix_;
    default: return 0.0f;
    }
}

const char* SpectralFreezeProcessor::paramName(int index) const {
    switch (index) {
    case FREEZE: return "Freeze";
    case DECAY:  return "Decay";
    case SMEAR:  return "Smear";
    case MIX:    return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
