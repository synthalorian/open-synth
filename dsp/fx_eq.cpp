#include "fx_eq.h"
#include <algorithm>
#include <cmath>

namespace openamp {

void EqProcessor::process(float& left, float& right, double sampleRate) {
    if (dirty_ || sampleRate != cachedSampleRate_) {
        updateCoefficients(sampleRate);
        cachedSampleRate_ = sampleRate;
        dirty_ = false;
    }

    // Process through low, mid, high filters in series
    left = lowFilter_.processL(left);
    right = lowFilter_.processR(right);
    left = midFilter_.processL(left);
    right = midFilter_.processR(right);
    left = highFilter_.processL(left);
    right = highFilter_.processR(right);

    // Apply output gain
    float gain = std::pow(10.0f, outputGain_ / 20.0f);
    left *= gain;
    right *= gain;
}

void EqProcessor::reset() {
    lowFilter_.reset();
    midFilter_.reset();
    highFilter_.reset();
    dirty_ = true;
}

void EqProcessor::setParam(int index, float value) {
    switch (index) {
    case LOW_GAIN: lowGain_ = std::clamp(value, -12.0f, 12.0f); break;
    case LOW_FREQ: lowFreq_ = std::clamp(value, 20.0f, 500.0f); break;
    case MID_GAIN: midGain_ = std::clamp(value, -12.0f, 12.0f); break;
    case MID_FREQ: midFreq_ = std::clamp(value, 100.0f, 8000.0f); break;
    case MID_Q:    midQ_ = std::clamp(value, 0.1f, 10.0f); break;
    case HIGH_GAIN: highGain_ = std::clamp(value, -12.0f, 12.0f); break;
    case HIGH_FREQ: highFreq_ = std::clamp(value, 500.0f, 20000.0f); break;
    case OUTPUT_GAIN: outputGain_ = std::clamp(value, -12.0f, 12.0f); break;
    }
    dirty_ = true;
}

float EqProcessor::getParam(int index) const {
    switch (index) {
    case LOW_GAIN: return lowGain_;
    case LOW_FREQ: return lowFreq_;
    case MID_GAIN: return midGain_;
    case MID_FREQ: return midFreq_;
    case MID_Q:    return midQ_;
    case HIGH_GAIN: return highGain_;
    case HIGH_FREQ: return highFreq_;
    case OUTPUT_GAIN: return outputGain_;
    }
    return 0.0f;
}

const char* EqProcessor::paramName(int index) const {
    switch (index) {
    case LOW_GAIN: return "Low Gain";
    case LOW_FREQ: return "Low Freq";
    case MID_GAIN: return "Mid Gain";
    case MID_FREQ: return "Mid Freq";
    case MID_Q:    return "Mid Q";
    case HIGH_GAIN: return "High Gain";
    case HIGH_FREQ: return "High Freq";
    case OUTPUT_GAIN: return "Output";
    }
    return "";
}

void EqProcessor::updateCoefficients(double sampleRate) {
    const double pi = 3.14159265358979323846;

    // Low shelf filter
    {
        double w0 = 2.0 * pi * lowFreq_ / sampleRate;
        double A = std::pow(10.0, lowGain_ / 40.0);
        double alpha = std::sin(w0) * std::sqrt(2.0) * 0.5;

        lowFilter_.b1 = -2.0 * std::cos(w0);
        lowFilter_.b2 = 1.0 - alpha;
        lowFilter_.a0 = A * ((A + 1.0) - (A - 1.0) * std::cos(w0) + 2.0 * std::sqrt(A) * alpha);
        lowFilter_.a1 = 2.0 * A * ((A - 1.0) - (A + 1.0) * std::cos(w0));
        lowFilter_.a2 = A * ((A + 1.0) - (A - 1.0) * std::cos(w0) - 2.0 * std::sqrt(A) * alpha);

        // Normalize
        double denom = (A + 1.0) + (A - 1.0) * std::cos(w0) + 2.0 * std::sqrt(A) * alpha;
        if (denom != 0.0) {
            lowFilter_.a0 /= denom;
            lowFilter_.a1 /= denom;
            lowFilter_.a2 /= denom;
            lowFilter_.b1 = -lowFilter_.b1 / denom;
            lowFilter_.b2 = -lowFilter_.b2 / denom;
        }
    }

    // Peak (parametric) filter
    {
        double w0 = 2.0 * pi * midFreq_ / sampleRate;
        double A = std::pow(10.0, midGain_ / 40.0);
        double alpha = std::sin(w0) / (2.0 * midQ_);

        double b0 = 1.0 + alpha * A;
        double b1 = -2.0 * std::cos(w0);
        double b2 = 1.0 - alpha * A;
        double a0 = 1.0 + alpha / A;
        double a1 = -2.0 * std::cos(w0);
        double a2 = 1.0 - alpha / A;

        if (a0 != 0.0) {
            midFilter_.a0 = b0 / a0;
            midFilter_.a1 = b1 / a0;
            midFilter_.a2 = b2 / a0;
            midFilter_.b1 = -a1 / a0;
            midFilter_.b2 = -a2 / a0;
        }
    }

    // High shelf filter
    {
        double w0 = 2.0 * pi * highFreq_ / sampleRate;
        double A = std::pow(10.0, highGain_ / 40.0);
        double alpha = std::sin(w0) * std::sqrt(2.0) * 0.5;

        highFilter_.b1 = -2.0 * std::cos(w0);
        highFilter_.b2 = 1.0 - alpha;
        highFilter_.a0 = A * ((A + 1.0) + (A - 1.0) * std::cos(w0) + 2.0 * std::sqrt(A) * alpha);
        highFilter_.a1 = -2.0 * A * ((A - 1.0) + (A + 1.0) * std::cos(w0));
        highFilter_.a2 = A * ((A + 1.0) + (A - 1.0) * std::cos(w0) - 2.0 * std::sqrt(A) * alpha);

        double denom = (A + 1.0) - (A - 1.0) * std::cos(w0) + 2.0 * std::sqrt(A) * alpha;
        if (denom != 0.0) {
            highFilter_.a0 /= denom;
            highFilter_.a1 /= denom;
            highFilter_.a2 /= denom;
            highFilter_.b1 = -highFilter_.b1 / denom;
            highFilter_.b2 = -highFilter_.b2 / denom;
        }
    }
}

} // namespace openamp
