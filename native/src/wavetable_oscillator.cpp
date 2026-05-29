#include "wavetable_oscillator.h"
#include <algorithm>
#include <cmath>

namespace openamp {

WavetableOscillator::WavetableOscillator() = default;
WavetableOscillator::~WavetableOscillator() = default;

void WavetableOscillator::setWavetable(const Wavetable* wt) {
    wavetable_ = wt;
}

void WavetableOscillator::reset() {
    phase_ = 0.0;
}

float WavetableOscillator::getSampleAtPhase(float phase) const {
    if (!wavetable_ || wavetable_->sampleCount <= 0) {
        return 0.0f;
    }

    // Clamp phase to [0, 1)
    float p = phase - std::floor(phase);
    if (!std::isfinite(p)) return 0.0f;

    double index = static_cast<double>(p) * wavetable_->sampleCount;
    float sample = interpolate(index);

    if (!std::isfinite(sample)) return 0.0f;
    return sample;
}

float WavetableOscillator::getSample(double frequency, double sampleRate) {
    if (!wavetable_ || wavetable_->sampleCount <= 0) {
        return 0.0f;
    }

    const int N = wavetable_->sampleCount;
    double increment = (frequency * N) / sampleRate;

    phase_ += increment;
    if (phase_ >= N) {
        phase_ -= N;
    }
    if (phase_ < 0.0) {
        phase_ += N;
    }

    // NaN/inf guard on phase
    if (!std::isfinite(phase_)) {
        phase_ = 0.0;
        return 0.0f;
    }

    float sample = interpolate(phase_);

    // NaN/inf guard on output
    if (!std::isfinite(sample)) {
        return 0.0f;
    }

    return sample;
}

float WavetableOscillator::interpolate(double index) const {
    const int N = wavetable_->sampleCount;
    const float* samples = wavetable_->samples;

    // Integer part and fractional part
    int i = static_cast<int>(std::floor(index));
    float frac = static_cast<float>(index - static_cast<double>(i));

    // Wrap to valid range
    i = i % N;
    if (i < 0) i += N;

    // Four neighboring samples with wraparound
    int im1 = (i - 1 + N) % N;
    int ip1 = (i + 1) % N;
    int ip2 = (i + 2) % N;

    float y0 = samples[im1];
    float y1 = samples[i];
    float y2 = samples[ip1];
    float y3 = samples[ip2];

    // Cubic hermite interpolation coefficients
    // c0 = y1
    // c1 = 1/2 * (y2 - y0)
    // c2 = y0 - 5/2 * y1 + 2 * y2 - 1/2 * y3
    // c3 = 3/2 * (y1 - y2) + 1/2 * (y3 - y0)
    float c0 = y1;
    float c1 = 0.5f * (y2 - y0);
    float c2 = y0 - 2.5f * y1 + 2.0f * y2 - 0.5f * y3;
    float c3 = 1.5f * (y1 - y2) + 0.5f * (y3 - y0);

    return ((c3 * frac + c2) * frac + c1) * frac + c0;
}

} // namespace openamp
