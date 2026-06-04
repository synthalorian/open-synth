#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Classic fuzz face style: hard clip with high gain and RC tone filter.
class FuzzProcessor : public FxProcessor {
public:
    enum Param {
        AMOUNT = 0,  // 0 - 1 (gain)
        TONE = 1,    // 0 - 1
        LEVEL = 2,   // 0 - 1
        SUSTAIN = 3, // 0 - 1 (clip threshold / compression)
    };

    explicit FuzzProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float amount_ = 0.5f;
    float tone_ = 0.5f;
    float level_ = 0.5f;
    float sustain_ = 0.5f;

    // RC tone filter state (simple 1-pole)
    float toneStateL_ = 0.0f;
    float toneStateR_ = 0.0f;
    double sampleRate_ = 48000.0;

    float distort(float sample);
    float toneFilter(float input, float& state);
};

} // namespace opensynth
