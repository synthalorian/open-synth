#include "fx_ringmod.h"

namespace opensynth {

RingModProcessor::RingModProcessor()
    : FxProcessor(FxType::RingMod) {}

void RingModProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    float carrierL = std::sin(phaseL_);
    float carrierR = std::sin(phaseR_);

    float wetL = inL * carrierL;
    float wetR = inR * carrierR;

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);

    double freqL = frequency_;
    double freqR = frequency_ * (1.0 + stereoOffset_ * 0.05);

    phaseL_ += 2.0 * 3.14159265358979 * freqL / sampleRate_;
    phaseR_ += 2.0 * 3.14159265358979 * freqR / sampleRate_;

    while (phaseL_ > 2.0 * 3.14159265358979) phaseL_ -= 2.0 * 3.14159265358979;
    while (phaseR_ > 2.0 * 3.14159265358979) phaseR_ -= 2.0 * 3.14159265358979;
}

void RingModProcessor::reset() {
    phaseL_ = 0.0;
    phaseR_ = 0.0;
}

void RingModProcessor::setParam(int index, float value) {
    switch (index) {
    case FREQUENCY:     frequency_ = value; break;
    case STEREO_OFFSET: stereoOffset_ = value; break;
    case MIX:           mix_ = value; break;
    default: break;
    }
}

float RingModProcessor::getParam(int index) const {
    switch (index) {
    case FREQUENCY:     return frequency_;
    case STEREO_OFFSET: return stereoOffset_;
    case MIX:           return mix_;
    default: return 0.0f;
    }
}

const char* RingModProcessor::paramName(int index) const {
    switch (index) {
    case FREQUENCY:     return "Frequency";
    case STEREO_OFFSET: return "Stereo Offset";
    case MIX:           return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
