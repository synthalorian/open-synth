#include "fx_room_reverb.h"
#include <algorithm>

namespace opensynth {

RoomReverbProcessor::RoomReverbProcessor()
    : FxProcessor(FxType::RoomReverb) {
    for (auto& c : combsL_) c.fill(0.0f);
    for (auto& c : combsR_) c.fill(0.0f);
    combPosL_.fill(0);
    combPosR_.fill(0);
    combLpfL_.fill(0.0f);
    combLpfR_.fill(0.0f);
    for (auto& ap : allpassesL_) ap.fill(0.0f);
    for (auto& ap : allpassesR_) ap.fill(0.0f);
    apPosL_.fill(0);
    apPosR_.fill(0);
}

int RoomReverbProcessor::combDelay(int index) const {
    static const float bases[COMB_COUNT] = { 800.0f, 1100.0f, 1400.0f, 1700.0f };
    float s = 0.3f + size_ * 0.7f;
    return static_cast<int>(bases[index] * s * sampleRate_ / 48000.0f);
}

int RoomReverbProcessor::apDelay(int index) const {
    static const float bases[AP_COUNT] = { 200.0f, 350.0f };
    return static_cast<int>(bases[index] * sampleRate_ / 48000.0f);
}

void RoomReverbProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;
    float inMono = (inL + inR) * 0.5f;

    float decay = 0.7f + size_ * 0.28f;
    float lpfCoeff = 0.1f + damping_ * 0.8f;

    float combSumL = 0.0f;
    float combSumR = 0.0f;

    for (int i = 0; i < COMB_COUNT; ++i) {
        int d = combDelay(i);
        d = std::clamp(d, 1, MAX_COMB - 1);

        // Left combs
        int rpL = combPosL_[i] - d;
        if (rpL < 0) rpL += MAX_COMB;
        float outL = combsL_[i][rpL];
        combLpfL_[i] += lpfCoeff * (outL - combLpfL_[i]);
        combsL_[i][combPosL_[i]] = inMono + combLpfL_[i] * decay;
        combSumL += outL;
        combPosL_[i] = (combPosL_[i] + 1) % MAX_COMB;

        // Right combs (slightly offset delay for width)
        int dR = d + static_cast<int>((i + 1) * 15.0f * width_ * sampleRate_ / 48000.0f);
        dR = std::clamp(dR, 1, MAX_COMB - 1);
        int rpR = combPosR_[i] - dR;
        if (rpR < 0) rpR += MAX_COMB;
        float outR = combsR_[i][rpR];
        combLpfR_[i] += lpfCoeff * (outR - combLpfR_[i]);
        combsR_[i][combPosR_[i]] = inMono + combLpfR_[i] * decay;
        combSumR += outR;
        combPosR_[i] = (combPosR_[i] + 1) % MAX_COMB;
    }

    float wetL = combSumL * 0.25f;
    float wetR = combSumR * 0.25f;

    // Allpass diffusion
    for (int i = 0; i < AP_COUNT; ++i) {
        int d = apDelay(i);
        d = std::clamp(d, 1, MAX_AP - 1);
        float coeff = 0.5f + width_ * 0.3f;

        int rpL = apPosL_[i] - d;
        if (rpL < 0) rpL += MAX_AP;
        float inApL = wetL;
        float outApL = allpassesL_[i][rpL];
        wetL = outApL - coeff * inApL;
        allpassesL_[i][apPosL_[i]] = inApL + coeff * outApL;
        apPosL_[i] = (apPosL_[i] + 1) % MAX_AP;

        int rpR = apPosR_[i] - d;
        if (rpR < 0) rpR += MAX_AP;
        float inApR = wetR;
        float outApR = allpassesR_[i][rpR];
        wetR = outApR - coeff * inApR;
        allpassesR_[i][apPosR_[i]] = inApR + coeff * outApR;
        apPosR_[i] = (apPosR_[i] + 1) % MAX_AP;
    }

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

void RoomReverbProcessor::reset() {
    for (auto& c : combsL_) c.fill(0.0f);
    for (auto& c : combsR_) c.fill(0.0f);
    combPosL_.fill(0);
    combPosR_.fill(0);
    combLpfL_.fill(0.0f);
    combLpfR_.fill(0.0f);
    for (auto& ap : allpassesL_) ap.fill(0.0f);
    for (auto& ap : allpassesR_) ap.fill(0.0f);
    apPosL_.fill(0);
    apPosR_.fill(0);
}

void RoomReverbProcessor::setParam(int index, float value) {
    switch (index) {
    case SIZE:    size_ = std::clamp(value, 0.0f, 1.0f); break;
    case DAMPING: damping_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:     mix_ = std::clamp(value, 0.0f, 1.0f); break;
    case WIDTH:   width_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float RoomReverbProcessor::getParam(int index) const {
    switch (index) {
    case SIZE:    return size_;
    case DAMPING: return damping_;
    case MIX:     return mix_;
    case WIDTH:   return width_;
    default: return 0.0f;
    }
}

const char* RoomReverbProcessor::paramName(int index) const {
    switch (index) {
    case SIZE:    return "Size";
    case DAMPING: return "Damping";
    case MIX:     return "Mix";
    case WIDTH:   return "Width";
    default: return "Unknown";
    }
}

} // namespace opensynth
