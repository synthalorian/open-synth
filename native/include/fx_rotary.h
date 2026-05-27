#pragma once
#include "fx_engine.h"
#include <cmath>

namespace openamp {

/// Rotary speaker emulation (Leslie cabinet).
/// Combines Doppler pitch shift, tremolo (volume modulation), and
/// spectral rotation via a stereo all-pass filter network.
class RotaryProcessor : public FxProcessor {
public:
    enum Param {
        RATE = 0,     // 0.1 - 10 Hz
        DEPTH = 1,    // 0 - 1
        TONE = 2,     // 0 - 1 (brightness)
        MIX = 3,      // 0 - 1
    };

    explicit RotaryProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float rate_ = 2.5f;     // Hz
    float depth_ = 0.7f;
    float tone_ = 0.5f;
    float mix_ = 0.5f;

    double phase_ = 0.0;
    float hornDelay_[2048] = {};
    float drumDelay_[4096] = {};
    uint32_t hornWritePos_ = 0;
    uint32_t drumWritePos_ = 0;
    float hornLpf_ = 0.0f;
    float drumLpf_ = 0.0f;
};

} // namespace openamp
