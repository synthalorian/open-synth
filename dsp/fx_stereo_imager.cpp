#include "fx_stereo_imager.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

StereoImagerProcessor::StereoImagerProcessor()
    : FxProcessor(FxType::StereoImager) {}

void StereoImagerProcessor::reset() {
    // No state to reset
}

void StereoImagerProcessor::process(float& left, float& right, double /*sampleRate*/) {
    float inL = left;
    float inR = right;

    // L/R to M/S
    float mid = (inL + inR) * 0.5f;
    float side = (inL - inR) * 0.5f;

    // Apply gains: width controls side, plus independent mid/side gains
    float sGain = width_ * sideGain_;
    float mGain = midGain_;

    mid *= mGain;
    side *= sGain;

    // M/S back to L/R
    float outL = mid + side;
    float outR = mid - side;

    left = applyMix(inL, outL);
    right = applyMix(inR, outR);
}

void StereoImagerProcessor::setParam(int index, float value) {
    switch (index) {
    case WIDTH: width_ = std::clamp(value, 0.0f, 2.0f); break;
    case MID:   midGain_ = std::clamp(value, 0.0f, 2.0f); break;
    case SIDE:  sideGain_ = std::clamp(value, 0.0f, 2.0f); break;
    case MIX:   mix_ = value; break;
    default: break;
    }
}

float StereoImagerProcessor::getParam(int index) const {
    switch (index) {
    case WIDTH: return width_;
    case MID:   return midGain_;
    case SIDE:  return sideGain_;
    case MIX:   return mix_;
    default: return 0.0f;
    }
}

const char* StereoImagerProcessor::paramName(int index) const {
    switch (index) {
    case WIDTH: return "Width";
    case MID:   return "Mid";
    case SIDE:  return "Side";
    case MIX:   return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
