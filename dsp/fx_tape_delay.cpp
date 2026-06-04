#include "fx_tape_delay.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

static const double TWO_PI = 6.283185307179586;

TapeDelayProcessor::TapeDelayProcessor()
    : FxProcessor(FxType::TapeDelay) {
    delayLineL_.fill(0.0f);
    delayLineR_.fill(0.0f);
}

float TapeDelayProcessor::readDelay(const std::array<float, MAX_DELAY>& line, float delaySamples) {
    float readPos = static_cast<float>(writeIndex_) - delaySamples;
    while (readPos < 0.0f) readPos += MAX_DELAY;
    int i0 = static_cast<int>(readPos) % MAX_DELAY;
    int i1 = (i0 + 1) % MAX_DELAY;
    float frac = readPos - std::floor(readPos);
    return line[i0] * (1.0f - frac) + line[i1] * frac;
}

float TapeDelayProcessor::lowpass(float input, float& state, double sr) {
    // Simple 1-pole lowpass ~3kHz for tape damping
    float freq = 3000.0f;
    float f = freq / static_cast<float>(sr);
    if (f > 0.49f) f = 0.49f;
    float coeff = 2.0f * 3.14159265f * f;
    state += coeff * (input - state);
    return state;
}

void TapeDelayProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    // Advance wow LFO (0.5 - 5 Hz based on wow amount)
    float wowRate = 0.5f + wow_ * 4.5f;
    phase_ += wowRate / sampleRate;
    if (phase_ >= 1.0) phase_ -= 1.0;

    float lfo = static_cast<float>(std::sin(phase_ * TWO_PI));

    // Modulate delay time with wow
    float modMs = wow_ * 10.0f * lfo; // +/- 10ms wow
    float delayMs = timeMs_ + modMs;
    float delaySamples = static_cast<float>(delayMs * 0.001 * sampleRate);
    delaySamples = std::clamp(delaySamples, 1.0f, static_cast<float>(MAX_DELAY - 1));

    float inL = left;
    float inR = right;

    // Read delayed signal
    float wetL = readDelay(delayLineL_, delaySamples);
    float wetR = readDelay(delayLineR_, delaySamples);

    // Tape damping: lowpass in feedback path
    float fbL = lowpass(wetL, lpL_, sampleRate);
    float fbR = lowpass(wetR, lpR_, sampleRate);

    // Write input + feedback to delay lines
    delayLineL_[writeIndex_] = inL + fbL * feedback_;
    delayLineR_[writeIndex_] = inR + fbR * feedback_;

    // Advance write pointer
    writeIndex_ = (writeIndex_ + 1) % MAX_DELAY;

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

void TapeDelayProcessor::reset() {
    delayLineL_.fill(0.0f);
    delayLineR_.fill(0.0f);
    writeIndex_ = 0;
    phase_ = 0.0;
    lpL_ = 0.0f;
    lpR_ = 0.0f;
}

void TapeDelayProcessor::setParam(int index, float value) {
    switch (index) {
    case TIME:     timeMs_ = std::clamp(value, 50.0f, 1000.0f); break;
    case FEEDBACK: feedback_ = std::clamp(value, 0.0f, 0.95f); break;
    case WOW:      wow_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:      mix_ = std::clamp(value, 0.0f, 1.0f); break;
    default: break;
    }
}

float TapeDelayProcessor::getParam(int index) const {
    switch (index) {
    case TIME:     return timeMs_;
    case FEEDBACK: return feedback_;
    case WOW:      return wow_;
    case MIX:      return mix_;
    default: return 0.0f;
    }
}

const char* TapeDelayProcessor::paramName(int index) const {
    switch (index) {
    case TIME:     return "Time";
    case FEEDBACK: return "Feedback";
    case WOW:      return "Wow";
    case MIX:      return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
