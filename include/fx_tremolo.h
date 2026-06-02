#pragma once
#include "fx_engine.h"
#include <cmath>

namespace openamp {

/// Stereo tremolo with multiple waveform shapes and stereo phase offset.
class TremoloProcessor : public FxProcessor {
public:
    enum Param {
        RATE = 0,    // 0.05 - 20 Hz
        DEPTH = 1,   // 0 - 1
        SHAPE = 2,   // 0=sine, 1=triangle, 2=square, 3=saw, 4=random
        STEREO = 3,  // 0-180 degrees phase offset
    };

    explicit TremoloProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float rate_ = 4.0f;
    float depth_ = 0.5f;
    int shape_ = 0;
    float stereoPhase_ = 0.0f; // 0-180

    double phase_ = 0.0;

    float sineWave(double ph) const;
    float triangleWave(double ph) const;
    float squareWave(double ph) const;
    float sawWave(double ph) const;
    float randWave();
};

} // namespace openamp
