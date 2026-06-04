#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Granular delay: chops input into grains, delays them, randomizes start positions.
class GrainDelayProcessor : public FxProcessor {
public:
    enum Param {
        TIME = 0,     // 50 - 1000 ms
        FEEDBACK = 1, // 0 - 0.95
        SIZE = 2,     // 1 - 100 ms grain size
        MIX = 3,      // 0 - 1
    };

    explicit GrainDelayProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    static constexpr int MAX_DELAY = 192000; // ~2s at 96k
    static constexpr int MAX_GRAINS = 8;

    float timeMs_ = 300.0f;
    float feedback_ = 0.3f;
    float sizeMs_ = 20.0f;

    double sampleRate_ = 48000.0;

    std::array<float, MAX_DELAY> bufL_;
    std::array<float, MAX_DELAY> bufR_;
    int writePos_ = 0;

    struct Grain {
        int startPos = 0;      // write position when grain was spawned
        int delaySamples = 0;  // how far back to read
        int sizeSamples = 0;   // total grain length
        int age = 0;           // current sample within grain
        float pan = 0.5f;      // 0=L, 1=R
        bool active = false;
    };
    std::array<Grain, MAX_GRAINS> grains_;
    int nextGrain_ = 0;
    int grainCounter_ = 0;

    float readDelay(const std::array<float, MAX_DELAY>& line, float pos);
    void spawnGrain(float inL, float inR);
    float grainWindow(float t); // Hann window 0..1
};

} // namespace opensynth
