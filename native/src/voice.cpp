#include "voice.h"
#include <algorithm>

namespace openamp {

void Voice::reset() {
    active = false;
    sustained = false;
    midiNote = 69;
    velocity = 1.0f;
    baseFreq = 440.0f;
    pan = 0.0f;
    for (int i = 0; i < 8; i++) {
        osc1Phase[i] = 0.0f;
        osc2Phase[i] = 0.0f;
    }
    filterState.lp = 0.0f;
    filterState.bp = 0.0f;
    filterState.hp = 0.0f;
    noteAge = 0.0f;
    lfo1Phase = 0.0;
    lfo2Phase = 0.0;
    ampEnv.reset();
    filterEnv.reset();
    pitchEnv.reset();
}

void Voice::noteOn(int note, float vel) {
    midiNote = note;
    velocity = std::clamp(vel, 0.0f, 1.0f);
    // MIDI note to frequency: f = 440 * 2^((note-69)/12)
    baseFreq = 440.0f * std::pow(2.0f, (note - 69) / 12.0f);
    active = true;
    sustained = false;
    noteAge = 0.0f;
    for (int i = 0; i < 8; i++) {
        osc1Phase[i] = 0.0f;
        osc2Phase[i] = 0.0f;
    }
    ampEnv.noteOn();
    filterEnv.noteOn();
    pitchEnv.noteOn();
}

void Voice::noteOff() {
    sustained = false;
    ampEnv.noteOff();
    filterEnv.noteOff();
    pitchEnv.noteOff();
}

} // namespace openamp
