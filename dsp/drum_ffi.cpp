#include "drum_synth.h"

using namespace opensynth;

extern "C" {

// ── Lifecycle ─────────────────────────────────────────────────────────────────

void* drum_kit_create(double sampleRate) {
    auto* kit = new DrumKit(sampleRate);
    return static_cast<void*>(kit);
}

void drum_kit_destroy(void* ptr) {
    delete static_cast<DrumKit*>(ptr);
}

// ── MIDI ──────────────────────────────────────────────────────────────────────

void drum_kit_note_on(void* ptr, int midiNote, float velocity) {
    static_cast<DrumKit*>(ptr)->noteOn(midiNote, velocity);
}

void drum_kit_note_off(void* ptr, int midiNote) {
    static_cast<DrumKit*>(ptr)->noteOff(midiNote);
}

// ── Audio process ─────────────────────────────────────────────────────────────

void drum_kit_process(void* ptr, float* left, float* right, int numFrames) {
    static_cast<DrumKit*>(ptr)->process(left, right,
                                         static_cast<uint32_t>(numFrames));
}

// ── Kit preset ────────────────────────────────────────────────────────────────

void drum_kit_set_preset(void* ptr, int index) {
    static_cast<DrumKit*>(ptr)->setKitPreset(index);
}

// ── Master level ──────────────────────────────────────────────────────────────

void drum_kit_set_level(void* ptr, float level) {
    static_cast<DrumKit*>(ptr)->setLevel(level);
}

// ── All notes off ─────────────────────────────────────────────────────────────

void drum_kit_all_notes_off(void* ptr) {
    static_cast<DrumKit*>(ptr)->allNotesOff();
}

} // extern "C"