#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Diffused delay cluster: delay line into 4 allpass filters in series.
class DiffusionDelayProcessor : public FxProcessor {
public:
    enum Param {
        TIME = 0,      // 50 - 1000 ms
        FEEDBACK = 1,  // 0 - 0.95
        DIFFUSION = 2, // 0 - 1 (allpass coefficient)
        MIX = 3,       // 0 - 1
    };

    explicit DiffusionDelayProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    static constexpr int AP_COUNT = 4;
    static constexpr int MAX_DELAY = 96000; // ~2s at 48k
    static constexpr int MAX_AP = 2048;

    float timeMs_ = 400.0f;
    float feedback_ = 0.4f;
    float diffusion_ = 0.5f;

    double sampleRate_ = 48000.0;

    std::array<float, MAX_DELAY> delayLineL_;
    std::array<float, MAX_DELAY> delayLineR_;
    int writeIndex_ = 0;

    std::array<std::array<float, MAX_AP>, AP_COUNT> allpassesL_;
    std::array<std::array<float, MAX_AP>, AP_COUNT> allpassesR_;
    std::array<int, AP_COUNT> apPosL_;
    std::array<int, AP_COUNT> apPosR_;

    float readDelay(const std::array<float, MAX_DELAY>& line, float delaySamples);
    int apDelay(int index) const;
};

} // namespace opensynth
