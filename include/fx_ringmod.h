#pragma once
#include "fx_engine.h"
#include <cmath>

namespace openamp {

/// Ring modulator: multiplies input by a carrier sine wave.
class RingModProcessor : public FxProcessor {
public:
    enum Param {
        FREQUENCY = 0, // 20 - 5000 Hz carrier
        STEREO_OFFSET = 1, // 0 - 1 (L/R frequency offset)
        MIX = 2,
    };

    explicit RingModProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 3; }
    const char* paramName(int index) const override;

private:
    float frequency_ = 440.0f;
    float stereoOffset_ = 0.1f;

    double phaseL_ = 0.0;
    double phaseR_ = 0.0;
    double sampleRate_ = 48000.0;
};

} // namespace openamp
