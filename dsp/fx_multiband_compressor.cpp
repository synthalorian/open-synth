#include "fx_multiband_compressor.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

MultibandCompressorProcessor::MultibandCompressorProcessor()
    : FxProcessor(FxType::MultibandCompressor) {}

void MultibandCompressorProcessor::reset() {
    lp1L_ = lp1R_ = lp1aL_ = lp1aR_ = 0.0f;
    hp1L_ = hp1R_ = hp1aL_ = hp1aR_ = 0.0f;
    lp2L_ = lp2R_ = lp2aL_ = lp2aR_ = 0.0f;
    hp2L_ = hp2R_ = hp2aL_ = hp2aR_ = 0.0f;
    envLowL_ = envLowR_ = 0.0f;
    envMidL_ = envMidR_ = 0.0f;
    envHighL_ = envHighR_ = 0.0f;
}

static inline float dbToGain(float db) {
    return std::pow(10.0f, db * 0.05f);
}

static inline float gainToDb(float gain) {
    if (gain <= 0.00001f) return -100.0f;
    return 20.0f * std::log10(gain);
}

void MultibandCompressorProcessor::updateCrossoverCoeffs() {
    // Linkwitz-Riley 2-pole: two cascaded 1-pole Butterworth filters
    // 1-pole lowpass coeff: c = 2 * sin(pi * fc / sr)  (approx)
    // Using bilinear-ish approx for stability
    auto calcCoeff = [&](float freq) -> float {
        float f = freq / static_cast<float>(sampleRate_);
        if (f > 0.49f) f = 0.49f;
        return static_cast<float>(std::tan(3.14159265f * f));
    };
    c1_ = calcCoeff(crossover1_);
    c2_ = calcCoeff(crossover2_);
}

static inline float processLp1(float input, float& state, float c) {
    // 1-pole lowpass: y += c * (x - y)  (pre-warped approx)
    state += c * (input - state);
    return state;
}

static inline float processHp1(float input, float& state, float c) {
    // 1-pole highpass: y = x - lp(x)
    state += c * (input - state);
    return input - state;
}

void MultibandCompressorProcessor::processCrossover(float inL, float inR,
    float& lowL, float& lowR, float& midL, float& midR, float& highL, float& highR) {
    // Crossover 1: split low from (mid+high)
    float lp1L = processLp1(inL, lp1L_, c1_);
    float lp1R = processLp1(inR, lp1R_, c1_);
    lp1L = processLp1(lp1L, lp1aL_, c1_);
    lp1R = processLp1(lp1R, lp1aR_, c1_);

    float hp1L = processHp1(inL, hp1L_, c1_);
    float hp1R = processHp1(inR, hp1R_, c1_);
    hp1L = processHp1(hp1L, hp1aL_, c1_);
    hp1R = processHp1(hp1R, hp1aR_, c1_);

    // Crossover 2: split mid from high
    float lp2L = processLp1(hp1L, lp2L_, c2_);
    float lp2R = processLp1(hp1R, lp2R_, c2_);
    lp2L = processLp1(lp2L, lp2aL_, c2_);
    lp2R = processLp1(lp2R, lp2aR_, c2_);

    float hp2L = processHp1(hp1L, hp2L_, c2_);
    float hp2R = processHp1(hp1R, hp2R_, c2_);
    hp2L = processHp1(hp2L, hp2aL_, c2_);
    hp2R = processHp1(hp2R, hp2aR_, c2_);

    lowL = lp1L; lowR = lp1R;
    midL = lp2L; midR = lp2R;
    highL = hp2L; highR = hp2R;
}

float MultibandCompressorProcessor::compress(float sample, float& env, float threshDb, float ratio) {
    // Envelope follower (peak detector with fast attack / medium release)
    float attackCoeff = 0.99f;   // fast attack
    float releaseCoeff = 0.95f;  // medium release
    float absSample = std::abs(sample);
    if (absSample > env) {
        env = attackCoeff * env + (1.0f - attackCoeff) * absSample;
    } else {
        env = releaseCoeff * env + (1.0f - releaseCoeff) * absSample;
    }

    float envDb = gainToDb(env);
    if (envDb <= threshDb) {
        return sample; // no compression
    }

    float gainReductionDb = (envDb - threshDb) * (1.0f - 1.0f / ratio);
    float gainReduction = dbToGain(-gainReductionDb);
    return sample * gainReduction;
}

void MultibandCompressorProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;
    updateCrossoverCoeffs();

    float lowL, lowR, midL, midR, highL, highR;
    processCrossover(left, right, lowL, lowR, midL, midR, highL, highR);

    // Compress each band
    float compLowL = compress(lowL, envLowL_, lowThresh_, lowRatio_);
    float compLowR = compress(lowR, envLowR_, lowThresh_, lowRatio_);
    float compMidL = compress(midL, envMidL_, midThresh_, midRatio_);
    float compMidR = compress(midR, envMidR_, midThresh_, midRatio_);
    float compHighL = compress(highL, envHighL_, highThresh_, highRatio_);
    float compHighR = compress(highR, envHighR_, highThresh_, highRatio_);

    // Sum bands
    float outL = compLowL + compMidL + compHighL;
    float outR = compLowR + compMidR + compHighR;

    // Soft clip to prevent inter-band summing overflow
    outL = std::tanh(outL);
    outR = std::tanh(outR);

    left = applyMix(left, outL);
    right = applyMix(right, outR);
}

void MultibandCompressorProcessor::setParam(int index, float value) {
    switch (index) {
    case LOW_THRESH:  lowThresh_ = std::clamp(value, -60.0f, 0.0f); break;
    case LOW_RATIO:   lowRatio_ = std::clamp(value, 1.0f, 20.0f); break;
    case MID_THRESH:  midThresh_ = std::clamp(value, -60.0f, 0.0f); break;
    case MID_RATIO:   midRatio_ = std::clamp(value, 1.0f, 20.0f); break;
    case HIGH_THRESH: highThresh_ = std::clamp(value, -60.0f, 0.0f); break;
    case HIGH_RATIO:  highRatio_ = std::clamp(value, 1.0f, 20.0f); break;
    case CROSSOVER1:  crossover1_ = std::clamp(value, 100.0f, 1000.0f); break;
    case CROSSOVER2:  crossover2_ = std::clamp(value, 1000.0f, 8000.0f); break;
    default: break;
    }
}

float MultibandCompressorProcessor::getParam(int index) const {
    switch (index) {
    case LOW_THRESH:  return lowThresh_;
    case LOW_RATIO:   return lowRatio_;
    case MID_THRESH:  return midThresh_;
    case MID_RATIO:   return midRatio_;
    case HIGH_THRESH: return highThresh_;
    case HIGH_RATIO:  return highRatio_;
    case CROSSOVER1:  return crossover1_;
    case CROSSOVER2:  return crossover2_;
    default: return 0.0f;
    }
}

const char* MultibandCompressorProcessor::paramName(int index) const {
    switch (index) {
    case LOW_THRESH:  return "Low Thresh";
    case LOW_RATIO:   return "Low Ratio";
    case MID_THRESH:  return "Mid Thresh";
    case MID_RATIO:   return "Mid Ratio";
    case HIGH_THRESH: return "High Thresh";
    case HIGH_RATIO:  return "High Ratio";
    case CROSSOVER1:  return "Crossover 1";
    case CROSSOVER2:  return "Crossover 2";
    default: return "Unknown";
    }
}

} // namespace opensynth
