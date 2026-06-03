#pragma once
#include "fx_engine.h"
#include <cmath>
#include <array>

namespace opensynth {

/// Multi-tap delay with 4 independently timed taps.
class MultitapDelayProcessor : public FxProcessor {
public:
    enum Param {
        TIME = 0,      // 50 - 1000 ms base time
        SPREAD = 1,    // 0 - 1 (tap spacing)
        FEEDBACK = 2,  // 0 - 0.95
        TONE = 3,      // 0 - 1 (lowpass damping)
        MIX = 4,
    };

    explicit MultitapDelayProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 5; }
    const char* paramName(int index) const override;

private:
    float timeMs_ = 300.0f;
    float spread_ = 0.5f;
    float feedback_ = 0.3f;
    float tone_ = 0.5f;

    static constexpr int MAX_DELAY = 96000; // 2s at 48kHz
    std::array<float, MAX_DELAY> delayL_;
    std::array<float, MAX_DELAY> delayR_;

    int writePos_ = 0;
    float lpfL_ = 0.0f;
    float lpfR_ = 0.0f;
    double sampleRate_ = 48000.0;

    int tapOffset(int tapIndex) const;
};

} // namespace opensynth
