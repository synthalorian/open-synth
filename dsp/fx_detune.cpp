#include "fx_detune.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

DetuneProcessor::DetuneProcessor()
    : FxProcessor(FxType::Detune) {
    for (auto& v : voices_) {
        v.delayL.fill(0.0f);
        v.delayR.fill(0.0f);
    }
}

void DetuneProcessor::process(float& left, float& right, double sampleRate) {
    sampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // Window size fixed for detune (moderate size for smoothness)
    int ws = 2048;

    float wetL = 0.0f;
    float wetR = 0.0f;

    for (int v = 0; v < voiceCount_ && v < MAX_VOICES; ++v) {
        auto& voice = voices_[v];

        // Each voice has slightly different detune amount
        float voiceSpread = (static_cast<float>(v) - static_cast<float>(voiceCount_ - 1) * 0.5f);
        float cents = amount_ + voiceSpread * (spread_ * 15.0f);
        float ratio = std::pow(2.0f, cents / 1200.0f);

        // Write to delay line
        voice.delayL[voice.writePos] = inL;
        voice.delayR[voice.writePos] = inR;

        // Two-tap crossfade pitch shifter
        float pos1L = voice.readPosL;
        float pos1R = voice.readPosR;
        float pos2L = pos1L + ws * 0.5f;
        float pos2R = pos1R + ws * 0.5f;

        if (pos2L >= ws) pos2L -= ws;
        if (pos2R >= ws) pos2R -= ws;

        float crossfade = pos1L / (ws * 0.5f);
        if (crossfade > 1.0f) crossfade = 2.0f - crossfade;

        float sL = readDelay(voice.delayL, pos1L, ws) * (1.0f - crossfade)
                 + readDelay(voice.delayL, pos2L, ws) * crossfade;
        float sR = readDelay(voice.delayR, pos1R, ws) * (1.0f - crossfade)
                 + readDelay(voice.delayR, pos2R, ws) * crossfade;

        // Pan voices across stereo field
        float pan = 0.5f + voiceSpread * spread_ * 0.5f;
        pan = std::clamp(pan, 0.0f, 1.0f);
        wetL += sL * (1.0f - pan);
        wetR += sR * pan;

        voice.readPosL += ratio;
        voice.readPosR += ratio;

        if (voice.readPosL >= ws) voice.readPosL -= ws;
        if (voice.readPosR >= ws) voice.readPosR -= ws;

        voice.writePos = (voice.writePos + 1) % ws;
    }

    // Normalize wet signal by voice count
    if (voiceCount_ > 0) {
        wetL /= static_cast<float>(voiceCount_);
        wetR /= static_cast<float>(voiceCount_);
    }

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

float DetuneProcessor::readDelay(const std::array<float, MAX_DELAY>& buf, float pos, int windowSize) {
    int i = static_cast<int>(pos);
    float frac = pos - i;
    int i1 = i % windowSize;
    int i2 = (i1 + 1) % windowSize;
    return buf[i1] * (1.0f - frac) + buf[i2] * frac;
}

void DetuneProcessor::reset() {
    for (auto& v : voices_) {
        v.delayL.fill(0.0f);
        v.delayR.fill(0.0f);
        v.writePos = 0;
        v.readPosL = 0.0f;
        v.readPosR = 0.0f;
    }
}

void DetuneProcessor::setParam(int index, float value) {
    switch (index) {
    case AMOUNT: amount_ = std::clamp(value, -50.0f, 50.0f); break;
    case MIX:    mix_ = value; break;
    case SPREAD: spread_ = std::clamp(value, 0.0f, 1.0f); break;
    case VOICES: voiceCount_ = static_cast<int>(std::clamp(value, 1.0f, 4.0f)); break;
    default: break;
    }
}

float DetuneProcessor::getParam(int index) const {
    switch (index) {
    case AMOUNT: return amount_;
    case MIX:    return mix_;
    case SPREAD: return spread_;
    case VOICES: return static_cast<float>(voiceCount_);
    default: return 0.0f;
    }
}

const char* DetuneProcessor::paramName(int index) const {
    switch (index) {
    case AMOUNT: return "Amount";
    case MIX:    return "Mix";
    case SPREAD: return "Spread";
    case VOICES: return "Voices";
    default: return "Unknown";
    }
}

} // namespace opensynth
