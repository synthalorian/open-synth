#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Tube saturation with per-sample bias control for asymmetry.
class TubeDriveProcessor : public FxProcessor {
public:
    enum Param {
        DRIVE = 0,   // 0 - 1
        BIAS = 1,    // 0 - 1 (asymmetry)
        TONE = 2,    // 0 - 1
        OUTPUT = 3,  // 0 - 1
    };

    explicit TubeDriveProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float drive_ = 0.5f;
    float bias_ = 0.5f;
    float tone_ = 0.5f;
    float output_ = 0.5f;

    // 1-pole tone filter state
    float toneStateL_ = 0.0f;
    float toneStateR_ = 0.0f;
    double sampleRate_ = 48000.0;

    float distort(float sample);
    float toneFilter(float input, float& state);
};

} // namespace opensynth
