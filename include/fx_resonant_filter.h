#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// State-variable resonant filter (Chamberlin SVF).
/// Params: Cutoff (20-20000 Hz), Resonance (0-1), Env (envelope follower amount), Mix.
class ResonantFilterProcessor : public FxProcessor {
public:
    enum Param {
        CUTOFF = 0,    // 20 - 20000 Hz
        RESONANCE = 1, // 0 - 1
        ENV = 2,       // 0 - 1 (envelope follower amount)
        MIX = 3,       // 0 - 1
    };

    explicit ResonantFilterProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float cutoff_ = 2000.0f;
    float resonance_ = 0.5f;
    float envAmount_ = 0.0f;

    // SVF state (per channel)
    float lowL_ = 0.0f, bandL_ = 0.0f, highL_ = 0.0f;
    float lowR_ = 0.0f, bandR_ = 0.0f, highR_ = 0.0f;

    // Envelope follower state
    float envL_ = 0.0f, envR_ = 0.0f;
    double sampleRate_ = 48000.0;

    void updateCoeffs(float fc, float q, double sr, float& f, float& q1);
    float processSVF(float in, float& low, float& band, float& high, float f, float q1);
    float processEnv(float in, float& env, double sr);
};

} // namespace opensynth
