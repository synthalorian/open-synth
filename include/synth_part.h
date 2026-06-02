#pragma once
#include <cstdint>
#include <cmath>
#include "oscillator.h"
#include "filter.h"
#include "lfo.h"
#include "envelope.h"

namespace openamp {

// ── Per-part synthesis configuration ─────────────────────────────────────────
//
// A SynthPart contains all the parameters for one timbre.
// The SynthEngine owns 16 of these and routes MIDI to the appropriate part.
// Voices are dynamically allocated from a global pool and tagged with partIndex.

struct SynthPart {
    // ── MIDI routing ──
    int midiChannel = 0;      // 0-15 (MIDI ch 1-16), -1 = off
    bool omni = false;        // respond to all channels

    // ── Mix ──
    float volume = 0.8f;      // 0-1
    float pan = 0.0f;         // -1..+1
    bool mute = false;
    bool solo = false;

    // ── Oscillators ──
    Oscillator osc1;
    Oscillator osc2;
    float oscMix = 0.5f;

    // ── Filter ──
    StateVariableFilter filter;

    // ── Envelopes (times in ms, levels 0-1) ──
    float ampAttack = 10.0f;
    float ampDecay = 100.0f;
    float ampSustain = 0.8f;
    float ampRelease = 200.0f;
    float ampDelay = 0.0f;
    float ampHold = 0.0f;
    int ampAttackCurve = 0;
    int ampDecayCurve = 0;
    int ampReleaseCurve = 0;

    float filterAttack = 20.0f;
    float filterDecay = 200.0f;
    float filterSustain = 0.5f;
    float filterRelease = 300.0f;
    float filterDelay = 0.0f;
    float filterHold = 0.0f;
    int filterAttackCurve = 0;
    int filterDecayCurve = 0;
    int filterReleaseCurve = 0;

    float pitchEnvAttack = 10.0f;
    float pitchEnvDecay = 100.0f;
    float pitchEnvSustain = 0.0f;
    float pitchEnvRelease = 100.0f;
    float pitchEnvAmount = 0.0f;

    // ── LFOs ──
    LFO lfo1;
    LFO lfo2;
    bool lfoPerVoice = false;

    // ── FX send ──
    float fxSend = 1.0f;      // amount to global FX bus

    // ── Instrument Realism ─────────────────────────────────────────────
    int   realismBodyType = 0;
    float realismBodyMix = 0.0f;
    float realismClickMix = 0.0f;
    float realismSympatheticMix = 0.0f;
    int   realismAttackCurve = 0;
    float realismBrightnessSens = 0.0f;

    void reset();
};

} // namespace openamp
