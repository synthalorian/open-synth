#include "fx_shimmer_reverb.h"
#include <algorithm>

namespace opensynth {

ShimmerReverbProcessor::ShimmerReverbProcessor()
    : FxProcessor(FxType::ShimmerReverb) {
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
    pitchLineL_.fill(0.0f);
    pitchLineR_.fill(0.0f);
}

int ShimmerReverbProcessor::combDelay(int index) const {
    static const float bases[COMB_COUNT] = { 1000.0f, 1400.0f, 1800.0f, 2200.0f };
    float s = 0.4f + size_ * 0.8f;
    return static_cast<int>(bases[index] * s * sampleRate_ / 48000.0f);
}

int ShimmerReverbProcessor::apDelay(int index) const {
    static const float bases[AP_COUNT] = { 300.0f, 500.0f };
    return static_cast<int>(bases[index] * sampleRate_ / 48000.0f);
}

float ShimmerReverbProcessor::pitchShift(float sampleL, float sampleR, float& outL, float& outR) {
    // Simple delay-line crossfade pitch shifter
    // +12 semitones max -> ratio = 2.0 at shift=1
    float ratio = 1.0f + shift_;
    float delaySamples = 1000.0f + 500.0f * std::sin(pitchPhase_);

    pitchLineL_[pitchWrite_] = sampleL;
    pitchLineR_[pitchWrite_] = sampleR;

    float readPos = static_cast<float>(pitchWrite_) - delaySamples;
    while (readPos < 0.0f) readPos += MAX_PITCH_DELAY;
    int i0 = static_cast<int>(readPos) % MAX_PITCH_DELAY;
    int i1 = (i0 + 1) % MAX_PITCH_DELAY;
    float frac = readPos - std::floor(readPos);

    outL = pitchLineL_[i0] * (1.0f - frac) + pitchLineL_[i1] * frac;
    outR = pitchLineR_[i0] * (1.0f - frac) + pitchLineR_[i1] * frac;

    pitchPhase_ += (ratio - 1.0f) * 0.01f;
    if (pitchPhase_ >= 6.283185307f) pitchPhase_ -= 6.283185307f;

    pitchWrite_ = (pitchWrite_ + 1) % MAX_PITCH_DELAY;
    return 0.0f; // out params used
}

void ShimmerReverbProcessor::process(float& left, float& right, double sampleRate) {
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

    float wetL = combSumL * 0.25f;
    float wetR = combSumR * 0.25f;

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

    // Pitch-shifted feedback path: feed wet back into pitch shifter and mix back in
    if (shift_ > 0.01f) {
        float shiftL = 0.0f, shiftR = 0.0f;
        pitchShift(wetL, wetR, shiftL, shiftR);
        wetL = wetL * 0.7f + shiftL * 0.5f;
        wetR = wetR * 0.7f + shiftR * 0.5f;
    }

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

void ShimmerReverbProcessor::reset() {
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
    pitchLineL_.fill(0.0f);
    pitchLineR_.fill(0.0f);
    pitchWrite_ = 0;
    pitchPhase_ = 0.0f;
}

void ShimmerReverbProcessor::setParam(int index, float value) {
    switch (index) {
    case SIZE:    size_ = std::clamp(value, 0.0f, 1.0f); break;
    case DAMPING: damping_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:     mix_ = std::clamp(value, 0.0f, 1.0f); break;
    case SHIFT:   shift_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float ShimmerReverbProcessor::getParam(int index) const {
    switch (index) {
    case SIZE:    return size_;
    case DAMPING: return damping_;
    case MIX:     return mix_;
    case SHIFT:   return shift_;
    default: return 0.0f;
    }
}

const char* ShimmerReverbProcessor::paramName(int index) const {
    switch (index) {
    case SIZE:    return "Size";
    case DAMPING: return "Damping";
    case MIX:     return "Mix";
    case SHIFT:   return "Shift";
    default: return "Unknown";
    }
}

} // namespace opensynth
