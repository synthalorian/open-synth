#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Guitar amp simulator: preamp distortion + tone stack.
class AmpSimulatorProcessor : public FxProcessor {
public:
    enum Param {
        GAIN = 0,      // 0 - 1
        BASS = 1,      // 0 - 1
        MID = 2,       // 0 - 1
        TREBLE = 3,    // 0 - 1
        PRESENCE = 4,  // 0 - 1
        MIX = 5,
    };

    explicit AmpSimulatorProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 6; }
    const char* paramName(int index) const override;

private:
    float gain_ = 0.5f;
    float bass_ = 0.5f;
    float mid_ = 0.5f;
    float treble_ = 0.5f;
    float presence_ = 0.3f;

    // Simple tone stack state (shelving filters)
    float bassL_ = 0.0f, bassR_ = 0.0f;
    float midL_ = 0.0f, midR_ = 0.0f;
    float trebleL_ = 0.0f, trebleR_ = 0.0f;
    float presenceL_ = 0.0f, presenceR_ = 0.0f;

    double sampleRate_ = 48000.0;

    float distort(float sample);
    float toneFilter(float input, float& state, float freq, float gain, double sr);
};

} // namespace opensynth
