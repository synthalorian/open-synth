#include "fx_hall_reverb.h"
#include <algorithm>

namespace opensynth {

HallReverbProcessor::HallReverbProcessor()
    : FxProcessor(FxType::HallReverb) {
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

int HallReverbProcessor::combDelay(int index) const {
    static const float bases[COMB_COUNT] = { 1200.0f, 1600.0f, 2100.0f, 2600.0f, 3200.0f, 3800.0f };
    float s = 0.4f + size_ * 0.8f;
    return static_cast<int>(bases[index] * s * sampleRate_ / 48000.0f);
}

int HallReverbProcessor::apDelay(int index) const {
    static const float bases[AP_COUNT] = { 400.0f, 600.0f, 850.0f };
    return static_cast<int>(bases[index] * sampleRate_ / 48000.0f);
}

void HallReverbProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;
    float inMono = (inL + inR) * 0.5f;

    float decay = 0.75f + size_ * 0.22f;
    float lpfCoeff = 0.1f + damping_ * 0.8f;

    float combSumL = 0.0f;
    float combSumR = 0.0f;

    for (int i = 0; i < COMB_COUNT; ++i) {
        int d = combDelay(i);
        d = std::clamp(d, 1, MAX_COMB - 1);

        int rpL = combPosL_[i] - d;
        if (rpL < 0) rpL += MAX_COMB;
        float outL = combsL_[i][rpL];
        combLpfL_[i] += lpfCoeff * (outL - combLpfL_[i]);
        combsL_[i][combPosL_[i]] = inMono + combLpfL_[i] * decay;
        combSumL += outL;
        combPosL_[i] = (combPosL_[i] + 1) % MAX_COMB;

        int dR = d + static_cast<int>((i + 1) * 20.0f * sampleRate_ / 48000.0f);
        dR = std::clamp(dR, 1, MAX_COMB - 1);
        int rpR = combPosR_[i] - dR;
        if (rpR < 0) rpR += MAX_COMB;
        float outR = combsR_[i][rpR];
        combLpfR_[i] += lpfCoeff * (outR - combLpfR_[i]);
        combsR_[i][combPosR_[i]] = inMono + combLpfR_[i] * decay;
        combSumR += outR;
        combPosR_[i] = (combPosR_[i] + 1) % MAX_COMB;
    }

    float wetL = combSumL * (1.0f / COMB_COUNT);
    float wetR = combSumR * (1.0f / COMB_COUNT);

    // Allpass diffusion cascade
    float apCoeff = 0.3f + diffusion_ * 0.5f;
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

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

void HallReverbProcessor::reset() {
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

void HallReverbProcessor::setParam(int index, float value) {
    switch (index) {
    case SIZE:      size_ = std::clamp(value, 0.0f, 1.0f); break;
    case DAMPING:   damping_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:       mix_ = std::clamp(value, 0.0f, 1.0f); break;
    case DIFFUSION: diffusion_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float HallReverbProcessor::getParam(int index) const {
    switch (index) {
    case SIZE:      return size_;
    case DAMPING:   return damping_;
    case MIX:       return mix_;
    case DIFFUSION: return diffusion_;
    default: return 0.0f;
    }
}

const char* HallReverbProcessor::paramName(int index) const {
    switch (index) {
    case SIZE:      return "Size";
    case DAMPING:   return "Damping";
    case MIX:       return "Mix";
    case DIFFUSION: return "Diffusion";
    default: return "Unknown";
    }
}

} // namespace opensynth
