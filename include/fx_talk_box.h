#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Talk box emulation: envelope follower modulates a formant filter.
/// Params: Vowel (0-4), Resonance (0-1), Drive (0-1), Mix.
class TalkBoxProcessor : public FxProcessor {
public:
    enum Param {
        VOWEL = 0,     // 0 - 4 (A/E/I/O/U)
        RESONANCE = 1, // 0 - 1
        DRIVE = 2,     // 0 - 1
        MIX = 3,       // 0 - 1
    };

    explicit TalkBoxProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float vowel_ = 0.0f;
    float resonance_ = 0.5f;
    float drive_ = 0.0f;

    double sampleRate_ = 48000.0;

    // Envelope follower state
    float envL_ = 0.0f;
    float envR_ = 0.0f;

    // 3 bandpass states per channel
    struct Biquad {
        float x1 = 0.0f, x2 = 0.0f;
        float y1 = 0.0f, y2 = 0.0f;
        float a0 = 1.0f, a1 = 0.0f, a2 = 0.0f;
        float b0 = 1.0f, b1 = 0.0f, b2 = 0.0f;
        float process(float in);
    };

    Biquad bpL_[3];
    Biquad bpR_[3];

    static constexpr int NUM_VOWELS = 5;
    static constexpr int NUM_FORMANTS = 3;
    static const float formantFreq_[NUM_VOWELS][NUM_FORMANTS];
    static const float formantAmp_[NUM_VOWELS][NUM_FORMANTS];

    void setBandpass(Biquad& bq, float freq, float bw, double sr);
    float processEnv(float in, float& env, double sr);
    void processFormant(float inL, float inR, float envL, float envR, float& outL, float& outR);
};

} // namespace opensynth
