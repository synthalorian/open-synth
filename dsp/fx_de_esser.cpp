#include "fx_de_esser.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

float DeEsserProcessor::Biquad::process(float in) {
    float out = b0 * in + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
    x2 = x1;
    x1 = in;
    y2 = y1;
    y1 = out;
    return out;
}

DeEsserProcessor::DeEsserProcessor()
    : FxProcessor(FxType::DeEsser) {}

void DeEsserProcessor::reset() {
    bpL_ = Biquad{};
    bpR_ = Biquad{};
    envL_ = 0.0f;
    envR_ = 0.0f;
}

float DeEsserProcessor::dbToLinear(float db) const {
    return std::pow(10.0f, db / 20.0f);
}

float DeEsserProcessor::linearToDb(float lin) const {
    if (lin <= 0.0f) return -120.0f;
    return 20.0f * std::log10(lin);
}

void DeEsserProcessor::setBandpass(Biquad& bq, float freq, double sr) {
    float omega = 2.0f * 3.14159265f * freq / static_cast<float>(sr);
    float sinO = std::sin(omega);
    float cosO = std::cos(omega);
    float q = 2.0f; // fairly narrow
    float alpha = sinO / (2.0f * q);

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

void DeEsserProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // Update bandpass
    setBandpass(bpL_, freq_, sampleRate_);
    setBandpass(bpR_, freq_, sampleRate_);

    // Bandpass the signal to isolate sibilance
    float bpOutL = bpL_.process(inL);
    float bpOutR = bpR_.process(inR);

    // Envelope follower on bandpass output
    // Fast attack (0.2 ms) and medium release (5 ms) to catch sibilance
    float attackCoeff  = 1.0f - std::exp(-1.0f / (0.0002f * static_cast<float>(sampleRate_)));
    float releaseCoeff = 1.0f - std::exp(-1.0f / (0.005f  * static_cast<float>(sampleRate_)));

    float targetL = std::abs(bpOutL);
    float targetR = std::abs(bpOutR);
    float coeffL = (targetL > envL_) ? attackCoeff : releaseCoeff;
    float coeffR = (targetR > envR_) ? attackCoeff : releaseCoeff;
    envL_ += coeffL * (targetL - envL_);
    envR_ += coeffR * (targetR - envR_);

    float envDbL = linearToDb(envL_);
    float envDbR = linearToDb(envR_);

    // Compression gain reduction when bandpass exceeds threshold
    // Amount controls ratio: 0 = no reduction, 1 = strong reduction
    float threshold = thresholdDb_;
    float gainL = 1.0f;
    float gainR = 1.0f;

    if (envDbL > threshold) {
        float reduction = (envDbL - threshold) * amount_ * 3.0f;
        gainL = dbToLinear(-reduction);
    }
    if (envDbR > threshold) {
        float reduction = (envDbR - threshold) * amount_ * 3.0f;
        gainR = dbToLinear(-reduction);
    }

    float wetL = inL * gainL;
    float wetR = inR * gainR;

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

void DeEsserProcessor::setParam(int index, float value) {
    switch (index) {
    case FREQ:      freq_ = std::clamp(value, 2000.0f, 16000.0f); break;
    case THRESHOLD: thresholdDb_ = std::clamp(value, -40.0f, 0.0f); break;
    case AMOUNT:    amount_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:       mix_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float DeEsserProcessor::getParam(int index) const {
    switch (index) {
    case FREQ:      return freq_;
    case THRESHOLD: return thresholdDb_;
    case AMOUNT:    return amount_;
    case MIX:       return mix_;
    default: return 0.0f;
    }
}

const char* DeEsserProcessor::paramName(int index) const {
    switch (index) {
    case FREQ:      return "Freq";
    case THRESHOLD: return "Threshold";
    case AMOUNT:    return "Amount";
    case MIX:       return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
