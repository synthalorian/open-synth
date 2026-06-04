#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Roland Dimension D style chorus ensemble.
class ChorusEnsembleProcessor : public FxProcessor {
public:
    enum Param {
        RATE = 0,    // 0.1 - 10 Hz
        DEPTH = 1,   // 0 - 1
        VOICES = 2,  // 1 - 4
        MODE = 3,    // 0-3: I/II/III/IV
    };

    explicit ChorusEnsembleProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    static constexpr int MAX_DELAY = 4096;
    static constexpr int MAX_VOICES = 4;

    float rate_ = 0.5f;
    float depth_ = 0.5f;
    int voices_ = 4;
    int mode_ = 0;

    double phase_ = 0.0;
    double sampleRate_ = 48000.0;

    std::array<std::array<float, MAX_DELAY>, MAX_VOICES> delayLines_;
    std::array<int, MAX_VOICES> writeIndices_;

    // Mode base delay offsets in ms for each voice
    static constexpr float modeOffsets_[4][MAX_VOICES] = {
        {5.0f,  8.0f,  0.0f,  0.0f},   // Mode I: 2 voices
        {5.0f,  8.0f, 11.0f,  0.0f},   // Mode II: 3 voices
        {5.0f,  8.0f, 11.0f, 14.0f},   // Mode III: 4 voices
        {4.0f,  7.0f, 10.0f, 13.0f},   // Mode IV: 4 voices, tighter
    };

    float readDelay(const std::array<float, MAX_DELAY>& line, int writeIdx, float delaySamples);
};

} // namespace opensynth
