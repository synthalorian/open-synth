#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// AM radio emulator: bandpass 300Hz-3kHz, noise, slight distortion.
class RadioSimulatorProcessor : public FxProcessor {
public:
    enum Param {
        BANDWIDTH = 0, // 0 - 1 (lowpass cutoff 1-4kHz)
        NOISE = 1,     // 0 - 1
        DISTORTION = 2,// 0 - 1
        MIX = 3,       // 0 - 1
    };

    explicit RadioSimulatorProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float bandwidth_ = 0.5f;
    float noise_ = 0.2f;
    float distortion_ = 0.2f;

    // Highpass state (300Hz fixed)
    float hpL_ = 0.0f, hpR_ = 0.0f;

    // Lowpass state (variable)
    float lpL_ = 0.0f, lpR_ = 0.0f;

    // Noise filter state
    float noiseStateL_ = 0.0f, noiseStateR_ = 0.0f;

    double nativeSampleRate_ = 48000.0;

    float highpass(float input, float& state, float freq, double sr);
    float lowpass(float input, float& state, float freq, double sr);
    float distort(float sample);
    float filteredNoise(float& state);
};

} // namespace opensynth
