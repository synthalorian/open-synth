#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// LFO-based stereo panning.
class AutoPanProcessor : public FxProcessor {
public:
    enum Param {
        RATE = 0,   // 0.1 - 20 Hz
        DEPTH = 1,  // 0 - 1
        WAVE = 2,   // 0=sine, 1=triangle, 2=square, 3=saw
        PHASE = 3,  // 0 - 1 (stereo phase offset)
    };

    explicit AutoPanProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float rate_ = 2.0f;
    float depth_ = 0.8f;
    int wave_ = 0;
    float phaseOffset_ = 0.0f;

    double phase_ = 0.0;

    float lfoValue(double ph) const;
};

} // namespace opensynth
