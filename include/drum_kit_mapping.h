#pragma once

struct DrumKitPreset;  // forward declaration from drum_synth.h

namespace opensynth {

/// Map a GM2 percussion MIDI note to a DrumType index (0-15).
/// Returns -1 if the note is not mapped to any drum type.
int gm2NoteToDrumType(int midiNote);

/// Return a human-readable name for a drum type index.
const char* drumTypeName(int type);

/// Populate an array of 18 DrumKitPreset structs with factory presets.
/// Called from DrumKit constructor.
void initDrumKitPresets(DrumKitPreset* kits);

} // namespace opensynth