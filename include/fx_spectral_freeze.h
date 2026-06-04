#pragma once
#include "fx_engine.h"
#include <cmath>
#include <array>

namespace opensynth {

/// Spectral freeze effect using delay-line capture and loop with crossfade.
class SpectralFreezeProcessor : public FxProcessor {
public:
    enum Param {
        FREEZE = 0,  // 0 - 1 (trigger threshold)
        DECAY = 1,   // 0 - 1
        SMEAR = 2,   // 0 - 1
        MIX = 3,
    };

    explicit SpectralFreezeProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float freezeThresh_ = 0.5f;
    float decay_ = 0.5f;
    float smear_ = 0.0f;

    double sampleRate_ = 48000.0;

    static constexpr int MAX_BUFFER = 48000; // 1 second at 48k
    std::array<float, MAX_BUFFER> bufL_;
    std::array<float, MAX_BUFFER> bufR_;

    int writePos_ = 0;
    int loopStart_ = 0;
    int loopLength_ = 0;
    int readPos_ = 0;
    bool frozen_ = false;
    float freezeEnv_ = 0.0f;

    // Crossfade state
    float xfPos_ = 0.0f;
    int xfLength_ = 256;

    float envelopeFollower(float inL, float inR);
    void enterFreeze(int length);
};

} // namespace opensynth
