#include "fx_stereo_widener.h"
#include <algorithm>

namespace opensynth {

StereoWidenerProcessor::StereoWidenerProcessor()
    : FxProcessor(FxType::StereoWidener) {
    delayL_.fill(0.0f);
    delayR_.fill(0.0f);
}

void StereoWidenerProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // Mid/side encoding
    float mid = (inL + inR) * 0.5f;
    float side = (inL - inR) * 0.5f;

    // Width scaling
    side *= width_;

    // Haas effect: delay one channel slightly
    int haasSamples = static_cast<int>(haasMs_ * 0.001f * sampleRate_);
    if (haasSamples >= MAX_DELAY) haasSamples = MAX_DELAY - 1;

    delayL_[writePos_] = mid + side;
    delayR_[writePos_] = mid - side;

    int rpL = writePos_;
    int rpR = writePos_ - haasSamples;
    if (rpR < 0) rpR += MAX_DELAY;

    float wetL = delayL_[rpL];
    float wetR = delayR_[rpR];

    // Mono bass: lowpass extract bass, make it mono
    if (monoBass_ > 0.01f) {
        float bassCutoff = 200.0f / sampleRate_;
        float bassL = lpfL_ + bassCutoff * (wetL - lpfL_);
        float bassR = lpfR_ + bassCutoff * (wetR - lpfR_);
        lpfL_ = bassL;
        lpfR_ = bassR;

        float monoBass = (bassL + bassR) * 0.5f;
        wetL = wetL * (1.0f - monoBass_) + monoBass * monoBass_;
        wetR = wetR * (1.0f - monoBass_) + monoBass * monoBass_;
    }

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);

    writePos_ = (writePos_ + 1) % MAX_DELAY;
}

void StereoWidenerProcessor::reset() {
    delayL_.fill(0.0f);
    delayR_.fill(0.0f);
    writePos_ = 0;
    lpfL_ = lpfR_ = 0.0f;
}

void StereoWidenerProcessor::setParam(int index, float value) {
    switch (index) {
    case WIDTH:     width_ = std::clamp(value, 0.0f, 2.0f); break;
    case HAAS_DELAY: haasMs_ = std::clamp(value, 0.0f, 30.0f); break;
    case MONO_BASS: monoBass_ = value; break;
    case MIX:       mix_ = value; break;
    default: break;
    }
}

float StereoWidenerProcessor::getParam(int index) const {
    switch (index) {
    case WIDTH:     return width_;
    case HAAS_DELAY: return haasMs_;
    case MONO_BASS: return monoBass_;
    case MIX:       return mix_;
    default: return 0.0f;
    }
}

const char* StereoWidenerProcessor::paramName(int index) const {
    switch (index) {
    case WIDTH:     return "Width";
    case HAAS_DELAY: return "Haas Delay";
    case MONO_BASS: return "Mono Bass";
    case MIX:       return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
