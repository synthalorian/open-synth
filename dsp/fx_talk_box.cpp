#include "fx_talk_box.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

// Formant frequencies (Hz) for vowels A, E, I, O, U
const float TalkBoxProcessor::formantFreq_[NUM_VOWELS][NUM_FORMANTS] = {
    { 650.0f, 1080.0f, 2650.0f }, // A
    { 400.0f, 1700.0f, 2600.0f }, // E
    { 290.0f, 1870.0f, 2800.0f }, // I
    { 400.0f,  800.0f, 2600.0f }, // O
    { 350.0f,  600.0f, 2400.0f }, // U
};

const float TalkBoxProcessor::formantAmp_[NUM_VOWELS][NUM_FORMANTS] = {
    { 1.0f, 0.63f, 0.16f }, // A
    { 1.0f, 0.20f, 0.13f }, // E
    { 1.0f, 0.10f, 0.08f }, // I
    { 1.0f, 0.50f, 0.13f }, // O
    { 1.0f, 0.60f, 0.17f }, // U
};

float TalkBoxProcessor::Biquad::process(float in) {
    float out = b0 * in + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
    x2 = x1;
    x1 = in;
    y2 = y1;
    y1 = out;
    return out;
}

TalkBoxProcessor::TalkBoxProcessor()
    : FxProcessor(FxType::TalkBox) {}

void TalkBoxProcessor::reset() {
    for (int i = 0; i < 3; ++i) {
        bpL_[i] = Biquad{};
        bpR_[i] = Biquad{};
    }
    envL_ = 0.0f;
    envR_ = 0.0f;
}

void TalkBoxProcessor::setBandpass(Biquad& bq, float freq, float bw, double sr) {
    float omega = 2.0f * 3.14159265f * freq / static_cast<float>(sr);
    float sinO = std::sin(omega);
    float cosO = std::cos(omega);

    float alpha;
    if (sinO > 1e-6f) {
        float arg = 0.34657359f * bw * omega / sinO; // ln(2)/2
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

    bq.a1 /= a0;
    bq.a2 /= a0;
    bq.b0 /= a0;
    bq.b1 /= a0;
    bq.b2 /= a0;
}

float TalkBoxProcessor::processEnv(float in, float& env, double sr) {
    // Drive controls envelope speed: more drive = faster attack/release = more pronounced
    float attackMs  = 5.0f  - drive_ * 4.5f;   // 5.0 -> 0.5 ms
    float releaseMs = 50.0f - drive_ * 45.0f;  // 50.0 -> 5.0 ms

    float attackCoeff  = 1.0f - std::exp(-1000.0f / (attackMs  * static_cast<float>(sr)));
    float releaseCoeff = 1.0f - std::exp(-1000.0f / (releaseMs * static_cast<float>(sr)));

    float target = std::abs(in);
    float coeff = (target > env) ? attackCoeff : releaseCoeff;
    env += coeff * (target - env);
    return env;
}

void TalkBoxProcessor::processFormant(float inL, float inR, float envL, float envR, float& outL, float& outR) {
    int v = static_cast<int>(std::clamp(vowel_, 0.0f, 4.0f));
    float q = 5.0f + resonance_ * 25.0f;

    // Envelope modulates formant amplitude (more drive = more pronounced envelope)
    float envModL = 1.0f + envL * drive_ * 4.0f;
    float envModR = 1.0f + envR * drive_ * 4.0f;

    outL = 0.0f;
    outR = 0.0f;
    for (int f = 0; f < NUM_FORMANTS; ++f) {
        float fc = formantFreq_[v][f];
        float bw = fc / q;
        setBandpass(bpL_[f], fc, bw, sampleRate_);
        setBandpass(bpR_[f], fc, bw, sampleRate_);
        float amp = formantAmp_[v][f];
        outL += bpL_[f].process(inL) * amp * envModL;
        outR += bpR_[f].process(inR) * amp * envModR;
    }
}

void TalkBoxProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // Envelope followers
    float envL = processEnv(inL, envL_, sampleRate_);
    float envR = processEnv(inR, envR_, sampleRate_);

    float wetL = 0.0f;
    float wetR = 0.0f;
    processFormant(inL, inR, envL, envR, wetL, wetR);

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

void TalkBoxProcessor::setParam(int index, float value) {
    switch (index) {
    case VOWEL:     vowel_ = std::clamp(value, 0.0f, 4.0f); break;
    case RESONANCE: resonance_ = std::clamp(value, 0.0f, 1.0f); break;
    case DRIVE:     drive_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:       mix_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float TalkBoxProcessor::getParam(int index) const {
    switch (index) {
    case VOWEL:     return vowel_;
    case RESONANCE: return resonance_;
    case DRIVE:     return drive_;
    case MIX:       return mix_;
    default: return 0.0f;
    }
}

const char* TalkBoxProcessor::paramName(int index) const {
    switch (index) {
    case VOWEL:     return "Vowel";
    case RESONANCE: return "Resonance";
    case DRIVE:     return "Drive";
    case MIX:       return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
