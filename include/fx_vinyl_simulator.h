#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Vinyl record emulator: dust crackle, scratch bursts, slow pitch wobble.
class VinylSimulatorProcessor : public FxProcessor {
public:
    enum Param {
        DUST = 0,    // 0 - 1 (crackle density)
        SCRATCH = 1, // 0 - 1 (scratch burst probability)
        WARP = 2,    // 0 - 1 (pitch wobble depth)
        MIX = 3,     // 0 - 1
    };

    explicit VinylSimulatorProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float dust_ = 0.3f;
    float scratch_ = 0.1f;
    float warp_ = 0.3f;

    // Warp LFO state
    float warpPhase_ = 0.0f;
    float warpSampleL_ = 0.0f;
    float warpSampleR_ = 0.0f;

    // Dust / crackle state
    float dustTimer_ = 0.0f;
    float dustImpulse_ = 0.0f;

    // Scratch burst state
    float scratchTimer_ = 0.0f;
    int scratchRemaining_ = 0;
    float scratchValue_ = 0.0f;

    double nativeSampleRate_ = 48000.0;

    float generateDust();
    float generateScratch();
};

} // namespace opensynth
