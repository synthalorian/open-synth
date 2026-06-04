#include "fx_dimension_d.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

static const double TWO_PI = 6.283185307179586;

DimensionDProcessor::DimensionDProcessor()
    : FxProcessor(FxType::DimensionD) {
    delayLineL_.fill(0.0f);
    delayLineR_.fill(0.0f);
}

float DimensionDProcessor::processAllpass(float input, float& inState, float& outState, float coeff) {
    float output = coeff * (input - outState) + inState;
    inState = input;
    outState = output;
    return output;
}

float DimensionDProcessor::readDelay(const std::array<float, MAX_DELAY>& line, int writeIdx, float delaySamples) {
    float readPos = static_cast<float>(writeIdx) - delaySamples;
    while (readPos < 0.0f) readPos += MAX_DELAY;
    int i0 = static_cast<int>(readPos) % MAX_DELAY;
    int i1 = (i0 + 1) % MAX_DELAY;
    float frac = readPos - std::floor(readPos);
    return line[i0] * (1.0f - frac) + line[i1] * frac;
}

void DimensionDProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    // Advance LFO
    phase_ += rate_ / sampleRate;
    if (phase_ >= 1.0) phase_ -= 1.0;

    float lfo = static_cast<float>(std::sin(phase_ * TWO_PI));

    float inL = left;
    float inR = right;

    // Allpass filters on input
    float apL = processAllpass(inL, ap1In1_, ap1Out1_, modeApCoeff_[mode_]);
    apL = processAllpass(apL, ap2In1_, ap2Out1_, modeApCoeff_[mode_] * 0.7f);
    float apR = processAllpass(inR, ap1In2_, ap1Out2_, modeApCoeff_[mode_]);
    apR = processAllpass(apR, ap2In2_, ap2Out2_, modeApCoeff_[mode_] * 0.7f);

    // Modulated delay times
    float baseDelayMs = modeBaseDelay_[mode_];
    float modMs = 3.0f * depth_ * lfo;
    float delayMsL = baseDelayMs + modMs;
    float delayMsR = baseDelayMs - modMs * 0.7f; // slightly different for stereo width

    float delaySamplesL = static_cast<float>(delayMsL * 0.001 * sampleRate);
    float delaySamplesR = static_cast<float>(delayMsR * 0.001 * sampleRate);
    delaySamplesL = std::clamp(delaySamplesL, 1.0f, static_cast<float>(MAX_DELAY - 1));
    delaySamplesR = std::clamp(delaySamplesR, 1.0f, static_cast<float>(MAX_DELAY - 1));

    // Cross-feedback into delay lines
    float fbAmount = modeFeedback_[mode_];
    delayLineL_[writeIdxL_] = apL + fbR_ * fbAmount;
    delayLineR_[writeIdxR_] = apR + fbL_ * fbAmount;

    // Read modulated delays
    float wetL = readDelay(delayLineL_, writeIdxL_, delaySamplesL);
    float wetR = readDelay(delayLineR_, writeIdxR_, delaySamplesR);

    // Update feedback state
    fbL_ = wetL;
    fbR_ = wetR;

    // Advance write pointers
    writeIdxL_ = (writeIdxL_ + 1) % MAX_DELAY;
    writeIdxR_ = (writeIdxR_ + 1) % MAX_DELAY;

    // Mix: Dimension D is subtle spatial enhancement
    left = applyMix(inL, inL + wetL * 0.5f);
    right = applyMix(inR, inR + wetR * 0.5f);
}

void DimensionDProcessor::reset() {
    delayLineL_.fill(0.0f);
    delayLineR_.fill(0.0f);
    writeIdxL_ = 0;
    writeIdxR_ = 0;
    phase_ = 0.0;
    ap1In1_ = ap1Out1_ = 0.0f;
    ap1In2_ = ap1Out2_ = 0.0f;
    ap2In1_ = ap2Out1_ = 0.0f;
    ap2In2_ = ap2Out2_ = 0.0f;
    fbL_ = 0.0f;
    fbR_ = 0.0f;
}

void DimensionDProcessor::setParam(int index, float value) {
    switch (index) {
    case MODE:  mode_ = std::clamp(static_cast<int>(value), 0, 3); break;
    case DEPTH: depth_ = std::clamp(value, 0.0f, 1.0f); break;
    case RATE:  rate_ = std::clamp(value, 0.1f, 5.0f); break;
    case MIX:   mix_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float DimensionDProcessor::getParam(int index) const {
    switch (index) {
    case MODE:  return static_cast<float>(mode_);
    case DEPTH: return depth_;
    case RATE:  return rate_;
    case MIX:   return mix_;
    default: return 0.0f;
    }
}

const char* DimensionDProcessor::paramName(int index) const {
    switch (index) {
    case MODE:  return "Mode";
    case DEPTH: return "Depth";
    case RATE:  return "Rate";
    case MIX:   return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
