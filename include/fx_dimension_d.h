#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Roland Dimension D spatial chorus with allpass filters + modulated delays.
class DimensionDProcessor : public FxProcessor {
public:
    enum Param {
        MODE = 0,   // 0-3
        DEPTH = 1,  // 0 - 1
        RATE = 2,   // 0.1 - 5 Hz
        MIX = 3,    // 0 - 1
    };

    explicit DimensionDProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    static constexpr int MAX_DELAY = 4096;

    int mode_ = 0;
    float depth_ = 0.5f;
    float rate_ = 0.5f;

    double phase_ = 0.0;
    double sampleRate_ = 48000.0;

    // Allpass filter state
    float ap1In1_ = 0.0f, ap1Out1_ = 0.0f;
    float ap1In2_ = 0.0f, ap1Out2_ = 0.0f;
    float ap2In1_ = 0.0f, ap2Out1_ = 0.0f;
    float ap2In2_ = 0.0f, ap2Out2_ = 0.0f;

    // Delay lines
    std::array<float, MAX_DELAY> delayLineL_;
    std::array<float, MAX_DELAY> delayLineR_;
    int writeIdxL_ = 0;
    int writeIdxR_ = 0;

    // Cross-feedback state
    float fbL_ = 0.0f;
    float fbR_ = 0.0f;

    // Mode presets: base delay ms, allpass coeff, feedback amount
    static constexpr float modeBaseDelay_[4] = {8.0f, 12.0f, 16.0f, 20.0f};
    static constexpr float modeApCoeff_[4] = {0.3f, 0.4f, 0.5f, 0.6f};
    static constexpr float modeFeedback_[4] = {0.15f, 0.25f, 0.35f, 0.45f};

    float processAllpass(float input, float& inState, float& outState, float coeff);
    float readDelay(const std::array<float, MAX_DELAY>& line, int writeIdx, float delaySamples);
};

} // namespace opensynth
