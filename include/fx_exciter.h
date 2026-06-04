#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Harmonic exciter using highpass + tanh distortion + bandpass.
class ExciterProcessor : public FxProcessor {
public:
    enum Param {
        AMOUNT = 0,    // 0 - 1
        FREQ = 1,      // 1000 - 10000 Hz
        HARMONICS = 2, // 0 - 1 (even vs odd mix)
        MIX = 3,
    };

    explicit ExciterProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float amount_ = 0.3f;
    float freq_ = 3000.0f;
    float harmonics_ = 0.5f;

    double sampleRate_ = 48000.0;

    // Highpass state for input filtering
    float hpL_ = 0.0f, hpR_ = 0.0f;
    // Bandpass state (2-pole)
    float bp1L_ = 0.0f, bp2L_ = 0.0f;
    float bp1R_ = 0.0f, bp2R_ = 0.0f;

    void updateFilters(double sr);
    float highpass(float in, float& state, float coeff);
    float bandpass(float in, float& s1, float& s2, float coeff);
};

} // namespace opensynth
