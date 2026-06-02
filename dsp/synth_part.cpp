#include "synth_part.h"

namespace openamp {

void SynthPart::reset() {
    midiChannel = 0;
    omni = false;
    volume = 0.8f;
    pan = 0.0f;
    mute = false;
    solo = false;

    oscMix = 0.5f;

    ampAttack = 10.0f;
    ampDecay = 100.0f;
    ampSustain = 0.8f;
    ampRelease = 200.0f;
    ampDelay = 0.0f;
    ampHold = 0.0f;
    ampAttackCurve = 0;
    ampDecayCurve = 0;
    ampReleaseCurve = 0;

    filterAttack = 20.0f;
    filterDecay = 200.0f;
    filterSustain = 0.5f;
    filterRelease = 300.0f;
    filterDelay = 0.0f;
    filterHold = 0.0f;
    filterAttackCurve = 0;
    filterDecayCurve = 0;
    filterReleaseCurve = 0;

    pitchEnvAttack = 10.0f;
    pitchEnvDecay = 100.0f;
    pitchEnvSustain = 0.0f;
    pitchEnvRelease = 100.0f;
    pitchEnvAmount = 0.0f;

    lfoPerVoice = false;
    fxSend = 1.0f;

    realismBodyType = 0;
    realismBodyMix = 0.0f;
    realismClickMix = 0.0f;
    realismSympatheticMix = 0.0f;
    realismAttackCurve = 0;
    realismBrightnessSens = 0.0f;
}

} // namespace openamp
