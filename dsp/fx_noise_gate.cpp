#include "fx_noise_gate.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

NoiseGateProcessor::NoiseGateProcessor()
    : FxProcessor(FxType::NoiseGate) {}

float NoiseGateProcessor::dbToLinear(float db) const {
    return std::pow(10.0f, db / 20.0f);
}

float NoiseGateProcessor::linearToDb(float lin) const {
    if (lin <= 0.0f) return -120.0f;
    return 20.0f * std::log10(lin);
}

void NoiseGateProcessor::reset() {
    env_ = 0.0f;
    state_ = State::CLOSED;
    gain_ = 0.0f;
    holdCounter_ = 0;
}

void NoiseGateProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // Peak detector: fast attack (1 ms), configurable release (10 ms)
    float peak = std::max(std::abs(inL), std::abs(inR));
    float attackCoeff  = 1.0f - std::exp(-1.0f / (0.001f * static_cast<float>(sampleRate_)));
    float releaseCoeff = 1.0f - std::exp(-1.0f / (0.010f * static_cast<float>(sampleRate_)));

    float coeff = (peak > env_) ? attackCoeff : releaseCoeff;
    env_ += coeff * (peak - env_);

    float envDb = linearToDb(env_);
    float threshold = thresholdDb_;

    // Convert user attack/release times to per-sample coefficients
    float gateAttackCoeff  = 1.0f - std::exp(-1.0f / (attackMs_  * 0.001f * static_cast<float>(sampleRate_)));
    float gateReleaseCoeff = 1.0f - std::exp(-1.0f / (releaseMs_ * 0.001f * static_cast<float>(sampleRate_)));
    int holdSamples = static_cast<int>(holdMs_ * 0.001f * static_cast<float>(sampleRate_) + 0.5f);

    // State machine
    switch (state_) {
    case State::CLOSED:
        gain_ = 0.0f;
        if (envDb > threshold) {
            state_ = State::ATTACK;
        }
        break;

    case State::ATTACK:
        gain_ += gateAttackCoeff * (1.0f - gain_);
        if (gain_ >= 0.999f) {
            gain_ = 1.0f;
            state_ = State::OPEN;
            holdCounter_ = holdSamples;
        }
        if (envDb < threshold) {
            state_ = State::RELEASE;
        }
        break;

    case State::OPEN:
        gain_ = 1.0f;
        if (envDb < threshold) {
            if (holdSamples > 0) {
                state_ = State::HOLD;
                holdCounter_ = holdSamples;
            } else {
                state_ = State::RELEASE;
            }
        }
        break;

    case State::HOLD:
        if (envDb > threshold) {
            state_ = State::OPEN;
            holdCounter_ = holdSamples;
        } else {
            --holdCounter_;
            if (holdCounter_ <= 0) {
                state_ = State::RELEASE;
            }
        }
        break;

    case State::RELEASE:
        gain_ -= gateReleaseCoeff * gain_;
        if (gain_ <= 0.001f) {
            gain_ = 0.0f;
            state_ = State::CLOSED;
        }
        if (envDb > threshold) {
            state_ = State::ATTACK;
        }
        break;
    }

    left = inL * gain_;
    right = inR * gain_;
}

void NoiseGateProcessor::setParam(int index, float value) {
    switch (index) {
    case THRESHOLD: thresholdDb_ = std::clamp(value, -60.0f, 0.0f); break;
    case ATTACK:    attackMs_    = std::clamp(value, 0.1f, 100.0f); break;
    case HOLD:      holdMs_      = std::clamp(value, 0.0f, 500.0f); break;
    case RELEASE:   releaseMs_   = std::clamp(value, 1.0f, 1000.0f); break;
    default: break;
    }
}

float NoiseGateProcessor::getParam(int index) const {
    switch (index) {
    case THRESHOLD: return thresholdDb_;
    case ATTACK:    return attackMs_;
    case HOLD:      return holdMs_;
    case RELEASE:   return releaseMs_;
    default: return 0.0f;
    }
}

const char* NoiseGateProcessor::paramName(int index) const {
    switch (index) {
    case THRESHOLD: return "Threshold";
    case ATTACK:    return "Attack";
    case HOLD:      return "Hold";
    case RELEASE:   return "Release";
    default: return "Unknown";
    }
}

} // namespace opensynth
