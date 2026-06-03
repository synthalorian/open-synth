#pragma once
#include "fx_engine.h"
#include <cmath>
#include <array>

namespace opensynth {

/// Ping-pong delay: input to left, feedback crosses to right.
class PingPongDelayProcessor : public FxProcessor {
public:
    enum Param {
        TIME = 0,      // 50 - 1000 ms
        FEEDBACK = 1,  // 0 - 0.95
        WIDTH = 2,     // 0 - 1 (cross-feedback amount)
        MIX = 3,
    };

    explicit PingPongDelayProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float timeMs_ = 350.0f;
    float feedback_ = 0.4f;
    float width_ = 0.8f;

    static constexpr int MAX_DELAY = 96000;
    std::array<float, MAX_DELAY> delayL_;
    std::array<float, MAX_DELAY> delayR_;

    int writePos_ = 0;
    double sampleRate_ = 48000.0;
};

} // namespace opensynth
