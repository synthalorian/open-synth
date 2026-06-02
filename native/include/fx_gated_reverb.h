#pragma once
#include "fx_engine.h"
#include <cmath>
#include <array>

namespace openamp {

/// Gated reverb: big reverb sound cut by noise gate.
class GatedReverbProcessor : public FxProcessor {
public:
    enum Param {
        SIZE = 0,      // 0 - 1 (pre-gate reverb size)
        GATE_THRESH = 1, // 0 - 1 (gate threshold)
        ATTACK = 2,    // 1 - 50 ms
        HOLD = 3,      // 10 - 500 ms
        MIX = 4,
    };

    explicit GatedReverbProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 5; }
    const char* paramName(int index) const override;

private:
    float size_ = 0.7f;
    float gateThresh_ = 0.3f;
    float attackMs_ = 5.0f;
    float holdMs_ = 150.0f;

    static constexpr int MAX_DELAY = 4800;
    std::array<float, MAX_DELAY> delayL_;
    std::array<float, MAX_DELAY> delayR_;
    std::array<float, 4> stateL_;
    std::array<float, 4> stateR_;
    std::array<int, 4> pos_;

    float envelope_ = 0.0f;
    float gateState_ = 0.0f;
    int holdSamples_ = 0;
    int holdCounter_ = 0;
    double sampleRate_ = 48000.0;

    void updateEnvelope(float input);
};

} // namespace openamp
