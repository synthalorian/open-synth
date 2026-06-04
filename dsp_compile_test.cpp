// Quick compile test for the 6 FX processors
#include "fx_vibrato.h"
#include "fx_auto_pan.h"
#include "fx_uni_vibe.h"
#include "fx_chorus_ensemble.h"
#include "fx_dimension_d.h"
#include "fx_tape_delay.h"

int main() {
    opensynth::VibratoProcessor vib;
    opensynth::AutoPanProcessor pan;
    opensynth::UniVibeProcessor uv;
    opensynth::ChorusEnsembleProcessor ce;
    opensynth::DimensionDProcessor dd;
    opensynth::TapeDelayProcessor td;

    float l = 0.5f, r = 0.5f;
    vib.process(l, r, 48000.0);
    pan.process(l, r, 48000.0);
    uv.process(l, r, 48000.0);
    ce.process(l, r, 48000.0);
    dd.process(l, r, 48000.0);
    td.process(l, r, 48000.0);

    return 0;
}
