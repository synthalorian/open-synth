#pragma once
#include "wavetable_oscillator.h"

namespace openamp {

// Returns a const pointer to a built-in wavetable by type index.
// 0 = Piano, 1 = Guitar, 2 = Choir, 3 = Brass, 4 = Strings,
// 5 = Woodwind, 6 = Organ, 7 = Bell, 8 = Synth Bass,
// 9 = Synth Lead, 10 = Pad, 11 = Electric Piano.
// Returns nullptr if type is out of range.
// The returned pointer is valid for the lifetime of the process.
const Wavetable* getBuiltinWavetable(int type);

// Get wavetable with velocity-sensitive layer selection.
// velocity: 0.0-1.0. Selects soft/medium/hard layer.
const Wavetable* getBuiltinWavetableWithVelocity(int type, float velocity);

// Total number of built-in wavetable types.
int getBuiltinWavetableCount();

// Get the display name for a wavetable type.
const char* getBuiltinWavetableName(int type);

} // namespace openamp
