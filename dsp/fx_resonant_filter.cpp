#include "fx_resonant_filter.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

ResonantFilterProcessor::ResonantFilterProcessor()
    : FxProcessor(FxType::ResonantFilter) {}

void ResonantFilterProcessor::reset() {
    lowL_ = bandL_ = highL_ = 0.0f;
    lowR_ = bandR_ = highR_ = 0.0f;
    envL_ = envR_ = 0.0f;
}

void ResonantFilterProcessor::updateCoeffs(float fc, float q, double sr, float& f, float& q1) {
    // Chamberlin SVF coefficients
    float normFc = std::clamp(fc / static_cast<float>(sr), 0.0f, 0.49f);
    f = 2.0f * std::sin(3.14159265f * normFc);
    // q is damping: 1.0 = no resonance, 0.0 = max resonance
    q1 = std::clamp(q, 0.001f, 1.0f);
}

float ResonantFilterProcessor::processSVF(float in, float& low, float& band, float& high, float f, float q1) {
    // Chamberlin state-variable filter (lowpass output)
    low = low + f * band;
    high = in - low - q1 * band;
    band = f * high + band;
    // Optional notch: low + high
    return low;
}

float ResonantFilterProcessor::processEnv(float in, float& env, double sr) {
    float target = std::abs(in);
    // Time constants in seconds
    float attackTime = 0.001f;   // 1 ms
    float releaseTime = 0.020f;  // 20 ms
    float attackCoeff = 1.0f - std::exp(-1.0f / (attackTime * static_cast<float>(sr)));
    float releaseCoeff = 1.0f - std::exp(-1.0f / (releaseTime * static_cast<float>(sr)));
    float coeff = (target > env) ? attackCoeff : releaseCoeff;
    env += coeff * (target - env);
    return env;
}

void ResonantFilterProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // Envelope followers
    float envL = processEnv(inL, envL_, sampleRate_);
    float envR = processEnv(inR, envR_, sampleRate_);

    // Modulate cutoff by envelope (up to +2 octaves at max env amount)
    float envModL = 1.0f + envL * envAmount_ * 3.0f;
    float envModR = 1.0f + envR * envAmount_ * 3.0f;
    float modCutoffL = cutoff_ * envModL;
    float modCutoffR = cutoff_ * envModR;
    modCutoffL = std::clamp(modCutoffL, 20.0f, static_cast<float>(sampleRate_ * 0.49));
    modCutoffR = std::clamp(modCutoffR, 20.0f, static_cast<float>(sampleRate_ * 0.49));

    // Damping: higher resonance = lower damping (more ringing)
    float damping = 1.0f - resonance_ * 0.99f;

    float fL, q1L;
    float fR, q1R;
    updateCoeffs(modCutoffL, damping, sampleRate_, fL, q1L);
    updateCoeffs(modCutoffR, damping, sampleRate_, fR, q1R);

    float wetL = processSVF(inL, lowL_, bandL_, highL_, fL, q1L);
    float wetR = processSVF(inR, lowR_, bandR_, highR_, fR, q1R);

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

void ResonantFilterProcessor::setParam(int index, float value) {
    switch (index) {
    case CUTOFF:    cutoff_ = std::clamp(value, 20.0f, 20000.0f); break;
    case RESONANCE: resonance_ = std::clamp(value, 0.0f, 1.0f); break;
    case ENV:       envAmount_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:       mix_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float ResonantFilterProcessor::getParam(int index) const {
    switch (index) {
    case CUTOFF:    return cutoff_;
    case RESONANCE: return resonance_;
    case ENV:       return envAmount_;
    case MIX:       return mix_;
    default: return 0.0f;
    }
}

const char* ResonantFilterProcessor::paramName(int index) const {
    switch (index) {
    case CUTOFF:    return "Cutoff";
    case RESONANCE: return "Resonance";
    case ENV:       return "Env";
    case MIX:       return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
