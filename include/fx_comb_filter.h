#pragma once
#include "fx_engine.h"
#include <cmath>
#include <vector>

namespace opensynth {

/// Comb filter with feedback and damping.
/// Params: Freq (20-5000 Hz), Feedback (0-0.99), Damping (0-1), Mix.
class CombFilterProcessor : public FxProcessor {
public:
    enum Param {
        FREQ = 0,      // 20 - 5000 Hz
        FEEDBACK = 1,  // 0 - 0.99
        DAMPING = 2,   // 0 - 1
        MIX = 3,       // 0 - 1
    };

    explicit CombFilterProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float freq_ = 1000.0f;
    float feedback_ = 0.5f;
    float damping_ = 0.3f;

    double sampleRate_ = 48000.0;

    // Delay lines
    std::vector<float> delayL_;
    std::vector<float> delayR_;
    size_t writeIdx_ = 0;

    // Damping filter state (1-pole LPF in feedback path)
    float dampL_ = 0.0f;
    float dampR_ = 0.0f;

    static constexpr int MAX_DELAY_MS = 100;
};

} // namespace opensynth
