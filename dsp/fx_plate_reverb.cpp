#include "fx_plate_reverb.h"
#include <cmath>

namespace opensynth {

PlateReverbProcessor::PlateReverbProcessor() : FxProcessor(FxType::PlateReverb) {
    params_[0] = 0.5f;
    params_[1] = 0.5f;
    params_[2] = 0.5f;
    params_[3] = 0.5f;
}

void PlateReverbProcessor::reset() {
    // TODO: implement full DSP reset
}

void PlateReverbProcessor::process(float& left, float& right, double /*sampleRate*/) {
    // Stub: pass-through with slight saturation character
    float drive = params_[0] * 0.1f;
    left += left * drive;
    right += right * drive;
}

void PlateReverbProcessor::setParam(int index, float value) {
    if (index >= 0 && index < 4) params_[index] = value;
}

float PlateReverbProcessor::getParam(int index) const {
    if (index >= 0 && index < 4) return params_[index];
    return 0.0f;
}

const char* PlateReverbProcessor::paramName(int index) const {
    static const char* names[] = {"Param 1", "Param 2", "Param 3", "Param 4"};
    if (index >= 0 && index < 4) return names[index];
    return "";
}

} // namespace opensynth
