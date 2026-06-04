#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// De-esser: bandpass at freq, envelope follow, compress full signal when bandpass > threshold.
/// Params: Freq (2000-16000 Hz), Threshold (-40 to 0 dB), Amount (0-1), Mix.
class DeEsserProcessor : public FxProcessor {
public:
    enum Param {
        FREQ = 0,       // 2000 - 16000 Hz
        THRESHOLD = 1,  // -40 to 0 dB
        AMOUNT = 2,     // 0 - 1
        MIX = 3,        // 0 - 1
    };

    explicit DeEsserProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float freq_ = 6000.0f;
    float thresholdDb_ = -20.0f;
    float amount_ = 0.5f;

    double sampleRate_ = 48000.0;

    // Bandpass filter state (biquad)
    struct Biquad {
        float x1 = 0.0f, x2 = 0.0f;
        float y1 = 0.0f, y2 = 0.0f;
        float a0 = 1.0f, a1 = 0.0f, a2 = 0.0f;
        float b0 = 1.0f, b1 = 0.0f, b2 = 0.0f;
        float process(float in);
    };

    Biquad bpL_;
    Biquad bpR_;

    // Envelope follower state
    float envL_ = 0.0f;
    float envR_ = 0.0f;

    void setBandpass(Biquad& bq, float freq, double sr);
    float dbToLinear(float db) const;
    float linearToDb(float lin) const;
};

} // namespace opensynth
