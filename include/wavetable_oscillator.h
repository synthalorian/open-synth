#pragma once
#include <cstdint>
#include <cmath>

namespace opensynth {

struct Wavetable {
    float* samples;        // 2048 samples, heap-allocated
    int sampleCount;       // 2048
    const char* name;

    Wavetable() : samples(nullptr), sampleCount(0), name("") {}
    ~Wavetable() { delete[] samples; }

    // Non-copyable, movable
    Wavetable(const Wavetable&) = delete;
    Wavetable& operator=(const Wavetable&) = delete;
    Wavetable(Wavetable&& other) noexcept
        : samples(other.samples), sampleCount(other.sampleCount), name(other.name) {
        other.samples = nullptr;
        other.sampleCount = 0;
    }
    Wavetable& operator=(Wavetable&& other) noexcept {
        if (this != &other) {
            delete[] samples;
            samples = other.samples;
            sampleCount = other.sampleCount;
            name = other.name;
            other.samples = nullptr;
            other.sampleCount = 0;
        }
        return *this;
    }
};

class WavetableOscillator {
public:
    WavetableOscillator();
    ~WavetableOscillator();

    void setWavetable(const Wavetable* wt);
    float getSample(double frequency, double sampleRate);
    float getSampleAtPhase(float phase) const;  // phase in [0, 1)
    void reset();

    const Wavetable* currentWavetable() const { return wavetable_; }

private:
    double phase_ = 0.0;
    const Wavetable* wavetable_ = nullptr;

    // Cubic hermite interpolation between 4 samples
    float interpolate(double index) const;
};

} // namespace opensynth
