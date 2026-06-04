#include "fx_lo_fi.h"
#include <cmath>

namespace opensynth {

LoFiProcessor::LoFiProcessor() : FxProcessor(FxType::LoFi) {
    params_[0] = 0.5f;
    params_[1] = 0.5f;
    params_[2] = 0.5f;
    params_[3] = 0.5f;
}

void LoFiProcessor::reset() {
    // TODO: implement full DSP reset
}

void LoFiProcessor::process(float& left, float& right, double /*sampleRate*/) {
    // Stub: pass-through with slight saturation character
    float drive = params_[0] * 0.1f;
    left += left * drive;
    right += right * drive;
}

void LoFiProcessor::setParam(int index, float value) {
    if (index >= 0 && index < 4) params_[index] = value;
}

float LoFiProcessor::getParam(int index) const {
    if (index >= 0 && index < 4) return params_[index];
    return 0.0f;
}

const char* LoFiProcessor::paramName(int index) const {
    static const char* names[] = {"Param 1", "Param 2", "Param 3", "Param 4"};
    if (index >= 0 && index < 4) return names[index];
    return "";
}

} // namespace opensynth
