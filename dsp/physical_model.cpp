#include "physical_model.h"
#include <cmath>
#include <cstring>
#include <algorithm>

namespace opensynth {

// ── Helpers ───────────────────────────────────────────────────────────────────

float KarplusStrongVoice::fastRand(float& seed) {
    uint32_t s;
    std::memcpy(&s, &seed, sizeof(s));
    s = s * 1103515245u + 12345u;
    std::memcpy(&seed, &s, sizeof(seed));
    return static_cast<float>((s >> 16) & 0x7FFF) / 16384.0f - 1.0f;
}

float KarplusStrongVoice::lerp(float a, float b, float t) {
    return a + (b - a) * t;
}

float ModalVoice::fastRand(float& seed) {
    uint32_t s;
    std::memcpy(&s, &seed, sizeof(s));
    s = s * 1103515245u + 12345u;
    std::memcpy(&seed, &s, sizeof(seed));
    return static_cast<float>((s >> 16) & 0x7FFF) / 16384.0f - 1.0f;
}

// ── Karplus-Strong ────────────────────────────────────────────────────────────

KarplusStrongVoice::KarplusStrongVoice() = default;

KarplusStrongVoice::~KarplusStrongVoice() {
    delete[] delayLine_;
}

void KarplusStrongVoice::init(double sampleRate, int maxDelaySamples) {
    sampleRate_ = sampleRate;
    delaySize_ = maxDelaySamples;
    if (delayLine_) delete[] delayLine_;
    delayLine_ = new float[delaySize_];
    std::memset(delayLine_, 0, sizeof(float) * delaySize_);
}

void KarplusStrongVoice::reset() {
    active_ = false;
    envelope_ = 0.0f;
    filterState_ = 0.0f;
    exciteCount_ = 0;
    if (delayLine_) {
        std::memset(delayLine_, 0, sizeof(float) * delaySize_);
    }
}

void KarplusStrongVoice::noteOn(float freq, float velocity, float brightness) {
    if (!delayLine_) return;

    active_ = true;
    velocity_ = velocity;
    envelope_ = 1.0f;

    // Calculate delay length for target frequency
    float delayLen = static_cast<float>(sampleRate_) / freq;
    if (delayLen >= delaySize_ - 1) delayLen = delaySize_ - 2;
    if (delayLen < 2.0f) delayLen = 2.0f;

    writePos_ = 0.0f;
    readPos_ = writePos_ - delayLen;
    while (readPos_ < 0.0f) readPos_ += delaySize_;

    // Decay coefficient: higher = longer sustain
    // Brightness affects both decay and filter
    float baseDecay = 0.998f - (1.0f - brightness) * 0.015f;
    // Lower frequencies naturally sustain longer
    float freqFactor = std::fmin(freq / 200.0f, 1.0f);
    decayCoef_ = baseDecay * (0.92f + 0.08f * freqFactor);
    if (decayCoef_ > 0.9995f) decayCoef_ = 0.9995f;
    if (decayCoef_ < 0.85f) decayCoef_ = 0.85f;

    // Excitation: noise burst whose length depends on brightness
    // Bright = short burst (hard pluck), Dark = longer burst (soft pluck)
    exciteLength_ = static_cast<int>((1.0f - brightness * 0.5f) * sampleRate_ * 0.003f);
    if (exciteLength_ < 5) exciteLength_ = 5;
    exciteCount_ = exciteLength_;

    // Seed noise from note+velocity for variation
    noiseSeed_ = static_cast<float>(static_cast<int>(freq) * 7 + static_cast<int>(velocity * 100.0f));
    if (noiseSeed_ == 0.0f) noiseSeed_ = 1.0f;

    // Pre-fill delay line with noise for immediate sound
    // This simulates the initial energy in the string
    int fillLen = static_cast<int>(delayLen);
    for (int i = 0; i < fillLen; ++i) {
        delayLine_[i] = fastRand(noiseSeed_) * velocity * 0.5f;
    }

    filterState_ = 0.0f;
}

void KarplusStrongVoice::noteOff() {
    // Rapid decay when note is released
    decayCoef_ *= 0.7f;
}

float KarplusStrongVoice::process() {
    if (!active_ || !delayLine_) return 0.0f;

    // Read from delay line with linear interpolation
    int idx0 = static_cast<int>(std::floor(readPos_)) % delaySize_;
    int idx1 = (idx0 + 1) % delaySize_;
    float frac = readPos_ - std::floor(readPos_);
    if (frac < 0.0f) frac = 0.0f;
    if (frac > 1.0f) frac = 1.0f;

    float sample = lerp(delayLine_[idx0], delayLine_[idx1], frac);

    // One-pole lowpass filter in feedback loop (string damping)
    filterState_ += (sample - filterState_) * 0.5f;
    float filtered = filterState_;

    // Excitation during attack phase
    if (exciteCount_ > 0) {
        filtered += fastRand(noiseSeed_) * velocity_ * 0.3f;
        exciteCount_--;
    }

    // Write back to delay line
    int wIdx = static_cast<int>(writePos_) % delaySize_;
    delayLine_[wIdx] = filtered * decayCoef_;

    // Advance positions
    readPos_ += 1.0f;
    writePos_ += 1.0f;
    if (readPos_ >= delaySize_) readPos_ -= delaySize_;
    if (writePos_ >= delaySize_) writePos_ -= delaySize_;

    // Envelope tracking
    envelope_ *= decayCoef_;
    if (envelope_ < 0.0001f) {
        active_ = false;
    }

    return sample * velocity_;
}

// ── Modal Synthesis ───────────────────────────────────────────────────────────

ModalVoice::ModalVoice() = default;
ModalVoice::~ModalVoice() = default;

void ModalVoice::init(double sampleRate) {
    sampleRate_ = sampleRate;
}

void ModalVoice::reset() {
    active_ = false;
    for (int i = 0; i < kMaxModes; ++i) {
        modes_[i].bp = 0.0f;
        modes_[i].lp = 0.0f;
        modes_[i].env = 0.0f;
        modes_[i].phase = 0.0f;
    }
}

// Mode presets: frequency ratios and relative amplitudes
// Preset 0: Marimba (wood bar — harmonic-ish, fast decay)
// Preset 1: Vibraphone (metal bar — inharmonic, slow decay, vibrato)
// Preset 2: Steel drum (membrane — complex inharmonic)

static const float kMarimbaRatios[] = {1.0f, 2.76f, 5.4f, 8.9f};
static const float kMarimbaAmps[]   = {1.0f, 0.4f, 0.15f, 0.05f};
static const float kMarimbaDecays[] = {0.985f, 0.96f, 0.92f, 0.88f};

static const float kVibraphoneRatios[] = {1.0f, 3.98f, 9.0f, 15.8f};
static const float kVibraphoneAmps[]   = {1.0f, 0.5f, 0.2f, 0.08f};
static const float kVibraphoneDecays[] = {0.995f, 0.99f, 0.98f, 0.96f};

static const float kSteelDrumRatios[] = {1.0f, 1.71f, 2.33f, 2.96f, 3.6f, 4.5f};
static const float kSteelDrumAmps[]   = {1.0f, 0.6f, 0.4f, 0.3f, 0.2f, 0.15f};
static const float kSteelDrumDecays[] = {0.992f, 0.985f, 0.98f, 0.97f, 0.96f, 0.94f};

void ModalVoice::noteOn(float freq, float velocity, int modePreset) {
    active_ = true;
    velocity_ = velocity;

    const float* ratios = nullptr;
    const float* amps = nullptr;
    const float* decays = nullptr;
    int nModes = 0;

    switch (modePreset) {
        case 0: // Marimba
            ratios = kMarimbaRatios;
            amps = kMarimbaAmps;
            decays = kMarimbaDecays;
            nModes = 4;
            break;
        case 1: // Vibraphone
            ratios = kVibraphoneRatios;
            amps = kVibraphoneAmps;
            decays = kVibraphoneDecays;
            nModes = 4;
            break;
        case 2: // Steel drum
            ratios = kSteelDrumRatios;
            amps = kSteelDrumAmps;
            decays = kSteelDrumDecays;
            nModes = 6;
            break;
        default:
            ratios = kMarimbaRatios;
            amps = kMarimbaAmps;
            decays = kMarimbaDecays;
            nModes = 4;
    }

    numModes_ = nModes;
    float invSr = 1.0f / static_cast<float>(sampleRate_);

    for (int i = 0; i < nModes; ++i) {
        modes_[i].freq = freq * ratios[i];
        modes_[i].amp = amps[i];
        modes_[i].decay = decays[i];
        modes_[i].env = 1.0f;
        modes_[i].phase = 0.0f;
        modes_[i].bp = 0.0f;
        modes_[i].lp = 0.0f;
    }

    // Excitation: short noise burst
    exciteLength_ = static_cast<int>(sampleRate_ * 0.002f);
    if (exciteLength_ < 3) exciteLength_ = 3;
    exciteCount_ = exciteLength_;

    noiseSeed_ = static_cast<float>(static_cast<int>(freq) * 13 + modePreset * 7);
    if (noiseSeed_ == 0.0f) noiseSeed_ = 1.0f;
}

void ModalVoice::noteOff() {
    // Accelerate decay for all modes
    for (int i = 0; i < numModes_; ++i) {
        modes_[i].decay *= 0.85f;
    }
}

float ModalVoice::process() {
    if (!active_) return 0.0f;

    float excitation = 0.0f;
    if (exciteCount_ > 0) {
        excitation = fastRand(noiseSeed_) * velocity_ * 0.5f;
        exciteCount_--;
    }

    float out = 0.0f;
    float invSr = 1.0f / static_cast<float>(sampleRate_);

    for (int i = 0; i < numModes_; ++i) {
        Mode& m = modes_[i];

        // State variable BPF
        float f = 2.0f * std::sin(3.14159265f * m.freq * invSr);
        f = std::min(f, 1.95f);
        float q = 0.995f; // High Q for resonant modes

        float input = excitation * m.amp;
        m.bp += f * (input - m.lp - q * m.bp);
        m.lp += f * m.bp;

        // Apply per-mode envelope decay
        m.env *= m.decay;
        out += m.bp * m.env * m.amp;
    }

    // Check if all modes have decayed
    bool anyActive = false;
    for (int i = 0; i < numModes_; ++i) {
        if (modes_[i].env > 0.0001f) {
            anyActive = true;
            break;
        }
    }
    if (!anyActive) active_ = false;

    return out * velocity_;
}

// ── PhysicalModelVoice wrapper ────────────────────────────────────────────────

PhysicalModelVoice::PhysicalModelVoice() = default;
PhysicalModelVoice::~PhysicalModelVoice() = default;

void PhysicalModelVoice::init(double sampleRate, int maxDelaySamples) {
    ksVoice_.init(sampleRate, maxDelaySamples);
    modalVoice_.init(sampleRate);
}

void PhysicalModelVoice::reset() {
    ksVoice_.reset();
    modalVoice_.reset();
    type_ = PhysicalModelType::OFF;
}

void PhysicalModelVoice::noteOn(float freq, float velocity) {
    switch (type_) {
        case PhysicalModelType::KARPLUS_STRONG:
            ksVoice_.noteOn(freq, velocity, 0.5f);
            break;
        case PhysicalModelType::KARPLUS_BRIGHT:
            ksVoice_.noteOn(freq, velocity, 0.75f);
            break;
        case PhysicalModelType::KARPLUS_BASS:
            ksVoice_.noteOn(freq, velocity, 0.25f);
            break;
        case PhysicalModelType::MODAL_MALLET:
            modalVoice_.noteOn(freq, velocity, 0);
            break;
        case PhysicalModelType::MODAL_VIBRAPHONE:
            modalVoice_.noteOn(freq, velocity, 1);
            break;
        case PhysicalModelType::MODAL_STEEL_DRUM:
            modalVoice_.noteOn(freq, velocity, 2);
            break;
        default:
            break;
    }
}

void PhysicalModelVoice::noteOff() {
    ksVoice_.noteOff();
    modalVoice_.noteOff();
}

float PhysicalModelVoice::process() {
    switch (type_) {
        case PhysicalModelType::KARPLUS_STRONG:
        case PhysicalModelType::KARPLUS_BRIGHT:
        case PhysicalModelType::KARPLUS_BASS:
            return ksVoice_.process();
        case PhysicalModelType::MODAL_MALLET:
        case PhysicalModelType::MODAL_VIBRAPHONE:
        case PhysicalModelType::MODAL_STEEL_DRUM:
            return modalVoice_.process();
        default:
            return 0.0f;
    }
}

bool PhysicalModelVoice::isActive() const {
    switch (type_) {
        case PhysicalModelType::KARPLUS_STRONG:
        case PhysicalModelType::KARPLUS_BRIGHT:
        case PhysicalModelType::KARPLUS_BASS:
            return ksVoice_.isActive();
        case PhysicalModelType::MODAL_MALLET:
        case PhysicalModelType::MODAL_VIBRAPHONE:
        case PhysicalModelType::MODAL_STEEL_DRUM:
            return modalVoice_.isActive();
        default:
            return false;
    }
}

} // namespace opensynth
