#include "fx_vocoder.h"
#include <cmath>
#include <cstdlib>

namespace openamp {

VocoderProcessor::VocoderProcessor()
    : FxProcessor(FxType::Vocoder)
{
}

void VocoderProcessor::setSampleRate(double sampleRate)
{
    sampleRate_ = sampleRate;
}

void VocoderProcessor::process(float& left, float& right, double /*sampleRate*/)
{
    // Stub: simple carrier + modulator simulation
    // For now, just mix carrier signal with input based on parameters
    float carrier = 0.0f;
    if (carrierType_ == 0) {
        carrier = noise();
    } else {
        phase_ += static_cast<float>(carrierFreq_ / sampleRate_);
        if (phase_ >= 1.0f) phase_ -= 1.0f;
        carrier = std::sin(phase_ * 6.28318530718f);
    }

    // Very basic "vocoder" effect: amplitude-modulate carrier with input envelope
    float inputEnv = (std::abs(left) + std::abs(right)) * 0.5f;
    float wetL = carrier * inputEnv;
    float wetR = carrier * inputEnv;

    left = applyMix(left, wetL);
    right = applyMix(right, wetR);
}

void VocoderProcessor::reset()
{
    phase_ = 0.0f;
}

void VocoderProcessor::setParam(int index, float value)
{
    switch (index) {
    case BANDS:        bands_ = static_cast<int>(value); break;
    case CARRIER_TYPE: carrierType_ = static_cast<int>(value); break;
    case CARRIER_FREQ: carrierFreq_ = value; break;
    case FORMANT_SHIFT: formantShift_ = value; break;
    case MIX:          mix_ = value; setMix(value); break;
    }
}

float VocoderProcessor::getParam(int index) const
{
    switch (index) {
    case BANDS:        return static_cast<float>(bands_);
    case CARRIER_TYPE: return static_cast<float>(carrierType_);
    case CARRIER_FREQ: return carrierFreq_;
    case FORMANT_SHIFT: return formantShift_;
    case MIX:          return mix_;
    }
    return 0.0f;
}

const char* VocoderProcessor::paramName(int index) const
{
    switch (index) {
    case BANDS:        return "Bands";
    case CARRIER_TYPE: return "Carrier";
    case CARRIER_FREQ: return "Freq";
    case FORMANT_SHIFT: return "Formant";
    case MIX:          return "Mix";
    }
    return "";
}

float VocoderProcessor::noise() const
{
    return (static_cast<float>(std::rand()) / RAND_MAX) * 2.0f - 1.0f;
}

} // namespace openamp
