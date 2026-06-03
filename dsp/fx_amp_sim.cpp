#include "fx_amp_sim.h"
#include <algorithm>

namespace opensynth {

AmpSimulatorProcessor::AmpSimulatorProcessor()
    : FxProcessor(FxType::AmpSimulator) {}

void AmpSimulatorProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // Preamp distortion
    float distL = distort(inL * (1.0f + gain_ * 9.0f));
    float distR = distort(inR * (1.0f + gain_ * 9.0f));

    // Tone stack
    float outL = toneFilter(distL, bassL_, 150.0f, bass_ * 2.0f, sampleRate_);
    outL = toneFilter(outL, midL_, 1000.0f, mid_ * 2.0f, sampleRate_);
    outL = toneFilter(outL, trebleL_, 4000.0f, treble_ * 2.0f, sampleRate_);
    outL = toneFilter(outL, presenceL_, 8000.0f, presence_ * 2.0f, sampleRate_);

    float outR = toneFilter(distR, bassR_, 150.0f, bass_ * 2.0f, sampleRate_);
    outR = toneFilter(outR, midR_, 1000.0f, mid_ * 2.0f, sampleRate_);
    outR = toneFilter(outR, trebleR_, 4000.0f, treble_ * 2.0f, sampleRate_);
    outR = toneFilter(outR, presenceR_, 8000.0f, presence_ * 2.0f, sampleRate_);

    left = applyMix(inL, outL);
    right = applyMix(inR, outR);
}

float AmpSimulatorProcessor::distort(float sample) {
    // Tube-like soft clipping with asymmetry
    float x = sample;
    if (x > 0.0f) {
        x = std::tanh(x * 1.5f);
    } else {
        x = std::tanh(x * 2.0f) * 0.8f;
    }
    return std::clamp(x, -1.0f, 1.0f);
}

float AmpSimulatorProcessor::toneFilter(float input, float& state, float freq, float gain, double sr) {
    // Simple 1-pole lowpass as basis, scaled by gain
    float f = freq / sr;
    if (f > 0.49f) f = 0.49f;
    float coeff = 2.0f * 3.14159265f * f;
    state += coeff * (input - state);
    return input * (1.0f - gain * 0.5f) + state * gain;
}

void AmpSimulatorProcessor::reset() {
    bassL_ = bassR_ = 0.0f;
    midL_ = midR_ = 0.0f;
    trebleL_ = trebleR_ = 0.0f;
    presenceL_ = presenceR_ = 0.0f;
}

void AmpSimulatorProcessor::setParam(int index, float value) {
    switch (index) {
    case GAIN:     gain_ = value; break;
    case BASS:     bass_ = value; break;
    case MID:      mid_ = value; break;
    case TREBLE:   treble_ = value; break;
    case PRESENCE: presence_ = value; break;
    case MIX:      mix_ = value; break;
    default: break;
    }
}

float AmpSimulatorProcessor::getParam(int index) const {
    switch (index) {
    case GAIN:     return gain_;
    case BASS:     return bass_;
    case MID:      return mid_;
    case TREBLE:   return treble_;
    case PRESENCE: return presence_;
    case MIX:      return mix_;
    default: return 0.0f;
    }
}

const char* AmpSimulatorProcessor::paramName(int index) const {
    switch (index) {
    case GAIN:     return "Gain";
    case BASS:     return "Bass";
    case MID:      return "Mid";
    case TREBLE:   return "Treble";
    case PRESENCE: return "Presence";
    case MIX:      return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
