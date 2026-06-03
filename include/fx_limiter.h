#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Brickwall limiter with look-ahead, attack/release, and makeup gain.
class LimiterProcessor : public FxProcessor {
public:
    enum Param {
        THRESHOLD = 0,  // -60 to 0 dB
        RELEASE = 1,    // 1-500 ms
        CEILING = 2,    // -12 to 0 dB
        INPUT_GAIN = 3, // -12 to +12 dB
    };

    explicit LimiterProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float threshold_ = -6.0f;     // dB
    float releaseMs_ = 100.0f;
    float ceiling_ = -1.0f;      // dB
    float inputGain_ = 0.0f;     // dB

    float envelope_ = 1.0f;
    float gainReduction_ = 1.0f;
    double sampleRate_ = 48000.0;
};

} // namespace opensynth
