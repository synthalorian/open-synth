#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Hard clipping distortion with 4 types (Soft, Hard, Fold, Asymmetric).
class DistortionProcessor : public FxProcessor {
public:
    enum Param {
        DRIVE = 0,  // 0 - 1
        TONE = 1,   // 0 - 1 (post-filter)
        LEVEL = 2,  // 0 - 1
        TYPE = 3,   // 0 - 3 (Soft, Hard, Fold, Asymmetric)
    };

    explicit DistortionProcessor();
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
    int type_ = 0;

    // 1-pole tone filter state
    float toneStateL_ = 0.0f;
    float toneStateR_ = 0.0f;
    double sampleRate_ = 48000.0;

    float distort(float sample);
    float toneFilter(float input, float& state);
};

} // namespace opensynth
