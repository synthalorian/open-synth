#pragma once
#include "fx_engine.h"
#include <cmath>
#include <algorithm>

namespace opensynth {

/// Transient designer: boosts or cuts attack and sustain of a signal.
class TransientShaperProcessor : public FxProcessor {
public:
    enum Param {
        ATTACK = 0,     // -1 to +1
        SUSTAIN = 1,    // -1 to +1
        SENSITIVITY = 2,// 0 to 1
        MIX = 3,        // 0 to 1
    };

    explicit TransientShaperProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float attack_ = 0.0f;
    float sustain_ = 0.0f;
    float sensitivity_ = 0.5f;

    // Envelope followers
    float fastEnvL_ = 0.0f, fastEnvR_ = 0.0f;
    float slowEnvL_ = 0.0f, slowEnvR_ = 0.0f;

    double sampleRate_ = 48000.0;

    float processChannel(float sample, float& fastEnv, float& slowEnv);
};

} // namespace opensynth
