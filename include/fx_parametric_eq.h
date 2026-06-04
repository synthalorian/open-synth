#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// 4-band parametric EQ: low shelf, mid peaking, high shelf.
class ParametricEQProcessor : public FxProcessor {
public:
    enum Param {
        LOW_FREQ = 0,   // 20 - 500 Hz
        LOW_GAIN = 1,   // -18 to +18 dB
        MID_FREQ = 2,   // 200 - 8000 Hz
        MID_GAIN = 3,   // -18 to +18 dB
        MID_Q = 4,      // 0.1 - 10
        HIGH_FREQ = 5,  // 1000 - 20000 Hz
        HIGH_GAIN = 6,  // -18 to +18 dB
        MIX = 7,
    };

    explicit ParametricEQProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 8; }
    const char* paramName(int index) const override;

private:
    float lowFreq_ = 250.0f;
    float lowGain_ = 0.0f;
    float midFreq_ = 2000.0f;
    float midGain_ = 0.0f;
    float midQ_ = 1.0f;
    float highFreq_ = 8000.0f;
    float highGain_ = 0.0f;

    double sampleRate_ = 48000.0;
    bool coeffsDirty_ = true;

    struct Biquad {
        float a0 = 1.0f, a1 = 0.0f, a2 = 0.0f;
        float b0 = 1.0f, b1 = 0.0f, b2 = 0.0f;
        float z1L = 0.0f, z2L = 0.0f;
        float z1R = 0.0f, z2R = 0.0f;

        void reset() { z1L = z2L = z1R = z2R = 0.0f; }

        float processL(float in) {
            float out = b0 * in + b1 * z1L + b2 * z2L - a1 * z1L - a2 * z2L;
            z2L = z1L;
            z1L = out;
            return out;
        }

        float processR(float in) {
            float out = b0 * in + b1 * z1R + b2 * z2R - a1 * z1R - a2 * z2R;
            z2R = z1R;
            z1R = out;
            return out;
        }
    };

    Biquad lowShelf_, peak_, highShelf_;

    void updateCoeffs();
    void calcLowShelf(Biquad& b, float freq, float gainDb, double sr);
    void calcPeaking(Biquad& b, float freq, float gainDb, float q, double sr);
    void calcHighShelf(Biquad& b, float freq, float gainDb, double sr);
};

} // namespace opensynth
