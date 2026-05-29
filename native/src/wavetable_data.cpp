#include "wavetable_oscillator.h"
#include <cmath>
#include <cstring>

namespace openamp {

static constexpr int kWavetableSize = 2048;

// ── Helper: generate a single-cycle additive wavetable with harmonic amplitudes ──
static void generateAdditive(float* samples, int size, const float* amplitudes, int numHarmonics) {
    // Normalize amplitudes to find max for later normalization
    float ampSum = 0.0f;
    for (int h = 0; h < numHarmonics; ++h) {
        ampSum += amplitudes[h];
    }

    float maxAbs = 0.0f;
    for (int i = 0; i < size; ++i) {
        float phase = (2.0f * static_cast<float>(M_PI) * i) / size;
        float val = 0.0f;
        for (int h = 0; h < numHarmonics; ++h) {
            val += std::sin(phase * (h + 1)) * amplitudes[h];
        }
        samples[i] = val;
        float absVal = std::fabs(val);
        if (absVal > maxAbs) maxAbs = absVal;
    }

    // Normalize to [-1, 1]
    if (maxAbs > 0.0001f) {
        float norm = 1.0f / maxAbs;
        for (int i = 0; i < size; ++i) {
            samples[i] *= norm;
        }
    }
}

// ── Piano: strong fundamental + harmonic series, rounded saw-like ──
// Amplitudes: fundamental 1.0, then decreasing 1/n + slight emphasis
static const float kPianoAmps[] = { 1.0f, 0.5f, 0.33f, 0.2f, 0.15f, 0.1f, 0.07f, 0.05f };
static constexpr int kPianoHarmonics = 8;

// ── Guitar: stronger even harmonics (string pluck), slightly asymmetric ──
// Amplitudes: 1.0, 0.6, 0.25, 0.3, 0.15, 0.12, 0.08, 0.04
static const float kGuitarAmps[] = { 1.0f, 0.6f, 0.25f, 0.3f, 0.15f, 0.12f, 0.08f, 0.04f };
static constexpr int kGuitarHarmonics = 8;

// ── Choir: formant-like, emphasis on 2nd and 4th harmonics ──
// Amplitudes: 0.7, 1.0, 0.5, 0.8, 0.3, 0.4, 0.15, 0.2
static const float kChoirAmps[] = { 0.7f, 1.0f, 0.5f, 0.8f, 0.3f, 0.4f, 0.15f, 0.2f };
static constexpr int kChoirHarmonics = 8;

// ── Static wavetable storage ──
// These are heap-allocated so they live for the process lifetime.
// The Wavetable struct owns the samples buffer.

static Wavetable* gPianoWt = nullptr;
static Wavetable* gGuitarWt = nullptr;
static Wavetable* gChoirWt = nullptr;

static void ensureWavetablesInitialized() {
    if (gPianoWt) return; // Already initialized

    gPianoWt = new Wavetable();
    gPianoWt->samples = new float[kWavetableSize];
    gPianoWt->sampleCount = kWavetableSize;
    gPianoWt->name = "Piano";
    generateAdditive(gPianoWt->samples, kWavetableSize, kPianoAmps, kPianoHarmonics);

    gGuitarWt = new Wavetable();
    gGuitarWt->samples = new float[kWavetableSize];
    gGuitarWt->sampleCount = kWavetableSize;
    gGuitarWt->name = "Guitar";
    generateAdditive(gGuitarWt->samples, kWavetableSize, kGuitarAmps, kGuitarHarmonics);

    gChoirWt = new Wavetable();
    gChoirWt->samples = new float[kWavetableSize];
    gChoirWt->sampleCount = kWavetableSize;
    gChoirWt->name = "Choir";
    generateAdditive(gChoirWt->samples, kWavetableSize, kChoirAmps, kChoirHarmonics);
}

const Wavetable* getBuiltinWavetable(int type) {
    ensureWavetablesInitialized();

    switch (type) {
    case 0: return gPianoWt;
    case 1: return gGuitarWt;
    case 2: return gChoirWt;
    default: return nullptr;
    }
}

} // namespace openamp
