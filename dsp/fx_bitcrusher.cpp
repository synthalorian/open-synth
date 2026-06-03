#include "fx_bitcrusher.h"
#include <algorithm>

namespace opensynth {

BitcrusherProcessor::BitcrusherProcessor()
    : FxProcessor(FxType::Bitcrusher) {}

void BitcrusherProcessor::process(float& left, float& right, double sampleRate) {
    nativeSampleRate_ = sampleRate;

    float inL = left * (1.0f + drive_ * 3.0f);
    float inR = right * (1.0f + drive_ * 3.0f);

    // Sample rate reduction
    float step = sampleRate_ / nativeSampleRate_;
    phase_ += step;

    if (phase_ >= 1.0f) {
        phase_ -= 1.0f;
        holdL_ = crush(inL);
        holdR_ = crush(inR);
    }

    left = applyMix(left, holdL_);
    right = applyMix(right, holdR_);
}

float BitcrusherProcessor::crush(float sample) {
    // Bit reduction: quantize to N bits
    float levels = std::pow(2.0f, bits_ - 1.0f);
    float quantized = std::round(sample * levels) / levels;
    return std::clamp(quantized, -1.0f, 1.0f);
}

void BitcrusherProcessor::reset() {
    phase_ = 0.0f;
    holdL_ = 0.0f;
    holdR_ = 0.0f;
}

void BitcrusherProcessor::setParam(int index, float value) {
    switch (index) {
    case BITS:        bits_ = std::clamp(value, 1.0f, 16.0f); break;
    case SAMPLE_RATE: sampleRate_ = std::clamp(value, 100.0f, 44100.0f); break;
    case DRIVE:       drive_ = value; break;
    case MIX:         mix_ = value; break;
    default: break;
    }
}

float BitcrusherProcessor::getParam(int index) const {
    switch (index) {
    case BITS:        return bits_;
    case SAMPLE_RATE: return sampleRate_;
    case DRIVE:       return drive_;
    case MIX:         return mix_;
    default: return 0.0f;
    }
}

const char* BitcrusherProcessor::paramName(int index) const {
    switch (index) {
    case BITS:        return "Bits";
    case SAMPLE_RATE: return "Sample Rate";
    case DRIVE:       return "Drive";
    case MIX:         return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
