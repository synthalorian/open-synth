#include "instrument_realism.h"
#include <cstring>
#include <algorithm>

namespace openamp {

// ── Body Resonance ───────────────────────────────────────────────────────────

void BodyResonance::reset() {
    for (int i = 0; i < 3; ++i) {
        modes[i].bp = 0.0f;
        modes[i].lp = 0.0f;
    }
}

float BodyResonance::process(float input, double sampleRate, const float* freqs, const float* qs, const float* amps) {
    float out = 0.0f;
    float invSr = 1.0f / static_cast<float>(sampleRate);

    for (int i = 0; i < 3; ++i) {
        float f = 2.0f * std::sin(3.14159265f * freqs[i] * invSr);
        f = std::min(f, 1.95f);
        float q = 1.0f - std::clamp(1.0f / qs[i], 0.01f, 0.99f);

        float bp = modes[i].bp + f * (input - modes[i].lp - q * modes[i].bp);
        float lp = modes[i].lp + f * bp;
        modes[i].bp = bp;
        modes[i].lp = lp;

        out += bp * amps[i];
    }

    return out;
}

// ── Key Click Generator ──────────────────────────────────────────────────────

static float fastRand(float& seed) {
    uint32_t s;
    std::memcpy(&s, &seed, sizeof(s));
    s = s * 1103515245u + 12345u;
    std::memcpy(&seed, &s, sizeof(seed));
    return static_cast<float>((s >> 16) & 0x7FFF) / 16384.0f - 1.0f;
}

void KeyClickGenerator::trigger(float velocity, float clickDurationMs, double sampleRate) {
    active = true;
    envelope = 1.0f;
    level = velocity * 0.4f;
    samplesRemaining = static_cast<int>(clickDurationMs * 0.001 * sampleRate);
    if (samplesRemaining < 10) samplesRemaining = 10;
    noiseSeed = static_cast<float>(static_cast<int>(velocity * 1000.0f) + 1);
    filterState = 0.0f;
    // Decay based on duration
    decay = std::pow(0.001f, 1.0f / static_cast<float>(samplesRemaining));
}

void KeyClickGenerator::reset() {
    active = false;
    envelope = 0.0f;
    samplesRemaining = 0;
}

float KeyClickGenerator::process(double sampleRate) {
    if (!active || samplesRemaining <= 0) {
        active = false;
        return 0.0f;
    }

    // White noise burst
    float noise = fastRand(noiseSeed);

    // High-pass filter for click character (simulates mechanical transient)
    float hpf = noise - filterState;
    filterState = noise;

    // Apply envelope
    float sample = hpf * envelope * level;
    envelope *= decay;
    samplesRemaining--;

    if (envelope < 0.0001f || samplesRemaining <= 0) {
        active = false;
    }

    return sample;
}

// ── Sympathetic Resonator ────────────────────────────────────────────────────

void SympatheticResonator::noteOn(float freq, float velocity) {
    // Find a free slot or steal the quietest
    int slot = -1;
    float minEnv = 999.0f;
    for (int i = 0; i < kMaxStrings; ++i) {
        if (!strings[i].active) {
            slot = i;
            break;
        }
        if (strings[i].envelope < minEnv) {
            minEnv = strings[i].envelope;
            slot = i;
        }
    }

    if (slot >= 0) {
        strings[slot].active = true;
        strings[slot].freq = freq;
        strings[slot].velocity = velocity;
        strings[slot].envelope = velocity * 0.3f;  // Start quieter than main note
        strings[slot].phase = 0.0f;
        // Decay depends on frequency (higher = faster decay)
        strings[slot].decay = 0.9995f - (freq / 20000.0f) * 0.003f;
        if (strings[slot].decay < 0.99f) strings[slot].decay = 0.99f;
    }
}

void SympatheticResonator::noteOff(float freq) {
    // Find matching string and accelerate decay
    for (int i = 0; i < kMaxStrings; ++i) {
        if (strings[i].active && std::abs(strings[i].freq - freq) < 1.0f) {
            strings[i].decay *= 0.8f;  // Faster decay on note-off
        }
    }
}

void SympatheticResonator::reset() {
    for (int i = 0; i < kMaxStrings; ++i) {
        strings[i].active = false;
        strings[i].envelope = 0.0f;
        strings[i].phase = 0.0f;
    }
}

float SympatheticResonator::process(double sampleRate) {
    float out = 0.0f;
    float invSr = 1.0f / static_cast<float>(sampleRate);

    for (int i = 0; i < kMaxStrings; ++i) {
        if (!strings[i].active) continue;

        strings[i].phase += strings[i].freq * invSr;
        if (strings[i].phase >= 1.0f) strings[i].phase -= 1.0f;

        float sample = std::sin(2.0f * 3.14159265f * strings[i].phase) * strings[i].envelope;
        out += sample;

        strings[i].envelope *= strings[i].decay;
        if (strings[i].envelope < 0.0001f) {
            strings[i].active = false;
        }
    }

    return out * 0.1f;  // Mix at low level
}

// ── Instrument Realism ───────────────────────────────────────────────────────

void InstrumentRealism::reset() {
    body.reset();
    click.reset();
    sympathetic.reset();
}

float InstrumentRealism::process(float input, float velocity, double sampleRate, float noteAge) {
    float out = input;

    // 1. Key click (only during attack phase)
    if (clickMix > 0.0f && noteAge < 0.05f) {
        out += click.process(sampleRate) * clickMix;
    }

    // 2. Body resonance
    if (bodyMix > 0.0f && bodyType > 0) {
        const float* freqs = nullptr;
        const float* qs = nullptr;
        const float* amps = nullptr;

        switch (bodyType) {
            case 1:  // Piano
                freqs = BodyResonance::kPianoModes;
                qs = BodyResonance::kPianoQs;
                amps = BodyResonance::kPianoAmps;
                break;
            case 2:  // Guitar
                freqs = BodyResonance::kGuitarModes;
                qs = BodyResonance::kGuitarQs;
                amps = BodyResonance::kGuitarAmps;
                break;
            case 3:  // Violin
                freqs = BodyResonance::kViolinModes;
                qs = BodyResonance::kViolinQs;
                amps = BodyResonance::kViolinAmps;
                break;
            default:
                break;
        }

        if (freqs) {
            float bodyOut = body.process(out, sampleRate, freqs, qs, amps);
            out = out * (1.0f - bodyMix) + bodyOut * bodyMix;
        }
    }

    // 3. Sympathetic resonance (global, mixed in post)
    // Note: sympathetic is typically processed at the engine level and mixed globally
    // We return the contribution here but the engine mixes it

    return out;
}

} // namespace openamp
