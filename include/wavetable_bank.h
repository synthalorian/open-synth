#pragma once
#include "wavetable_oscillator.h"

namespace opensynth {

// ── Expanded Wavetable Types for Juno-Di Coverage ────────────────────────────
//
// 0  = Piano           20 = Flute           40 = Synth Lead 2
// 1  = Guitar          21 = Clarinet        41 = Synth Bass 2
// 2  = Choir           22 = Oboe            42 = Synth Pad 2
// 3  = Brass           23 = Bassoon         43 = Synth FX
// 4  = Strings         24 = Recorder        44 = Ethnic 1 (Sitar)
// 5  = Woodwind        25 = Pan Flute       45 = Ethnic 2 (Shamisen)
// 6  = Organ           26 = Shakuhachi      46 = Ethnic 3 (Koto)
// 7  = Bell            27 = Whistle         47 = Percussive 1 (Timpani)
// 8  = Synth Bass      28 = Ocarina         48 = Percussive 2 (Agogo)
// 9  = Synth Lead      29 = Square Lead     49 = Sound FX
// 10 = Synth Pad       30 = Saw Lead        50 = Harp
// 11 = Electric Piano  31 = Calliope        51 = Accordion
// 12 = Vibraphone      32 = Chiff Lead      52 = Harmonica
// 13 = Marimba         33 = Charang         53 = Banjo
// 14 = Xylophone       34 = Voice Lead      54 = Shamisen
// 15 = Tubular Bells   35 = Fifth Lead      55 = Koto
// 16 = Dulcimer        36 = Bass + Lead     56 = Kalimba
// 17 = Hammond Organ   37 = New Age Pad     57 = Bagpipe
// 18 = Church Organ    38 = Warm Pad        58 = Fiddle
// 19 = Reed Organ      39 = Polysynth Pad   59 = Shanai
//
// Total: 60 wavetable types covering all GM2 / Juno-Di categories.

static constexpr int kNumWavetableTypes = 60;

const Wavetable* getBuiltinWavetable(int type);
const Wavetable* getBuiltinWavetableWithVelocity(int type, float velocity);
int getBuiltinWavetableCount();
const char* getBuiltinWavetableName(int type);

} // namespace opensynth
