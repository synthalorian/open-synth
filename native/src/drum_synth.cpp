#include "drum_synth.h"
#include "drum_kit_mapping.h"
#include <cmath>
#include <cstring>
#include <algorithm>

namespace openamp {

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

// ── Construction ──────────────────────────────────────────────────────────────

DrumKit::DrumKit(double sampleRate)
    : sampleRate_(sampleRate)
{
    // Zero all voices
    for (int i = 0; i < kMaxVoices; ++i) {
        voices_[i].active = false;
    }
    // Initialize kit presets
    initDrumKitPresets(kits_);
    // Default to kit 0
    setKitPreset(0);
}

// ── Voice management ─────────────────────────────────────────────────────────

int DrumKit::findFreeVoice() {
    // Find an inactive voice, or steal the oldest one
    for (int i = 0; i < kMaxVoices; ++i) {
        if (!voices_[i].active) return i;
    }
    // Steal voice 0 (simplest policy)
    return 0;
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
    v.burstTimer = 0.0f;
    v.burstCount = 0;
    v.filterState1 = 0.0f;
    v.filterState2 = 0.0f;

    // Initialize noise seed from note+velocity for variation
    float nseed = static_cast<float>(note * 127 + static_cast<int>(velocity * 1000.0f));
    v.noiseState = (nseed != 0.0f) ? nseed : 1.0f;

    v.tuning = cfg.tuning;
    float tuning = cfg.tuning;
    float decay  = (cfg.decay >= 0.0f) ? cfg.decay : -1.0f;  // -1 = use default

    switch (type) {
        case DrumType::KICK:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.3f;
            v.pitchStart = 200.0f * tuning;
            v.pitchEnd   = 50.0f * tuning;
            v.pitchSweepTime = 0.03f;
            v.noiseLevel = 0.3f;
            v.toneLevel  = 1.0f;
            break;

        case DrumType::SNARE:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.3f;
            v.toneLevel  = cfg.toneMix;           // triangle tone amount
            v.noiseLevel = 1.0f - cfg.toneMix;     // noise amount
            v.pitchStart = 200.0f * tuning;
            v.pitchEnd   = 180.0f * tuning;
            v.pitchSweepTime = 0.15f;
            break;

        case DrumType::CLOSED_HH:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.03f;
            v.noiseLevel = 1.0f;
            v.toneLevel  = 0.0f;
            break;

        case DrumType::OPEN_HH:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.3f;
            v.noiseLevel = 1.0f;
            v.toneLevel  = 0.0f;
            break;

        case DrumType::TOM_HIGH:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.2f;
            v.pitchStart = 300.0f * tuning;
            v.pitchEnd   = 150.0f * tuning;
            v.pitchSweepTime = 0.04f;
            v.noiseLevel = 0.05f;
            v.toneLevel  = 1.0f;
            break;

        case DrumType::TOM_MID:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.2f;
            v.pitchStart = 220.0f * tuning;
            v.pitchEnd   = 110.0f * tuning;
            v.pitchSweepTime = 0.05f;
            v.noiseLevel = 0.05f;
            v.toneLevel  = 1.0f;
            break;

        case DrumType::TOM_LOW:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.2f;
            v.pitchStart = 160.0f * tuning;
            v.pitchEnd   = 80.0f * tuning;
            v.pitchSweepTime = 0.06f;
            v.noiseLevel = 0.05f;
            v.toneLevel  = 1.0f;
            break;

        case DrumType::CRASH:
            v.baseDecay = (decay >= 0.0f) ? decay : 2.0f;
            v.noiseLevel = 1.0f;
            v.toneLevel  = 0.0f;
            break;

        case DrumType::RIDE:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.8f;
            v.noiseLevel = 1.0f;
            v.toneLevel  = cfg.toneMix;  // undertone level
            v.pitchStart = 800.0f * tuning;
            v.pitchEnd   = 800.0f * tuning;
            v.pitchSweepTime = 0.0f;
            break;

        case DrumType::CLAP:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.2f;
            v.noiseLevel = 1.0f;
            v.toneLevel  = 0.0f;
            v.burstTimer = 0.0f;
            v.burstCount = 0;
            v.pitchSweepTime = 0.03f;  // burst window
            break;

        case DrumType::RIMSHOT:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.02f;
            v.pitchStart = 1000.0f * tuning;
            v.pitchEnd   = 1000.0f * tuning;
            v.pitchSweepTime = 0.0f;
            v.toneLevel  = 1.0f;
            v.noiseLevel = 0.0f;
            break;

        case DrumType::COWBELL:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.15f;
            v.pitchStart = 800.0f * tuning;
            v.pitchEnd   = 800.0f * tuning;
            v.pitchSweepTime = 0.0f;
            v.toneLevel  = 1.0f;
            v.noiseLevel = 0.0f;
            v.detune     = 12.0f * tuning;  // 12 Hz default detune
            break;

        case DrumType::SHAKER:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.08f;
            v.noiseLevel = 1.0f;
            v.toneLevel  = 0.0f;
            v.velocity *= 0.4f;
            break;

        case DrumType::CONGA_HIGH:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.2f;
            v.pitchStart = 420.0f * tuning;
            v.pitchEnd   = 370.0f * tuning;
            v.pitchSweepTime = 0.06f;
            v.toneLevel  = 1.0f;
            v.noiseLevel = 0.02f;
            break;

        case DrumType::CONGA_LOW:
            v.baseDecay = (decay >= 0.0f) ? decay : 0.2f;
            v.pitchStart = 260.0f * tuning;
            v.pitchEnd   = 220.0f * tuning;
            v.pitchSweepTime = 0.06f;
            v.toneLevel  = 1.0f;
            v.noiseLevel = 0.02f;
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

    // ── Hi-hat choke: triggering closed HH chokes any open HH ──────────
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

    // For hi-hat — choke the open HH when closed HH note-off happens
    // (or choke any note-off on open HH directly)
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
    // Zero the output buffers at the start
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
            // ── Compute envelope ──────────────────────────────────────────
            float decaySamples = v.baseDecay * static_cast<float>(sampleRate_);
            if (decaySamples < 1.0f) decaySamples = 1.0f;
            float phaseStep = invSr / v.baseDecay;  // fraction per sample

            float envelope = 0.0f;
            if (v.type == DrumType::CLAP) {
                // Clap uses burst envelope, not simple exponential
                float burstLen = v.pitchSweepTime / v.baseDecay; // normalized burst window
                if (v.envelopePhase < burstLen) {
                    // 3 rapid hits
                    float burstPhase = v.envelopePhase / burstLen;  // 0..1 over burst
                    // Three gaussian-like peaks
                    float hit1 = std::exp(-std::pow((burstPhase - 0.1f) / 0.05f, 2.0f));
                    float hit2 = std::exp(-std::pow((burstPhase - 0.35f) / 0.05f, 2.0f));
                    float hit3 = std::exp(-std::pow((burstPhase - 0.6f) / 0.05f, 2.0f));
                    envelope = (hit1 + hit2 * 0.7f + hit3 * 0.5f) * 1.2f;
                } else {
                    // Tail decay
                    float tailPhase = (v.envelopePhase - burstLen) / (1.0f - burstLen);
                    envelope = std::exp(-tailPhase * 8.0f);
                }
            } else if (v.type == DrumType::KICK) {
                envelope = std::exp(-v.envelopePhase * 4.0f);
            } else {
                envelope = std::exp(-v.envelopePhase * 5.0f);
            }

            // Check if done
            if (v.envelopePhase >= 1.0f || envelope < 0.0001f) {
                v.active = false;
                break;
            }

            // ── Choke ramp ──────────────────────────────────────────────
            if (v.chokeLevel <= 0.0f) {
                v.active = false;
                break;
            }

            float sample = 0.0f;

            // ── Per-type synthesis ──────────────────────────────────────
            switch (v.type) {

                // ─── KICK ───────────────────────────────────────────────
                case DrumType::KICK: {
                    float pitchFrac = (v.pitchSweepTime > 0.0f)
                        ? std::fmin(v.envelopePhase / (v.pitchSweepTime / v.baseDecay), 1.0f)
                        : 0.0f;
                    float freq = v.pitchStart + (v.pitchEnd - v.pitchStart) * pitchFrac;
                    v.phase += freq * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    float tone = std::sin(twoPi * v.phase);

                    // Body resonance: slightly detuned lower sine
                    float bodyFreq = v.pitchEnd * 0.65f;
                    v.phase2 += bodyFreq * invSr;
                    if (v.phase2 >= 1.0f) v.phase2 -= std::floor(v.phase2);
                    float body = std::sin(twoPi * v.phase2);

                    // Click: noise burst for beater impact
                    float clickEnv = std::exp(-v.envelopePhase * 40.0f);
                    float click = fastRand(v.noiseState) * 0.4f * clickEnv;

                    // Sub/boom: very low sine tracking the pitch sweep
                    float subPhase = v.phase * 0.35f;
                    subPhase = subPhase - std::floor(subPhase);
                    float sub = std::sin(twoPi * subPhase) * 0.5f;

                    sample = (tone + body * 0.6f + sub * 0.5f) * v.toneLevel * envelope
                           + click * v.noiseLevel;
                    break;
                }

                // ─── SNARE ──────────────────────────────────────────────
                case DrumType::SNARE: {
                    // Shell tone: slightly detuned sine for drum body
                    float shellFreq = 180.0f * v.tuning;
                    v.phase2 += shellFreq * invSr;
                    if (v.phase2 >= 1.0f) v.phase2 -= std::floor(v.phase2);
                    float shell = std::sin(twoPi * v.phase2);

                    // Snare wires: bright rattle using BPF'd noise
                    float rawNoise = fastRand(v.noiseState);
                    float hpfOut = rawNoise - v.filterState2;
                    v.filterState2 = rawNoise;
                    float wireFreq = 1500.0f;
                    float wireQ = 0.92f;
                    float wireF = 2.0f * std::sin(M_PI * wireFreq * invSr);
                    wireF = std::min(wireF, 1.95f);
                    v.filterState1 = v.filterState1 + wireF * (hpfOut - v.filterState1 * (1.0f - wireQ));
                    float wireBuzz = v.filterState1;

                    // Strike transient: fast noise burst at onset
                    float transientEnv = std::exp(-v.envelopePhase * 35.0f);
                    float transient = fastRand(v.noiseState) * transientEnv * 0.6f;

                    sample = (shell * v.toneLevel * 0.7f
                              + wireBuzz * v.noiseLevel * 0.5f
                              + transient * v.noiseLevel)
                             * envelope;
                    break;
                }

                // ─── CLOSED HH ──────────────────────────────────────────
                case DrumType::CLOSED_HH: {
                    float rawNoise = fastRand(v.noiseState);
                    // Simple HPF: differentiator
                    float hpfOut = rawNoise - v.filterState2;
                    v.filterState2 = rawNoise;
                    sample = hpfOut * envelope * 0.5f;
                    break;
                }

                // ─── OPEN HH ────────────────────────────────────────────
                case DrumType::OPEN_HH: {
                    float rawNoise = fastRand(v.noiseState);
                    float hpfOut = rawNoise - v.filterState2;
                    v.filterState2 = rawNoise;
                    sample = hpfOut * envelope * 0.5f;
                    break;
                }

                // ─── TOM HIGH ───────────────────────────────────────────
                case DrumType::TOM_HIGH: {
                    float pitchFrac = (v.pitchSweepTime > 0.0f)
                        ? std::fmin(v.envelopePhase / (v.pitchSweepTime / v.baseDecay), 1.0f)
                        : 0.0f;
                    float freq = v.pitchStart + (v.pitchEnd - v.pitchStart) * pitchFrac;
                    v.phase += freq * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    float tone = std::sin(twoPi * v.phase);

                    // Optional noise click
                    float noise = fastRand(v.noiseState) * v.noiseLevel
                                  * std::exp(-v.envelopePhase * 50.0f);

                    sample = (tone + noise) * envelope;
                    break;
                }

                // ─── TOM MID ────────────────────────────────────────────
                case DrumType::TOM_MID: {
                    float pitchFrac = (v.pitchSweepTime > 0.0f)
                        ? std::fmin(v.envelopePhase / (v.pitchSweepTime / v.baseDecay), 1.0f)
                        : 0.0f;
                    float freq = v.pitchStart + (v.pitchEnd - v.pitchStart) * pitchFrac;
                    v.phase += freq * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    float tone = std::sin(twoPi * v.phase);
                    float noise = fastRand(v.noiseState) * v.noiseLevel
                                  * std::exp(-v.envelopePhase * 50.0f);
                    sample = (tone + noise) * envelope;
                    break;
                }

                // ─── TOM LOW ────────────────────────────────────────────
                case DrumType::TOM_LOW: {
                    float pitchFrac = (v.pitchSweepTime > 0.0f)
                        ? std::fmin(v.envelopePhase / (v.pitchSweepTime / v.baseDecay), 1.0f)
                        : 0.0f;
                    float freq = v.pitchStart + (v.pitchEnd - v.pitchStart) * pitchFrac;
                    v.phase += freq * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    float tone = std::sin(twoPi * v.phase);
                    float noise = fastRand(v.noiseState) * v.noiseLevel
                                  * std::exp(-v.envelopePhase * 50.0f);
                    sample = (tone + noise) * envelope;
                    break;
                }

                // ─── CRASH ──────────────────────────────────────────────
                case DrumType::CRASH: {
                    float rawNoise = fastRand(v.noiseState);

                    // Proper BPF on noise at ~3.5kHz for shimmer body
                    float bpfCut = 3500.0f;
                    float bpfQ = 4.0f;
                    float bpfF = 2.0f * std::sin(pi * bpfCut * invSr);
                    bpfF = std::min(bpfF, 1.95f);
                    float bpfQf = 1.0f - std::clamp(1.0f / bpfQ, 0.01f, 0.99f);
                    v.filterState1 = v.filterState1 + bpfF * (rawNoise - v.filterState2 - bpfQf * v.filterState1);
                    v.filterState2 = v.filterState2 + bpfF * v.filterState1;
                    float bpfOut = v.filterState1;

                    // Bell-like attack at ~12kHz using phase2 (avoids aliasing)
                    float bellEnv = std::exp(-v.envelopePhase * 12.0f);
                    float bell = std::sin(twoPi * v.phase2) * bellEnv * 0.4f;
                    v.phase2 += 12000.0f * invSr;
                    if (v.phase2 >= 1.0f) v.phase2 -= std::floor(v.phase2);

                    sample = (bpfOut * 0.8f + bell * 0.3f) * envelope;
                    break;
                }

                // ─── RIDE ───────────────────────────────────────────────
                case DrumType::RIDE: {
                    float rawNoise = fastRand(v.noiseState);

                    // Proper BPF at ~4kHz for shimmer body
                    float bpfCut = 4000.0f;
                    float bpfQ = 8.0f;
                    float bpfF = 2.0f * std::sin(pi * bpfCut * invSr);
                    bpfF = std::min(bpfF, 1.95f);
                    float bpfQf = 1.0f - std::clamp(1.0f / bpfQ, 0.01f, 0.99f);
                    v.filterState1 = v.filterState1 + bpfF * (rawNoise - v.filterState2 - bpfQf * v.filterState1);
                    v.filterState2 = v.filterState2 + bpfF * v.filterState1;
                    float bpfOut = v.filterState1;

                    // Bell-like ping at ~800Hz + inharmonic overtones
                    float ping = 0.0f;
                    if (v.toneLevel > 0.0f) {
                        v.phase2 += v.pitchStart * invSr;
                        if (v.phase2 >= 1.0f) v.phase2 -= std::floor(v.phase2);
                        ping = std::sin(twoPi * v.phase2);
                        float bell1 = std::sin(twoPi * (v.phase2 * 2.71f - std::floor(v.phase2 * 2.71f))) * 0.25f;
                        float bell2 = std::sin(twoPi * (v.phase2 * 4.33f - std::floor(v.phase2 * 4.33f))) * 0.15f;
                        ping += bell1 + bell2;
                    }

                    sample = (bpfOut * 0.7f + ping * v.toneLevel * 0.4f) * envelope;
                    break;
                }

                // ─── CLAP ───────────────────────────────────────────────
                case DrumType::CLAP: {
                    float rawNoise = fastRand(v.noiseState);

                    // BPF at ~2kHz
                    float bpfCut = 2000.0f;
                    float bpfCoeff = 1.0f - (bpfCut * invSr * twoPi / 4.0f);
                    if (bpfCoeff < 0.0f) bpfCoeff = 0.0f;
                    if (bpfCoeff > 0.999f) bpfCoeff = 0.999f;
                    float bpfOut = bpfCoeff * v.filterState1
                                   + (1.0f - bpfCoeff) * (rawNoise - v.filterState2);
                    v.filterState2 = rawNoise;
                    v.filterState1 = bpfOut;

                    sample = bpfOut * envelope * 0.6f;
                    break;
                }

                // ─── RIMSHOT ────────────────────────────────────────────
                case DrumType::RIMSHOT: {
                    // Triangle wave through HPF
                    float freq = v.pitchStart;
                    v.phase += freq * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    float tri = 2.0f * std::fabs(2.0f * (v.phase
                                 - std::floor(v.phase + 0.5f))) - 0.5f;

                    // Simple HPF
                    float hpfCoeff = 1.0f - (freq * 2.0f * invSr * twoPi);
                    if (hpfCoeff < 0.0f) hpfCoeff = 0.0f;
                    if (hpfCoeff > 0.999f) hpfCoeff = 0.999f;
                    float hpfOut = hpfCoeff * v.filterState1
                                   + hpfCoeff * (tri - v.filterState2);
                    v.filterState2 = tri;
                    v.filterState1 = hpfOut;

                    sample = hpfOut * envelope;
                    break;
                }

                // ─── COWBELL ────────────────────────────────────────────
                case DrumType::COWBELL: {
                    float freq1 = v.pitchStart;
                    float freq2 = freq1 + v.detune;

                    // Square wave 1
                    v.phase += freq1 * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    float sq1 = (v.phase < 0.5f) ? 1.0f : -1.0f;

                    // Square wave 2
                    v.phase2 += freq2 * invSr;
                    if (v.phase2 >= 1.0f) v.phase2 -= std::floor(v.phase2);
                    float sq2 = (v.phase2 < 0.5f) ? 1.0f : -1.0f;

                    float mixed = (sq1 + sq2) * 0.5f;

                    // BPF at ~3kHz
                    float bpfCut = 3000.0f;
                    float bpfCoeff = 1.0f - (bpfCut * invSr * twoPi / 6.0f);
                    if (bpfCoeff < 0.0f) bpfCoeff = 0.0f;
                    if (bpfCoeff > 0.999f) bpfCoeff = 0.999f;
                    float bpfOut = bpfCoeff * v.filterState1
                                   + (1.0f - bpfCoeff) * (mixed - v.filterState2);
                    v.filterState2 = mixed;
                    v.filterState1 = bpfOut;

                    sample = bpfOut * envelope;
                    break;
                }

                // ─── SHAKER ─────────────────────────────────────────────
                case DrumType::SHAKER: {
                    float rawNoise = fastRand(v.noiseState);
                    float hpfOut = rawNoise - v.filterState2;
                    v.filterState2 = rawNoise;
                    sample = hpfOut * envelope * v.velocity;
                    break;
                }

                // ─── CONGA HIGH ─────────────────────────────────────────
                case DrumType::CONGA_HIGH: {
                    float pitchFrac = (v.pitchSweepTime > 0.0f)
                        ? std::fmin(v.envelopePhase / (v.pitchSweepTime / v.baseDecay), 1.0f)
                        : 0.0f;
                    float freq = v.pitchStart + (v.pitchEnd - v.pitchStart) * pitchFrac;
                    v.phase += freq * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    float tone = std::sin(twoPi * v.phase);

                    float noise = fastRand(v.noiseState) * v.noiseLevel
                                  * std::exp(-v.envelopePhase * 30.0f);
                    sample = (tone + noise) * envelope;
                    break;
                }

                // ─── CONGA LOW ──────────────────────────────────────────
                case DrumType::CONGA_LOW: {
                    float pitchFrac = (v.pitchSweepTime > 0.0f)
                        ? std::fmin(v.envelopePhase / (v.pitchSweepTime / v.baseDecay), 1.0f)
                        : 0.0f;
                    float freq = v.pitchStart + (v.pitchEnd - v.pitchStart) * pitchFrac;
                    v.phase += freq * invSr;
                    if (v.phase >= 1.0f) v.phase -= std::floor(v.phase);
                    float tone = std::sin(twoPi * v.phase);

                    float noise = fastRand(v.noiseState) * v.noiseLevel
                                  * std::exp(-v.envelopePhase * 30.0f);
                    sample = (tone + noise) * envelope;
                    break;
                }

                default:
                    break;
            }

            // ── Apply velocity, master level, choke ────────────────────
            sample *= v.velocity * masterLevel_;

            // ── Choke ramp (linear) ────────────────────────────────────
            float chokeDecay = 0.005f;  // 5ms choke ramp
            if (v.chokeLevel < 1.0f) {
                sample *= v.chokeLevel;
                v.chokeLevel -= invSr / chokeDecay;
                if (v.chokeLevel < 0.0f) v.chokeLevel = 0.0f;
            }

            // ── NaN / inf guard ────────────────────────────────────────
            if (!std::isfinite(sample)) sample = 0.0f;

            // ── Soft clip ──────────────────────────────────────────────
            sample = std::tanhf(sample);

            // ── Mix into output buffers ────────────────────────────────
            leftOut[frame]  += sample;
            rightOut[frame] += sample;

            // ── Advance envelope ───────────────────────────────────────
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

} // namespace openamp