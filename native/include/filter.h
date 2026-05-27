#pragma once
#include <cstdint>
#include <cmath>
#include <utility>

namespace openamp {

enum class FilterType : int {
    LOW_PASS = 0,
    HIGH_PASS = 1,
    BAND_PASS = 2,
    NOTCH = 3,
    LOW_SHELF = 4,
    HIGH_SHELF = 5,
    PEAKING_EQ = 6,
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

    int type() const { return type_; }
    float cutoff() const { return cutoff_; }
    float resonance() const { return resonance_; }
    float envAmount() const { return envAmount_; }
    float keyTracking() const { return keyTracking_; }
    float drive() const { return drive_; }

    float process(float input, float envMod, double sampleRate, int midiNote = 69);

    void reset();

private:
    int type_ = 0; // LOW_PASS
    float cutoff_ = 20000.0f;
    float resonance_ = 0.0f;
    float envAmount_ = 0.0f;
    float keyTracking_ = 0.0f;
    float drive_ = 0.0f;

    float lp_ = 0.0f;
    float bp_ = 0.0f;
    float hp_ = 0.0f;
};

} // namespace openamp
