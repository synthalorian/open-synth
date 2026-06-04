#include "fx_parametric_eq.h"
#include <cmath>

namespace opensynth {

ParametricEQProcessor::ParametricEQProcessor() : FxProcessor(FxType::ParametricEQ) {
    params_[0] = 0.5f;
    params_[1] = 0.5f;
    params_[2] = 0.5f;
    params_[3] = 0.5f;
}

void ParametricEQProcessor::reset() {
    // TODO: implement full DSP reset
}

void ParametricEQProcessor::process(float& left, float& right, double /*sampleRate*/) {
    // Stub: pass-through with slight saturation character
    float drive = params_[0] * 0.1f;
    left += left * drive;
    right += right * drive;
}

void ParametricEQProcessor::setParam(int index, float value) {
    if (index >= 0 && index < 4) params_[index] = value;
}

float ParametricEQProcessor::getParam(int index) const {
    if (index >= 0 && index < 4) return params_[index];
    return 0.0f;
}

const char* ParametricEQProcessor::paramName(int index) const {
    static const char* names[] = {"Param 1", "Param 2", "Param 3", "Param 4"};
    if (index >= 0 && index < 4) return names[index];
    return "";
}

} // namespace opensynth
