#pragma once
#include "wavetable_oscillator.h"

namespace openamp {

// Returns a const pointer to a built-in wavetable by type index.
// 0 = Piano, 1 = Guitar, 2 = Choir.
// Returns nullptr if type is out of range.
// The returned pointer is valid for the lifetime of the process.
const Wavetable* getBuiltinWavetable(int type);

} // namespace openamp
