#include "filter.h"
#include <cmath>
#include <algorithm>

namespace opensynth {

void StateVariableFilter::setType(int type) {
    type_ = std::clamp(type, 0, 6);
}

void StateVariableFilter::setCutoff(float hz) {
    if (!std::isfinite(hz)) return;  // keep the previous cutoff
    cutoff_ = std::clamp(hz, 20.0f, 20000.0f);
}

void StateVariableFilter::setResonance(float q) {
    if (!std::isfinite(q)) return;
    resonance_ = std::clamp(q, 0.0f, 1.0f);
}

void StateVariableFilter::setEnvAmount(float amount) {
    if (!std::isfinite(amount)) return;
    envAmount_ = std::clamp(amount, -1.0f, 1.0f);
}

void StateVariableFilter::setKeyTracking(float amount) {
    if (!std::isfinite(amount)) return;
    keyTracking_ = std::clamp(amount, 0.0f, 1.0f);
}

void StateVariableFilter::setDrive(float amount) {
    if (!std::isfinite(amount)) return;
    drive_ = std::clamp(amount, 0.0f, 1.0f);
}

void StateVariableFilter::setEnvRangeSemitones(float semis) {
    if (!std::isfinite(semis)) return;
    envRangeSemis_ = std::clamp(semis, 0.0f, 96.0f);
}

void StateVariableFilter::reset() {
    lp_ = 0.0f;
    bp_ = 0.0f;
    hp_ = 0.0f;
    state_ = FilterState{};
}

// Drive below this is a clean bypass (unchanged from the original curve).
static constexpr float kDriveOnThreshold = 0.01f;

static float saturate(float sample, float amount) {
    // Soft saturation: tanh with increasing drive
    float driven = sample * (1.0f + amount * 4.0f);
    return std::tanh(driven) / std::tanh(1.0f + amount * 4.0f);
}

// mix crossfades bypass -> saturator so crossing the on-threshold does not
// step the gain (the saturator has ~+2.5 dB small-signal gain at 0.01).
static float applyDrive(float sample, float amount, float mix) {
    if (mix <= 0.0f) return sample;
    const float wet = saturate(sample, std::max(amount, kDriveOnThreshold));
    if (mix >= 1.0f) return wet;
    return sample + (wet - sample) * mix;
}

float StateVariableFilter::process(float input, float envMod, double sampleRate, int midiNote) {
    float out = process(input, envMod, sampleRate, midiNote, state_);
    lp_ = state_.lp;
    bp_ = state_.bp;
    hp_ = state_.hp;
    return out;
}

float StateVariableFilter::process(float input, float envMod, double sampleRate, int midiNote, FilterState& state) {
    if (sampleRate <= 0.0) return input;

    // One-pole parameter smoothing, per voice (state), so knob moves and
    // automation do not zipper. Cutoff is smoothed in the log domain.
    if (sampleRate != smoothSr_) {
        smoothSr_ = sampleRate;
        smoothCoef_ = std::exp(-1.0f / (kSmoothingMs * 0.001f * static_cast<float>(sampleRate)));
    }
    const float targetLog2 = std::log2(cutoff_);
    const float targetMix = drive_ >= kDriveOnThreshold ? 1.0f : 0.0f;
    if (!state.primed || !std::isfinite(state.cutoffLog2)) {
        state.cutoffLog2 = targetLog2;
        state.resonance = resonance_;
        state.drive = drive_;
        state.driveMix = targetMix;
        state.primed = true;
    } else {
        const float c = smoothCoef_;
        state.cutoffLog2 = targetLog2 + (state.cutoffLog2 - targetLog2) * c;
        state.resonance = resonance_ + (state.resonance - resonance_) * c;
        state.drive = drive_ + (state.drive - drive_) * c;
        state.driveMix = targetMix + (state.driveMix - targetMix) * c;
        if (std::fabs(state.driveMix - targetMix) < 1e-5f) state.driveMix = targetMix;
    }
    const float resonance = state.resonance;

    // Key tracking: cutoff shifts with MIDI note (69 = A440)
    float keyOffset = 0.0f;
    if (keyTracking_ > 0.0f) {
        keyOffset = (midiNote - 69) * keyTracking_;
    }

    // Envelope modulation and key tracking, in semitones
    const float semis = envMod * envAmount_ * envRangeSemis_ + keyOffset;
    float cutoff = std::exp2(state.cutoffLog2 + semis / 12.0f);
    const float maxCutoff = kMaxCutoffRatio * static_cast<float>(sampleRate);
    cutoff = std::clamp(cutoff, 20.0f, std::max(20.0f, maxCutoff));

    // Pre-filter drive
    float sample = applyDrive(input, state.drive, state.driveMix);

    // TPT (Zavalishin) SVF: stable for any cutoff below Nyquist.
    float g = std::tan(static_cast<float>(M_PI) * cutoff / static_cast<float>(sampleRate));
    float k = 2.0f - 2.0f * std::clamp(resonance, 0.0f, 0.99f); // k = 2 - 2R

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

    // Flush subnormal state so a decaying tail does not hit the slow
    // denormal path in hosts without FTZ (the plugin has ScopedNoDenormals;
    // the engine and FFI hosts do not).
    constexpr float kTiny = 1e-20f;
    if (std::fabs(state.lp) < kTiny) state.lp = 0.0f;
    if (std::fabs(state.bp) < kTiny) state.bp = 0.0f;
    if (std::fabs(state.hp) < kTiny) state.hp = 0.0f;

    if (!std::isfinite(v1) || !std::isfinite(v2)) return 0.0f;

    // Outputs are the TPT taps v2 (LP) and v1 (BP), not the integrator
    // states, which carry an extra 1/(1+z^-1)-shaped error near Nyquist.
    switch (static_cast<FilterType>(type_)) {
    case FilterType::LOW_PASS:   return v2;
    case FilterType::HIGH_PASS:  return state.hp;
    case FilterType::BAND_PASS:  return v1;
    case FilterType::NOTCH:      return v2 + state.hp;
    case FilterType::LOW_SHELF:  return input + (v2 - input) * resonance; // simple shelf approximation
    case FilterType::HIGH_SHELF: return input + (state.hp - input) * resonance;
    case FilterType::PEAKING_EQ: return input + v1 * resonance;
    }
    return v2;
}

void StateVariableFilter::reset(FilterState& state) {
    state = FilterState{};
}

} // namespace opensynth
