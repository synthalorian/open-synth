#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Stereo width / mid-side processor.
class StereoImagerProcessor : public FxProcessor {
public:
    enum Param {
        WIDTH = 0, // 0 - 2 (side gain)
        MID = 1,   // 0 - 2
        SIDE = 2,  // 0 - 2
        MIX = 3,
    };

    explicit StereoImagerProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float width_ = 1.0f;
    float midGain_ = 1.0f;
    float sideGain_ = 1.0f;
};

} // namespace opensynth
