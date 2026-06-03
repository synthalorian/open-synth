#pragma once
#include <cstdint>
#include <cmath>

namespace opensynth {

// ── Instrument Realism Engine ────────────────────────────────────────────────
//
// Adds acoustic instrument character to synthesized voices.
// This is the "secret sauce" that makes wavetable + subtractive synthesis
// sound like a real Roland workstation instead of a cheap toy keyboard.
//
// Features:
//   1. Velocity-sensitive brightness (harder hit = more harmonics)
//   2. Key-click / hammer noise (piano, clavinet, harpsichord)
//   3. Body resonance filter (simulates instrument cavity/body)
//   4. Sympathetic string resonance (held notes ring together)
//   5. Attack transient shaping (instrument-specific curves)
//
// All processing is per-voice, per-sample, CPU-light.

// ── Body Resonance Filter ────────────────────────────────────────────────────
// Simulates the acoustic resonance of an instrument body (guitar, piano, etc.)
// using a parallel bank of 3 resonant bandpass filters at body-mode frequencies.

struct BodyResonance {
    // Mode frequencies (Hz) and Q factors for different instrument types
    static constexpr float kPianoModes[3] = {120.0f, 280.0f, 450.0f};
    static constexpr float kPianoQs[3] = {8.0f, 6.0f, 4.0f};
    static constexpr float kPianoAmps[3] = {0.3f, 0.2f, 0.1f};

    static constexpr float kGuitarModes[3] = {98.0f, 196.0f, 294.0f};
    static constexpr float kGuitarQs[3] = {10.0f, 8.0f, 6.0f};
    static constexpr float kGuitarAmps[3] = {0.4f, 0.25f, 0.15f};

    static constexpr float kViolinModes[3] = {280.0f, 440.0f, 680.0f};
    static constexpr float kViolinQs[3] = {12.0f, 10.0f, 8.0f};
    static constexpr float kViolinAmps[3] = {0.35f, 0.25f, 0.15f};

    static constexpr float kOrganModes[3] = {80.0f, 160.0f, 240.0f};
    static constexpr float kOrganQs[3] = {6.0f, 5.0f, 4.0f};
    static constexpr float kOrganAmps[3] = {0.5f, 0.3f, 0.15f};

    static constexpr float kBrassModes[3] = {180.0f, 350.0f, 520.0f};
    static constexpr float kBrassQs[3] = {7.0f, 6.0f, 5.0f};
    static constexpr float kBrassAmps[3] = {0.45f, 0.3f, 0.15f};

    static constexpr float kPluckedModes[3] = {150.0f, 300.0f, 450.0f};
    static constexpr float kPluckedQs[3] = {9.0f, 7.0f, 5.0f};
    static constexpr float kPluckedAmps[3] = {0.35f, 0.25f, 0.15f};

    static constexpr float kMalletModes[3] = {200.0f, 400.0f, 600.0f};
    static constexpr float kMalletQs[3] = {11.0f, 9.0f, 7.0f};
    static constexpr float kMalletAmps[3] = {0.3f, 0.2f, 0.1f};

    // State variable filter states for 3 parallel resonators
    struct ModeState {
        float bp = 0.0f;
        float lp = 0.0f;
    };
    ModeState modes[3];

    void reset();
    float process(float input, double sampleRate, const float* freqs, const float* qs, const float* amps);
};

// ── Key Click / Hammer Noise ─────────────────────────────────────────────────
// Generates a short noise burst + high-frequency click at note onset.
// Used for piano (hammer strike), clavinet (key mechanism), harpsichord (quill pluck).

struct KeyClickGenerator {
    bool active = false;
    float envelope = 0.0f;
    float decay = 0.995f;
    float noiseSeed = 1.0f;
    float level = 0.3f;
    float filterState = 0.0f;
    int samplesRemaining = 0;

    void trigger(float velocity, float clickDurationMs, double sampleRate);
    void reset();
    float process(double sampleRate);
};

// ── Sympathetic Resonance ────────────────────────────────────────────────────
// When multiple notes are held, they excite each other's partials.
// Simplified model: a global resonator bank that all voices feed into.

struct SympatheticResonator {
    static constexpr int kMaxStrings = 12;  // Track up to 12 held notes

    struct StringState {
        bool active = false;
        float freq = 0.0f;
        float velocity = 0.0f;
        float envelope = 0.0f;
        float phase = 0.0f;
        float decay = 0.999f;
    };
    StringState strings[kMaxStrings];

    void noteOn(float freq, float velocity);
    void noteOff(float freq);
    void reset();
    float process(double sampleRate);
};

// ── Velocity Brightness ──────────────────────────────────────────────────────
// Maps velocity to a brightness multiplier that boosts high frequencies.
// Applied as a filter cutoff multiplier or harmonic boost.

inline float velocityBrightness(float velocity, float sensitivity) {
    // velocity 0-1, sensitivity 0-1
    // Returns 1.0 (no change) at low velocity, up to 1.0 + sensitivity at high velocity
    return 1.0f + sensitivity * velocity * velocity;
}

// ── Attack Transient Shaper ──────────────────────────────────────────────────
// Instrument-specific attack curves:
//   0 = linear (default synth)
//   1 = exponential (piano — fast initial hit, quick settle)
//   2 = logarithmic (organ — slow build)
//   3 = double-exponential (plucked strings — very fast attack)

inline float applyAttackCurve(float phase, int curveType) {
    switch (curveType) {
        case 1:  // Exponential — piano
            return 1.0f - std::exp(-phase * 8.0f);
        case 2:  // Logarithmic — organ
            return std::log1p(phase * 3.0f) / std::log1p(3.0f);
        case 3:  // Double-exponential — plucked
            return 1.0f - std::exp(-phase * 20.0f);
        default: // Linear
            return phase;
    }
}

// ── Realism Processor (per-voice) ────────────────────────────────────────────
// Combines all realism features into one struct that lives on each Voice.

struct InstrumentRealism {
    BodyResonance body;
    KeyClickGenerator click;
    SympatheticResonator sympathetic;  // Note: this is global-ish, shared across voices

    // Configuration
    int bodyType = 0;        // 0=none, 1=piano, 2=guitar, 3=violin, 4=organ, 5=brass, 6=plucked, 7=mallet
    float bodyMix = 0.0f;    // 0-1, amount of body resonance
    float clickMix = 0.0f;   // 0-1, amount of key click
    float sympatheticMix = 0.0f;  // 0-1, amount of sympathetic resonance
    int attackCurve = 0;     // 0=linear, 1=exponential, 2=log, 3=double-exp
    float brightnessSens = 0.0f;  // 0-1, velocity brightness sensitivity

    void reset();
    float process(float input, float velocity, double sampleRate, float noteAge);
};

} // namespace opensynth
