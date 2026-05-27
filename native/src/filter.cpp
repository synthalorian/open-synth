#include "filter.h"
#include <cmath>
#include <algorithm>

namespace openamp {

void StateVariableFilter::setType(int type) {
    type_ = std::clamp(type, 0, 3);
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

void StateVariableFilter::reset() {
    lp_ = 0.0f;
    bp_ = 0.0f;
    hp_ = 0.0f;
}

float StateVariableFilter::process(float input, float envMod, double sampleRate) {
    // Apply envelope modulation to cutoff
    float cutoff = cutoff_ * std::pow(2.0f, envMod * envAmount_ * 5.0f);
    cutoff = std::clamp(cutoff, 20.0f, 20000.0f);

    float f = 2.0f * std::sin(M_PI * cutoff / (float)sampleRate);
    float q = 1.0f - std::clamp(resonance_, 0.0f, 0.99f);

    // State-variable filter
    hp_ = input - lp_ - q * bp_;
    bp_ = bp_ + f * hp_;
    lp_ = lp_ + f * bp_;

    switch (static_cast<FilterType>(type_)) {
    case FilterType::LOW_PASS:  return lp_;
    case FilterType::HIGH_PASS: return hp_;
    case FilterType::BAND_PASS: return bp_;
    case FilterType::NOTCH:     return lp_ + hp_;
    }
    return lp_;
}

} // namespace openamp
