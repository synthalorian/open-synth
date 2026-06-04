#pragma once
#include "fx_engine.h"
#include <array>
#include <cmath>

namespace opensynth {

/// Reverse delay: buffers segments of 'Time' length, plays them backwards with overlap-add.
class ReverseDelayProcessor : public FxProcessor {
public:
    enum Param {
        TIME = 0,     // 100 - 2000 ms
        FEEDBACK = 1, // 0 - 0.95
        MIX = 2,      // 0 - 1
        DECAY = 3,    // 0 - 1
    };

    explicit ReverseDelayProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    static constexpr int MAX_DELAY = 192000; // ~2s at 96k

    float timeMs_ = 500.0f;
    float feedback_ = 0.4f;
    float decay_ = 0.5f;

    double sampleRate_ = 48000.0;

    std::array<float, MAX_DELAY> bufL_;
    std::array<float, MAX_DELAY> bufR_;
    int writePos_ = 0;

    // Segment state
    int segmentSamples_ = 0;
    int segmentCounter_ = 0;
    bool reading_ = false;

    // Overlap-add: two reverse voices
    struct Voice {
        int readPos = 0;
        int remaining = 0;
        float amp = 0.0f;
    };
    Voice voiceA_;
    Voice voiceB_;

    float readDelay(const std::array<float, MAX_DELAY>& line, int pos);
    float windowShape(float t); // Hann-like window 0..1
};

} // namespace opensynth
