#include "fx_reverse_delay.h"
#include <algorithm>

namespace opensynth {

ReverseDelayProcessor::ReverseDelayProcessor()
    : FxProcessor(FxType::ReverseDelay) {
    bufL_.fill(0.0f);
    bufR_.fill(0.0f);
}

void ReverseDelayProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    int targetSegment = static_cast<int>(timeMs_ * 0.001f * sampleRate_);
    if (targetSegment < 64) targetSegment = 64;
    if (targetSegment > MAX_DELAY) targetSegment = MAX_DELAY;

    if (segmentSamples_ != targetSegment) {
        segmentSamples_ = targetSegment;
        segmentCounter_ = 0;
        reading_ = false;
        voiceA_.remaining = 0;
        voiceB_.remaining = 0;
    }

    // Write input to buffer
    bufL_[writePos_] = inL;
    bufR_[writePos_] = inR;

    float wetL = 0.0f;
    float wetR = 0.0f;

    // Voice A: main reverse playback
    if (voiceA_.remaining > 0) {
        float t = 1.0f - static_cast<float>(voiceA_.remaining) / static_cast<float>(segmentSamples_);
        float w = windowShape(t);
        wetL += readDelay(bufL_, voiceA_.readPos) * w * voiceA_.amp;
        wetR += readDelay(bufR_, voiceA_.readPos) * w * voiceA_.amp;
        voiceA_.readPos--;
        if (voiceA_.readPos < 0) voiceA_.readPos += MAX_DELAY;
        voiceA_.remaining--;
    }

    // Voice B: overlapping reverse playback (starts at midpoint)
    if (voiceB_.remaining > 0) {
        float t = 1.0f - static_cast<float>(voiceB_.remaining) / static_cast<float>(segmentSamples_);
        float w = windowShape(t);
        wetL += readDelay(bufL_, voiceB_.readPos) * w * voiceB_.amp;
        wetR += readDelay(bufR_, voiceB_.readPos) * w * voiceB_.amp;
        voiceB_.readPos--;
        if (voiceB_.readPos < 0) voiceB_.readPos += MAX_DELAY;
        voiceB_.remaining--;
    }

    // Decay scaling
    wetL *= (0.3f + decay_ * 0.7f);
    wetR *= (0.3f + decay_ * 0.7f);

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);

    // Feedback: mix wet back into buffer for next cycle
    bufL_[writePos_] = inL + wetL * feedback_;
    bufR_[writePos_] = inR + wetR * feedback_;

    writePos_ = (writePos_ + 1) % MAX_DELAY;
    segmentCounter_++;

    // Trigger new reverse segment at end of each segment period
    if (segmentCounter_ >= segmentSamples_) {
        segmentCounter_ = 0;
        // Start voice A from current write position (just filled)
        voiceA_.readPos = (writePos_ - 1 + MAX_DELAY) % MAX_DELAY;
        voiceA_.remaining = segmentSamples_;
        voiceA_.amp = 1.0f;

        // If voice B is inactive, start it for overlap (half segment offset)
        if (voiceB_.remaining <= 0) {
            voiceB_.readPos = (writePos_ - 1 + MAX_DELAY) % MAX_DELAY;
            voiceB_.remaining = segmentSamples_;
            voiceB_.amp = 0.7f;
        }
    }
}

float ReverseDelayProcessor::readDelay(const std::array<float, MAX_DELAY>& line, int pos) {
    int i1 = pos % MAX_DELAY;
    int i2 = (i1 + 1) % MAX_DELAY;
    return line[i1]; // simple read (no interpolation needed for integer pos)
}

float ReverseDelayProcessor::windowShape(float t) {
    // Hann-like window: 0 at edges, 1 in middle
    return 0.5f * (1.0f - std::cos(t * 3.14159265f * 2.0f));
}

void ReverseDelayProcessor::reset() {
    bufL_.fill(0.0f);
    bufR_.fill(0.0f);
    writePos_ = 0;
    segmentCounter_ = 0;
    segmentSamples_ = 0;
    reading_ = false;
    voiceA_ = {};
    voiceB_ = {};
}

void ReverseDelayProcessor::setParam(int index, float value) {
    switch (index) {
    case TIME:     timeMs_ = std::clamp(value, 100.0f, 2000.0f); break;
    case FEEDBACK: feedback_ = std::clamp(value, 0.0f, 0.95f); break;
    case MIX:      mix_ = value; break;
    case DECAY:    decay_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float ReverseDelayProcessor::getParam(int index) const {
    switch (index) {
    case TIME:     return timeMs_;
    case FEEDBACK: return feedback_;
    case MIX:      return mix_;
    case DECAY:    return decay_;
    default: return 0.0f;
    }
}

const char* ReverseDelayProcessor::paramName(int index) const {
    switch (index) {
    case TIME:     return "Time";
    case FEEDBACK: return "Feedback";
    case MIX:      return "Mix";
    case DECAY:    return "Decay";
    default: return "Unknown";
    }
}

} // namespace opensynth
