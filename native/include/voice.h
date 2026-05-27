#pragma once
#include <cstdint>
#include <cmath>
#include "envelope.h"
#include "oscillator.h"

namespace openamp {

class Filter;

struct Voice {
    bool active = false;
    bool sustained = false;
    int midiNote = 69;
    float velocity = 1.0f;
    float baseFreq = 440.0f;

    // Oscillator phase accumulators (one per unison voice)
    float osc1Phase[8] = {};
    float osc2Phase[8] = {};

    // Envelopes
    Envelope ampEnv;
    Envelope filterEnv;
    Envelope pitchEnv;

    // Per-voice LFO phase (for per-voice LFO mode)
    double lfo1Phase = 0.0;
    double lfo2Phase = 0.0;

    // Filter state (per-voice for now, could be global)
    float filterState1 = 0.0f;
    float filterState2 = 0.0f;

    // Pan
    float pan = 0.0f;

    void reset();
    void noteOn(int note, float vel);
    void noteOff();
};

} // namespace openamp
