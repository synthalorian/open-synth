#pragma once
#include "fx_engine.h"
#include <cmath>
#include <cstdint>

namespace opensynth {

/// Bitcrusher + sample rate reducer for lo-fi grit.
class BitcrusherProcessor : public FxProcessor {
public:
    enum Param {
        BITS = 0,       // 1 - 16 (bit depth)
        SAMPLE_RATE = 1, // 100 - 44100 Hz (downsample rate)
        DRIVE = 2,      // 0 - 1 (pre-gain)
        MIX = 3,        // 0 - 1
    };

    explicit BitcrusherProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float bits_ = 8.0f;
    float sampleRate_ = 8000.0f;
    float drive_ = 0.3f;

    float phase_ = 0.0f;
    float holdL_ = 0.0f;
    float holdR_ = 0.0f;
    double nativeSampleRate_ = 48000.0;

    float crush(float sample);
};

} // namespace opensynth
