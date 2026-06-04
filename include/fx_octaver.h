#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Octave up/down using zero-crossing detection + half-wave rectification for down,
/// and frequency doubler (full-wave rectification + DC removal) for up.
class OctaverProcessor : public FxProcessor {
public:
    enum Param {
        OCTAVE = 0,  // -2 to +2
        MIX = 1,     // 0 - 1
        TONE = 2,    // 0 - 1 (lowpass on octave signal)
        TRACKING = 3,// 0 - 1 (smoothing / sensitivity)
    };

    explicit OctaverProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float octave_ = -1.0f;
    float tone_ = 0.5f;
    float tracking_ = 0.5f;

    double sampleRate_ = 48000.0;

    // Zero-crossing state
    float prevL_ = 0.0f;
    float prevR_ = 0.0f;
    bool posL_ = false;
    bool posR_ = false;

    // Half-wave / full-wave buffers for smoothing
    float hwL_ = 0.0f;
    float hwR_ = 0.0f;
    float fwL_ = 0.0f;
    float fwR_ = 0.0f;

    // DC removal state
    float dcL_ = 0.0f;
    float dcR_ = 0.0f;

    // Tone filter state
    float toneL_ = 0.0f;
    float toneR_ = 0.0f;

    float toneFilter(float input, float& state);
    float dcBlock(float input, float& state);
};

} // namespace opensynth
