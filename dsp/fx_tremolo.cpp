#include "fx_tremolo.h"
#include <algorithm>
#include <cmath>
#include <cstdlib>

namespace opensynth {

static const double TWO_PI = 6.283185307179586;

TremoloProcessor::TremoloProcessor()
    : FxProcessor(FxType::Tremolo) {}

float TremoloProcessor::sineWave(double ph) const {
    return static_cast<float>(std::sin(ph * TWO_PI));
}

float TremoloProcessor::triangleWave(double ph) const {
    double t = ph - std::floor(ph);
    return static_cast<float>((t < 0.5) ? (4.0 * t - 1.0) : (3.0 - 4.0 * t));
}

float TremoloProcessor::squareWave(double ph) const {
    double t = ph - std::floor(ph);
    return (t < 0.5) ? 1.0f : -1.0f;
}

float TremoloProcessor::sawWave(double ph) const {
    double t = ph - std::floor(ph);
    return static_cast<float>(2.0 * t - 1.0);
}

float TremoloProcessor::randWave() {
    return static_cast<float>((std::rand() % 2000 - 1000) / 1000.0);
}

void TremoloProcessor::process(float& left, float& right, double sampleRate) {
    // Advance main phase
    phase_ += rate_ / sampleRate;
    if (phase_ >= 1.0) {
        phase_ -= 1.0;
        if (shape_ == 4) {
            // Reseed random for sample-and-hold style
            std::srand(static_cast<unsigned>(phase_ * 100000));
        }
    }

    // Compute LFO value for left channel
    float lfoLeft;
    switch (shape_) {
    case 0: lfoLeft = sineWave(phase_); break;
    case 1: lfoLeft = triangleWave(phase_); break;
    case 2: lfoLeft = squareWave(phase_); break;
    case 3: lfoLeft = sawWave(phase_); break;
    case 4: lfoLeft = randWave(); break;
    default: lfoLeft = sineWave(phase_); break;
    }

    // Right channel with stereo phase offset
    double rightPhase = phase_ + stereoPhase_ / 360.0;
    if (rightPhase >= 1.0) rightPhase -= 1.0;

    float lfoRight;
    switch (shape_) {
    case 0: lfoRight = sineWave(rightPhase); break;
    case 1: lfoRight = triangleWave(rightPhase); break;
    case 2: lfoRight = squareWave(rightPhase); break;
    case 3: lfoRight = sawWave(rightPhase); break;
    case 4: lfoRight = randWave(); break;
    default: lfoRight = sineWave(rightPhase); break;
    }

    // Map LFO from [-1,1] to [1-depth, 1]
    float modLeft = 1.0f - (lfoLeft * 0.5f + 0.5f) * depth_;
    float modRight = 1.0f - (lfoRight * 0.5f + 0.5f) * depth_;

    // Apply modulation
    left *= modLeft;
    right *= modRight;
}

void TremoloProcessor::reset() {
    phase_ = 0.0;
}

void TremoloProcessor::setParam(int index, float value) {
    switch (index) {
    case RATE:    rate_ = std::clamp(value, 0.05f, 20.0f); break;
    case DEPTH:   depth_ = std::clamp(value, 0.0f, 1.0f); break;
    case SHAPE:   shape_ = std::clamp(static_cast<int>(value), 0, 4); break;
    case STEREO:  stereoPhase_ = std::clamp(value, 0.0f, 180.0f); break;
    }
}

float TremoloProcessor::getParam(int index) const {
    switch (index) {
    case RATE:   return rate_;
    case DEPTH:  return depth_;
    case SHAPE:  return static_cast<float>(shape_);
    case STEREO: return stereoPhase_;
    }
    return 0.0f;
}

const char* TremoloProcessor::paramName(int index) const {
    switch (index) {
    case RATE:   return "Rate";
    case DEPTH:  return "Depth";
    case SHAPE:  return "Shape";
    case STEREO: return "Stereo";
    }
    return "";
}

} // namespace opensynth
