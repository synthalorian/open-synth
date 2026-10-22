#include "wavetable_oscillator.h"
#include <algorithm>
#include <cmath>
#include <complex>
#include <vector>

namespace opensynth {

namespace {

// In-place iterative radix-2 FFT. n must be a power of two.
void fft(std::vector<std::complex<double>>& a, bool inverse) {
    const size_t n = a.size();
    for (size_t i = 1, j = 0; i < n; ++i) {
        size_t bit = n >> 1;
        for (; j & bit; bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) std::swap(a[i], a[j]);
    }
    for (size_t len = 2; len <= n; len <<= 1) {
        const double ang = 2.0 * M_PI / static_cast<double>(len) * (inverse ? 1.0 : -1.0);
        const std::complex<double> wl(std::cos(ang), std::sin(ang));
        for (size_t i = 0; i < n; i += len) {
            std::complex<double> w(1.0);
            for (size_t k = 0; k < len / 2; ++k) {
                auto u = a[i + k];
                auto v = a[i + k + len / 2] * w;
                a[i + k] = u + v;
                a[i + k + len / 2] = u - v;
                w *= wl;
            }
        }
    }
    if (inverse) for (auto& x : a) x /= static_cast<double>(n);
}

bool isPowerOfTwo(int n) { return n > 0 && (n & (n - 1)) == 0; }

} // namespace

void Wavetable::buildMips() {
    freeMips();
    if (!samples || !isPowerOfTwo(sampleCount) || sampleCount < 8) return;

    const int n = sampleCount;
    std::vector<std::complex<double>> spec(n);
    for (int i = 0; i < n; ++i) spec[i] = samples[i];
    fft(spec, false);

    // Highest harmonic carrying non-negligible energy (relative to the peak).
    double peak = 0.0;
    for (int h = 1; h < n / 2; ++h) peak = std::max(peak, std::abs(spec[h]));
    int highest = 0;
    for (int h = 1; h <= n / 2; ++h)
        if (std::abs(spec[h]) > peak * 1e-5) highest = h;

    mips[0] = samples;
    numMips = 1;
    std::vector<std::complex<double>> work(n);
    for (int level = 1; level < kMaxMipLevels; ++level) {
        const int maxHarm = (n / 2) >> level;
        if (maxHarm < 1) break;
        if (maxHarm >= highest) {        // nothing to remove at this level
            mips[level] = mips[level - 1];
        } else {
            work = spec;
            for (int h = maxHarm + 1; h <= n - maxHarm - 1; ++h) work[h] = 0.0;
            fft(work, true);
            float* t = new float[n];
            for (int i = 0; i < n; ++i) t[i] = static_cast<float>(work[i].real());
            mips[level] = t;
        }
        numMips = level + 1;
    }
}

const float* Wavetable::tableForIncrement(double cyclesPerSample) const {
    if (numMips <= 1) return samples;
    const double inc = std::fabs(cyclesPerSample);
    if (!(inc > 0.0)) return samples;
    // Harmonics allowed below Nyquist for this pitch.
    const double allowed = 0.5 / inc;
    for (int level = 0; level < numMips; ++level) {
        const int maxHarm = (sampleCount / 2) >> level;
        if (maxHarm <= allowed) return mips[level];
    }
    return mips[numMips - 1];
}

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

float WavetableOscillator::getSampleAtPhase(float phase, double cyclesPerSample) const {
    if (!wavetable_ || wavetable_->sampleCount <= 0) {
        return 0.0f;
    }
    float p = phase - std::floor(phase);
    if (!std::isfinite(p)) return 0.0f;
    const float* table = wavetable_->tableForIncrement(cyclesPerSample);
    float sample = interpolate(table, static_cast<double>(p) * wavetable_->sampleCount);
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

    float sample = interpolate(wavetable_->tableForIncrement(frequency / sampleRate), phase_);

    // NaN/inf guard on output
    if (!std::isfinite(sample)) {
        return 0.0f;
    }

    return sample;
}

float WavetableOscillator::interpolate(double index) const {
    return interpolate(wavetable_->samples, index);
}

float WavetableOscillator::interpolate(const float* samples, double index) const {
    const int N = wavetable_->sampleCount;

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

} // namespace opensynth
