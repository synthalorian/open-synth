#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Brickwall maximizer / limiter with fast peak detector.
class MaximizerProcessor : public FxProcessor {
public:
    enum Param {
        CEILING = 0,  // -12 to 0 dB
        RELEASE = 1,  // 1 - 1000 ms
        DRIVE = 2,    // 0 - 1 (input gain)
        MIX = 3,
    };

    explicit MaximizerProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float ceiling_ = -1.0f;   // dB
    float release_ = 50.0f;   // ms
    float drive_ = 0.0f;

    double sampleRate_ = 48000.0;
    float envelope_ = 0.0f;
    float gainReduction_ = 1.0f;

    static inline float dbToLinear(float db) { return std::pow(10.0f, db * 0.05f); }
    static inline float linearToDb(float linear) {
        return linear > 0.00001f ? 20.0f * std::log10(linear) : -100.0f;
    }
};

} // namespace opensynth
