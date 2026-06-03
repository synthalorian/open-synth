#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Vocoder FX stub.
/// Uses a carrier (synth oscillator) + modulator (simulated with noise/secondary osc)
/// to create a vocoder effect. Full DSP not yet implemented.
class VocoderProcessor : public FxProcessor {
public:
    enum Param {
        BANDS = 0,      // Number of filter bands (4-32)
        CARRIER_TYPE,   // 0=noise, 1=osc
        CARRIER_FREQ,   // Carrier oscillator freq
        FORMANT_SHIFT,  // Formant shift
        MIX             // Wet/dry
    };

    explicit VocoderProcessor();

    void setSampleRate(double sampleRate) override;
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 5; }
    const char* paramName(int index) const override;

private:
    double sampleRate_ = 48000.0;
    int bands_ = 16;
    int carrierType_ = 0;
    float carrierFreq_ = 440.0f;
    float formantShift_ = 0.0f;
    float mix_ = 0.5f;
    float phase_ = 0.0f;

    // Simple noise generator
    float noise() const;
};

} // namespace opensynth
