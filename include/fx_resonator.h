#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Modal resonator using 4 parallel bandpass filters.
class ResonatorProcessor : public FxProcessor {
public:
    enum Param {
        FREQ = 0,     // 20 - 5000 Hz
        DECAY = 1,    // 0 - 1
        MATERIAL = 2, // 0 - 1 (stiffness / detune amount)
        MIX = 3,
    };

    explicit ResonatorProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float freq_ = 440.0f;
    float decay_ = 0.5f;
    float material_ = 0.5f;

    double sampleRate_ = 48000.0;

    struct Bandpass {
        float z1L = 0.0f, z2L = 0.0f;
        float z1R = 0.0f, z2R = 0.0f;
        float a0 = 1.0f, a1 = 0.0f, a2 = 0.0f;
        float b0 = 1.0f, b1 = 0.0f, b2 = 0.0f;

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

        void setCoeffs(float freq, float q, double sr);
    };

    Bandpass bp_[4];
    bool coeffsDirty_ = true;

    void updateCoeffs();
};

} // namespace opensynth
