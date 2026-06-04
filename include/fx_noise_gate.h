#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Noise gate with attack / hold / release stages.
/// Params: Threshold (-60 to 0 dB), Attack (0.1-100 ms), Hold (0-500 ms), Release (1-1000 ms).
class NoiseGateProcessor : public FxProcessor {
public:
    enum Param {
        THRESHOLD = 0, // -60 to 0 dB
        ATTACK = 1,    // 0.1 - 100 ms
        HOLD = 2,      // 0 - 500 ms
        RELEASE = 3,   // 1 - 1000 ms
    };

    explicit NoiseGateProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float thresholdDb_ = -40.0f;
    float attackMs_ = 1.0f;
    float holdMs_ = 0.0f;
    float releaseMs_ = 100.0f;

    double sampleRate_ = 48000.0;

    // Envelope follower state
    float env_ = 0.0f;

    // Gate state machine
    enum class State { OPEN, ATTACK, HOLD, RELEASE, CLOSED };
    State state_ = State::CLOSED;
    float gain_ = 0.0f;
    int holdCounter_ = 0;

    float dbToLinear(float db) const;
    float linearToDb(float lin) const;
};

} // namespace opensynth
