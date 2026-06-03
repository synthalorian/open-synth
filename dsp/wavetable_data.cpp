#include "wavetable_oscillator.h"
#include <cmath>
#include <cstring>
#include <cstdio>

namespace opensynth {

static constexpr int kWavetableSize = 2048;
static constexpr int kMaxHarmonics = 64;

// ── Helper: generate additive wavetable with harmonic amplitudes ──
static void generateAdditive(float* samples, int size, const float* amplitudes, int numHarmonics) {
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
    if (maxAbs > 0.0001f) {
        float norm = 1.0f / maxAbs;
        for (int i = 0; i < size; ++i) samples[i] *= norm;
    }
}

// ── Helper: generate with inharmonic partials (for bells, metallic sounds) ──
static void generateInharmonic(float* samples, int size, const float* freqs, const float* amps, int numPartials) {
    float maxAbs = 0.0f;
    for (int i = 0; i < size; ++i) {
        float phase = (2.0f * static_cast<float>(M_PI) * i) / size;
        float val = 0.0f;
        for (int p = 0; p < numPartials; ++p) {
            val += std::sin(phase * freqs[p]) * amps[p];
        }
        samples[i] = val;
        float absVal = std::fabs(val);
        if (absVal > maxAbs) maxAbs = absVal;
    }
    if (maxAbs > 0.0001f) {
        float norm = 1.0f / maxAbs;
        for (int i = 0; i < size; ++i) samples[i] *= norm;
    }
}

// ── Helper: generate pulse wave with variable width ──
static void generatePulse(float* samples, int size, float width) {
    for (int i = 0; i < size; ++i) {
        float phase = static_cast<float>(i) / size;
        samples[i] = (phase < width) ? 1.0f : -1.0f;
    }
    // Remove DC offset
    float dc = 0.0f;
    for (int i = 0; i < size; ++i) dc += samples[i];
    dc /= size;
    for (int i = 0; i < size; ++i) samples[i] -= dc;
}

// ── Helper: generate sawtooth via additive (bandlimited) ──
static void generateSaw(float* samples, int size, int harmonics) {
    float maxAbs = 0.0f;
    for (int i = 0; i < size; ++i) {
        float phase = (2.0f * static_cast<float>(M_PI) * i) / size;
        float val = 0.0f;
        for (int h = 1; h <= harmonics; ++h) {
            val += std::sin(phase * h) / h;
        }
        samples[i] = val;
        float absVal = std::fabs(val);
        if (absVal > maxAbs) maxAbs = absVal;
    }
    if (maxAbs > 0.0001f) {
        float norm = 1.0f / maxAbs;
        for (int i = 0; i < size; ++i) samples[i] *= norm;
    }
}

// ── Helper: generate square via additive ──
static void generateSquare(float* samples, int size, int harmonics) {
    float maxAbs = 0.0f;
    for (int i = 0; i < size; ++i) {
        float phase = (2.0f * static_cast<float>(M_PI) * i) / size;
        float val = 0.0f;
        for (int h = 1; h <= harmonics; h += 2) {
            val += std::sin(phase * h) / h;
        }
        samples[i] = val;
        float absVal = std::fabs(val);
        if (absVal > maxAbs) maxAbs = absVal;
    }
    if (maxAbs > 0.0001f) {
        float norm = 1.0f / maxAbs;
        for (int i = 0; i < size; ++i) samples[i] *= norm;
    }
}

// ── Helper: apply simple lowpass filter to soften a wavetable ──
static void applyLowpass(float* samples, int size, float cutoff) {
    float state = samples[0];
    for (int i = 0; i < size; ++i) {
        state += cutoff * (samples[i] - state);
        samples[i] = state;
    }
    // Second pass for steeper rolloff
    state = samples[0];
    for (int i = 0; i < size; ++i) {
        state += cutoff * (samples[i] - state);
        samples[i] = state;
    }
}

// ── Instrument definitions ─────────────────────────────────────────

// 0: Piano — strong fundamental, moderate harmonics, slight inharmonicity
static const float kPianoAmps[] = {
    1.0f, 0.55f, 0.35f, 0.22f, 0.15f, 0.10f, 0.07f, 0.05f,
    0.04f, 0.03f, 0.02f, 0.015f, 0.01f, 0.008f, 0.006f, 0.005f
};

// 1: Guitar — stronger even harmonics, plucked character
static const float kGuitarAmps[] = {
    1.0f, 0.65f, 0.30f, 0.35f, 0.18f, 0.15f, 0.10f, 0.07f,
    0.05f, 0.04f, 0.03f, 0.02f, 0.015f, 0.01f, 0.008f, 0.005f
};

// 2: Choir — formant-like, emphasis on 2nd/4th
static const float kChoirAmps[] = {
    0.75f, 1.0f, 0.55f, 0.85f, 0.35f, 0.45f, 0.20f, 0.25f,
    0.15f, 0.12f, 0.10f, 0.08f, 0.06f, 0.05f, 0.04f, 0.03f
};

// 3: Brass — rich, slightly buzzy, strong harmonics
static const float kBrassAmps[] = {
    1.0f, 0.85f, 0.70f, 0.55f, 0.45f, 0.35f, 0.28f, 0.22f,
    0.18f, 0.14f, 0.11f, 0.09f, 0.07f, 0.05f, 0.04f, 0.03f
};

// 4: Strings — saw-like but softer, rolled off highs
static const float kStringsAmps[] = {
    1.0f, 0.70f, 0.50f, 0.38f, 0.28f, 0.20f, 0.14f, 0.10f,
    0.07f, 0.05f, 0.035f, 0.025f, 0.018f, 0.012f, 0.008f, 0.005f
};

// 5: Woodwind — hollow, odd harmonics emphasis
static const float kWoodwindAmps[] = {
    1.0f, 0.15f, 0.55f, 0.10f, 0.25f, 0.08f, 0.15f, 0.06f,
    0.10f, 0.05f, 0.08f, 0.04f, 0.06f, 0.03f, 0.04f, 0.02f
};

// 6: Organ — bright, full harmonics
static const float kOrganAmps[] = {
    1.0f, 0.90f, 0.80f, 0.70f, 0.60f, 0.50f, 0.42f, 0.35f,
    0.28f, 0.22f, 0.18f, 0.14f, 0.11f, 0.08f, 0.06f, 0.04f
};

// 7: Bell — inharmonic partials (tubular bell ratios)
static const float kBellFreqs[] = {
    1.0f, 2.76f, 5.40f, 8.93f, 13.34f, 18.64f, 24.0f, 30.0f
};
static const float kBellAmps[] = {
    1.0f, 0.45f, 0.25f, 0.15f, 0.10f, 0.06f, 0.04f, 0.02f
};

// 8: Synth Bass — punchy, few strong harmonics
static const float kBassAmps[] = {
    1.0f, 0.20f, 0.15f, 0.10f, 0.08f, 0.06f, 0.04f, 0.03f,
    0.02f, 0.015f, 0.01f, 0.008f, 0.005f, 0.003f, 0.002f, 0.001f
};

// 9: Synth Lead — bright saw-rich
static const float kLeadAmps[] = {
    1.0f, 0.80f, 0.60f, 0.45f, 0.35f, 0.28f, 0.22f, 0.18f,
    0.14f, 0.11f, 0.09f, 0.07f, 0.055f, 0.04f, 0.03f, 0.02f
};

// 10: Pad — soft, even harmonics
static const float kPadAmps[] = {
    1.0f, 0.30f, 0.50f, 0.20f, 0.35f, 0.15f, 0.25f, 0.12f,
    0.18f, 0.10f, 0.12f, 0.08f, 0.08f, 0.06f, 0.05f, 0.04f
};

// 11: Electric Piano — tine with bell overtone
static const float kEPianoAmps[] = {
    1.0f, 0.25f, 0.15f, 0.60f, 0.10f, 0.08f, 0.05f, 0.30f,
    0.04f, 0.03f, 0.03f, 0.15f, 0.02f, 0.02f, 0.02f, 0.08f
};

static constexpr int kNumWavetables = 12;

// ── Wavetable storage ──

struct WavetableEntry {
    Wavetable* soft = nullptr;    // low velocity
    Wavetable* medium = nullptr;  // normal velocity
    Wavetable* hard = nullptr;    // high velocity
};

static WavetableEntry gWavetables[kNumWavetables];
static bool gInitialized = false;

static Wavetable* createWavetable(const char* name) {
    Wavetable* wt = new Wavetable();
    wt->samples = new float[kWavetableSize];
    wt->sampleCount = kWavetableSize;
    wt->name = name;
    return wt;
}

static void generateVelocityLayers(int idx, const float* amplitudes, int numHarmonics,
                                   const char* baseName) {
    char nameBuf[64];
    
    // Soft layer: fewer harmonics, lowpass filtered
    snprintf(nameBuf, sizeof(nameBuf), "%s Soft", baseName);
    gWavetables[idx].soft = createWavetable(nameBuf);
    float softAmps[kMaxHarmonics];
    std::memcpy(softAmps, amplitudes, sizeof(float) * numHarmonics);
    // Roll off higher harmonics
    for (int h = numHarmonics / 3; h < numHarmonics; ++h) {
        softAmps[h] *= 0.3f;
    }
    generateAdditive(gWavetables[idx].soft->samples, kWavetableSize, softAmps, numHarmonics);
    applyLowpass(gWavetables[idx].soft->samples, kWavetableSize, 0.15f);
    
    // Medium layer: full harmonics
    snprintf(nameBuf, sizeof(nameBuf), "%s", baseName);
    gWavetables[idx].medium = createWavetable(nameBuf);
    generateAdditive(gWavetables[idx].medium->samples, kWavetableSize, amplitudes, numHarmonics);
    
    // Hard layer: enhanced highs, slight saturation character
    snprintf(nameBuf, sizeof(nameBuf), "%s Hard", baseName);
    gWavetables[idx].hard = createWavetable(nameBuf);
    float hardAmps[kMaxHarmonics];
    std::memcpy(hardAmps, amplitudes, sizeof(float) * numHarmonics);
    // Boost higher harmonics
    for (int h = numHarmonics / 2; h < numHarmonics; ++h) {
        hardAmps[h] *= 1.5f;
    }
    generateAdditive(gWavetables[idx].hard->samples, kWavetableSize, hardAmps, numHarmonics);
}

static void ensureWavetablesInitialized() {
    if (gInitialized) return;
    
    // 0: Piano
    generateVelocityLayers(0, kPianoAmps, 16, "Piano");
    
    // 1: Guitar
    generateVelocityLayers(1, kGuitarAmps, 16, "Guitar");
    
    // 2: Choir
    generateVelocityLayers(2, kChoirAmps, 16, "Choir");
    
    // 3: Brass
    generateVelocityLayers(3, kBrassAmps, 16, "Brass");
    
    // 4: Strings
    generateVelocityLayers(4, kStringsAmps, 16, "Strings");
    
    // 5: Woodwind
    generateVelocityLayers(5, kWoodwindAmps, 16, "Woodwind");
    
    // 6: Organ
    generateVelocityLayers(6, kOrganAmps, 16, "Organ");
    
    // 7: Bell (inharmonic, no velocity layers — bells don't change much with velocity)
    gWavetables[7].soft = createWavetable("Bell");
    gWavetables[7].medium = gWavetables[7].soft;
    gWavetables[7].hard = gWavetables[7].soft;
    generateInharmonic(gWavetables[7].soft->samples, kWavetableSize, kBellFreqs, kBellAmps, 8);
    
    // 8: Synth Bass
    generateVelocityLayers(8, kBassAmps, 16, "Synth Bass");
    
    // 9: Synth Lead
    generateVelocityLayers(9, kLeadAmps, 16, "Synth Lead");
    
    // 10: Pad
    generateVelocityLayers(10, kPadAmps, 16, "Pad");
    
    // 11: Electric Piano
    generateVelocityLayers(11, kEPianoAmps, 16, "Electric Piano");
    
    gInitialized = true;
}

const Wavetable* getBuiltinWavetable(int type) {
    ensureWavetablesInitialized();
    if (type < 0 || type >= kNumWavetables) return nullptr;
    return gWavetables[type].medium;
}

const Wavetable* getBuiltinWavetableWithVelocity(int type, float velocity) {
    ensureWavetablesInitialized();
    if (type < 0 || type >= kNumWavetables) return nullptr;
    if (velocity < 0.4f) return gWavetables[type].soft;
    if (velocity > 0.75f) return gWavetables[type].hard;
    return gWavetables[type].medium;
}

int getBuiltinWavetableCount() {
    return kNumWavetables;
}

const char* getBuiltinWavetableName(int type) {
    ensureWavetablesInitialized();
    if (type < 0 || type >= kNumWavetables) return nullptr;
    return gWavetables[type].medium->name;
}

} // namespace opensynth
