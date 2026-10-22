#include "voice.h"
#include <algorithm>

namespace opensynth {

void Voice::reset() {
    active = false;
    sustained = false;
    midiNote = 69;
    velocity = 1.0f;
    baseFreq = 440.0f;
    pan = 0.0f;
    partIndex = 0;
    for (int i = 0; i < 8; i++) {
        osc1Phase[i] = 0.0f;
        osc2Phase[i] = 0.0f;
    }
    osc1State.reset();
    osc2State.reset();
    filterState.lp = 0.0f;
    filterState.bp = 0.0f;
    filterState.hp = 0.0f;
    noteAge = 0.0f;
    lfo1Phase = 0.0;
    lfo2Phase = 0.0;
    ampEnv.reset();
    filterEnv.reset();
    pitchEnv.reset();
    realism.reset();
    hasPending = false;
    pendingReleased = false;
    pendingSustained = false;
    stealFadeRemaining = 0;
    stealFadeTotal = 0;
}

void Voice::beginSteal(int note, float vel, int part, int mpeChannel, int fadeSamples) {
    // If a fade is already running, keep its position and just replace the
    // pending note so the gain ramp never jumps back up.
    if (!hasPending) {
        stealFadeTotal = std::max(1, fadeSamples);
        stealFadeRemaining = stealFadeTotal;
    }
    hasPending = true;
    pendingNote = note;
    pendingVelocity = vel;
    pendingPart = part;
    pendingMpeChannel = mpeChannel;
    pendingReleased = false;
    pendingSustained = false;
}

void Voice::noteOn(int note, float vel) {
    midiNote = note;
    velocity = std::clamp(vel, 0.0f, 1.0f);
    targetVelocity = velocity;
    velocityRampRemaining = 0;
    velocityRampPending = false;
    // MIDI note to frequency: f = 440 * 2^((note-69)/12)
    baseFreq = 440.0f * std::pow(2.0f, (note - 69) / 12.0f);
    active = true;
    sustained = false;
    hasPending = false;
    stealFadeRemaining = 0;
    noteAge = 0.0f;
    for (int i = 0; i < 8; i++) {
        osc1Phase[i] = 0.0f;
        osc2Phase[i] = 0.0f;
    }
    osc1State.reset();
    osc2State.reset();
    // Reset filter state to prevent DC thump / static when stealing voices
    filterState.lp = 0.0f;
    filterState.bp = 0.0f;
    filterState.hp = 0.0f;
    // Reset physical model so old delay-line data doesn't leak
    physicalModel.reset();
    ampEnv.noteOn();
    filterEnv.noteOn();
    pitchEnv.noteOn();
    realism.click.trigger(velocity, 15.0f, 48000.0);
}

void Voice::retrigger(int note, float vel) {
    if (!active || !ampEnv.isActive()) {
        noteOn(note, vel);
        return;
    }
    midiNote = note;
    // Ramp to the new velocity (about 3 ms) instead of stepping the level.
    targetVelocity = std::clamp(vel, 0.0f, 1.0f);
    velocityRampPending = true;
    baseFreq = 440.0f * std::pow(2.0f, (note - 69) / 12.0f);
    sustained = false;
    hasPending = false;
    stealFadeRemaining = 0;
    noteAge = 0.0f;
    // Physical models are re-excited by the engine; clear the old delay line
    // as noteOn() does so their behaviour is unchanged.
    physicalModel.reset();
    ampEnv.retrigger();
    filterEnv.retrigger();
    pitchEnv.retrigger();
    realism.click.trigger(targetVelocity, 15.0f, 48000.0);
}

void Voice::noteOff() {
    sustained = false;
    ampEnv.noteOff();
    filterEnv.noteOff();
    pitchEnv.noteOff();
}

} // namespace opensynth
