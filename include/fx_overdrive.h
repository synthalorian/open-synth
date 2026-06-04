#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Warm tube overdrive with even-harmonic bias.
class OverdriveProcessor : public FxProcessor {
public:
    enum Param {
        DRIVE = 0,   // 0 - 1
        TONE = 1,    // 0 - 1
        LEVEL = 2,   // 0 - 1
        WARMTH = 3,  // 0 - 1 (even-harmonic bias)
    };

    explicit OverdriveProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float drive_ = 0.5f;
    float tone_ = 0.5f;
    float level_ = 0.5f;
    float warmth_ = 0.5f;

    // 1-pole tone filter state
    float toneStateL_ = 0.0f;
    float toneStateR_ = 0.0f;
    double sampleRate_ = 48000.0;

    float distort(float sample);
    float toneFilter(float input, float& state);
};

} // namespace opensynth
