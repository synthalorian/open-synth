#include "fx_plate_reverb.h"
#include <algorithm>

namespace opensynth {

PlateReverbProcessor::PlateReverbProcessor()
    : FxProcessor(FxType::PlateReverb) {
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

int PlateReverbProcessor::combDelay(int index) const {
    static const float bases[COMB_COUNT] = { 900.0f, 1300.0f, 1700.0f, 2100.0f, 2500.0f };
    float s = 0.35f + size_ * 0.75f;
    return static_cast<int>(bases[index] * s * sampleRate_ / 48000.0f);
}

int PlateReverbProcessor::apDelay(int index) const {
    static const float bases[AP_COUNT] = { 250.0f, 450.0f };
    return static_cast<int>(bases[index] * sampleRate_ / 48000.0f);
}

void PlateReverbProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;
    float inMono = (inL + inR) * 0.5f;

    float decay = 0.72f + size_ * 0.25f;
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

        int dR = d + static_cast<int>((i + 1) * 18.0f * sampleRate_ / 48000.0f);
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

    // Allpass diffusion
    for (int i = 0; i < AP_COUNT; ++i) {
        int d = apDelay(i);
        d = std::clamp(d, 1, MAX_AP - 1);

        int rpL = apPosL_[i] - d;
        if (rpL < 0) rpL += MAX_AP;
        float inApL = wetL;
        float outApL = allpassesL_[i][rpL];
        wetL = outApL - 0.5f * inApL;
        allpassesL_[i][apPosL_[i]] = inApL + 0.5f * outApL;
        apPosL_[i] = (apPosL_[i] + 1) % MAX_AP;

        int rpR = apPosR_[i] - d;
        if (rpR < 0) rpR += MAX_AP;
        float inApR = wetR;
        float outApR = allpassesR_[i][rpR];
        wetR = outApR - 0.5f * inApR;
        allpassesR_[i][apPosR_[i]] = inApR + 0.5f * outApR;
        apPosR_[i] = (apPosR_[i] + 1) % MAX_AP;
    }

    // Brightness emphasis: simple high-shelf via 1-pole differentiator + gain
    float brightGain = 1.0f + brightness_ * 2.5f;
    float brightCoeff = 0.3f + brightness_ * 0.5f;
    float brightL = (wetL - brightStateL_) * brightGain;
    float brightR = (wetR - brightStateR_) * brightGain;
    brightStateL_ += brightCoeff * (wetL - brightStateL_);
    brightStateR_ += brightCoeff * (wetR - brightStateR_);
    wetL = brightL;
    wetR = brightR;

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

void PlateReverbProcessor::reset() {
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
    brightStateL_ = 0.0f;
    brightStateR_ = 0.0f;
}

void PlateReverbProcessor::setParam(int index, float value) {
    switch (index) {
    case SIZE:      size_ = std::clamp(value, 0.0f, 1.0f); break;
    case DAMPING:   damping_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:       mix_ = std::clamp(value, 0.0f, 1.0f); break;
    case BRIGHTNESS:brightness_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float PlateReverbProcessor::getParam(int index) const {
    switch (index) {
    case SIZE:      return size_;
    case DAMPING:   return damping_;
    case MIX:       return mix_;
    case BRIGHTNESS:return brightness_;
    default: return 0.0f;
    }
}

const char* PlateReverbProcessor::paramName(int index) const {
    switch (index) {
    case SIZE:      return "Size";
    case DAMPING:   return "Damping";
    case MIX:       return "Mix";
    case BRIGHTNESS:return "Brightness";
    default: return "Unknown";
    }
}

} // namespace opensynth
