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
    // Velocity the voice is heading to. Equal to velocity except during the
    // short ramp applied when a sounding voice is retriggered.
    float targetVelocity = 1.0f;
    float velocityStep = 0.0f;
    int velocityRampRemaining = 0;
    bool velocityRampPending = false;
    static constexpr float kRetriggerVelocityRampSec = 0.003f;

    // Advance the velocity ramp by one sample (call once per sample).
    void advanceVelocity(double sampleRate) {
        if (velocityRampPending) {
            velocityRampPending = false;
            int n = static_cast<int>(kRetriggerVelocityRampSec * sampleRate);
            if (n < 1) n = 1;
            velocityRampRemaining = n;
            velocityStep = (targetVelocity - velocity) / static_cast<float>(n);
        }
        if (velocityRampRemaining > 0) {
            if (--velocityRampRemaining == 0) velocity = targetVelocity;
            else velocity += velocityStep;
        }
    }
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
    // Re-strike a voice that is already sounding this note: envelopes
    // continue from their current level and oscillator/filter state is kept,
    // so there is no click. Falls back to noteOn() for an idle voice.
    void retrigger(int note, float vel);
    void noteOff();
};

} // namespace opensynth
