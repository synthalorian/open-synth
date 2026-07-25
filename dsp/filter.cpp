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

    // Compute g and clamp to stable region
    // TPT (Zavalishin) SVF: stable for ANY cutoff up to Nyquist.
    // The previous Chamberlin form (f = 2sin(πf/fs)) goes unstable above
    // sr/6 (8kHz @ 48k) — any preset with cutoff > 8kHz exploded the filter
    // state into railed square-wave noise (the "static" bug).
    float g = std::tan(M_PI * cutoff / (float)sampleRate);
    g = std::clamp(g, 0.0f, 10.0f); // tan() blows up at Nyquist; 10 is plenty
    float k = 2.0f - 2.0f * std::clamp(resonance_, 0.0f, 0.99f); // k = 2 - 2R

    // NaN/inf guard — if state is corrupted, reset it before processing
    if (!std::isfinite(state.lp) || !std::isfinite(state.bp) || !std::isfinite(state.hp)) {
        state.lp = 0.0f;
        state.bp = 0.0f;
        state.hp = 0.0f;
    }

    // TPT state-variable filter (state.bp = ic1, state.lp = ic2)
    const float a1 = 1.0f / (1.0f + g * (g + k));
    const float a2 = g * a1;
    const float a3 = g * a2;
    const float v3 = sample - state.lp;
    const float v1 = a1 * state.bp + a2 * v3;   // band-pass
    const float v2 = state.lp + a2 * state.bp + a3 * v3; // low-pass
    state.bp = 2.0f * v1 - state.bp;
    state.lp = 2.0f * v2 - state.lp;
    state.hp = sample - k * v1 - v2;            // high-pass

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
