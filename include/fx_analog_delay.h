#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Bucket-brigade style analog delay with lowpass in feedback path.
class AnalogDelayProcessor : public FxProcessor {
public:
    enum Param {
        TIME = 0,     // 50 - 1000 ms
        FEEDBACK = 1, // 0 - 0.95
        TONE = 2,     // 0 - 1 (lowpass in feedback)
        MIX = 3,      // 0 - 1
    };

    explicit AnalogDelayProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    static constexpr int MAX_DELAY = 192000; // ~2s at 96k

    float timeMs_ = 400.0f;
    float feedback_ = 0.4f;
    float tone_ = 0.5f;

    double sampleRate_ = 48000.0;

    std::array<float, MAX_DELAY> delayL_;
    std::array<float, MAX_DELAY> delayR_;
    int writePos_ = 0;

    // 1-pole LPF state for feedback path
    float lpfL_ = 0.0f;
    float lpfR_ = 0.0f;

    float readDelay(const std::array<float, MAX_DELAY>& line, float delaySamples);
    float saturate(float x);
};

} // namespace opensynth
