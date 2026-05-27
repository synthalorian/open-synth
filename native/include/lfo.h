#pragma once
#include <cstdint>
#include <cmath>

namespace openamp {

class LFO {
public:
    enum class Waveform : int {
        SINE = 0,
        TRIANGLE = 1,
        SAW = 2,
        SQUARE = 3,
        RANDOM = 4,
    };

    enum class Target : int {
        PITCH = 0,
        FILTER = 1,
        AMPLITUDE = 2,
        PAN = 3,
    };

    LFO() = default;

    void setWaveform(int w);
    void setRate(float hz);
    void setDepth(float depth);
    void setTarget(int target);

    int waveform() const { return static_cast<int>(waveform_); }
    float rate() const { return rate_; }
    float depth() const { return depth_; }

    void prepare(double sampleRate);
    void reset();
    float process();
    float getValue() const { return value_; }
    Target target() const { return target_; }

    int intTarget() const { return static_cast<int>(target_); }
    void setIntTarget(int t) { target_ = static_cast<Target>(t); }

private:
    Waveform waveform_ = Waveform::SINE;
    float rate_ = 1.0f;
    float depth_ = 0.5f;
    Target target_ = Target::FILTER;

    double phase_ = 0.0;
    double phaseIncrement_ = 0.0;
    double sampleRate_ = 48000.0;
    float value_ = 0.0f;
};

} // namespace openamp
