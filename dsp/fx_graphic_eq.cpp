#include "fx_graphic_eq.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

GraphicEQProcessor::GraphicEQProcessor()
    : FxProcessor(FxType::GraphicEQ) {
    for (int i = 0; i < NUM_BANDS; ++i) {
        gains_[i] = 0.0f;
    }
}

void GraphicEQProcessor::reset() {
    for (int i = 0; i < NUM_BANDS; ++i) {
        bandsL_[i].x1 = bandsL_[i].x2 = 0.0f;
        bandsL_[i].y1 = bandsL_[i].y2 = 0.0f;
        bandsR_[i].x1 = bandsR_[i].x2 = 0.0f;
        bandsR_[i].y1 = bandsR_[i].y2 = 0.0f;
    }
}

void GraphicEQProcessor::process(float& left, float& right, double sampleRate) {
    nativeSampleRate_ = sampleRate;

    float outL = left;
    float outR = right;

    for (int i = 0; i < NUM_BANDS; ++i) {
        updateCoefficients(bandsL_[i], FREQS[i], gains_[i], nativeSampleRate_);
        updateCoefficients(bandsR_[i], FREQS[i], gains_[i], nativeSampleRate_);
        outL = processBand(outL, bandsL_[i]);
        outR = processBand(outR, bandsR_[i]);
    }

    left = outL;
    right = outR;
}

void GraphicEQProcessor::updateCoefficients(BandState& state, float freq, float gainDb, double sr) {
    float A = std::pow(10.0f, gainDb / 40.0f);
    float w0 = 2.0f * 3.14159265f * freq / static_cast<float>(sr);
    float cosw0 = std::cos(w0);
    float sinw0 = std::sin(w0);
    float alpha = sinw0 / (2.0f * Q);

    float a0 = 1.0f + alpha / A;
    state.b0 = (1.0f + alpha * A) / a0;
    state.b1 = (-2.0f * cosw0) / a0;
    state.b2 = (1.0f - alpha * A) / a0;
    state.a1 = (-2.0f * cosw0) / a0;
    state.a2 = (1.0f - alpha / A) / a0;
}

float GraphicEQProcessor::processBand(float input, BandState& state) {
    float output = state.b0 * input + state.b1 * state.x1 + state.b2 * state.x2
                   - state.a1 * state.y1 - state.a2 * state.y2;
    state.x2 = state.x1;
    state.x1 = input;
    state.y2 = state.y1;
    state.y1 = output;
    return output;
}

void GraphicEQProcessor::setParam(int index, float value) {
    if (index >= 0 && index < NUM_BANDS) {
        gains_[index] = std::clamp(value, -18.0f, 18.0f);
    }
}

float GraphicEQProcessor::getParam(int index) const {
    if (index >= 0 && index < NUM_BANDS) return gains_[index];
    return 0.0f;
}

const char* GraphicEQProcessor::paramName(int index) const {
    switch (index) {
    case BAND_60HZ:    return "60Hz";
    case BAND_250HZ:   return "250Hz";
    case BAND_500HZ:   return "500Hz";
    case BAND_1KHZ:    return "1kHz";
    case BAND_2_5KHZ:  return "2.5kHz";
    case BAND_6KHZ:    return "6kHz";
    case BAND_12KHZ:   return "12kHz";
    default: return "Unknown";
    }
}

} // namespace opensynth
