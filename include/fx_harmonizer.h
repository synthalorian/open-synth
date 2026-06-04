#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Pitch-shifted harmony using delay-line crossfade pitch shifter (single voice).
class HarmonizerProcessor : public FxProcessor {
public:
    enum Param {
        INTERVAL = 0, // -12 to +12 semitones
        FINE = 1,     // -100 to +100 cents
        MIX = 2,      // 0 - 1
        QUALITY = 3,  // 0 - 1 (window size)
    };

    explicit HarmonizerProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    static constexpr int MAX_DELAY = 96000; // ~2s at 48k

    float interval_ = 7.0f;   // perfect fifth
    float fine_ = 0.0f;
    float quality_ = 0.5f;

    double sampleRate_ = 48000.0;
    int windowSize_ = 2048;

    std::array<float, MAX_DELAY> delayL_;
    std::array<float, MAX_DELAY> delayR_;
    int writePos_ = 0;
    float readPosL_ = 0.0f;
    float readPosR_ = 0.0f;

    float readDelay(const std::array<float, MAX_DELAY>& buf, float pos);
    void updateWindowSize();
};

} // namespace opensynth
