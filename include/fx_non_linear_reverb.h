#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Gated / non-linear reverb: reverb tank with envelope follower that gates output.
class NonLinearReverbProcessor : public FxProcessor {
public:
    enum Param {
        SIZE = 0,   // 0 - 1 (reverb decay/size)
        GATE = 1,   // 0 - 1 (gate threshold)
        MIX = 2,    // 0 - 1
        ATTACK = 3, // 0.1 - 50 ms (envelope attack)
    };

    explicit NonLinearReverbProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    static constexpr int COMB_COUNT = 4;
    static constexpr int AP_COUNT = 2;
    static constexpr int MAX_COMB = 4096;
    static constexpr int MAX_AP = 1024;

    float size_ = 0.5f;
    float gate_ = 0.3f;
    float attackMs_ = 5.0f;

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

    float envelope_ = 0.0f;

    int combDelay(int index) const;
    int apDelay(int index) const;
    void updateEnvelope(float input);
};

} // namespace opensynth
