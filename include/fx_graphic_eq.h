#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// 7-band graphic EQ with fixed Q=1.4 peaking filters.
class GraphicEQProcessor : public FxProcessor {
public:
    enum Param {
        BAND_60HZ = 0,
        BAND_250HZ = 1,
        BAND_500HZ = 2,
        BAND_1KHZ = 3,
        BAND_2_5KHZ = 4,
        BAND_6KHZ = 5,
        BAND_12KHZ = 6,
    };

    explicit GraphicEQProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 7; }
    const char* paramName(int index) const override;

private:
    static constexpr int NUM_BANDS = 7;
    static constexpr float Q = 1.4f;
    static constexpr float FREQS[NUM_BANDS] = {60.0f, 250.0f, 500.0f, 1000.0f, 2500.0f, 6000.0f, 12000.0f};

    float gains_[NUM_BANDS] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f};

    // Peaking EQ state per band per channel (Direct Form 1)
    // y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]
    struct BandState {
        float x1 = 0.0f, x2 = 0.0f;
        float y1 = 0.0f, y2 = 0.0f;
        float b0 = 1.0f, b1 = 0.0f, b2 = 0.0f;
        float a1 = 0.0f, a2 = 0.0f;
    };

    BandState bandsL_[NUM_BANDS];
    BandState bandsR_[NUM_BANDS];

    double nativeSampleRate_ = 48000.0;

    void updateCoefficients(BandState& state, float freq, float gainDb, double sr);
    float processBand(float input, BandState& state);
};

} // namespace opensynth
