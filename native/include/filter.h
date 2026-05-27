#pragma once
#include <cstdint>

namespace openamp {

enum class FilterType : int {
    LOW_PASS = 0,
    HIGH_PASS = 1,
    BAND_PASS = 2,
    NOTCH = 3,
};

class StateVariableFilter {
public:
    StateVariableFilter() = default;

    void setType(int type);
    void setCutoff(float hz);
    void setResonance(float q);
    void setEnvAmount(float amount);

    int type() const { return type_; }
    float cutoff() const { return cutoff_; }
    float resonance() const { return resonance_; }
    float envAmount() const { return envAmount_; }

    float process(float input, float envMod, double sampleRate);

    void reset();

private:
    int type_ = 0; // LOW_PASS
    float cutoff_ = 20000.0f;
    float resonance_ = 0.0f;
    float envAmount_ = 0.0f;

    float lp_ = 0.0f;
    float bp_ = 0.0f;
    float hp_ = 0.0f;
};

} // namespace openamp
