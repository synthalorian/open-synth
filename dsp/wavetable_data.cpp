#include "wavetable_bank.h"
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

// ── Helper: generate with inharmonic partials ──
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

// ── Helper: apply simple lowpass filter to soften a wavetable ──
static void applyLowpass(float* samples, int size, float cutoff) {
    float state = samples[0];
    for (int i = 0; i < size; ++i) {
        state += cutoff * (samples[i] - state);
        samples[i] = state;
    }
    state = samples[0];
    for (int i = 0; i < size; ++i) {
        state += cutoff * (samples[i] - state);
        samples[i] = state;
    }
}

// ── Instrument definitions ─────────────────────────────────────────

// 0: Piano
static const float kPianoAmps[] = {
    1.0f, 0.55f, 0.35f, 0.22f, 0.15f, 0.10f, 0.07f, 0.05f,
    0.04f, 0.03f, 0.02f, 0.015f, 0.01f, 0.008f, 0.006f, 0.005f
};
// 1: Guitar
static const float kGuitarAmps[] = {
    1.0f, 0.65f, 0.30f, 0.35f, 0.18f, 0.15f, 0.10f, 0.07f,
    0.05f, 0.04f, 0.03f, 0.02f, 0.015f, 0.01f, 0.008f, 0.005f
};
// 2: Choir
static const float kChoirAmps[] = {
    0.75f, 1.0f, 0.55f, 0.85f, 0.35f, 0.45f, 0.20f, 0.25f,
    0.15f, 0.12f, 0.10f, 0.08f, 0.06f, 0.05f, 0.04f, 0.03f
};
// 3: Brass
static const float kBrassAmps[] = {
    1.0f, 0.85f, 0.70f, 0.55f, 0.45f, 0.35f, 0.28f, 0.22f,
    0.18f, 0.14f, 0.11f, 0.09f, 0.07f, 0.05f, 0.04f, 0.03f
};
// 4: Strings
static const float kStringsAmps[] = {
    1.0f, 0.70f, 0.50f, 0.38f, 0.28f, 0.20f, 0.14f, 0.10f,
    0.07f, 0.05f, 0.035f, 0.025f, 0.018f, 0.012f, 0.008f, 0.005f
};
// 5: Woodwind
static const float kWoodwindAmps[] = {
    1.0f, 0.15f, 0.55f, 0.10f, 0.25f, 0.08f, 0.15f, 0.06f,
    0.10f, 0.05f, 0.08f, 0.04f, 0.06f, 0.03f, 0.04f, 0.02f
};
// 6: Organ
static const float kOrganAmps[] = {
    1.0f, 0.90f, 0.80f, 0.70f, 0.60f, 0.50f, 0.42f, 0.35f,
    0.28f, 0.22f, 0.18f, 0.14f, 0.11f, 0.08f, 0.06f, 0.04f
};
// 7: Bell
static const float kBellFreqs[] = {1.0f, 2.76f, 5.40f, 8.93f, 13.34f, 18.64f, 24.0f, 30.0f};
static const float kBellAmps[] = {1.0f, 0.45f, 0.25f, 0.15f, 0.10f, 0.06f, 0.04f, 0.02f};
// 8: Synth Bass
static const float kBassAmps[] = {
    1.0f, 0.20f, 0.15f, 0.10f, 0.08f, 0.06f, 0.04f, 0.03f,
    0.02f, 0.015f, 0.01f, 0.008f, 0.005f, 0.003f, 0.002f, 0.001f
};
// 9: Synth Lead
static const float kLeadAmps[] = {
    1.0f, 0.80f, 0.60f, 0.45f, 0.35f, 0.28f, 0.22f, 0.18f,
    0.14f, 0.11f, 0.09f, 0.07f, 0.055f, 0.04f, 0.03f, 0.02f
};
// 10: Pad
static const float kPadAmps[] = {
    1.0f, 0.30f, 0.50f, 0.20f, 0.35f, 0.15f, 0.25f, 0.12f,
    0.18f, 0.10f, 0.12f, 0.08f, 0.08f, 0.06f, 0.05f, 0.04f
};
// 11: Electric Piano
static const float kEPianoAmps[] = {
    1.0f, 0.25f, 0.15f, 0.60f, 0.10f, 0.08f, 0.05f, 0.30f,
    0.04f, 0.03f, 0.03f, 0.15f, 0.02f, 0.02f, 0.02f, 0.08f
};
// 12: Vibraphone
static const float kVibraphoneAmps[] = {
    1.0f, 0.30f, 0.20f, 0.15f, 0.10f, 0.08f, 0.06f, 0.04f,
    0.03f, 0.02f, 0.015f, 0.01f, 0.008f, 0.005f, 0.003f, 0.002f
};
// 13: Marimba
static const float kMarimbaAmps[] = {
    1.0f, 0.40f, 0.15f, 0.30f, 0.08f, 0.12f, 0.05f, 0.08f,
    0.03f, 0.04f, 0.02f, 0.02f, 0.01f, 0.008f, 0.005f, 0.003f
};
// 14: Xylophone
static const float kXylophoneAmps[] = {
    1.0f, 0.50f, 0.25f, 0.35f, 0.15f, 0.20f, 0.10f, 0.12f,
    0.06f, 0.08f, 0.04f, 0.05f, 0.02f, 0.03f, 0.015f, 0.01f
};
// 15: Tubular Bells
static const float kTubularFreqs[] = {1.0f, 2.0f, 3.0f, 4.18f, 5.4f, 6.8f, 8.2f, 10.0f};
static const float kTubularAmps[] = {1.0f, 0.60f, 0.35f, 0.20f, 0.12f, 0.07f, 0.04f, 0.02f};
// 16: Dulcimer
static const float kDulcimerAmps[] = {
    1.0f, 0.55f, 0.30f, 0.40f, 0.18f, 0.22f, 0.12f, 0.14f,
    0.08f, 0.09f, 0.05f, 0.05f, 0.03f, 0.03f, 0.02f, 0.015f
};
// 17: Hammond Organ
static const float kHammondAmps[] = {
    1.0f, 0.95f, 0.85f, 0.75f, 0.65f, 0.55f, 0.45f, 0.38f,
    0.30f, 0.24f, 0.19f, 0.15f, 0.12f, 0.09f, 0.07f, 0.05f
};
// 18: Church Organ
static const float kChurchOrganAmps[] = {
    1.0f, 0.80f, 0.70f, 0.60f, 0.50f, 0.42f, 0.35f, 0.28f,
    0.22f, 0.18f, 0.14f, 0.11f, 0.08f, 0.06f, 0.04f, 0.03f
};
// 19: Reed Organ
static const float kReedOrganAmps[] = {
    1.0f, 0.60f, 0.45f, 0.35f, 0.25f, 0.18f, 0.13f, 0.09f,
    0.06f, 0.04f, 0.03f, 0.02f, 0.015f, 0.01f, 0.008f, 0.005f
};
// 20: Flute
static const float kFluteAmps[] = {
    1.0f, 0.20f, 0.40f, 0.08f, 0.20f, 0.06f, 0.12f, 0.05f,
    0.08f, 0.04f, 0.06f, 0.03f, 0.04f, 0.02f, 0.03f, 0.015f
};
// 21: Clarinet
static const float kClarinetAmps[] = {
    1.0f, 0.10f, 0.50f, 0.06f, 0.25f, 0.05f, 0.15f, 0.04f,
    0.10f, 0.03f, 0.07f, 0.02f, 0.05f, 0.02f, 0.03f, 0.01f
};
// 22: Oboe
static const float kOboeAmps[] = {
    1.0f, 0.30f, 0.60f, 0.15f, 0.35f, 0.10f, 0.20f, 0.08f,
    0.12f, 0.06f, 0.08f, 0.04f, 0.05f, 0.03f, 0.03f, 0.02f
};
// 23: Bassoon
static const float kBassoonAmps[] = {
    1.0f, 0.25f, 0.45f, 0.12f, 0.28f, 0.08f, 0.18f, 0.06f,
    0.12f, 0.05f, 0.08f, 0.03f, 0.05f, 0.02f, 0.03f, 0.015f
};
// 24: Recorder
static const float kRecorderAmps[] = {
    1.0f, 0.15f, 0.35f, 0.08f, 0.18f, 0.05f, 0.10f, 0.04f,
    0.06f, 0.03f, 0.04f, 0.02f, 0.03f, 0.015f, 0.01f, 0.008f
};
// 25: Pan Flute
static const float kPanFluteAmps[] = {
    1.0f, 0.20f, 0.30f, 0.10f, 0.15f, 0.06f, 0.08f, 0.04f,
    0.05f, 0.03f, 0.03f, 0.02f, 0.02f, 0.01f, 0.008f, 0.005f
};
// 26: Shakuhachi
static const float kShakuhachiAmps[] = {
    1.0f, 0.35f, 0.25f, 0.20f, 0.12f, 0.10f, 0.06f, 0.05f,
    0.03f, 0.03f, 0.02f, 0.015f, 0.01f, 0.008f, 0.005f, 0.003f
};
// 27: Whistle
static const float kWhistleAmps[] = {
    1.0f, 0.10f, 0.20f, 0.05f, 0.10f, 0.03f, 0.05f, 0.02f,
    0.03f, 0.015f, 0.02f, 0.01f, 0.01f, 0.005f, 0.003f, 0.002f
};
// 28: Ocarina
static const float kOcarinaAmps[] = {
    1.0f, 0.12f, 0.25f, 0.06f, 0.12f, 0.04f, 0.07f, 0.03f,
    0.04f, 0.02f, 0.03f, 0.015f, 0.02f, 0.01f, 0.008f, 0.005f
};
// 29: Square Lead
static const float kSquareLeadAmps[] = {
    1.0f, 0.0f, 0.33f, 0.0f, 0.20f, 0.0f, 0.14f, 0.0f,
    0.11f, 0.0f, 0.09f, 0.0f, 0.08f, 0.0f, 0.07f, 0.0f
};
// 30: Saw Lead
static const float kSawLeadAmps[] = {
    1.0f, 0.50f, 0.33f, 0.25f, 0.20f, 0.17f, 0.14f, 0.12f,
    0.11f, 0.10f, 0.09f, 0.08f, 0.08f, 0.07f, 0.07f, 0.06f
};
// 31: Calliope
static const float kCalliopeAmps[] = {
    1.0f, 0.40f, 0.30f, 0.25f, 0.15f, 0.12f, 0.08f, 0.06f,
    0.04f, 0.03f, 0.02f, 0.015f, 0.01f, 0.008f, 0.005f, 0.003f
};
// 32: Chiff Lead
static const float kChiffAmps[] = {
    1.0f, 0.60f, 0.40f, 0.30f, 0.20f, 0.14f, 0.10f, 0.07f,
    0.05f, 0.035f, 0.025f, 0.018f, 0.012f, 0.008f, 0.005f, 0.003f
};
// 33: Charang
static const float kCharangAmps[] = {
    1.0f, 0.70f, 0.50f, 0.35f, 0.25f, 0.18f, 0.13f, 0.09f,
    0.065f, 0.045f, 0.03f, 0.02f, 0.014f, 0.009f, 0.006f, 0.004f
};
// 34: Voice Lead
static const float kVoiceLeadAmps[] = {
    0.80f, 1.0f, 0.60f, 0.70f, 0.40f, 0.45f, 0.25f, 0.28f,
    0.15f, 0.16f, 0.10f, 0.10f, 0.06f, 0.06f, 0.04f, 0.03f
};
// 35: Fifth Lead
static const float kFifthLeadAmps[] = {
    1.0f, 0.0f, 0.80f, 0.0f, 0.50f, 0.0f, 0.35f, 0.0f,
    0.25f, 0.0f, 0.18f, 0.0f, 0.14f, 0.0f, 0.11f, 0.0f
};
// 36: Bass + Lead
static const float kBassLeadAmps[] = {
    1.0f, 0.30f, 0.60f, 0.20f, 0.40f, 0.15f, 0.28f, 0.12f,
    0.20f, 0.10f, 0.15f, 0.08f, 0.11f, 0.06f, 0.08f, 0.05f
};
// 37: New Age Pad
static const float kNewAgeAmps[] = {
    1.0f, 0.25f, 0.40f, 0.15f, 0.30f, 0.12f, 0.22f, 0.10f,
    0.16f, 0.08f, 0.12f, 0.06f, 0.09f, 0.05f, 0.06f, 0.04f
};
// 38: Warm Pad
static const float kWarmPadAmps[] = {
    1.0f, 0.35f, 0.55f, 0.22f, 0.38f, 0.16f, 0.28f, 0.12f,
    0.20f, 0.09f, 0.14f, 0.07f, 0.10f, 0.05f, 0.07f, 0.04f
};
// 39: Polysynth Pad
static const float kPolyPadAmps[] = {
    1.0f, 0.50f, 0.70f, 0.35f, 0.50f, 0.25f, 0.38f, 0.18f,
    0.28f, 0.14f, 0.20f, 0.10f, 0.14f, 0.07f, 0.10f, 0.05f
};
// 40: Synth Lead 2 (brighter)
static const float kLead2Amps[] = {
    1.0f, 0.90f, 0.70f, 0.55f, 0.42f, 0.32f, 0.25f, 0.20f,
    0.16f, 0.13f, 0.10f, 0.08f, 0.065f, 0.05f, 0.04f, 0.03f
};
// 41: Synth Bass 2 (punchier)
static const float kBass2Amps[] = {
    1.0f, 0.30f, 0.22f, 0.15f, 0.12f, 0.09f, 0.07f, 0.05f,
    0.04f, 0.03f, 0.022f, 0.017f, 0.012f, 0.009f, 0.006f, 0.004f
};
// 42: Synth Pad 2 (ambient)
static const float kPad2Amps[] = {
    1.0f, 0.20f, 0.45f, 0.12f, 0.32f, 0.09f, 0.22f, 0.07f,
    0.15f, 0.05f, 0.10f, 0.04f, 0.07f, 0.03f, 0.05f, 0.02f
};
// 43: Synth FX
static const float kSynthFxFreqs[] = {1.0f, 1.41f, 2.0f, 2.83f, 4.0f, 5.66f, 8.0f, 11.3f};
static const float kSynthFxAmps[] = {1.0f, 0.70f, 0.50f, 0.35f, 0.25f, 0.18f, 0.12f, 0.08f};
// 44: Ethnic 1 (Sitar)
static const float kSitarAmps[] = {
    1.0f, 0.50f, 0.35f, 0.40f, 0.20f, 0.25f, 0.12f, 0.15f,
    0.08f, 0.10f, 0.05f, 0.06f, 0.03f, 0.04f, 0.02f, 0.02f
};
// 45: Ethnic 2 (Shamisen)
static const float kShamisenAmps[] = {
    1.0f, 0.40f, 0.20f, 0.30f, 0.12f, 0.18f, 0.08f, 0.12f,
    0.05f, 0.08f, 0.03f, 0.05f, 0.02f, 0.03f, 0.015f, 0.02f
};
// 46: Ethnic 3 (Koto)
static const float kKotoAmps[] = {
    1.0f, 0.45f, 0.25f, 0.35f, 0.15f, 0.22f, 0.10f, 0.14f,
    0.06f, 0.09f, 0.04f, 0.06f, 0.025f, 0.04f, 0.02f, 0.025f
};
// 47: Percussive 1 (Timpani)
static const float kTimpaniAmps[] = {
    1.0f, 0.60f, 0.40f, 0.30f, 0.20f, 0.14f, 0.10f, 0.07f,
    0.05f, 0.035f, 0.025f, 0.018f, 0.012f, 0.008f, 0.005f, 0.003f
};
// 48: Percussive 2 (Agogo)
static const float kAgogoFreqs[] = {1.0f, 2.3f, 3.8f, 5.5f, 7.4f, 9.5f, 12.0f, 15.0f};
static const float kAgogoAmps[] = {1.0f, 0.50f, 0.30f, 0.18f, 0.10f, 0.06f, 0.03f, 0.015f};
// 49: Sound FX
static const float kSoundFxFreqs[] = {1.0f, 1.5f, 2.2f, 3.1f, 4.3f, 5.8f, 7.6f, 10.0f};
static const float kSoundFxAmps[] = {1.0f, 0.60f, 0.35f, 0.20f, 0.12f, 0.07f, 0.04f, 0.02f};
// 50: Harp
static const float kHarpAmps[] = {
    1.0f, 0.55f, 0.30f, 0.35f, 0.18f, 0.20f, 0.10f, 0.12f,
    0.06f, 0.07f, 0.035f, 0.04f, 0.02f, 0.022f, 0.012f, 0.01f
};
// 51: Accordion
static const float kAccordionAmps[] = {
    1.0f, 0.70f, 0.50f, 0.40f, 0.30f, 0.22f, 0.16f, 0.12f,
    0.09f, 0.07f, 0.05f, 0.04f, 0.03f, 0.02f, 0.015f, 0.01f
};
// 52: Harmonica
static const float kHarmonicaAmps[] = {
    1.0f, 0.25f, 0.45f, 0.12f, 0.22f, 0.08f, 0.12f, 0.05f,
    0.07f, 0.03f, 0.04f, 0.02f, 0.025f, 0.012f, 0.015f, 0.008f
};
// 53: Banjo
static const float kBanjoAmps[] = {
    1.0f, 0.50f, 0.25f, 0.30f, 0.14f, 0.16f, 0.08f, 0.10f,
    0.05f, 0.06f, 0.03f, 0.035f, 0.018f, 0.02f, 0.01f, 0.012f
};
// 54: Shamisen (same as 45 but distinct)
static const float kShamisen2Amps[] = {
    1.0f, 0.35f, 0.18f, 0.28f, 0.11f, 0.16f, 0.07f, 0.10f,
    0.045f, 0.07f, 0.025f, 0.04f, 0.018f, 0.025f, 0.012f, 0.015f
};
// 55: Koto (same as 46 but distinct)
static const float kKoto2Amps[] = {
    1.0f, 0.40f, 0.22f, 0.32f, 0.14f, 0.20f, 0.09f, 0.12f,
    0.055f, 0.08f, 0.035f, 0.05f, 0.022f, 0.035f, 0.015f, 0.02f
};
// 56: Kalimba
static const float kKalimbaFreqs[] = {1.0f, 4.0f, 7.0f, 10.5f, 14.0f, 18.0f, 22.0f, 27.0f};
static const float kKalimbaAmps[] = {1.0f, 0.45f, 0.20f, 0.10f, 0.05f, 0.025f, 0.012f, 0.006f};
// 57: Bagpipe
static const float kBagpipeAmps[] = {
    1.0f, 0.30f, 0.55f, 0.15f, 0.30f, 0.10f, 0.18f, 0.07f,
    0.12f, 0.05f, 0.08f, 0.03f, 0.05f, 0.02f, 0.03f, 0.015f
};
// 58: Fiddle
static const float kFiddleAmps[] = {
    1.0f, 0.75f, 0.45f, 0.50f, 0.28f, 0.30f, 0.18f, 0.20f,
    0.12f, 0.13f, 0.08f, 0.09f, 0.05f, 0.06f, 0.035f, 0.04f
};
// 59: Shanai
static const float kShanaiAmps[] = {
    1.0f, 0.60f, 0.40f, 0.35f, 0.22f, 0.20f, 0.12f, 0.11f,
    0.07f, 0.06f, 0.04f, 0.035f, 0.022f, 0.02f, 0.012f, 0.01f
};

static constexpr int kNumWavetables = 60;

struct WavetableEntry {
    Wavetable* soft = nullptr;
    Wavetable* medium = nullptr;
    Wavetable* hard = nullptr;
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
    
    snprintf(nameBuf, sizeof(nameBuf), "%s Soft", baseName);
    gWavetables[idx].soft = createWavetable(nameBuf);
    float softAmps[kMaxHarmonics];
    std::memcpy(softAmps, amplitudes, sizeof(float) * numHarmonics);
    for (int h = numHarmonics / 3; h < numHarmonics; ++h) {
        softAmps[h] *= 0.3f;
    }
    generateAdditive(gWavetables[idx].soft->samples, kWavetableSize, softAmps, numHarmonics);
    applyLowpass(gWavetables[idx].soft->samples, kWavetableSize, 0.15f);
    
    snprintf(nameBuf, sizeof(nameBuf), "%s", baseName);
    gWavetables[idx].medium = createWavetable(nameBuf);
    generateAdditive(gWavetables[idx].medium->samples, kWavetableSize, amplitudes, numHarmonics);
    
    snprintf(nameBuf, sizeof(nameBuf), "%s Hard", baseName);
    gWavetables[idx].hard = createWavetable(nameBuf);
    float hardAmps[kMaxHarmonics];
    std::memcpy(hardAmps, amplitudes, sizeof(float) * numHarmonics);
    for (int h = numHarmonics / 2; h < numHarmonics; ++h) {
        hardAmps[h] *= 1.5f;
    }
    generateAdditive(gWavetables[idx].hard->samples, kWavetableSize, hardAmps, numHarmonics);
}

static void generateInharmonicEntry(int idx, const float* freqs, const float* amps, int numPartials,
                                    const char* baseName) {
    char nameBuf[64];
    snprintf(nameBuf, sizeof(nameBuf), "%s", baseName);
    gWavetables[idx].soft = createWavetable(nameBuf);
    gWavetables[idx].medium = gWavetables[idx].soft;
    gWavetables[idx].hard = gWavetables[idx].soft;
    generateInharmonic(gWavetables[idx].soft->samples, kWavetableSize, freqs, amps, numPartials);
}

static void ensureWavetablesInitialized() {
    if (gInitialized) return;
    
    generateVelocityLayers(0, kPianoAmps, 16, "Piano");
    generateVelocityLayers(1, kGuitarAmps, 16, "Guitar");
    generateVelocityLayers(2, kChoirAmps, 16, "Choir");
    generateVelocityLayers(3, kBrassAmps, 16, "Brass");
    generateVelocityLayers(4, kStringsAmps, 16, "Strings");
    generateVelocityLayers(5, kWoodwindAmps, 16, "Woodwind");
    generateVelocityLayers(6, kOrganAmps, 16, "Organ");
    // 7: Bell (inharmonic, no velocity layers)
    gWavetables[7].soft = createWavetable("Bell");
    gWavetables[7].medium = gWavetables[7].soft;
    gWavetables[7].hard = gWavetables[7].soft;
    generateInharmonic(gWavetables[7].soft->samples, kWavetableSize, kBellFreqs, kBellAmps, 8);
    generateVelocityLayers(8, kBassAmps, 16, "Synth Bass");
    generateVelocityLayers(9, kLeadAmps, 16, "Synth Lead");
    generateVelocityLayers(10, kPadAmps, 16, "Pad");
    generateVelocityLayers(11, kEPianoAmps, 16, "Electric Piano");
    generateVelocityLayers(12, kVibraphoneAmps, 16, "Vibraphone");
    generateVelocityLayers(13, kMarimbaAmps, 16, "Marimba");
    generateVelocityLayers(14, kXylophoneAmps, 16, "Xylophone");
    // 15: Tubular Bells
    gWavetables[15].soft = createWavetable("Tubular Bells");
    gWavetables[15].medium = gWavetables[15].soft;
    gWavetables[15].hard = gWavetables[15].soft;
    generateInharmonic(gWavetables[15].soft->samples, kWavetableSize, kTubularFreqs, kTubularAmps, 8);
    generateVelocityLayers(16, kDulcimerAmps, 16, "Dulcimer");
    generateVelocityLayers(17, kHammondAmps, 16, "Hammond Organ");
    generateVelocityLayers(18, kChurchOrganAmps, 16, "Church Organ");
    generateVelocityLayers(19, kReedOrganAmps, 16, "Reed Organ");
    generateVelocityLayers(20, kFluteAmps, 16, "Flute");
    generateVelocityLayers(21, kClarinetAmps, 16, "Clarinet");
    generateVelocityLayers(22, kOboeAmps, 16, "Oboe");
    generateVelocityLayers(23, kBassoonAmps, 16, "Bassoon");
    generateVelocityLayers(24, kRecorderAmps, 16, "Recorder");
    generateVelocityLayers(25, kPanFluteAmps, 16, "Pan Flute");
    generateVelocityLayers(26, kShakuhachiAmps, 16, "Shakuhachi");
    generateVelocityLayers(27, kWhistleAmps, 16, "Whistle");
    generateVelocityLayers(28, kOcarinaAmps, 16, "Ocarina");
    generateVelocityLayers(29, kSquareLeadAmps, 16, "Square Lead");
    generateVelocityLayers(30, kSawLeadAmps, 16, "Saw Lead");
    generateVelocityLayers(31, kCalliopeAmps, 16, "Calliope");
    generateVelocityLayers(32, kChiffAmps, 16, "Chiff Lead");
    generateVelocityLayers(33, kCharangAmps, 16, "Charang");
    generateVelocityLayers(34, kVoiceLeadAmps, 16, "Voice Lead");
    generateVelocityLayers(35, kFifthLeadAmps, 16, "Fifth Lead");
    generateVelocityLayers(36, kBassLeadAmps, 16, "Bass + Lead");
    generateVelocityLayers(37, kNewAgeAmps, 16, "New Age Pad");
    generateVelocityLayers(38, kWarmPadAmps, 16, "Warm Pad");
    generateVelocityLayers(39, kPolyPadAmps, 16, "Polysynth Pad");
    generateVelocityLayers(40, kLead2Amps, 16, "Synth Lead 2");
    generateVelocityLayers(41, kBass2Amps, 16, "Synth Bass 2");
    generateVelocityLayers(42, kPad2Amps, 16, "Synth Pad 2");
    // 43: Synth FX
    gWavetables[43].soft = createWavetable("Synth FX");
    gWavetables[43].medium = gWavetables[43].soft;
    gWavetables[43].hard = gWavetables[43].soft;
    generateInharmonic(gWavetables[43].soft->samples, kWavetableSize, kSynthFxFreqs, kSynthFxAmps, 8);
    generateVelocityLayers(44, kSitarAmps, 16, "Sitar");
    generateVelocityLayers(45, kShamisenAmps, 16, "Shamisen");
    generateVelocityLayers(46, kKotoAmps, 16, "Koto");
    generateVelocityLayers(47, kTimpaniAmps, 16, "Timpani");
    // 48: Agogo
    gWavetables[48].soft = createWavetable("Agogo");
    gWavetables[48].medium = gWavetables[48].soft;
    gWavetables[48].hard = gWavetables[48].soft;
    generateInharmonic(gWavetables[48].soft->samples, kWavetableSize, kAgogoFreqs, kAgogoAmps, 8);
    // 49: Sound FX
    gWavetables[49].soft = createWavetable("Sound FX");
    gWavetables[49].medium = gWavetables[49].soft;
    gWavetables[49].hard = gWavetables[49].soft;
    generateInharmonic(gWavetables[49].soft->samples, kWavetableSize, kSoundFxFreqs, kSoundFxAmps, 8);
    // 56: Kalimba
    gWavetables[56].soft = createWavetable("Kalimba");
    gWavetables[56].medium = gWavetables[56].soft;
    gWavetables[56].hard = gWavetables[56].soft;
    generateInharmonic(gWavetables[56].soft->samples, kWavetableSize, kKalimbaFreqs, kKalimbaAmps, 8);
    generateVelocityLayers(50, kHarpAmps, 16, "Harp");
    generateVelocityLayers(51, kAccordionAmps, 16, "Accordion");
    generateVelocityLayers(52, kHarmonicaAmps, 16, "Harmonica");
    generateVelocityLayers(53, kBanjoAmps, 16, "Banjo");
    generateVelocityLayers(54, kShamisen2Amps, 16, "Shamisen 2");
    generateVelocityLayers(55, kKoto2Amps, 16, "Koto 2");
    generateVelocityLayers(57, kBagpipeAmps, 16, "Bagpipe");
    generateVelocityLayers(58, kFiddleAmps, 16, "Fiddle");
    generateVelocityLayers(59, kShanaiAmps, 16, "Shanai");
    
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
