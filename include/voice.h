#pragma once
#include <cstdint>
#include <cmath>
#include "envelope.h"
#include "oscillator.h"
#include "filter.h"
#include "physical_model.h"
#include "instrument_realism.h"
#include "mpe_voice.h"

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

    // Per-voice sub-oscillator phase and noise state for each oscillator
    OscVoiceState osc1State;
    OscVoiceState osc2State;

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

    // MPE per-note expression state
    MpeVoiceState mpe;

    // Monotonic note-on order, used to find the oldest voice when stealing.
    uint64_t startOrder = 0;

    // Voice stealing: the old note fades out over stealFadeTotal samples,
    // then the pending note starts. Avoids a hard reset (click) on steal.
    bool hasPending = false;
    int pendingNote = 69;
    float pendingVelocity = 1.0f;
    int pendingPart = 0;
    int pendingMpeChannel = -1;
    bool pendingReleased = false;
    bool pendingSustained = false;
    int stealFadeRemaining = 0;
    int stealFadeTotal = 0;

    void beginSteal(int note, float vel, int part, int mpeChannel, int fadeSamples);

    void reset();
    void noteOn(int note, float vel);
    void noteOff();
};

} // namespace opensynth
