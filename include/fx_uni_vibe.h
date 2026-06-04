#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Uni-Vibe chorus/vibrato with 4-phase LFO modulating 4 delay lines.
class UniVibeProcessor : public FxProcessor {
public:
    enum Param {
        RATE = 0,   // 0.1 - 10 Hz
        DEPTH = 1,  // 0 - 1
        MODE = 2,   // 0=vibrato, 1=chorus
        MIX = 3,    // 0 - 1
    };

    explicit UniVibeProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    static constexpr int MAX_DELAY = 4096;
    static constexpr int NUM_PHASES = 4;

    float rate_ = 2.0f;
    float depth_ = 0.6f;
    int mode_ = 0; // 0=vibrato, 1=chorus

    double phase_ = 0.0;
    double sampleRate_ = 48000.0;

    std::array<std::array<float, MAX_DELAY>, NUM_PHASES> delayLines_;
    std::array<int, NUM_PHASES> writeIndices_;

    float readDelay(const std::array<float, MAX_DELAY>& line, int writeIdx, float delaySamples);
};

} // namespace opensynth
