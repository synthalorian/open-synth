#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Lo-fi degradation: sample-rate reduction, bit-crush, tape hiss, pitch wobble.
class LoFiProcessor : public FxProcessor {
public:
    enum Param {
        SAMPLE_RATE = 0, // 0.01 - 1 (normalized target sample rate)
        BIT_DEPTH = 1,   // 1 - 16
        NOISE = 2,       // 0 - 1 (tape hiss amount)
        WOW = 3,         // 0 - 1 (pitch wobble depth)
    };

    explicit LoFiProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float sampleRateNorm_ = 0.5f;
    float bitDepth_ = 8.0f;
    float noise_ = 0.3f;
    float wow_ = 0.3f;

    // Sample-rate reduction state
    float phase_ = 0.0f;
    float holdL_ = 0.0f;
    float holdR_ = 0.0f;

    // Wow LFO state
    float wowPhase_ = 0.0f;
    float wowSampleL_ = 0.0f;
    float wowSampleR_ = 0.0f;

    // Noise filter state (1-pole lowpass for pink-ish hiss)
    float noiseStateL_ = 0.0f;
    float noiseStateR_ = 0.0f;

    double nativeSampleRate_ = 48000.0;

    float crush(float sample);
    float filteredNoise(float& state);
};

} // namespace opensynth
