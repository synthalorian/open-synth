#pragma once
#include "fx_engine.h"
#include <cmath>
#include <algorithm>

namespace opensynth {

/// 3-band compressor with Linkwitz-Riley crossovers and per-band dynamics.
class MultibandCompressorProcessor : public FxProcessor {
public:
    enum Param {
        LOW_THRESH = 0,   // -60 to 0 dB
        LOW_RATIO = 1,    // 1 to 20
        MID_THRESH = 2,   // -60 to 0 dB
        MID_RATIO = 3,    // 1 to 20
        HIGH_THRESH = 4,  // -60 to 0 dB
        HIGH_RATIO = 5,   // 1 to 20
        CROSSOVER1 = 6,   // 100 to 1000 Hz
        CROSSOVER2 = 7,   // 1000 to 8000 Hz
    };

    explicit MultibandCompressorProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 8; }
    const char* paramName(int index) const override;

private:
    // Parameters (stored in natural units)
    float lowThresh_ = -20.0f;
    float lowRatio_ = 4.0f;
    float midThresh_ = -20.0f;
    float midRatio_ = 4.0f;
    float highThresh_ = -20.0f;
    float highRatio_ = 4.0f;
    float crossover1_ = 400.0f;
    float crossover2_ = 2500.0f;

    // Linkwitz-Riley crossover states (2 cascaded 1-pole filters per band)
    // Lowpass / highpass pairs for each crossover
    // Crossover 1: splits low from mid+high
    float lp1L_ = 0.0f, lp1R_ = 0.0f;
    float lp1aL_ = 0.0f, lp1aR_ = 0.0f; // second pole
    float hp1L_ = 0.0f, hp1R_ = 0.0f;
    float hp1aL_ = 0.0f, hp1aR_ = 0.0f; // second pole
    // Crossover 2: splits mid from high
    float lp2L_ = 0.0f, lp2R_ = 0.0f;
    float lp2aL_ = 0.0f, lp2aR_ = 0.0f; // second pole
    float hp2L_ = 0.0f, hp2R_ = 0.0f;
    float hp2aL_ = 0.0f, hp2aR_ = 0.0f; // second pole

    // Compressor envelope followers per band (left/right)
    float envLowL_ = 0.0f, envLowR_ = 0.0f;
    float envMidL_ = 0.0f, envMidR_ = 0.0f;
    float envHighL_ = 0.0f, envHighR_ = 0.0f;

    double sampleRate_ = 48000.0;

    // Coefficients
    float c1_ = 0.0f, c2_ = 0.0f; // crossover coeffs

    void updateCrossoverCoeffs();
    void processCrossover(float inL, float inR, float& lowL, float& lowR, float& midL, float& midR, float& highL, float& highR);
    float compress(float sample, float& env, float threshDb, float ratio);
};

} // namespace opensynth
