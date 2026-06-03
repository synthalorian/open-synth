#include "fx_pitchshift.h"
#include <algorithm>

namespace opensynth {

PitchShiftProcessor::PitchShiftProcessor()
    : FxProcessor(FxType::PitchShift) {
    delayL_.fill(0.0f);
    delayR_.fill(0.0f);
}

void PitchShiftProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;
    updateWindowSize();

    float inL = left;
    float inR = right;

    // Write to delay line
    delayL_[writePos_] = inL;
    delayR_[writePos_] = inR;

    // Pitch ratio: 2^(semitones/12)
    float ratio = std::pow(2.0f, semitones_ / 12.0f);

    // Two-tap crossfade for smooth pitch shifting
    float wetL = 0.0f;
    float wetR = 0.0f;

    float pos1L = readPosL_;
    float pos1R = readPosR_;
    float pos2L = pos1L + windowSize_ * 0.5f;
    float pos2R = pos1R + windowSize_ * 0.5f;

    if (pos2L >= windowSize_) pos2L -= windowSize_;
    if (pos2R >= windowSize_) pos2R -= windowSize_;

    float crossfade = pos1L / (windowSize_ * 0.5f);
    if (crossfade > 1.0f) crossfade = 2.0f - crossfade;

    wetL = readDelay(delayL_, pos1L) * (1.0f - crossfade)
         + readDelay(delayL_, pos2L) * crossfade;
    wetR = readDelay(delayR_, pos1R) * (1.0f - crossfade)
         + readDelay(delayR_, pos2R) * crossfade;

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);

    readPosL_ += ratio;
    readPosR_ += ratio;

    if (readPosL_ >= windowSize_) readPosL_ -= windowSize_;
    if (readPosR_ >= windowSize_) readPosR_ -= windowSize_;

    writePos_ = (writePos_ + 1) % windowSize_;
}

float PitchShiftProcessor::readDelay(const std::array<float, MAX_DELAY>& buf, float pos) {
    int i = static_cast<int>(pos);
    float frac = pos - i;
    int i1 = i % windowSize_;
    int i2 = (i1 + 1) % windowSize_;
    return buf[i1] * (1.0f - frac) + buf[i2] * frac;
}

void PitchShiftProcessor::updateWindowSize() {
    int target = static_cast<int>(windowSizeMs_ * 0.001f * sampleRate_);
    if (target < 64) target = 64;
    if (target > MAX_DELAY) target = MAX_DELAY;
    windowSize_ = target;
}

void PitchShiftProcessor::reset() {
    delayL_.fill(0.0f);
    delayR_.fill(0.0f);
    readPosL_ = 0.0f;
    readPosR_ = 0.0f;
    writePos_ = 0;
}

void PitchShiftProcessor::setParam(int index, float value) {
    switch (index) {
    case SEMITONES:   semitones_ = std::clamp(value, -12.0f, 12.0f); break;
    case WINDOW_SIZE: windowSizeMs_ = std::clamp(value, 10.0f, 100.0f); break;
    case MIX:         mix_ = value; break;
    default: break;
    }
}

float PitchShiftProcessor::getParam(int index) const {
    switch (index) {
    case SEMITONES:   return semitones_;
    case WINDOW_SIZE: return windowSizeMs_;
    case MIX:         return mix_;
    default: return 0.0f;
    }
}

const char* PitchShiftProcessor::paramName(int index) const {
    switch (index) {
    case SEMITONES:   return "Semitones";
    case WINDOW_SIZE: return "Window Size";
    case MIX:         return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
