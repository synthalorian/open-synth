#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Tape echo with wow/flutter and lowpass feedback damping.
class TapeDelayProcessor : public FxProcessor {
public:
    enum Param {
        TIME = 0,      // 50 - 1000 ms
        FEEDBACK = 1,  // 0 - 0.95
        WOW = 2,       // 0 - 1
        MIX = 3,       // 0 - 1
    };

    explicit TapeDelayProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    static constexpr int MAX_DELAY = 96000;

    float timeMs_ = 400.0f;
    float feedback_ = 0.4f;
    float wow_ = 0.1f;

    double phase_ = 0.0;
    double sampleRate_ = 48000.0;

    std::array<float, MAX_DELAY> delayLineL_;
    std::array<float, MAX_DELAY> delayLineR_;
    int writeIndex_ = 0;

    // Lowpass filter state for feedback damping (tape emulation)
    float lpL_ = 0.0f;
    float lpR_ = 0.0f;

    float readDelay(const std::array<float, MAX_DELAY>& line, float delaySamples);
    float lowpass(float input, float& state, double sr);
};

} // namespace opensynth
