#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Thickening detune using multiple delay-line pitch shifters with slightly different ratios.
class DetuneProcessor : public FxProcessor {
public:
    enum Param {
        AMOUNT = 0, // -50 to +50 cents
        MIX = 1,    // 0 - 1
        SPREAD = 2, // 0 - 1 (stereo width)
        VOICES = 3, // 1 - 4
    };

    explicit DetuneProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    static constexpr int MAX_DELAY = 96000;
    static constexpr int MAX_VOICES = 4;

    float amount_ = 10.0f;
    float spread_ = 0.5f;
    int voiceCount_ = 2;

    double sampleRate_ = 48000.0;
    int windowSize_ = 2048;

    struct Voice {
        std::array<float, MAX_DELAY> delayL;
        std::array<float, MAX_DELAY> delayR;
        int writePos = 0;
        float readPosL = 0.0f;
        float readPosR = 0.0f;
        float ratio = 1.0f;
        float panL = 0.5f;
        float panR = 0.5f;
    };
    std::array<Voice, MAX_VOICES> voices_;

    float readDelay(const std::array<float, MAX_DELAY>& buf, float pos, int windowSize);
};

} // namespace opensynth
