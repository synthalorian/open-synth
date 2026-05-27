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
    filterState1 = 0.0f;
    filterState2 = 0.0f;
    ampEnv.reset();
    filterEnv.reset();
}

void Voice::noteOn(int note, float vel) {
    midiNote = note;
    velocity = std::clamp(vel, 0.0f, 1.0f);
    // MIDI note to frequency: f = 440 * 2^((note-69)/12)
    baseFreq = 440.0f * std::pow(2.0f, (note - 69) / 12.0f);
    active = true;
    sustained = false;
    for (int i = 0; i < 8; i++) {
        osc1Phase[i] = 0.0f;
        osc2Phase[i] = 0.0f;
    }
    ampEnv.noteOn();
    filterEnv.noteOn();
}

void Voice::noteOff() {
    sustained = false;
    ampEnv.noteOff();
    filterEnv.noteOff();
}

} // namespace openamp
