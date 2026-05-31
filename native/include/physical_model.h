#pragma once
#include <cstdint>
#include <cmath>
#include <cstring>

namespace openamp {

// ── Physical modeling synthesis types ────────────────────────────────────────

enum class PhysicalModelType : uint8_t {
    OFF = 0,
    KARPLUS_STRONG,      // Plucked string (guitar, bass, harp)
    KARPLUS_BRIGHT,      // Brighter pluck (clavinet, harpsichord)
    KARPLUS_BASS,        // Deeper pluck (acoustic bass)
    MODAL_MALLET,        // Modal synthesis (marimba, xylophone)
    MODAL_VIBRAPHONE,    // Vibraphone with tremolo
    MODAL_STEEL_DRUM,    // Steel pan / drum
    COUNT
};

// ── Karplus-Strong string synthesis ──────────────────────────────────────────
//
// A delay line with a lowpass filter in the feedback loop simulates
// a vibrating string. The excitation is a short burst of noise.
//
// Key parameters:
//   - Delay length determines pitch
//   - Filter coefficient determines brightness/decay
//   - Excitation length determines "pluck hardness"
//   - Pick position affects tone (simulated by initial delay tap)

class KarplusStrongVoice {
public:
    KarplusStrongVoice();
    ~KarplusStrongVoice();

    void init(double sampleRate, int maxDelaySamples);
    void reset();

    // Trigger a note. freq = target frequency, velocity = 0-1
    void noteOn(float freq, float velocity, float brightness = 0.5f);
    void noteOff();

    // Generate one sample
    float process();

    bool isActive() const { return active_; }
    float getEnvelope() const { return envelope_; }

private:
    double sampleRate_ = 48000.0;
    float* delayLine_ = nullptr;
    int delaySize_ = 0;
    float readPos_ = 0.0f;
    float writePos_ = 0.0f;

    bool active_ = false;
    float envelope_ = 0.0f;
    float decayCoef_ = 0.99f;
    float filterState_ = 0.0f;
    float velocity_ = 1.0f;

    // Excitation
    int exciteCount_ = 0;
    int exciteLength_ = 0;
    float noiseSeed_ = 1.0f;

    static float fastRand(float& seed);
    static float lerp(float a, float b, float t);
};

// ── Modal synthesis (resonator bank) ─────────────────────────────────────────
//
// Multiple parallel bandpass filters at specific frequencies simulate
// the resonant modes of a physical object (bar, plate, membrane).
//
// Key parameters:
//   - Mode frequencies (inharmonic ratios for metal, harmonic for wood)
//   - Decay times per mode (higher modes decay faster)
//   - Excitation: noise burst or impulse

class ModalVoice {
public:
    static constexpr int kMaxModes = 8;

    ModalVoice();
    ~ModalVoice();

    void init(double sampleRate);
    void reset();

    // Trigger a note
    void noteOn(float freq, float velocity, int modePreset);
    void noteOff();

    // Generate one sample
    float process();

    bool isActive() const { return active_; }

private:
    double sampleRate_ = 48000.0;

    // Per-mode state
    struct Mode {
        float freq = 0.0f;
        float amp = 0.0f;
        float decay = 0.99f;
        float phase = 0.0f;
        float env = 0.0f;
        // State variable filter states
        float bp = 0.0f;
        float lp = 0.0f;
    };
    Mode modes_[kMaxModes];
    int numModes_ = 0;

    bool active_ = false;
    float velocity_ = 1.0f;
    float noiseSeed_ = 1.0f;
    int exciteCount_ = 0;
    int exciteLength_ = 0;

    static float fastRand(float& seed);
};

// ── Physical Model voice wrapper ─────────────────────────────────────────────

class PhysicalModelVoice {
public:
    PhysicalModelVoice();
    ~PhysicalModelVoice();

    void init(double sampleRate, int maxDelaySamples = 4096);
    void reset();

    void setType(PhysicalModelType type) { type_ = type; }
    PhysicalModelType type() const { return type_; }

    void noteOn(float freq, float velocity);
    void noteOff();

    float process();
    bool isActive() const;

private:
    PhysicalModelType type_ = PhysicalModelType::OFF;
    KarplusStrongVoice ksVoice_;
    ModalVoice modalVoice_;
};

} // namespace openamp
