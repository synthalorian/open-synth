#pragma once
#include <cstdint>
#include <cmath>

namespace opensynth {

struct Wavetable {
    // Band-limited copies of the table, one per octave. Level L keeps at
    // most (sampleCount / 2) >> L harmonics; level 0 is the original table.
    static constexpr int kMaxMipLevels = 12;

    float* samples;        // 2048 samples, heap-allocated
    int sampleCount;       // 2048
    const char* name;
    float* mips[kMaxMipLevels] = {};  // owned unless equal to a lower level
    int numMips = 0;                  // 0 = not built, use samples only

    Wavetable() : samples(nullptr), sampleCount(0), name("") {}
    ~Wavetable() { freeMips(); delete[] samples; }

    // Builds the per-octave band-limited levels from `samples`. Levels that
    // would be identical to the one below (no harmonics above their limit)
    // share its buffer. Safe to call more than once.
    void buildMips();

    // Table to read for a given phase increment (cycles per sample), chosen
    // so every kept harmonic stays below Nyquist.
    const float* tableForIncrement(double cyclesPerSample) const;

    // Like tableForIncrement, but over the top kMipFadeRatio of each level's
    // pitch range it also returns the next (darker) level and a weight for it,
    // rising from 0 to 1 as the pitch reaches the switch point. Both tables
    // are alias-free, and the read is continuous across level switches.
    // `next` is null and `nextWeight` 0 outside the fade region.
    static constexpr double kMipFadeRatio = 1.3;
    const float* tablesForIncrement(double cyclesPerSample, const float*& next, float& nextWeight) const;

    void freeMips() {
        for (int i = 1; i < numMips; ++i) {
            bool shared = false;
            for (int j = 0; j < i; ++j) shared = shared || (mips[j] == mips[i]);
            if (!shared && mips[i] != samples) delete[] mips[i];
        }
        for (auto& m : mips) m = nullptr;
        numMips = 0;
    }

    // Non-copyable, movable
    Wavetable(const Wavetable&) = delete;
    Wavetable& operator=(const Wavetable&) = delete;
    Wavetable(Wavetable&& other) noexcept
        : samples(other.samples), sampleCount(other.sampleCount), name(other.name),
          numMips(other.numMips) {
        for (int i = 0; i < kMaxMipLevels; ++i) { mips[i] = other.mips[i]; other.mips[i] = nullptr; }
        other.numMips = 0;
        other.samples = nullptr;
        other.sampleCount = 0;
    }
    Wavetable& operator=(Wavetable&& other) noexcept {
        if (this != &other) {
            freeMips();
            delete[] samples;
            samples = other.samples;
            sampleCount = other.sampleCount;
            name = other.name;
            numMips = other.numMips;
            for (int i = 0; i < kMaxMipLevels; ++i) { mips[i] = other.mips[i]; other.mips[i] = nullptr; }
            other.numMips = 0;
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
    float getSampleAtPhase(float phase) const;  // phase in [0, 1), full-band table
    // Band-limited read: picks the mip level for the given phase increment
    // (cycles per sample, i.e. frequency / sampleRate).
    float getSampleAtPhase(float phase, double cyclesPerSample) const;
    void reset();

    const Wavetable* currentWavetable() const { return wavetable_; }

private:
    double phase_ = 0.0;
    const Wavetable* wavetable_ = nullptr;

    // Cubic hermite interpolation between 4 samples
    float interpolate(double index) const;
    float interpolate(const float* table, double index) const;
};

} // namespace opensynth
