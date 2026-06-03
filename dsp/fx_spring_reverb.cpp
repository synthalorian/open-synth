#include "fx_spring_reverb.h"
#include <algorithm>

namespace opensynth {

SpringReverbProcessor::SpringReverbProcessor()
    : FxProcessor(FxType::SpringReverb) {
    for (auto& c : combs_) c.fill(0.0f);
    for (auto& ap : allpasses_) ap.fill(0.0f);
    combPos_.fill(0);
    combLpf_.fill(0.0f);
    apPos_.fill(0);
}

void SpringReverbProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;
    float in = (inL + inR) * 0.5f;

    // Comb filters
    float combSum = 0.0f;
    for (int i = 0; i < COMB_COUNT; ++i) {
        int d = combDelay(i);
        int rp = combPos_[i] - d;
        if (rp < 0) rp += MAX_COMB;

        float out = combs_[i][rp];

        // Damping LPF
        float lpfCoeff = 0.1f + damping_ * 0.8f;
        combLpf_[i] += lpfCoeff * (out - combLpf_[i]);

        combs_[i][combPos_[i]] = in + combLpf_[i] * decay_;
        combSum += out;

        combPos_[i] = (combPos_[i] + 1) % MAX_COMB;
    }

    float wet = combSum * 0.25f;

    // Allpass diffusion
    for (int i = 0; i < AP_COUNT; ++i) {
        int d = apDelay(i);
        int rp = apPos_[i] - d;
        if (rp < 0) rp += 2048;

        float inAp = wet;
        float outAp = allpasses_[i][rp];
        wet = outAp - 0.5f * inAp;
        allpasses_[i][apPos_[i]] = inAp + 0.5f * outAp;

        apPos_[i] = (apPos_[i] + 1) % 2048;
    }

    // Brightness (simple high-shelf emulation)
    float brightGain = 1.0f + brightness_ * 2.0f;
    wet *= brightGain;

    left = applyMix(inL, wet);
    right = applyMix(inR, wet);
}

int SpringReverbProcessor::combDelay(int index) const {
    float base = 1000.0f + index * 400.0f;
    return static_cast<int>(base * sampleRate_ / 48000.0f);
}

int SpringReverbProcessor::apDelay(int index) const {
    float base = 300.0f + index * 150.0f;
    return static_cast<int>(base * sampleRate_ / 48000.0f);
}

void SpringReverbProcessor::reset() {
    for (auto& c : combs_) c.fill(0.0f);
    for (auto& ap : allpasses_) ap.fill(0.0f);
    combPos_.fill(0);
    combLpf_.fill(0.0f);
    apPos_.fill(0);
}

void SpringReverbProcessor::setParam(int index, float value) {
    switch (index) {
    case DECAY:      decay_ = value; break;
    case DAMPING:    damping_ = value; break;
    case BRIGHTNESS: brightness_ = value; break;
    case MIX:        mix_ = value; break;
    default: break;
    }
}

float SpringReverbProcessor::getParam(int index) const {
    switch (index) {
    case DECAY:      return decay_;
    case DAMPING:    return damping_;
    case BRIGHTNESS: return brightness_;
    case MIX:        return mix_;
    default: return 0.0f;
    }
}

const char* SpringReverbProcessor::paramName(int index) const {
    switch (index) {
    case DECAY:      return "Decay";
    case DAMPING:    return "Damping";
    case BRIGHTNESS: return "Brightness";
    case MIX:        return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
