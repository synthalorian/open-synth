#include "oscillator.h"
#include <cstdlib>
#include <algorithm>

namespace openamp {

void Oscillator::setWaveform(int w) { waveform_ = std::clamp(w, 0, 5); }
void Oscillator::setOctave(int oct) { octave_ = std::clamp(oct, -2, 2); }
void Oscillator::setDetune(float cents) { detune_ = std::clamp(cents, -100.0f, 100.0f); }
void Oscillator::setPulseWidth(float pw) { pulseWidth_ = std::clamp(pw, 0.01f, 0.99f); }
void Oscillator::setVolume(float vol) { volume_ = std::clamp(vol, 0.0f, 1.0f); }

void Oscillator::setNoiseType(int nt) { noiseType_ = static_cast<NoiseType>(std::clamp(nt, 0, 2)); }

void Oscillator::setSubOscMode(int mode) { subOscMode_ = static_cast<SubOscMode>(std::clamp(mode, 0, 3)); }
void Oscillator::setSubOscVolume(float vol) { subOscVolume_ = std::clamp(vol, 0.0f, 1.0f); }

void Oscillator::setUnisonVoiceCount(int count) {
    unison_.voiceCount = std::clamp(count, 1, 8);
}
void Oscillator::setUnisonDetuneSpread(float cents) {
    unison_.detuneSpread = std::clamp(cents, 0.0f, 50.0f);
}
void Oscillator::setUnisonStereoSpread(float spread) {
    unison_.stereoSpread = std::clamp(spread, 0.0f, 1.0f);
}
void Oscillator::setUnisonMix(float mix) {
    unison_.mix = std::clamp(mix, 0.0f, 1.0f);
}

void Oscillator::reset() {
    // No state to reset besides parameters which stay as set
}

float Oscillator::voiceDetuneCents(int voiceIndex) const {
    if (voiceIndex == 0 || unison_.voiceCount <= 1) return 0.0f;
    // Spread unison voices across [-spread/2, +spread/2] cents
    int total = unison_.voiceCount - 1;
    float step = unison_.detuneSpread / total;
    return -unison_.detuneSpread * 0.5f + voiceIndex * step;
}

float Oscillator::voicePan(int voiceIndex) const {
    if (unison_.voiceCount <= 1) return 0.0f;
    // Stereo spread across unison voices
    int total = unison_.voiceCount - 1;
    if (total == 0) return 0.0f;
    float spread = unison_.stereoSpread;
    float pan = -spread * 0.5f + (voiceIndex / (float)total) * spread;
    return std::clamp(pan, -1.0f, 1.0f);
}

float Oscillator::phaseIncrement(float midiNoteFreq, int voiceIndex) const {
    float detuneCents = detune_;
    if (voiceIndex > 0) {
        detuneCents += voiceDetuneCents(voiceIndex);
    }
    // Convert cents to frequency ratio: 2^(cents/1200)
    float ratio = std::pow(2.0f, detuneCents / 1200.0f);
    float octaveMult = std::pow(2.0f, (float)octave_);
    return (midiNoteFreq * octaveMult * ratio) / 48000.0f; // normalized frequency
}

float Oscillator::generateWaveform(float phase) const {
    // Wrap phase to [0, 1)
    phase = phase - std::floor(phase);

    switch (static_cast<OscWaveform>(waveform_)) {
    case OscWaveform::SAW:
        return 2.0f * phase - 1.0f;

    case OscWaveform::SQUARE:
        return phase < 0.5f ? 1.0f : -1.0f;

    case OscWaveform::TRIANGLE:
        return 4.0f * std::abs(phase - 0.5f) - 1.0f;

    case OscWaveform::SINE:
        return std::sin(2.0f * M_PI * phase);

    case OscWaveform::NOISE: {
        // Generate noise based on type
        switch (noiseType_) {
        case NoiseType::WHITE: {
            float hash = std::sin(phase * 12453.789f) * 43758.5453f;
            return 2.0f * (hash - std::floor(hash)) - 1.0f;
        }
        case NoiseType::PINK: {
            // Paul Kellet's refined pink noise approximation
            // Uses 6 white noise generators at different octaves
            float white = std::sin(phase * 12453.789f) * 43758.5453f;
            white = 2.0f * (white - std::floor(white)) - 1.0f;
            // Approximate pink by averaging with lower-frequency white noise
            float lowFreq = std::sin(phase * 0.125f * 12453.789f) * 43758.5453f;
            lowFreq = 2.0f * (lowFreq - std::floor(lowFreq)) - 1.0f;
            float midFreq = std::sin(phase * 0.5f * 12453.789f) * 43758.5453f;
            midFreq = 2.0f * (midFreq - std::floor(midFreq)) - 1.0f;
            return std::clamp((white * 0.5f + midFreq * 0.3f + lowFreq * 0.2f) * 1.4f, -1.0f, 1.0f);
        }
        case NoiseType::BROWN: {
            // Brown noise: integrate white noise (random walk approximation)
            float white = std::sin(phase * 12453.789f) * 43758.5453f;
            white = 2.0f * (white - std::floor(white)) - 1.0f;
            // Leaky integrator to approximate brown noise
            static float brownState = 0.0f;
            brownState = brownState * 0.99f + white * 0.01f;
            return std::clamp(brownState * 5.0f, -1.0f, 1.0f);
        }
        default:
            return 0.0f;
        }
    }

    case OscWaveform::PULSE:
        return phase < pulseWidth_ ? 1.0f : -1.0f;
    }

    return 0.0f;
}

float Oscillator::process(float phase, int voiceIndex, float freq, double sampleRate) const {
    (void)sampleRate;
    float sample = generateWaveform(phase);

    // Sub-oscillator (square or sine below)
    if (subOscMode_ != SubOscMode::OFF && voiceIndex == 0) {
        float subDiv = 1.0f;
        float subFreq = freq;
        switch (subOscMode_) {
        case SubOscMode::SQUARE_1OCT:
            subDiv = 0.5f;
            subFreq = freq * 0.5f;
            break;
        case SubOscMode::SQUARE_2OCT:
            subDiv = 0.25f;
            subFreq = freq * 0.25f;
            break;
        case SubOscMode::SINE_1OCT:
            subDiv = 0.5f;
            subFreq = freq * 0.5f;
            break;
        default: break;
        }
        // Simple sub-osc: use phase (already independent per voice)
        float subPhase = phase * subDiv;
        subPhase = subPhase - std::floor(subPhase);
        float subSample = 0.0f;
        if (subOscMode_ == SubOscMode::SINE_1OCT) {
            subSample = std::sin(2.0f * M_PI * subPhase);
        } else {
            subSample = subPhase < 0.5f ? 1.0f : -1.0f;
        }
        sample = sample * (1.0f - subOscVolume_ * 0.7f) + subSample * subOscVolume_ * 0.7f;
    }

    // Apply unison mix: for voice 0 (main), blend dry/wet
    if (unison_.voiceCount > 1 && unison_.mix < 1.0f) {
        // Voice 0 = dry, voices 1+ = wet
        if (voiceIndex == 0) {
            sample *= (1.0f - unison_.mix);
        } else {
            sample *= unison_.mix / (float)(unison_.voiceCount - 1);
        }
    }

    return sample * volume_;
}

} // namespace openamp
