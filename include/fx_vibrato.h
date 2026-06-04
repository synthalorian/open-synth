#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Pitch vibrato using modulated delay line.
class VibratoProcessor : public FxProcessor {
public:
    enum Param {
        RATE = 0,   // 0.1 - 10 Hz
        DEPTH = 1,  // 0 - 1
        WAVE = 2,   // 0=sine, 1=triangle, 2=square, 3=saw
        MIX = 3,    // 0 - 1
    };

    explicit VibratoProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    static constexpr int MAX_DELAY = 8192;

    float rate_ = 3.0f;
    float depth_ = 0.5f;
    int wave_ = 0;

    double phase_ = 0.0;
    double sampleRate_ = 48000.0;

    std::array<float, MAX_DELAY> delayLineL_;
    std::array<float, MAX_DELAY> delayLineR_;
    int writeIndex_ = 0;

    float lfoValue(double ph) const;
    float readDelay(const std::array<float, MAX_DELAY>& line, float delaySamples);
};

} // namespace opensynth
