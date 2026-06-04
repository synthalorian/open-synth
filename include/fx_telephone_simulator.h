#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Telephone bandpass: 300Hz-3.4kHz with resonance, optional clipping.
class TelephoneSimulatorProcessor : public FxProcessor {
public:
    enum Param {
        QUALITY = 0,    // 0 - 1 (resonance / filter steepness)
        DISTORTION = 1, // 0 - 1 (clipping amount)
        MIX = 2,        // 0 - 1
    };

    explicit TelephoneSimulatorProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 3; }
    const char* paramName(int index) const override;

private:
    float quality_ = 0.5f;
    float distortion_ = 0.2f;

    // 2-pole bandpass state variables (SVF)
    float z1L_ = 0.0f, z2L_ = 0.0f;
    float z1R_ = 0.0f, z2R_ = 0.0f;

    double nativeSampleRate_ = 48000.0;

    float bandpassSVF(float input, float& z1, float& z2, float freq, float q, double sr);
    float distort(float sample);
};

} // namespace opensynth
