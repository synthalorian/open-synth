#pragma once
#include "fx_engine.h"
#include <cmath>
#include <array>

namespace opensynth {

/// Simple pitch shifter using delay-line crossfade (PSOLA-style).
class PitchShiftProcessor : public FxProcessor {
public:
    enum Param {
        SEMITONES = 0, // -12 to +12
        WINDOW_SIZE = 1, // 10 - 100 ms
        MIX = 2,
    };

    explicit PitchShiftProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 3; }
    const char* paramName(int index) const override;

private:
    float semitones_ = 0.0f;
    float windowSizeMs_ = 30.0f;

    static constexpr int MAX_DELAY = 8192;
    std::array<float, MAX_DELAY> delayL_;
    std::array<float, MAX_DELAY> delayR_;

    float readPosL_ = 0.0f;
    float readPosR_ = 0.0f;
    int writePos_ = 0;
    int windowSize_ = 1440; // samples at 48kHz
    double sampleRate_ = 48000.0;

    void updateWindowSize();
    float readDelay(const std::array<float, MAX_DELAY>& buf, float pos);
};

} // namespace opensynth
