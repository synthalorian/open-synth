#pragma once
#include <cstdint>
#include <cmath>
#include <utility>

namespace opensynth {

enum class FilterType : int {
    LOW_PASS = 0,
    HIGH_PASS = 1,
    BAND_PASS = 2,
    NOTCH = 3,
    LOW_SHELF = 4,
    HIGH_SHELF = 5,
    PEAKING_EQ = 6,
};

struct FilterState {
    float lp = 0.0f;   // integrator state ic2
    float bp = 0.0f;   // integrator state ic1
    float hp = 0.0f;   // last high-pass output

    // Per-voice parameter smoothing (one-pole, ~5 ms). `primed` is false
    // after a reset, so the first sample snaps to the target instead of
    // gliding from zero.
    bool primed = false;
    float cutoffLog2 = 0.0f;  // smoothed log2(base cutoff in Hz)
    float resonance = 0.0f;
    float drive = 0.0f;
    float driveMix = 0.0f;    // 0 = clean bypass, 1 = saturator (drive >= 0.01)
};

class StateVariableFilter {
public:
    StateVariableFilter() = default;

    void setType(int type);
    void setCutoff(float hz);
    void setResonance(float q);
    void setEnvAmount(float amount);
    void setKeyTracking(float amount);
    void setDrive(float amount);
    // Semitones of cutoff shift at envelope amount = 1 (envMod = 1).
    // Defaults to 5, the historical range, so existing presets are unchanged.
    void setEnvRangeSemitones(float semis);

    // Modulated cutoff is capped at this fraction of the sample rate.
    static constexpr float kMaxCutoffRatio = 0.45f;
    static constexpr float kDefaultEnvRangeSemitones = 5.0f;
    static constexpr float kSmoothingMs = 5.0f;

    int type() const { return type_; }
    float cutoff() const { return cutoff_; }
    float resonance() const { return resonance_; }
    float envAmount() const { return envAmount_; }
    float keyTracking() const { return keyTracking_; }
    float drive() const { return drive_; }
    float envRangeSemitones() const { return envRangeSemis_; }

    float process(float input, float envMod, double sampleRate, int midiNote, FilterState& state);
    float process(float input, float envMod, double sampleRate, int midiNote = 69);

    void reset(FilterState& state);
    void reset();

private:
    int type_ = 0; // LOW_PASS
    float cutoff_ = 20000.0f;
    float resonance_ = 0.0f;
    float envAmount_ = 0.0f;
    float keyTracking_ = 0.0f;
    float drive_ = 0.0f;
    float envRangeSemis_ = kDefaultEnvRangeSemitones;

    double smoothSr_ = 0.0;
    float smoothCoef_ = 0.0f;

    FilterState state_;  // for the stateless process() overload
    float lp_ = 0.0f;
    float bp_ = 0.0f;
    float hp_ = 0.0f;
};

} // namespace opensynth
