#include "fx_chorus_ensemble.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

static const double TWO_PI = 6.283185307179586;

ChorusEnsembleProcessor::ChorusEnsembleProcessor()
    : FxProcessor(FxType::ChorusEnsemble) {
    for (int i = 0; i < MAX_VOICES; ++i) {
        delayLines_[i].fill(0.0f);
        writeIndices_[i] = 0;
    }
}

float ChorusEnsembleProcessor::readDelay(const std::array<float, MAX_DELAY>& line, int writeIdx, float delaySamples) {
    float readPos = static_cast<float>(writeIdx) - delaySamples;
    while (readPos < 0.0f) readPos += MAX_DELAY;
    int i0 = static_cast<int>(readPos) % MAX_DELAY;
    int i1 = (i0 + 1) % MAX_DELAY;
    float frac = readPos - std::floor(readPos);
    return line[i0] * (1.0f - frac) + line[i1] * frac;
}

void ChorusEnsembleProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    // Advance LFO phase
    phase_ += rate_ / sampleRate;
    if (phase_ >= 1.0) phase_ -= 1.0;

    float inL = left;
    float inR = right;

    float wetL = 0.0f;
    float wetR = 0.0f;

    int activeVoices = std::clamp(voices_, 1, MAX_VOICES);

    for (int i = 0; i < activeVoices; ++i) {
        // Each voice has slight detune and stereo spread
        double voicePhase = phase_ + i * 0.25;
        if (voicePhase >= 1.0) voicePhase -= 1.0;
        float lfo = static_cast<float>(std::sin(voicePhase * TWO_PI));

        float baseDelayMs = modeOffsets_[mode_][i];
        if (baseDelayMs <= 0.0f) continue;

        float modMs = 1.5f * depth_ * lfo;
        float delayMs = baseDelayMs + modMs;
        float delaySamples = static_cast<float>(delayMs * 0.001 * sampleRate);
        delaySamples = std::clamp(delaySamples, 1.0f, static_cast<float>(MAX_DELAY - 1));

        // Write mono sum to each delay line
        delayLines_[i][writeIndices_[i]] = (inL + inR) * 0.5f;

        float tap = readDelay(delayLines_[i], writeIndices_[i], delaySamples);
        writeIndices_[i] = (writeIndices_[i] + 1) % MAX_DELAY;

        // Stereo spread: odd voices panned left, even right
        float pan = (i % 2 == 0) ? 0.6f : 0.4f;
        wetL += tap * pan;
        wetR += tap * (1.0f - pan);
    }

    // Normalize
    if (activeVoices > 0) {
        wetL /= activeVoices;
        wetR /= activeVoices;
    }

    // Chorus ensemble: dry + wet
    left = applyMix(inL, inL + wetL);
    right = applyMix(inR, inR + wetR);
}

void ChorusEnsembleProcessor::reset() {
    for (int i = 0; i < MAX_VOICES; ++i) {
        delayLines_[i].fill(0.0f);
        writeIndices_[i] = 0;
    }
    phase_ = 0.0;
}

void ChorusEnsembleProcessor::setParam(int index, float value) {
    switch (index) {
    case RATE:   rate_ = std::clamp(value, 0.1f, 10.0f); break;
    case DEPTH:  depth_ = std::clamp(value, 0.0f, 1.0f); break;
    case VOICES: voices_ = std::clamp(static_cast<int>(value), 1, MAX_VOICES); break;
    case MODE:   mode_ = std::clamp(static_cast<int>(value), 0, 3); break;
    default: break;
    }
}

float ChorusEnsembleProcessor::getParam(int index) const {
    switch (index) {
    case RATE:   return rate_;
    case DEPTH:  return depth_;
    case VOICES: return static_cast<float>(voices_);
    case MODE:   return static_cast<float>(mode_);
    default: return 0.0f;
    }
}

const char* ChorusEnsembleProcessor::paramName(int index) const {
    switch (index) {
    case RATE:   return "Rate";
    case DEPTH:  return "Depth";
    case VOICES: return "Voices";
    case MODE:   return "Mode";
    default: return "Unknown";
    }
}

} // namespace opensynth
