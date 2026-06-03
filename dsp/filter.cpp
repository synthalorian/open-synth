#include "filter.h"
#include <cmath>
#include <algorithm>

namespace opensynth {

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
    FilterState tmp{lp_, bp_, hp_};
    float out = process(input, envMod, sampleRate, midiNote, tmp);
    lp_ = tmp.lp;
    bp_ = tmp.bp;
    hp_ = tmp.hp;
    return out;
}

float StateVariableFilter::process(float input, float envMod, double sampleRate, int midiNote, FilterState& state) {
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

    // Compute f and clamp to stable region
    float f = 2.0f * std::sin(M_PI * cutoff / (float)sampleRate);
    // Clamp f to prevent instability near Nyquist (safety margin < 2.0)
    f = std::min(f, 1.95f);
    float q = 1.0f - std::clamp(resonance_, 0.0f, 0.99f);

    // NaN/inf guard — if state is corrupted, reset it before processing
    if (!std::isfinite(state.lp) || !std::isfinite(state.bp) || !std::isfinite(state.hp)) {
        state.lp = 0.0f;
        state.bp = 0.0f;
        state.hp = 0.0f;
    }

    // State-variable filter
    state.hp = sample - state.lp - q * state.bp;
    state.bp = state.bp + f * state.hp;
    state.lp = state.lp + f * state.bp;

    // NaN/inf guard after update
    if (!std::isfinite(state.lp) || !std::isfinite(state.bp) || !std::isfinite(state.hp)) {
        state.lp = 0.0f;
        state.bp = 0.0f;
        state.hp = 0.0f;
    }

    switch (static_cast<FilterType>(type_)) {
    case FilterType::LOW_PASS:   return state.lp;
    case FilterType::HIGH_PASS:  return state.hp;
    case FilterType::BAND_PASS:  return state.bp;
    case FilterType::NOTCH:      return state.lp + state.hp;
    case FilterType::LOW_SHELF:  return input + (state.lp - input) * resonance_; // simple shelf approximation
    case FilterType::HIGH_SHELF: return input + (state.hp - input) * resonance_;
    case FilterType::PEAKING_EQ: return input + state.bp * resonance_;
    }
    return state.lp;
}

void StateVariableFilter::reset(FilterState& state) {
    state.lp = 0.0f;
    state.bp = 0.0f;
    state.hp = 0.0f;
}

} // namespace opensynth
