#include "fx_wah_wah.h"
#include <algorithm>

namespace opensynth {

WahWahProcessor::WahWahProcessor()
    : FxProcessor(FxType::WahWah) {}

void WahWahProcessor::reset() {
    bandL_ = 0.0f; lowL_ = 0.0f; highL_ = 0.0f;
    bandR_ = 0.0f; lowR_ = 0.0f; highR_ = 0.0f;
}

void WahWahProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    double f, q;
    updateCoefficients(f, q);

    float outL = processBandpass(inL, bandL_, lowL_, highL_, f, q);
    float outR = processBandpass(inR, bandR_, lowR_, highR_, f, q);

    left = applyMix(inL, outL);
    right = applyMix(inR, outR);
}

void WahWahProcessor::updateCoefficients(double& f, double& q) {
    // Cutoff = 300 + position * range * 1700 Hz
    double sweepRange = 300.0 + position_ * range_ * 1700.0;
    if (sweepRange < 300.0) sweepRange = 300.0;
    if (sweepRange > 20000.0) sweepRange = 20000.0;

    f = 2.0 * std::sin(3.14159265358979323846 * sweepRange / sampleRate_);
    if (f > 1.0) f = 1.0;

    // Q mapping: 0.5 to 8.0
    q = 0.5 + q_ * 7.5;
}

float WahWahProcessor::processBandpass(float input, float& band, float& low, float& high, double f, double q) {
    // State variable filter (Chamberlin / SVF)
    // low = low + f * band
    // high = input - low - q * band
    // band = f * high + band
    // peak = low - high (or band for bandpass)

    low += static_cast<float>(f * band);
    high = input - low - static_cast<float>(q * band);
    band += static_cast<float>(f * high);

    // Return bandpass output (band)
    return band;
}

void WahWahProcessor::setParam(int index, float value) {
    switch (index) {
    case POSITION: position_ = std::clamp(value, 0.0f, 1.0f); break;
    case RANGE:    range_ = std::clamp(value, 0.0f, 1.0f); break;
    case Q:        q_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:      mix_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float WahWahProcessor::getParam(int index) const {
    switch (index) {
    case POSITION: return position_;
    case RANGE:    return range_;
    case Q:        return q_;
    case MIX:      return mix_;
    default: return 0.0f;
    }
}

const char* WahWahProcessor::paramName(int index) const {
    switch (index) {
    case POSITION: return "Position";
    case RANGE:    return "Range";
    case Q:        return "Q";
    case MIX:      return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
