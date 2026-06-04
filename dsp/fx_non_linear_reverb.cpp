#include "fx_non_linear_reverb.h"
#include <algorithm>

namespace opensynth {

NonLinearReverbProcessor::NonLinearReverbProcessor()
    : FxProcessor(FxType::NonLinearReverb) {
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

int NonLinearReverbProcessor::combDelay(int index) const {
    static const float bases[COMB_COUNT] = { 1000.0f, 1400.0f, 1900.0f, 2400.0f };
    float s = 0.4f + size_ * 0.8f;
    return static_cast<int>(bases[index] * s * sampleRate_ / 48000.0f);
}

int NonLinearReverbProcessor::apDelay(int index) const {
    static const float bases[AP_COUNT] = { 300.0f, 500.0f };
    return static_cast<int>(bases[index] * sampleRate_ / 48000.0f);
}

void NonLinearReverbProcessor::updateEnvelope(float input) {
    float attackCoeff = std::exp(-1.0f / (attackMs_ * 0.001f * static_cast<float>(sampleRate_)));
    if (input > envelope_) {
        envelope_ = attackCoeff * envelope_ + (1.0f - attackCoeff) * input;
    } else {
        envelope_ *= 0.95f; // fast-ish release for gating effect
    }
}

void NonLinearReverbProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;
    float inMono = (inL + inR) * 0.5f;

    float decay = 0.7f + size_ * 0.28f;
    float lpfCoeff = 0.2f + size_ * 0.5f;

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

    // Envelope follower gates the output
    float wetMono = (wetL + wetR) * 0.5f;
    updateEnvelope(std::abs(wetMono));

    float gateGain = (envelope_ > gate_) ? 1.0f : 0.0f;
    wetL *= gateGain;
    wetR *= gateGain;

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

void NonLinearReverbProcessor::reset() {
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
    envelope_ = 0.0f;
}

void NonLinearReverbProcessor::setParam(int index, float value) {
    switch (index) {
    case SIZE:   size_ = std::clamp(value, 0.0f, 1.0f); break;
    case GATE:   gate_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:    mix_ = std::clamp(value, 0.0f, 1.0f); break;
    case ATTACK: attackMs_ = std::clamp(value, 0.1f, 50.0f); break;
    default: break;
    }
}

float NonLinearReverbProcessor::getParam(int index) const {
    switch (index) {
    case SIZE:   return size_;
    case GATE:   return gate_;
    case MIX:    return mix_;
    case ATTACK: return attackMs_;
    default: return 0.0f;
    }
}

const char* NonLinearReverbProcessor::paramName(int index) const {
    switch (index) {
    case SIZE:   return "Size";
    case GATE:   return "Gate";
    case MIX:    return "Mix";
    case ATTACK: return "Attack";
    default: return "Unknown";
    }
}

} // namespace opensynth
