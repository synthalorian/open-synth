#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>
#include <algorithm>

namespace opensynth {

/// Vocoder: filter bank on modulator, envelope follow each band, apply to carrier.
class VocoderProcessor : public FxProcessor {
public:
    enum Param {
        BANDS = 0,       // Number of filter bands (4-16)
        RANGE = 1,       // Frequency range (0-1)
        MIX = 2,         // Wet/dry
        CARRIER = 3,     // 0=noise, 1=saw, 2=square
    };

    explicit VocoderProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    static constexpr int MAX_BANDS = 16;

    int bands_ = 8;
    float range_ = 0.5f;
    int carrierType_ = 0;

    double sampleRate_ = 48000.0;
    float phase_ = 0.0f;

    // Bandpass filter states (2-pole state variable filter per band per channel)
    // y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]
    struct FilterState {
        float x1 = 0.0f, x2 = 0.0f;
        float y1 = 0.0f, y2 = 0.0f;
    };
    std::array<FilterState, MAX_BANDS> modL_;
    std::array<FilterState, MAX_BANDS> modR_;
    std::array<FilterState, MAX_BANDS> carL_;
    std::array<FilterState, MAX_BANDS> carR_;

    // Envelope followers per band per channel
    std::array<float, MAX_BANDS> envL_;
    std::array<float, MAX_BANDS> envR_;

    // Filter coefficients per band
    std::array<float, MAX_BANDS> b0_, b1_, b2_, a1_, a2_;

    void updateFilters();
    float processFilter(float input, FilterState& s, float b0, float b1, float b2, float a1, float a2);
    float generateCarrier();
    float noise();
};

} // namespace opensynth
