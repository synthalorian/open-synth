#pragma once
#include "fx_engine.h"
#include <cmath>
#include <array>

namespace openamp {

/// Spring reverb emulation using cascaded comb filters + allpass.
class SpringReverbProcessor : public FxProcessor {
public:
    enum Param {
        DECAY = 0,     // 0 - 1
        DAMPING = 1,   // 0 - 1
        BRIGHTNESS = 2,// 0 - 1 (high shelf)
        MIX = 3,
    };

    explicit SpringReverbProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float decay_ = 0.6f;
    float damping_ = 0.5f;
    float brightness_ = 0.5f;

    static constexpr int COMB_COUNT = 4;
    static constexpr int AP_COUNT = 2;
    static constexpr int MAX_COMB = 8192;

    std::array<std::array<float, MAX_COMB>, COMB_COUNT> combs_;
    std::array<int, COMB_COUNT> combPos_;
    std::array<float, COMB_COUNT> combLpf_;

    std::array<std::array<float, 2048>, AP_COUNT> allpasses_;
    std::array<int, AP_COUNT> apPos_;

    double sampleRate_ = 48000.0;

    int combDelay(int index) const;
    int apDelay(int index) const;
};

} // namespace openamp
