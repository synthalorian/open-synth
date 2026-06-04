#include "fx_formant_filter.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

// Formant frequencies (Hz) for vowels A, E, I, O, U
const float FormantFilterProcessor::formantFreq_[NUM_VOWELS][NUM_FORMANTS] = {
    { 650.0f, 1080.0f, 2650.0f }, // A
    { 400.0f, 1700.0f, 2600.0f }, // E
    { 290.0f, 1870.0f, 2800.0f }, // I
    { 400.0f,  800.0f, 2600.0f }, // O
    { 350.0f,  600.0f, 2400.0f }, // U
};

const float FormantFilterProcessor::formantAmp_[NUM_VOWELS][NUM_FORMANTS] = {
    { 1.0f, 0.63f, 0.16f }, // A
    { 1.0f, 0.20f, 0.13f }, // E
    { 1.0f, 0.10f, 0.08f }, // I
    { 1.0f, 0.50f, 0.13f }, // O
    { 1.0f, 0.60f, 0.17f }, // U
};

float FormantFilterProcessor::Biquad::process(float in) {
    float out = b0 * in + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
    x2 = x1;
    x1 = in;
    y2 = y1;
    y1 = out;
    return out;
}

FormantFilterProcessor::FormantFilterProcessor()
    : FxProcessor(FxType::FormantFilter) {}

void FormantFilterProcessor::reset() {
    for (int i = 0; i < 3; ++i) {
        bpL_[i] = Biquad{};
        bpR_[i] = Biquad{};
    }
    sweepPhase_ = 0.0f;
}

void FormantFilterProcessor::setBandpass(Biquad& bq, float freq, float bw, double sr) {
    float omega = 2.0f * 3.14159265f * freq / static_cast<float>(sr);
    float sinO = std::sin(omega);
    float cosO = std::cos(omega);

    // Compute alpha safely: alpha = sinO * sinh( ln(2)/2 * bw * omega / sinO )
    // When sinO is very small (near DC), fall back to a safe approximation.
    float alpha;
    if (sinO > 1e-6f) {
        float arg = 0.34657359f * bw * omega / sinO; // ln(2)/2 ≈ 0.34657359
        // For small x, sinh(x) ≈ x. Clamp arg to avoid overflow.
        arg = std::clamp(arg, -10.0f, 10.0f);
        alpha = sinO * std::sinh(arg);
    } else {
        alpha = 0.01f;
    }
    if (std::isnan(alpha) || std::isinf(alpha) || alpha <= 0.0f) {
        alpha = 0.01f;
    }

    float a0 = 1.0f + alpha;
    bq.a0 = a0;
    bq.a1 = -2.0f * cosO;
    bq.a2 = 1.0f - alpha;
    bq.b0 = alpha;
    bq.b1 = 0.0f;
    bq.b2 = -alpha;

    // Normalize
    bq.a1 /= a0;
    bq.a2 /= a0;
    bq.b0 /= a0;
    bq.b1 /= a0;
    bq.b2 /= a0;
}

void FormantFilterProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // Continuous vowel index with sweep
    float sweepSpeed = sweep_ * 2.0f; // up to 2 cycles per second
    sweepPhase_ += sweepSpeed / static_cast<float>(sampleRate_);
    if (sweepPhase_ >= 1.0f) sweepPhase_ -= 1.0f;

    float continuousVowel = vowel_ + sweepPhase_ * 4.0f;
    if (continuousVowel >= 4.0f) continuousVowel -= 4.0f;

    int v0 = static_cast<int>(continuousVowel) % NUM_VOWELS;
    int v1 = (v0 + 1) % NUM_VOWELS;
    float morph = continuousVowel - static_cast<float>(v0);

    // Quality factor derived from resonance (higher resonance = narrower bands)
    float q = 5.0f + resonance_ * 25.0f;

    // Update filter coefficients for morphed frequencies
    for (int f = 0; f < NUM_FORMANTS; ++f) {
        float f0 = formantFreq_[v0][f];
        float f1 = formantFreq_[v1][f];
        float fc = f0 + (f1 - f0) * morph;
        float bw = fc / q;
        setBandpass(bpL_[f], fc, bw, sampleRate_);
        setBandpass(bpR_[f], fc, bw, sampleRate_);
    }

    float wetL = 0.0f;
    float wetR = 0.0f;
    for (int f = 0; f < NUM_FORMANTS; ++f) {
        float amp0 = formantAmp_[v0][f];
        float amp1 = formantAmp_[v1][f];
        float amp = amp0 + (amp1 - amp0) * morph;
        wetL += bpL_[f].process(inL) * amp;
        wetR += bpR_[f].process(inR) * amp;
    }

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

void FormantFilterProcessor::setParam(int index, float value) {
    switch (index) {
    case VOWEL:     vowel_ = std::clamp(value, 0.0f, 4.0f); break;
    case RESONANCE: resonance_ = std::clamp(value, 0.0f, 1.0f); break;
    case SWEEP:     sweep_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:       mix_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float FormantFilterProcessor::getParam(int index) const {
    switch (index) {
    case VOWEL:     return vowel_;
    case RESONANCE: return resonance_;
    case SWEEP:     return sweep_;
    case MIX:       return mix_;
    default: return 0.0f;
    }
}

const char* FormantFilterProcessor::paramName(int index) const {
    switch (index) {
    case VOWEL:     return "Vowel";
    case RESONANCE: return "Resonance";
    case SWEEP:     return "Sweep";
    case MIX:       return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
