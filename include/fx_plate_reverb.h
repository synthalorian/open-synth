#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Bright plate reverb using 5 comb filters + 2 allpass filters with HF emphasis.
class PlateReverbProcessor : public FxProcessor {
public:
    enum Param {
        SIZE = 0,      // 0 - 1 (scales comb delays)
        DAMPING = 1,   // 0 - 1 (comb feedback LPF)
        MIX = 2,       // 0 - 1
        BRIGHTNESS = 3,// 0 - 1 (HF emphasis)
    };

    explicit PlateReverbProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    static constexpr int COMB_COUNT = 5;
    static constexpr int AP_COUNT = 2;
    static constexpr int MAX_COMB = 4096;
    static constexpr int MAX_AP = 1024;

    float size_ = 0.5f;
    float damping_ = 0.3f;
    float brightness_ = 0.6f;

    double sampleRate_ = 48000.0;

    std::array<std::array<float, MAX_COMB>, COMB_COUNT> combsL_;
    std::array<std::array<float, MAX_COMB>, COMB_COUNT> combsR_;
    std::array<int, COMB_COUNT> combPosL_;
    std::array<int, COMB_COUNT> combPosR_;
    std::array<float, COMB_COUNT> combLpfL_;
    std::array<float, COMB_COUNT> combLpfR_;

    std::array<std::array<float, MAX_AP>, AP_COUNT> allpassesL_;
    std::array<std::array<float, MAX_AP>, AP_COUNT> allpassesR_;
    std::array<int, AP_COUNT> apPosL_;
    std::array<int, AP_COUNT> apPosR_;

    // Pre-delay brightness filter state (1-pole highpass-ish emphasis)
    float brightStateL_ = 0.0f;
    float brightStateR_ = 0.0f;

    int combDelay(int index) const;
    int apDelay(int index) const;
};

} // namespace opensynth
