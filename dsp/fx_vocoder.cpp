#include "fx_vocoder.h"
#include <algorithm>
#include <cstdlib>

namespace opensynth {

VocoderProcessor::VocoderProcessor()
    : FxProcessor(FxType::Vocoder)
{
    envL_.fill(0.0f);
    envR_.fill(0.0f);
    b0_.fill(0.0f);
    b1_.fill(0.0f);
    b2_.fill(0.0f);
    a1_.fill(0.0f);
    a2_.fill(0.0f);
}

void VocoderProcessor::reset() {
    phase_ = 0.0f;
    envL_.fill(0.0f);
    envR_.fill(0.0f);
    for (int i = 0; i < MAX_BANDS; ++i) {
        modL_[i] = {};
        modR_[i] = {};
        carL_[i] = {};
        carR_[i] = {};
    }
}

float VocoderProcessor::noise() {
    return (static_cast<float>(std::rand()) / static_cast<float>(RAND_MAX)) * 2.0f - 1.0f;
}

float VocoderProcessor::generateCarrier() {
    float carrier = 0.0f;
    switch (carrierType_) {
    case 0: // noise
        carrier = noise();
        break;
    case 1: { // saw
        phase_ += 100.0f / static_cast<float>(sampleRate_);
        if (phase_ >= 1.0f) phase_ -= 1.0f;
        carrier = phase_ * 2.0f - 1.0f;
        break;
    }
    case 2: { // square
        phase_ += 100.0f / static_cast<float>(sampleRate_);
        if (phase_ >= 1.0f) phase_ -= 1.0f;
        carrier = (phase_ < 0.5f) ? 1.0f : -1.0f;
        break;
    }
    default:
        carrier = noise();
        break;
    }
    return carrier;
}

void VocoderProcessor::updateFilters() {
    // Log-spaced bandpass filters
    float minFreq = 100.0f;
    float maxFreq = 8000.0f * range_ + 500.0f;
    if (maxFreq < minFreq * 2.0f) maxFreq = minFreq * 2.0f;

    float logMin = std::log10(minFreq);
    float logMax = std::log10(maxFreq);

    for (int i = 0; i < bands_; ++i) {
        float t = (bands_ > 1) ? static_cast<float>(i) / static_cast<float>(bands_ - 1) : 0.0f;
        float freq = std::pow(10.0f, logMin + t * (logMax - logMin));
        float bw = (maxFreq - minFreq) / static_cast<float>(bands_) * 0.5f;
        float q = freq / bw;
        if (q < 0.5f) q = 0.5f;
        if (q > 20.0f) q = 20.0f;

        // Biquad bandpass coefficients (constant Q)
        float w0 = 2.0f * 3.14159265f * freq / static_cast<float>(sampleRate_);
        float cosw0 = std::cos(w0);
        float sinw0 = std::sin(w0);
        float alpha = sinw0 / (2.0f * q);

        float a0 = 1.0f + alpha;
        b0_[i] = alpha / a0;
        b1_[i] = 0.0f;
        b2_[i] = -alpha / a0;
        a1_[i] = -2.0f * cosw0 / a0;
        a2_[i] = (1.0f - alpha) / a0;
    }
}

float VocoderProcessor::processFilter(float input, FilterState& s, float b0, float b1, float b2, float a1, float a2) {
    float out = b0 * input + b1 * s.x1 + b2 * s.x2 - a1 * s.y1 - a2 * s.y2;
    s.x2 = s.x1;
    s.x1 = input;
    s.y2 = s.y1;
    s.y1 = out;
    return out;
}

void VocoderProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;
    updateFilters();

    float carrier = generateCarrier();

    float wetL = 0.0f;
    float wetR = 0.0f;

    float attackCoeff = 0.0f;   // instant attack
    float releaseCoeff = 0.92f; // medium release

    for (int i = 0; i < bands_; ++i) {
        // Filter modulator (input signal)
        float modBandL = processFilter(left, modL_[i], b0_[i], b1_[i], b2_[i], a1_[i], a2_[i]);
        float modBandR = processFilter(right, modR_[i], b0_[i], b1_[i], b2_[i], a1_[i], a2_[i]);

        // Envelope follow each band
        float absModL = std::abs(modBandL);
        float absModR = std::abs(modBandR);

        if (absModL > envL_[i]) {
            envL_[i] = absModL;
        } else {
            envL_[i] = releaseCoeff * envL_[i] + (1.0f - releaseCoeff) * absModL;
        }

        if (absModR > envR_[i]) {
            envR_[i] = absModR;
        } else {
            envR_[i] = releaseCoeff * envR_[i] + (1.0f - releaseCoeff) * absModR;
        }

        // Filter carrier
        float carBandL = processFilter(carrier, carL_[i], b0_[i], b1_[i], b2_[i], a1_[i], a2_[i]);
        float carBandR = processFilter(carrier, carR_[i], b0_[i], b1_[i], b2_[i], a1_[i], a2_[i]);

        // Apply envelope to carrier
        wetL += carBandL * envL_[i];
        wetR += carBandR * envR_[i];
    }

    // Normalize by number of bands to prevent excessive gain buildup
    float norm = 1.0f / std::sqrt(static_cast<float>(bands_));
    wetL *= norm;
    wetR *= norm;

    // Soft clip
    wetL = std::tanh(wetL);
    wetR = std::tanh(wetR);

    left = applyMix(left, wetL);
    right = applyMix(right, wetR);
}

void VocoderProcessor::setParam(int index, float value) {
    switch (index) {
    case BANDS:    bands_ = std::clamp(static_cast<int>(value), 4, MAX_BANDS); break;
    case RANGE:    range_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:      mix_ = std::clamp(value, 0.0f, 1.0f); break;
    case CARRIER:  carrierType_ = std::clamp(static_cast<int>(value), 0, 2); break;
    default: break;
    }
}

float VocoderProcessor::getParam(int index) const {
    switch (index) {
    case BANDS:    return static_cast<float>(bands_);
    case RANGE:    return range_;
    case MIX:      return mix_;
    case CARRIER:  return static_cast<float>(carrierType_);
    default: return 0.0f;
    }
}

const char* VocoderProcessor::paramName(int index) const {
    switch (index) {
    case BANDS:    return "Bands";
    case RANGE:    return "Range";
    case MIX:      return "Mix";
    case CARRIER:  return "Carrier";
    default: return "Unknown";
    }
}

} // namespace opensynth
