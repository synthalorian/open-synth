#pragma once
#include "fx_engine.h"
#include <cmath>
#include <array>

namespace opensynth {

/// Stereo widener using Haas effect (micro-delay) + mid/side processing.
class StereoWidenerProcessor : public FxProcessor {
public:
    enum Param {
        WIDTH = 0,     // 0 - 2 (1 = normal, 0 = mono, 2 = extra wide)
        HAAS_DELAY = 1,// 0 - 30 ms
        MONO_BASS = 2, // 0 - 1 (keep bass mono)
        MIX = 3,
    };

    explicit StereoWidenerProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float width_ = 1.2f;
    float haasMs_ = 8.0f;
    float monoBass_ = 0.5f;

    static constexpr int MAX_DELAY = 4096;
    std::array<float, MAX_DELAY> delayL_;
    std::array<float, MAX_DELAY> delayR_;

    int writePos_ = 0;
    double sampleRate_ = 48000.0;

    float lpfL_ = 0.0f;
    float lpfR_ = 0.0f;
};

} // namespace opensynth
