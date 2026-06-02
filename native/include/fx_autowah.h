#pragma once
#include "fx_engine.h"
#include <cmath>

namespace openamp {

/// Auto-wah / envelope filter.
/// A resonant lowpass filter whose cutoff tracks the input signal envelope.
class AutoWahProcessor : public FxProcessor {
public:
    enum Param {
        SENSITIVITY = 0, // 0 - 1 (envelope tracking amount)
        RESONANCE   = 1, // 0 - 1 (filter Q)
        RANGE       = 2, // 0 - 1 (cutoff sweep range)
        ATTACK      = 3, // 1 - 100 ms
        RELEASE     = 4, // 10 - 500 ms
        MIX         = 5, // 0 - 1
    };

    explicit AutoWahProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 6; }
    const char* paramName(int index) const override;

private:
    float sensitivity_ = 0.7f;
    float resonance_ = 0.6f;
    float range_ = 0.8f;
    float attackMs_ = 5.0f;
    float releaseMs_ = 80.0f;

    float envelope_ = 0.0f;
    float cutoff_ = 200.0f;

    // State variable filter state
    float lpL_ = 0.0f, bpL_ = 0.0f;
    float lpR_ = 0.0f, bpR_ = 0.0f;

    double sampleRate_ = 48000.0;

    void updateEnvelope(float input);
    float processFilter(float input, float& lp, float& bp, float cutoff, float q);
};

} // namespace openamp
