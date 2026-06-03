#pragma once
#include <cstdint>
#include <cmath>
#include "envelope.h"
#include "oscillator.h"
#include "filter.h"
#include "physical_model.h"
#include "instrument_realism.h"

namespace opensynth {

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

    // Per-voice filter state (prevents NaN poisoning across voices)
    FilterState filterState;

    // Per-voice note age (seconds since note-on, for hammer transients etc.)
    float noteAge = 0.0f;

    // Pan
    float pan = 0.0f;

    // Part index for multitimbral routing (0-15)
    int partIndex = 0;

    // Physical modeling voice (for Karplus-Strong, modal synthesis)
    PhysicalModelVoice physicalModel;

    // Instrument realism (body resonance, key click, etc.)
    InstrumentRealism realism;

    void reset();
    void noteOn(int note, float vel);
    void noteOff();
};

} // namespace opensynth
