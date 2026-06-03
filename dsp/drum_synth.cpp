#include "drum_synth.h"
#include "drum_kit_mapping.h"
#include <cmath>
#include <cstring>
#include <algorithm>

namespace opensynth {

// ── Helpers ───────────────────────────────────────────────────────────────────

float DrumKit::midiToFreq(int note) {
    return 440.0f * std::pow(2.0f, (note - 69) / 12.0f);
}

float DrumKit::fastRand(float& noiseState) {
    uint32_t seed;
    std::memcpy(&seed, &noiseState, sizeof(seed));
    seed = seed * 1103515245u + 12345u;
    std::memcpy(&noiseState, &seed, sizeof(noiseState));
    float v = static_cast<float>((seed >> 16) & 0x7FFF) / 32767.0f;
    return v * 2.0f - 1.0f;  // -1 .. +1
}

// Standalone fast random for free functions
static inline float fastRandFloat(float& noiseState) {
    uint32_t seed;
    std::memcpy(&seed, &noiseState, sizeof(seed));
    seed = seed * 1103515245u + 12345u;
    std::memcpy(&noiseState, &seed, sizeof(noiseState));
    float v = static_cast<float>((seed >> 16) & 0x7FFF) / 32767.0f;
    return v * 2.0f - 1.0f;
}

// Pink noise approximation (Paul Kellet's method)
static float pinkNoise(float& whiteState, float& b0, float& b1, float& b2, float& b3, float& b4, float& b5, float& b6) {
    float white = fastRandFloat(whiteState);
    b0 = 0.99886f * b0 + white * 0.0555179f;
    b1 = 0.99332f * b1 + white * 0.0750759f;
    b2 = 0.96900f * b2 + white * 0.1538520f;
    b3 = 0.86650f * b3 + white * 0.3104856f;
    b4 = 0.55000f * b4 + white * 0.5329522f;
    b5 = -0.7616f * b5 - white * 0.0168980f;
    float out = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362f;
    b6 = white * 0.115926f;
    return out * 0.11f;  // normalize
}

// Exponential pitch envelope: fast initial drop, then settles
static float pitchEnvelope(float phase, float startFreq, float endFreq, float sweepTime, float totalDecay) {
    float sweepPhase = std::fmin(phase / (sweepTime / totalDecay), 1.0f);
    // Exponential curve: 0.7^x gives fast initial drop
    float curve = std::pow(0.7f, sweepPhase * 10.0f);
    return endFreq + (startFreq - endFreq) * curve;
}

// Multiple resonant mode oscillator (for drumheads and cymbals)
static float multiModeOsc(float phase, float* modePhases, const float* modeFreqs, 
                          const float* modeAmps, int numModes, float invSr) {
    float out = 0.0f;
    for (int i = 0; i < numModes; ++i) {
        modePhases[i] += modeFreqs[i] * invSr;
        if (modePhases[i] >= 1.0f) modePhases[i] -= std::floor(modePhases[i]);
        out += std::sin(2.0f * 3.14159265f * modePhases[i]) * modeAmps[i];
    }
    return out;
}

// ── Construction ──────────────────────────────────────────────────────────────

DrumKit::DrumKit(double sampleRate)
    : sampleRate_(sampleRate)
{
    for (int i = 0; i < kMaxVoices; ++i) {
        voices_[i].active = false;
    }
    initDrumKitPresets(kits_);
    setKitPreset(0);
}

// ── Voice management ─────────────────────────────────────────────────────────

int DrumKit::findFreeVoice() {
    for (int i = 0; i < kMaxVoices; ++i) {
        if (!voices_[i].active) return i;
    }
    // Steal oldest (voice 0 is simplest, but track age for better stealing)
    int oldestIdx = 0;
    float oldestAge = 0.0f;
    for (int i = 0; i < kMaxVoices; ++i) {
        if (voices_[i].envelopePhase > oldestAge) {
            oldestAge = voices_[i].envelopePhase;
            oldestIdx = i;
        }
    }
    return oldestIdx;
}

void DrumKit::configureVoice(DrumVoice& v, DrumType type,
                              const DrumSoundConfig& cfg,
                              float velocity, int note) {
    v.type = type;
    v.active = true;
    v.velocity = velocity;
    v.envelopePhase = 0.0f;
    v.midiNote = note;
    v.chokeLevel = 1.0f;
    v.phase = 0.0f;
    v.phase2 = 0.0f;
    v.subPhase = 0.0f;
    v.burstTimer = 0.0f;
    v.burstCount = 0;
    v.filterState1 = 0.0f;
    v.filterState2 = 0.0f;
    // Pink noise filter states
    v.pinkB0 = v.pinkB1 = v.pinkB2 = v.pinkB3 = v.pinkB4 = v.pinkB5 = v.pinkB6 = 0.0f;
    // Multi-mode oscillator states
    for (int i = 0; i < 8; ++i) v.modePhases[i] = 0.0f;
    v.modeCount = 0;

    float nseed = static_cast<float>(note * 127 + static_cast<int>(velocity * 1000.0f));
    v.noiseState = (nseed != 0.0f) ? nseed : 1.0f;

    v.tuning = cfg.tuning;
    float tuning = cfg.tuning;
    float decay  = (cfg.decay >= 0.0f) ? cfg.decay : -1.0f;

    switch (type) {
        case DrumType::KICK:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.45f;
            v.pitchStart = 180.0f * tuning;
            v.pitchEnd   = 45.0f * tuning;
            v.pitchSweepTime = 0.06f;
            v.noiseLevel = 0.4f;
            v.toneLevel  = 1.0f;
            break;

        case DrumType::SNARE:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.35f;
            v.toneLevel  = cfg.toneMix;
            v.noiseLevel = 1.0f - cfg.toneMix;
            v.pitchStart = 185.0f * tuning;
            v.pitchEnd   = 165.0f * tuning;
            v.pitchSweepTime = 0.08f;
            break;

        case DrumType::CLOSED_HH:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.04f;
            v.noiseLevel = 1.0f;
            v.toneLevel  = 0.0f;
            break;

        case DrumType::OPEN_HH:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.45f;
            v.noiseLevel = 1.0f;
            v.toneLevel  = 0.0f;
            break;

        case DrumType::TOM_HIGH:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.28f;
            v.pitchStart = 280.0f * tuning;
            v.pitchEnd   = 130.0f * tuning;
            v.pitchSweepTime = 0.05f;
            v.noiseLevel = 0.08f;
            v.toneLevel  = 1.0f;
            break;

        case DrumType::TOM_MID:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.32f;
            v.pitchStart = 200.0f * tuning;
            v.pitchEnd   = 95.0f * tuning;
            v.pitchSweepTime = 0.06f;
            v.noiseLevel = 0.08f;
            v.toneLevel  = 1.0f;
            break;

        case DrumType::TOM_LOW:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.38f;
            v.pitchStart = 140.0f * tuning;
            v.pitchEnd   = 65.0f * tuning;
            v.pitchSweepTime = 0.07f;
            v.noiseLevel = 0.08f;
            v.toneLevel  = 1.0f;
            break;

        case DrumType::CRASH:
            v.baseDecay = (decay >= 0.0f) ? decay : 7.0f;
            v.noiseLevel = 1.0f;
            v.toneLevel  = 0.0f;
            break;

        case DrumType::RIDE:
            v.baseDecay = (decay >= 0.0f) ? decay : 1.0f;
            v.noiseLevel = 1.0f;
            v.toneLevel  = cfg.toneMix;
            v.pitchStart = 800.0f * tuning;
            v.pitchEnd   = 800.0f * tuning;
            v.pitchSweepTime = 0.0f;
            break;

        case DrumType::CLAP:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.22f;
            v.noiseLevel = 1.0f;
            v.toneLevel  = 0.0f;
            v.burstTimer = 0.0f;
            v.burstCount = 0;
            v.pitchSweepTime = 0.025f;
            break;

        case DrumType::RIMSHOT:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.025f;
            v.pitchStart = 1200.0f * tuning;
            v.pitchEnd   = 1200.0f * tuning;
            v.pitchSweepTime = 0.0f;
            v.toneLevel  = 0.3f;
            v.noiseLevel = 0.7f;
            break;

        case DrumType::COWBELL:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.18f;
            v.pitchStart = 853.0f * tuning;  // Classic LP cowbell freq 1
            v.pitchEnd   = 853.0f * tuning;
            v.pitchSweepTime = 0.0f;
            v.toneLevel  = 1.0f;
            v.noiseLevel = 0.0f;
            v.detune     = 277.0f * tuning;  // 1130 - 853 = 277 Hz difference
            break;

        case DrumType::SHAKER:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.1f;
            v.noiseLevel = 1.0f;
            v.toneLevel  = 0.0f;
            v.velocity *= 0.5f;
            break;

        case DrumType::CONGA_HIGH:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.22f;
            v.pitchStart = 400.0f * tuning;
            v.pitchEnd   = 340.0f * tuning;
            v.pitchSweepTime = 0.07f;
            v.toneLevel  = 1.0f;
            v.noiseLevel = 0.03f;
            break;

        case DrumType::CONGA_LOW:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.25f;
            v.pitchStart = 250.0f * tuning;
            v.pitchEnd   = 200.0f * tuning;
            v.pitchSweepTime = 0.08f;
            v.toneLevel  = 1.0f;
            v.noiseLevel = 0.03f;
            break;

        default:
            break;
    }
}

// ── MIDI input ────────────────────────────────────────────────────────────────

void DrumKit::noteOn(int midiNote, float velocity) {
    int drumIdx = gm2NoteToDrumType(midiNote);
    if (drumIdx < 0) return;

    DrumType type = static_cast<DrumType>(drumIdx);

    if (type == DrumType::CLOSED_HH) {
        for (int i = 0; i < kMaxVoices; ++i) {
            if (voices_[i].active && voices_[i].type == DrumType::OPEN_HH) {
                voices_[i].chokeLevel = 0.0f;
            }
        }
    }

    int idx = findFreeVoice();
    const DrumSoundConfig& cfg = kits_[currentKit_].sounds[drumIdx];
    configureVoice(voices_[idx], type, cfg, velocity, midiNote);
}

void DrumKit::noteOff(int midiNote) {
    int drumIdx = gm2NoteToDrumType(midiNote);
    if (drumIdx < 0) return;
    DrumType type = static_cast<DrumType>(drumIdx);

    for (int i = 0; i < kMaxVoices; ++i) {
        if (voices_[i].active) {
            if (type == DrumType::CLOSED_HH && voices_[i].type == DrumType::OPEN_HH) {
                voices_[i].chokeLevel = 0.0f;
            }
            if (voices_[i].type == type && type == DrumType::OPEN_HH) {
                voices_[i].chokeLevel = 0.0f;
            }
        }
    }
}

// ── Process ───────────────────────────────────────────────────────────────────

void DrumKit::process(float* leftOut, float* rightOut, uint32_t numFrames) {
    for (uint32_t i = 0; i < numFrames; ++i) {
        leftOut[i] = 0.0f;
        rightOut[i] = 0.0f;
    }

    const float invSr = 1.0f / static_cast<float>(sampleRate_);
    const float pi = 3.14159265358979323846f;
    const float twoPi = 2.0f * pi;

    for (int vi = 0; vi < kMaxVoices; ++vi) {
        DrumVoice& v = voices_[vi];
        if (!v.active) continue;

        for (uint32_t frame = 0; frame < numFrames; ++frame) {
            float phaseStep = invSr / v.baseDecay;

            // ── Envelope with per-type characteristics ─────────────────────
            float envelope = 0.0f;
            float ampEnv = 0.0f;      // amplitude envelope
            float toneEnv = 0.0f;     // tone/body envelope  
            float noiseEnv = 0.0f;    // noise envelope
            float clickEnv = 0.0f;    // click/transient envelope

            if (v.type == DrumType::CLAP) {
                float burstLen = v.pitchSweepTime / v.baseDecay;
                if (v.envelopePhase < burstLen) {
                    float burstPhase = v.envelopePhase / burstLen;
                    float hit1 = std::exp(-std::pow((burstPhase - 0.08f) / 0.04f, 2.0f));
                    float hit2 = std::exp(-std::pow((burstPhase - 0.28f) / 0.04f, 2.0f));
                    float hit3 = std::exp(-std::pow((burstPhase - 0.48f) / 0.04f, 2.0f));
                    float hit4 = std::exp(-std::pow((burstPhase - 0.68f) / 0.05f, 2.0f));
                    envelope = (hit1 + hit2 * 0.8f + hit3 * 0.6f + hit4 * 0.4f) * 1.3f;
                } else {
                    float tailPhase = (v.envelopePhase - burstLen) / (1.0f - burstLen);
                    envelope = std::exp(-tailPhase * 10.0f);
                }
                ampEnv = envelope;
            } else if (v.type == DrumType::KICK) {
                // Multi-stage envelope: fast attack, exponential decay
                ampEnv = std::exp(-v.envelopePhase * 3.5f);
                toneEnv = std::exp(-v.envelopePhase * 2.8f);
                noiseEnv = std::exp(-v.envelopePhase * 25.0f);
                clickEnv = std::exp(-v.envelopePhase * 60.0f);
                envelope = ampEnv;
            } else if (v.type == DrumType::SNARE) {
                ampEnv = std::exp(-v.envelopePhase * 4.0f);
                toneEnv = std::exp(-v.envelopePhase * 3.0f);
                noiseEnv = std::exp(-v.envelopePhase * 5.5f);
                clickEnv = std::exp(-v.envelopePhase * 40.0f);
                envelope = ampEnv;
            } else if (v.type == DrumType::CRASH) {
                // Frequency-dependent decay: highs die faster
                ampEnv = std::exp(-v.envelopePhase * 1.2f);
                toneEnv = std::exp(-v.envelopePhase * 3.0f);  // highs decay faster
                envelope = ampEnv;
            } else if (v.type == DrumType::RIDE) {
                ampEnv = std::exp(-v.envelopePhase * 2.5f);
                toneEnv = std::exp(-v.envelopePhase * 4.0f);
                envelope = ampEnv;
            } else {
                ampEnv = std::exp(-v.envelopePhase * 5.0f);
                envelope = ampEnv;
            }

            if (v.envelopePhase >= 1.0f || envelope < 0.00005f) {
                v.active = false;
                break;
            }

            if (v.chokeLevel <= 0.0f) {
                v.active = false;
                break;
            }

            float sample = 0.0f;

            // ── Per-type synthesis ─────────────────────────────────────────
            switch (v.type) {

                // ─── KICK ───────────────────────────────────────────────────
                case DrumType::KICK: {
                    float freq = pitchEnvelope(v.envelopePhase, v.pitchStart, v.pitchEnd, 
                                               v.pitchSweepTime, v.baseDecay);
                    
                    // Main body: pitched sine with exponential curve
                    v.phase += freq * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    float body = std::sin(twoPi * v.phase);
                    
                    // Sub-boom: octave below, follows pitch
                    v.subPhase += freq * 0.5f * invSr;
                    if (v.subPhase >= 1.0f) v.subPhase -= std::floor(v.subPhase);
                    float sub = std::sin(twoPi * v.subPhase);
                    
                    // Shell resonance: slightly detuned, lower amplitude
                    float shellFreq = v.pitchEnd * 0.72f;
                    v.phase2 += shellFreq * invSr;
                    if (v.phase2 >= 1.0f) v.phase2 -= std::floor(v.phase2);
                    float shell = std::sin(twoPi * v.phase2);
                    
                    // Beater click: filtered noise burst
                    float clickNoise = DrumKit::fastRand(v.noiseState);
                    // Simple 1-pole HPF for click
                    float clickHpf = clickNoise - v.filterState2;
                    v.filterState2 = clickNoise;
                    float click = clickHpf * clickEnv * 0.5f;
                    
                    // Knock transient: very short low-mid thump
                    float knockFreq = 80.0f;
                    float knockPhase = v.envelopePhase * 20.0f;  // very fast
                    float knock = std::sin(twoPi * knockPhase) * clickEnv * 0.3f;
                    
                    sample = (body * 0.6f + sub * 0.35f + shell * 0.15f) * toneEnv * v.toneLevel
                           + click * v.noiseLevel
                           + knock * v.noiseLevel * 0.5f;
                    break;
                }

                // ─── SNARE ──────────────────────────────────────────────────
                case DrumType::SNARE: {
                    // Shell: two resonant modes (fundamental + first overtone)
                    float shellFreq1 = 185.0f * v.tuning;
                    float shellFreq2 = shellFreq1 * 1.6f;  // first overtone
                    v.phase += shellFreq1 * invSr;
                    v.phase2 += shellFreq2 * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    if (v.phase2 >= 1.0f) v.phase2 -= std::floor(v.phase2);
                    float shell = std::sin(twoPi * v.phase) * 0.7f 
                                + std::sin(twoPi * v.phase2) * 0.3f;
                    
                    // Snare wires: multiple BPFs on pink noise for realistic rattle
                    float wireNoise = pinkNoise(v.noiseState, v.pinkB0, v.pinkB1, 
                                                v.pinkB2, v.pinkB3, v.pinkB4, v.pinkB5, v.pinkB6);
                    
                    // 4 parallel resonant filters at wire frequencies
                    float wireFreqs[4] = {1200.0f, 2500.0f, 3800.0f, 5200.0f};
                    float wireQs[4] = {0.85f, 0.75f, 0.65f, 0.55f};
                    float wireOut = 0.0f;
                    
                    for (int w = 0; w < 4; ++w) {
                        float f = 2.0f * std::sin(pi * wireFreqs[w] * invSr);
                        f = std::min(f, 1.95f);
                        float qf = 1.0f - std::clamp(1.0f / wireQs[w], 0.01f, 0.99f);
                        // Simple state variable BPF
                        float bp = v.modePhases[w] + f * (wireNoise - v.filterState1 - qf * v.modePhases[w]);
                        float lp = v.filterState1 + f * bp;
                        v.modePhases[w] = bp;
                        v.filterState1 = lp;
                        wireOut += bp * (0.25f - w * 0.03f);  // decreasing amplitude
                    }
                    
                    // Strike transient: bright noise burst
                    float strikeNoise = DrumKit::fastRand(v.noiseState);
                    float strikeHpf = strikeNoise - v.filterState2;
                    v.filterState2 = strikeNoise;
                    float strike = strikeHpf * clickEnv * 0.8f;
                    
                    // Rimshot edge: brighter click for high velocity
                    float rimAmt = (v.velocity > 0.7f) ? (v.velocity - 0.7f) * 1.5f : 0.0f;
                    float rim = strikeHpf * clickEnv * rimAmt;
                    
                    sample = (shell * v.toneLevel * 0.6f * toneEnv
                              + wireOut * v.noiseLevel * 0.5f * noiseEnv
                              + strike * v.noiseLevel * 0.4f
                              + rim * 0.3f)
                             * ampEnv;
                    break;
                }

                // ─── CLOSED HH / OPEN HH ────────────────────────────────────
                case DrumType::CLOSED_HH:
                case DrumType::OPEN_HH: {
                    // Metallic shimmer: 6 inharmonic sine waves + filtered noise
                    float baseFreq = 400.0f * v.tuning;
                    // Inharmonic ratios for cymbal-like sound
                    float ratios[6] = {1.0f, 1.43f, 1.89f, 2.37f, 2.89f, 3.47f};
                    float amps[6] = {0.35f, 0.25f, 0.20f, 0.12f, 0.05f, 0.03f};
                    
                    float metallic = 0.0f;
                    for (int m = 0; m < 6; ++m) {
                        v.modePhases[m] += baseFreq * ratios[m] * invSr;
                        if (v.modePhases[m] >= 1.0f) v.modePhases[m] -= std::floor(v.modePhases[m]);
                        // Each partial has its own decay rate (higher = faster decay)
                        float partialDecay = std::exp(-v.envelopePhase * (2.0f + m * 1.5f));
                        metallic += std::sin(twoPi * v.modePhases[m]) * amps[m] * partialDecay;
                    }
                    
                    // Noise layer: pink noise through HPF
                    float noise = pinkNoise(v.noiseState, v.pinkB0, v.pinkB1,
                                           v.pinkB2, v.pinkB3, v.pinkB4, v.pinkB5, v.pinkB6);
                    float hpfOut = noise - v.filterState2;
                    v.filterState2 = noise;
                    
                    // Closed hat: shorter, tighter
                    // Open hat: longer, more shimmer
                    float noiseAmt = (v.type == DrumType::CLOSED_HH) ? 0.6f : 0.8f;
                    float metallicAmt = (v.type == DrumType::CLOSED_HH) ? 0.4f : 0.5f;
                    
                    sample = (metallic * metallicAmt + hpfOut * noiseAmt) * envelope * 0.7f;
                    break;
                }

                // ─── TOMS ───────────────────────────────────────────────────
                case DrumType::TOM_HIGH:
                case DrumType::TOM_MID:
                case DrumType::TOM_LOW: {
                    float freq = pitchEnvelope(v.envelopePhase, v.pitchStart, v.pitchEnd,
                                               v.pitchSweepTime, v.baseDecay);
                    
                    // Fundamental
                    v.phase += freq * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    float fundamental = std::sin(twoPi * v.phase);
                    
                    // First overtone (drumhead mode 1,1)
                    float overtoneFreq = freq * 1.59f;
                    v.phase2 += overtoneFreq * invSr;
                    if (v.phase2 >= 1.0f) v.phase2 -= std::floor(v.phase2);
                    float overtone = std::sin(twoPi * v.phase2) * 0.4f;
                    
                    // Shell resonance (lower, fixed-ish)
                    float shellFreq = v.pitchEnd * 0.55f;
                    v.subPhase += shellFreq * invSr;
                    if (v.subPhase >= 1.0f) v.subPhase -= std::floor(v.subPhase);
                    float shell = std::sin(twoPi * v.subPhase) * 0.25f;
                    
                    // Stick click
                    float clickNoise = DrumKit::fastRand(v.noiseState);
                    float clickHpf = clickNoise - v.filterState1;
                    v.filterState1 = clickNoise;
                    float click = clickHpf * std::exp(-v.envelopePhase * 45.0f) * 0.3f;
                    
                    sample = (fundamental * 0.65f + overtone * 0.25f + shell * 0.15f) * toneEnv
                           + click * v.noiseLevel;
                    sample *= ampEnv;
                    break;
                }

                // ─── CRASH ──────────────────────────────────────────────────
                case DrumType::CRASH: {
                    // Many metallic partials (8) with inharmonic ratios
                    float baseFreq = 350.0f * v.tuning;
                    float crashRatios[8] = {1.0f, 1.38f, 1.72f, 2.15f, 2.58f, 3.12f, 3.67f, 4.25f};
                    float crashAmps[8] = {0.30f, 0.22f, 0.18f, 0.14f, 0.08f, 0.04f, 0.02f, 0.02f};
                    
                    float metallic = 0.0f;
                    for (int m = 0; m < 8; ++m) {
                        v.modePhases[m] += baseFreq * crashRatios[m] * invSr;
                        if (v.modePhases[m] >= 1.0f) v.modePhases[m] -= std::floor(v.modePhases[m]);
                        // Higher partials decay much faster
                        float partialDecay = std::exp(-v.envelopePhase * (1.0f + m * 0.8f));
                        metallic += std::sin(twoPi * v.modePhases[m]) * crashAmps[m] * partialDecay;
                    }
                    
                    // Noise shimmer: pink noise through BPF
                    float noise = pinkNoise(v.noiseState, v.pinkB0, v.pinkB1,
                                           v.pinkB2, v.pinkB3, v.pinkB4, v.pinkB5, v.pinkB6);
                    float bpfF = 2.0f * std::sin(pi * 4000.0f * invSr);
                    bpfF = std::min(bpfF, 1.95f);
                    float bpfQf = 1.0f - std::clamp(1.0f / 6.0f, 0.01f, 0.99f);
                    float bp = v.filterState1 + bpfF * (noise - v.filterState2 - bpfQf * v.filterState1);
                    float lp = v.filterState2 + bpfF * v.filterState1;
                    v.filterState1 = bp;
                    v.filterState2 = lp;
                    
                    // Bell attack: very bright initial transient
                    float bellEnv = std::exp(-v.envelopePhase * 8.0f);
                    float bellNoise = DrumKit::fastRand(v.noiseState);
                    float bell = bellNoise * bellEnv * 0.2f;
                    
                    sample = (metallic * 0.7f + bp * 0.4f + bell * 0.3f) * ampEnv;
                    break;
                }

                // ─── RIDE ───────────────────────────────────────────────────
                case DrumType::RIDE: {
                    // Bell ping: fundamental + inharmonic overtones
                    float pingFreq = v.pitchStart;
                    v.phase += pingFreq * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    float ping = std::sin(twoPi * v.phase);
                    
                    // Overtones
                    float ot1 = std::sin(twoPi * (v.phase * 2.71f - std::floor(v.phase * 2.71f))) * 0.20f;
                    float ot2 = std::sin(twoPi * (v.phase * 4.33f - std::floor(v.phase * 4.33f))) * 0.12f;
                    float ot3 = std::sin(twoPi * (v.phase * 5.89f - std::floor(v.phase * 5.89f))) * 0.06f;
                    ping += ot1 + ot2 + ot3;
                    
                    // Shimmer body: pink noise through tight BPF
                    float noise = pinkNoise(v.noiseState, v.pinkB0, v.pinkB1,
                                           v.pinkB2, v.pinkB3, v.pinkB4, v.pinkB5, v.pinkB6);
                    float bpfF = 2.0f * std::sin(pi * 4500.0f * invSr);
                    bpfF = std::min(bpfF, 1.95f);
                    float bpfQf = 1.0f - std::clamp(1.0f / 10.0f, 0.01f, 0.99f);
                    float bp = v.filterState1 + bpfF * (noise - v.filterState2 - bpfQf * v.filterState1);
                    float lp = v.filterState2 + bpfF * v.filterState1;
                    v.filterState1 = bp;
                    v.filterState2 = lp;
                    
                    sample = (bp * 0.6f + ping * v.toneLevel * 0.35f) * ampEnv;
                    break;
                }

                // ─── CLAP ───────────────────────────────────────────────────
                case DrumType::CLAP: {
                    // 4-pulse burst with room ambience
                    float burstLen = v.pitchSweepTime / v.baseDecay;
                    float rawNoise = DrumKit::fastRand(v.noiseState);
                    
                    // BPF at ~1.8kHz for body
                    float bpfF = 2.0f * std::sin(pi * 1800.0f * invSr);
                    bpfF = std::min(bpfF, 1.95f);
                    float bpfQf = 1.0f - std::clamp(1.0f / 3.0f, 0.01f, 0.99f);
                    float bp = v.filterState1 + bpfF * (rawNoise - v.filterState2 - bpfQf * v.filterState1);
                    float lp = v.filterState2 + bpfF * v.filterState1;
                    v.filterState1 = bp;
                    v.filterState2 = lp;
                    
                    // Room ambience: delayed/reverb-ish tail
                    float roomAmt = (v.envelopePhase > burstLen) ? 0.3f : 0.0f;
                    float room = bp * roomAmt * std::exp(-(v.envelopePhase - burstLen) * 5.0f);
                    
                    sample = (bp * 0.8f + room * 0.4f) * envelope * 0.7f;
                    break;
                }

                // ─── RIMSHOT ────────────────────────────────────────────────
                case DrumType::RIMSHOT: {
                    // Bright, woody click + noise
                    float freq = v.pitchStart;
                    v.phase += freq * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    
                    // Triangle-ish wave for woody character
                    float tri = 2.0f * std::fabs(2.0f * (v.phase - std::floor(v.phase + 0.5f))) - 0.5f;
                    
                    // HPF for brightness
                    float hpfF = 2.0f * std::sin(pi * 2000.0f * invSr);
                    hpfF = std::min(hpfF, 1.95f);
                    float hpfOut = tri - v.filterState2;
                    v.filterState2 = tri;
                    
                    // Noise burst
                    float noise = DrumKit::fastRand(v.noiseState);
                    float noiseHpf = noise - v.filterState1;
                    v.filterState1 = noise;
                    
                    sample = (hpfOut * v.toneLevel * 0.5f + noiseHpf * v.noiseLevel * 0.8f) 
                             * envelope * 1.2f;
                    break;
                }

                // ─── COWBELL ────────────────────────────────────────────────
                case DrumType::COWBELL: {
                    // Classic LP cowbell: 853Hz + 1130Hz
                    float freq1 = v.pitchStart;        // 853 Hz
                    float freq2 = freq1 + v.detune;    // 1130 Hz
                    
                    v.phase += freq1 * invSr;
                    v.phase2 += freq2 * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    if (v.phase2 >= 1.0f) v.phase2 -= std::floor(v.phase2);
                    
                    // Use triangle waves for more metallic edge than sine
                    float tri1 = 2.0f * std::fabs(2.0f * (v.phase - std::floor(v.phase + 0.5f))) - 0.5f;
                    float tri2 = 2.0f * std::fabs(2.0f * (v.phase2 - std::floor(v.phase2 + 0.5f))) - 0.5f;
                    
                    float mixed = tri1 * 0.55f + tri2 * 0.45f;
                    
                    // Slight BPF for character
                    float bpfF = 2.0f * std::sin(pi * 1000.0f * invSr);
                    bpfF = std::min(bpfF, 1.95f);
                    float bpfQf = 1.0f - std::clamp(1.0f / 4.0f, 0.01f, 0.99f);
                    float bp = v.filterState1 + bpfF * (mixed - v.filterState2 - bpfQf * v.filterState1);
                    float lp = v.filterState2 + bpfF * v.filterState1;
                    v.filterState1 = bp;
                    v.filterState2 = lp;
                    
                    sample = bp * envelope * 0.9f;
                    break;
                }

                // ─── SHAKER ─────────────────────────────────────────────────
                case DrumType::SHAKER: {
                    float noise = pinkNoise(v.noiseState, v.pinkB0, v.pinkB1,
                                           v.pinkB2, v.pinkB3, v.pinkB4, v.pinkB5, v.pinkB6);
                    // HPF for shaker character
                    float hpfOut = noise - v.filterState2;
                    v.filterState2 = noise;
                    
                    // Amplitude modulation for "shaking" feel
                    float shakeMod = 0.7f + 0.3f * std::sin(v.envelopePhase * 80.0f);
                    
                    sample = hpfOut * envelope * shakeMod * v.velocity * 0.8f;
                    break;
                }

                // ─── CONGAS ─────────────────────────────────────────────────
                case DrumType::CONGA_HIGH:
                case DrumType::CONGA_LOW: {
                    float freq = pitchEnvelope(v.envelopePhase, v.pitchStart, v.pitchEnd,
                                               v.pitchSweepTime, v.baseDecay);
                    
                    // Main tone
                    v.phase += freq * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    float tone = std::sin(twoPi * v.phase);
                    
                    // Slap overtone (higher, faster decay)
                    float slapFreq = freq * 2.1f;
                    v.phase2 += slapFreq * invSr;
                    if (v.phase2 >= 1.0f) v.phase2 -= std::floor(v.phase2);
                    float slap = std::sin(twoPi * v.phase2) * 0.3f;
                    float slapDecay = std::exp(-v.envelopePhase * 12.0f);
                    
                    // Hand noise
                    float noise = DrumKit::fastRand(v.noiseState);
                    float handNoise = noise * std::exp(-v.envelopePhase * 25.0f) * v.noiseLevel;
                    
                    sample = (tone * 0.75f + slap * slapDecay * 0.25f) * toneEnv
                           + handNoise;
                    sample *= ampEnv;
                    break;
                }

                default:
                    break;
            }

            // ── Apply velocity, master level, choke ────────────────────────
            sample *= v.velocity * masterLevel_;

            // Choke ramp
            float chokeDecay = 0.004f;
            if (v.chokeLevel < 1.0f) {
                sample *= v.chokeLevel;
                v.chokeLevel -= invSr / chokeDecay;
                if (v.chokeLevel < 0.0f) v.chokeLevel = 0.0f;
            }

            // NaN / inf guard
            if (!std::isfinite(sample)) sample = 0.0f;

            // Soft clip
            sample = std::tanhf(sample);

            // Pan: slight stereo width for cymbals
            float pan = 0.0f;
            if (v.type == DrumType::CRASH) pan = -0.3f;
            if (v.type == DrumType::RIDE) pan = 0.3f;
            if (v.type == DrumType::OPEN_HH) pan = -0.2f;
            
            float panL = 1.0f - pan * 0.5f;
            float panR = 1.0f + pan * 0.5f;
            
            leftOut[frame]  += sample * panL;
            rightOut[frame] += sample * panR;

            // Advance envelope
            v.envelopePhase += phaseStep;
        }
    }
}

// ── Kit preset ───────────────────────────────────────────────────────────────

void DrumKit::setKitPreset(int index) {
    if (index < 0 || index >= 10) index = 0;
    currentKit_ = index;
}

// ── Master level ─────────────────────────────────────────────────────────────

void DrumKit::setLevel(float level) {
    masterLevel_ = std::max(0.0f, std::min(level, 1.0f));
}

// ── All notes off ────────────────────────────────────────────────────────────

void DrumKit::allNotesOff() {
    for (int i = 0; i < kMaxVoices; ++i) {
        voices_[i].active = false;
    }
}

} // namespace opensynth
