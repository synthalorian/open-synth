#include "fx_gated_reverb.h"
#include <algorithm>

namespace openamp {

GatedReverbProcessor::GatedReverbProcessor()
    : FxProcessor(FxType::GatedReverb) {
    delayL_.fill(0.0f);
    delayR_.fill(0.0f);
    stateL_.fill(0.0f);
    stateR_.fill(0.0f);
    pos_.fill(0);
}

void GatedReverbProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;
    float in = (inL + inR) * 0.5f;

    // Simple 4-tap reverb
    float wet = 0.0f;
    int delays[4] = { 1000, 1500, 2200, 3000 };
    for (int i = 0; i < 4; ++i) {
        int d = static_cast<int>(delays[i] * (0.5f + size_ * 0.5f));
        if (d >= MAX_DELAY) d = MAX_DELAY - 1;

        int rp = pos_[i] - d;
        if (rp < 0) rp += MAX_DELAY;

        wet += delayL_[rp] * 0.25f;

        float fb = stateL_[i] * 0.5f;
        delayL_[pos_[i]] = in + fb;
        stateL_[i] = delayL_[rp];

        pos_[i] = (pos_[i] + 1) % MAX_DELAY;
    }

    // Noise gate
    updateEnvelope(std::abs(wet));

    holdSamples_ = static_cast<int>(holdMs_ * 0.001f * sampleRate_);

    float gateOpen = envelope_ > gateThresh_ ? 1.0f : 0.0f;
    if (gateOpen > 0.5f) {
        holdCounter_ = holdSamples_;
    }

    if (holdCounter_ > 0) {
        holdCounter_--;
        gateState_ += (1.0f - gateState_) * 0.3f;
    } else {
        gateState_ += (0.0f - gateState_) * 0.1f;
    }

    wet *= gateState_;

    left = applyMix(inL, wet);
    right = applyMix(inR, wet);
}

void GatedReverbProcessor::updateEnvelope(float input) {
    float attackCoeff = std::exp(-1.0f / (attackMs_ * 0.001f * sampleRate_));
    if (input > envelope_) {
        envelope_ = attackCoeff * envelope_ + (1.0f - attackCoeff) * input;
    } else {
        envelope_ *= 0.99f; // slow release
    }
}

void GatedReverbProcessor::reset() {
    delayL_.fill(0.0f);
    delayR_.fill(0.0f);
    stateL_.fill(0.0f);
    stateR_.fill(0.0f);
    pos_.fill(0);
    envelope_ = 0.0f;
    gateState_ = 0.0f;
    holdCounter_ = 0;
}

void GatedReverbProcessor::setParam(int index, float value) {
    switch (index) {
    case SIZE:        size_ = value; break;
    case GATE_THRESH: gateThresh_ = value; break;
    case ATTACK:      attackMs_ = value; break;
    case HOLD:        holdMs_ = value; break;
    case MIX:         mix_ = value; break;
    default: break;
    }
}

float GatedReverbProcessor::getParam(int index) const {
    switch (index) {
    case SIZE:        return size_;
    case GATE_THRESH: return gateThresh_;
    case ATTACK:      return attackMs_;
    case HOLD:        return holdMs_;
    case MIX:         return mix_;
    default: return 0.0f;
    }
}

const char* GatedReverbProcessor::paramName(int index) const {
    switch (index) {
    case SIZE:        return "Size";
    case GATE_THRESH: return "Gate Threshold";
    case ATTACK:      return "Attack";
    case HOLD:        return "Hold";
    case MIX:         return "Mix";
    default: return "Unknown";
    }
}

} // namespace openamp
