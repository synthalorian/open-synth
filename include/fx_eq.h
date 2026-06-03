#pragma once
#include "fx_engine.h"
#include <cmath>
#include <array>

namespace opensynth {

/// Parametric EQ with low-shelf, peak (parametric), and high-shelf bands.
class EqProcessor : public FxProcessor {
public:
    /// Band indices for setParam
    enum Param {
        LOW_GAIN = 0,    // -12 to +12 dB
        LOW_FREQ = 1,    // 20-500 Hz
        MID_GAIN = 2,    // -12 to +12 dB
        MID_FREQ = 3,    // 100-8000 Hz
        MID_Q    = 4,    // 0.1 - 10
        HIGH_GAIN = 5,   // -12 to +12 dB
        HIGH_FREQ = 6,   // 500-20000 Hz
        OUTPUT_GAIN = 7, // -12 to +12 dB
    };

    explicit EqProcessor()
        : FxProcessor(FxType::Equalizer) {}

    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 8; }
    const char* paramName(int index) const override;

private:
    struct BiquadFilter {
        float a0 = 1.0f, a1 = 0.0f, a2 = 0.0f;
        float b1 = 0.0f, b2 = 0.0f;
        float x1L = 0.0f, x2L = 0.0f, y1L = 0.0f, y2L = 0.0f;
        float x1R = 0.0f, x2R = 0.0f, y1R = 0.0f, y2R = 0.0f;

        float processL(float x) {
            float y = a0 * x + a1 * x1L + a2 * x2L - b1 * y1L - b2 * y2L;
            x2L = x1L; x1L = x;
            y2L = y1L; y1L = y;
            return y;
        }

        float processR(float x) {
            float y = a0 * x + a1 * x1R + a2 * x2R - b1 * y1R - b2 * y2R;
            x2R = x1R; x1R = x;
            y2R = y1R; y1R = y;
            return y;
        }

        void reset() {
            x1L = x2L = y1L = y2L = 0.0f;
            x1R = x2R = y1R = y2R = 0.0f;
        }
    };

    void updateCoefficients(double sampleRate);

    float lowGain_ = 0.0f;     // dB
    float lowFreq_ = 200.0f;
    float midGain_ = 0.0f;
    float midFreq_ = 1000.0f;
    float midQ_ = 1.0f;
    float highGain_ = 0.0f;
    float highFreq_ = 5000.0f;
    float outputGain_ = 0.0f;  // dB

    BiquadFilter lowFilter_;
    BiquadFilter midFilter_;
    BiquadFilter highFilter_;

    bool dirty_ = true;
    double cachedSampleRate_ = 0.0;
};

} // namespace opensynth
