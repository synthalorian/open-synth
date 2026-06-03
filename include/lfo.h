#pragma once
#include <cstdint>
#include <cmath>

namespace opensynth {

class LFO {
public:
    enum class Waveform : int {
        SINE = 0,
        TRIANGLE = 1,
        SAW = 2,
        SQUARE = 3,
        RANDOM_SH = 4,      // Sample & Hold (stepped)
        SMOOTHED_SH = 5,    // Smoothed S&H (interpolated random)
        RANDOM_WALK = 6,    // Random walk
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
    void setFadeIn(float seconds);
    void setTempoSync(bool enabled);
    void setTempoNoteDivision(int div); // 1=whole, 2=half, 4=quarter, 8=eighth, 16=16th, etc.

    int waveform() const { return static_cast<int>(waveform_); }
    float rate() const { return rate_; }
    float depth() const { return depth_; }
    float fadeIn() const { return fadeIn_; }
    bool tempoSync() const { return tempoSync_; }
    int tempoNoteDivision() const { return tempoNoteDivision_; }

    void prepare(double sampleRate);
    void reset();
    float process();
    float getValue() const { return value_; }
    Target target() const { return target_; }

    int intTarget() const { return static_cast<int>(target_); }
    void setIntTarget(int t) { target_ = static_cast<Target>(t); }

    /// Set tempo sync rate from BPM and note division.
    void setTempoRateBpm(float bpm, int division);

private:
    Waveform waveform_ = Waveform::SINE;
    float rate_ = 1.0f;
    float depth_ = 0.5f;
    Target target_ = Target::FILTER;
    float fadeIn_ = 0.0f;   // Seconds
    bool tempoSync_ = false;
    int tempoNoteDivision_ = 4; // Quarter note

    double phase_ = 0.0;
    double phaseIncrement_ = 0.0;
    double sampleRate_ = 48000.0;
    float value_ = 0.0f;

    // S&H / random walk state
    float currentTarget_ = 0.0f;
    float previousTarget_ = 0.0f;
    float smoothPhase_ = 0.0f; // For smoothed S&H interpolation

    // Fade-in tracking
    float fadeInPhase_ = 0.0f;
    bool fadeInComplete_ = false;

    float randomValue();
};

} // namespace opensynth
