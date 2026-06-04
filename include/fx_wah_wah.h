#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Manual wah-wah using a resonant bandpass (state variable filter).
class WahWahProcessor : public FxProcessor {
public:
    enum Param {
        POSITION = 0, // 0 - 1 (cutoff sweep)
        RANGE = 1,    // 0 - 1 (sweep width)
        Q = 2,        // 0 - 1 (resonance)
        MIX = 3,      // 0 - 1
    };

    explicit WahWahProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float position_ = 0.5f;
    float range_ = 0.5f;
    float q_ = 0.5f;

    // State variable filter states (left/right)
    float bandL_ = 0.0f, lowL_ = 0.0f, highL_ = 0.0f;
    float bandR_ = 0.0f, lowR_ = 0.0f, highR_ = 0.0f;
    double sampleRate_ = 48000.0;

    void updateCoefficients(double& f, double& q);
    float processBandpass(float input, float& band, float& low, float& high, double f, double q);
};

} // namespace opensynth
