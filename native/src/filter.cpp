#include "filter.h"
#include <cmath>
#include <algorithm>

namespace openamp {

void StateVariableFilter::setType(int type) {
    type_ = std::clamp(type, 0, 6);
}

void StateVariableFilter::setCutoff(float hz) {
    cutoff_ = std::clamp(hz, 20.0f, 20000.0f);
}

void StateVariableFilter::setResonance(float q) {
    resonance_ = std::clamp(q, 0.0f, 1.0f);
}

void StateVariableFilter::setEnvAmount(float amount) {
    envAmount_ = std::clamp(amount, -1.0f, 1.0f);
}

void StateVariableFilter::setKeyTracking(float amount) {
    keyTracking_ = std::clamp(amount, 0.0f, 1.0f);
}

void StateVariableFilter::setDrive(float amount) {
    drive_ = std::clamp(amount, 0.0f, 1.0f);
}

void StateVariableFilter::reset() {
    lp_ = 0.0f;
    bp_ = 0.0f;
    hp_ = 0.0f;
}

static float applyDrive(float sample, float amount) {
    if (amount < 0.01f) return sample;
    // Soft saturation: tanh with increasing drive
    float driven = sample * (1.0f + amount * 4.0f);
    return std::tanh(driven) / std::tanh(1.0f + amount * 4.0f);
}

float StateVariableFilter::process(float input, float envMod, double sampleRate, int midiNote) {
    // Apply key tracking: cutoff shifts with MIDI note
    float keyOffset = 0.0f;
    if (keyTracking_ > 0.0f) {
        // 69 = A440, each semitone = factor of 2^(1/12)
        keyOffset = (midiNote - 69) * keyTracking_;
    }

    // Apply envelope modulation to cutoff
    float cutoff = cutoff_ * std::pow(2.0f, (envMod * envAmount_ * 5.0f + keyOffset) / 12.0f);
    cutoff = std::clamp(cutoff, 20.0f, 20000.0f);

    // Pre-filter drive
    float sample = applyDrive(input, drive_);

    float f = 2.0f * std::sin(M_PI * cutoff / (float)sampleRate);
    float q = 1.0f - std::clamp(resonance_, 0.0f, 0.99f);

    // State-variable filter
    hp_ = sample - lp_ - q * bp_;
    bp_ = bp_ + f * hp_;
    lp_ = lp_ + f * bp_;

    switch (static_cast<FilterType>(type_)) {
    case FilterType::LOW_PASS:   return lp_;
    case FilterType::HIGH_PASS:  return hp_;
    case FilterType::BAND_PASS:  return bp_;
    case FilterType::NOTCH:      return lp_ + hp_;
    case FilterType::LOW_SHELF:  return input + (lp_ - input) * resonance_; // simple shelf approximation
    case FilterType::HIGH_SHELF: return input + (hp_ - input) * resonance_;
    case FilterType::PEAKING_EQ: return input + bp_ * resonance_;
    }
    return lp_;
}

} // namespace openamp
