#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Vocal formant filter using 3 parallel bandpass filters.
/// Params: Vowel (0-4 A/E/I/O/U), Resonance (0-1), Sweep (0-1 morph speed), Mix.
class FormantFilterProcessor : public FxProcessor {
public:
    enum Param {
        VOWEL = 0,     // 0 - 4 (A/E/I/O/U)
        RESONANCE = 1, // 0 - 1
        SWEEP = 2,     // 0 - 1 (morph speed)
        MIX = 3,       // 0 - 1
    };

    explicit FormantFilterProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float vowel_ = 0.0f;
    float resonance_ = 0.5f;
    float sweep_ = 0.0f;

    double sampleRate_ = 48000.0;
    float sweepPhase_ = 0.0f;

    // 3 bandpass states per channel (x1, x2, y1, y2)
    struct Biquad {
        float x1 = 0.0f, x2 = 0.0f;
        float y1 = 0.0f, y2 = 0.0f;
        float a0 = 1.0f, a1 = 0.0f, a2 = 0.0f;
        float b0 = 1.0f, b1 = 0.0f, b2 = 0.0f;
        float process(float in);
    };

    Biquad bpL_[3];
    Biquad bpR_[3];

    // Formant tables: 5 vowels x 3 formants (freq, amp, bw)
    static constexpr int NUM_VOWELS = 5;
    static constexpr int NUM_FORMANTS = 3;
    static const float formantFreq_[NUM_VOWELS][NUM_FORMANTS];
    static const float formantAmp_[NUM_VOWELS][NUM_FORMANTS];

    void setBandpass(Biquad& bq, float freq, float bw, double sr);
    void processVowel(float inL, float inR, int vowelIdx, float& outL, float& outR);
};

} // namespace opensynth
