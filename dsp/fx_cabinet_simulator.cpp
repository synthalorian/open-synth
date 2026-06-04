#include "fx_cabinet_simulator.h"
#include <algorithm>

namespace opensynth {

CabinetSimulatorProcessor::CabinetSimulatorProcessor()
    : FxProcessor(FxType::CabinetSimulator) {}

void CabinetSimulatorProcessor::reset() {
    lpL_ = lpR_ = 0.0f;
    hpL_ = hpR_ = 0.0f;
    notchZ1L_ = notchZ2L_ = 0.0f;
    notchZ1R_ = notchZ2R_ = 0.0f;
}

void CabinetSimulatorProcessor::process(float& left, float& right, double sampleRate) {
    nativeSampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    float lpFreq, hpFreq, notchFreq, notchQ;
    getCabinetFreqs(lpFreq, hpFreq, notchFreq, notchQ);

    float midBoost, trebleBoost;
    getMicEmphasis(midBoost, trebleBoost);

    // Apply distance rolloff (more distance = more lowpass)
    lpFreq = lpFreq * (1.0f - distance_ * 0.5f);

    // Lowpass (cabinet rolloff)
    float wetL = lowpass(inL, lpL_, lpFreq, nativeSampleRate_);
    float wetR = lowpass(inR, lpR_, lpFreq, nativeSampleRate_);

    // Highpass (remove sub-bass mud)
    wetL = highpass(wetL, hpL_, hpFreq, nativeSampleRate_);
    wetR = highpass(wetR, hpR_, hpFreq, nativeSampleRate_);

    // Notch (cabinet resonance dip)
    wetL = notchSVF(wetL, notchZ1L_, notchZ2L_, notchFreq, notchQ, nativeSampleRate_);
    wetR = notchSVF(wetR, notchZ1R_, notchZ2R_, notchFreq, notchQ, nativeSampleRate_);

    // Mic emphasis (simple gain shaping)
    wetL *= (1.0f + midBoost * 0.3f);
    wetR *= (1.0f + midBoost * 0.3f);

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

float CabinetSimulatorProcessor::lowpass(float input, float& state, float freq, double sr) {
    float f = freq / static_cast<float>(sr);
    if (f > 0.49f) f = 0.49f;
    float coeff = 2.0f * 3.14159265f * f;
    state += coeff * (input - state);
    return state;
}

float CabinetSimulatorProcessor::highpass(float input, float& state, float freq, double sr) {
    float f = freq / static_cast<float>(sr);
    if (f > 0.49f) f = 0.49f;
    float coeff = 2.0f * 3.14159265f * f;
    state += coeff * (input - state);
    return input - state;
}

float CabinetSimulatorProcessor::notchSVF(float input, float& z1, float& z2, float freq, float q, double sr) {
    float f = 2.0f * std::sin(3.14159265f * freq / static_cast<float>(sr));
    if (f > 1.0f) f = 1.0f;
    float r = 1.0f / q;

    float low = z2 + f * z1;
    float band = z1 - f * low;
    float high = input - low - r * band;
    band += f * high;
    low += f * band;

    z1 = band;
    z2 = low;

    return low + high; // notch = low + high
}

void CabinetSimulatorProcessor::getCabinetFreqs(float& lpFreq, float& hpFreq, float& notchFreq, float& notchQ) {
    int t = static_cast<int>(type_) % 4;
    switch (t) {
    case 0: // 1x12
        lpFreq = 4500.0f;
        hpFreq = 80.0f;
        notchFreq = 2500.0f;
        notchQ = 2.0f;
        break;
    case 1: // 2x12
        lpFreq = 5000.0f;
        hpFreq = 70.0f;
        notchFreq = 2800.0f;
        notchQ = 2.5f;
        break;
    case 2: // 4x12
        lpFreq = 5500.0f;
        hpFreq = 60.0f;
        notchFreq = 3000.0f;
        notchQ = 3.0f;
        break;
    case 3: // 1x15
        lpFreq = 3500.0f;
        hpFreq = 40.0f;
        notchFreq = 1800.0f;
        notchQ = 1.5f;
        break;
    }
}

void CabinetSimulatorProcessor::getMicEmphasis(float& midBoost, float& trebleBoost) {
    int m = static_cast<int>(mic_) % 3;
    switch (m) {
    case 0: // dynamic
        midBoost = 0.3f;
        trebleBoost = -0.2f;
        break;
    case 1: // condenser
        midBoost = 0.1f;
        trebleBoost = 0.3f;
        break;
    case 2: // ribbon
        midBoost = 0.2f;
        trebleBoost = -0.4f;
        break;
    }
}

void CabinetSimulatorProcessor::setParam(int index, float value) {
    switch (index) {
    case TYPE:     type_ = std::clamp(value, 0.0f, 3.0f); break;
    case MIC:      mic_ = std::clamp(value, 0.0f, 2.0f); break;
    case DISTANCE: distance_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:      mix_ = value; break;
    default: break;
    }
}

float CabinetSimulatorProcessor::getParam(int index) const {
    switch (index) {
    case TYPE:     return type_;
    case MIC:      return mic_;
    case DISTANCE: return distance_;
    case MIX:      return mix_;
    default: return 0.0f;
    }
}

const char* CabinetSimulatorProcessor::paramName(int index) const {
    switch (index) {
    case TYPE:     return "Type";
    case MIC:      return "Mic";
    case DISTANCE: return "Distance";
    case MIX:      return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
