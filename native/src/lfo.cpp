#include "lfo.h"
#include <algorithm>
#include <cstdlib>

namespace openamp {

void LFO::setWaveform(int w) {
    waveform_ = static_cast<Waveform>(std::clamp(w, 0, 4));
}

void LFO::setRate(float hz) {
    rate_ = std::clamp(hz, 0.01f, 50.0f);
}

void LFO::setDepth(float depth) {
    depth_ = std::clamp(depth, 0.0f, 1.0f);
}

void LFO::setTarget(int target) {
    target_ = static_cast<Target>(std::clamp(target, 0, 3));
}

void LFO::prepare(double sampleRate) {
    sampleRate_ = sampleRate;
    phaseIncrement_ = rate_ / sampleRate_;
}

void LFO::reset() {
    phase_ = 0.0;
    value_ = 0.0f;
}

float LFO::process() {
    if (phaseIncrement_ <= 0.0) {
        prepare(sampleRate_);
    }

    // Advance phase
    phase_ += phaseIncrement_;
    if (phase_ >= 1.0) phase_ -= 1.0;

    // Generate waveform
    float v = 0.0f;
    switch (waveform_) {
    case Waveform::SINE:
        v = std::sin(2.0 * M_PI * phase_);
        break;
    case Waveform::TRIANGLE:
        v = 4.0f * std::abs((float)phase_ - 0.5f) - 1.0f;
        break;
    case Waveform::SAW:
        v = 2.0f * (float)phase_ - 1.0f;
        break;
    case Waveform::SQUARE:
        v = phase_ < 0.5f ? 1.0f : -1.0f;
        break;
    case Waveform::RANDOM:
        // Sample-and-hold: update on phase wrap
        if (phase_ < phaseIncrement_) {
            v = 2.0f * (float)std::rand() / (float)RAND_MAX - 1.0f;
        }
        break;
    }

    // Scale by depth (0..1)
    value_ = v * depth_;
    return value_;
}

} // namespace openamp
