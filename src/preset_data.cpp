#include "preset_data.h"
#include "synth_engine_wrapper.h"

namespace openamp {

void applyPresetToEngine(const PresetData& p, SynthEngineWrapper& e)
{
    // Osc 1
    e.setOsc1Waveform(p.osc1Waveform);
    e.setOsc1Octave(p.osc1Octave);
    e.setOsc1Detune(p.osc1Detune);
    e.setOsc1Volume(p.osc1Volume);

    // Osc 2
    e.setOsc2Waveform(p.osc2Waveform);
    e.setOsc2Octave(p.osc2Octave);
    e.setOsc2Detune(p.osc2Detune);
    e.setOsc2Volume(p.osc2Volume);
    e.setOscMix(p.oscMix);

    // Filter
    e.setFilterCutoff(p.filterCutoff);
    e.setFilterResonance(p.filterResonance);
    e.setFilterEnvAmount(p.filterEnvAmount);
    e.setFilterDrive(p.filterDrive);

    // Amp envelope
    e.setAmpAttack(p.ampAttack);
    e.setAmpDecay(p.ampDecay);
    e.setAmpSustain(p.ampSustain);
    e.setAmpRelease(p.ampRelease);

    // Filter envelope
    e.setFilterAttack(p.filterAttack);
    e.setFilterDecay(p.filterDecay);
    e.setFilterSustain(p.filterSustain);
    e.setFilterRelease(p.filterRelease);

    // LFO 1
    e.setLfo1Rate(p.lfo1Rate);
    e.setLfo1Depth(p.lfo1Depth);

    // Master
    e.setMasterVolume(p.masterVolume);

    // FX slots
    for (int slot = 0; slot < 3; ++slot)
    {
        e.setFxEnabled(slot + 1, p.fxSlotEnabled[slot]);
        for (int param = 0; param < 4; ++param)
            e.setFxParam(slot + 1, param, p.fxSlotParam[slot][param]);
    }

    // Instrument realism
    e.setRealismBodyType(p.realismBodyType);
    e.setRealismBodyMix(p.realismBodyMix);
    e.setRealismClickMix(p.realismClickMix);
    e.setRealismSympatheticMix(p.realismSympatheticMix);
    e.setRealismAttackCurve(p.realismAttackCurve);
    e.setRealismBrightnessSens(p.realismBrightnessSens);
}

void applyPresetToAPVTS(const PresetData& p, juce::AudioProcessorValueTreeState& apvts)
{
    auto setFloat = [&](const juce::String& id, float v) {
        if (auto* param = apvts.getParameter(id))
            param->setValueNotifyingHost(param->convertTo0to1(v));
    };
    auto setInt = [&](const juce::String& id, int v) {
        if (auto* param = apvts.getParameter(id))
            param->setValueNotifyingHost(param->convertTo0to1((float)v));
    };
    auto setBool = [&](const juce::String& id, bool b) {
        if (auto* param = apvts.getParameter(id))
            param->setValueNotifyingHost(b ? 1.0f : 0.0f);
    };

    setInt("osc1Waveform", p.osc1Waveform);
    setInt("osc1Octave", p.osc1Octave);
    setFloat("osc1Detune", p.osc1Detune);
    setFloat("osc1Volume", p.osc1Volume);

    setInt("osc2Waveform", p.osc2Waveform);
    setInt("osc2Octave", p.osc2Octave);
    setFloat("osc2Detune", p.osc2Detune);
    setFloat("osc2Volume", p.osc2Volume);
    setFloat("oscMix", p.oscMix);

    setFloat("filterCutoff", p.filterCutoff);
    setFloat("filterResonance", p.filterResonance);
    setFloat("filterEnvAmt", p.filterEnvAmount);
    setFloat("filterDrive", p.filterDrive);

    setFloat("ampAttack", p.ampAttack);
    setFloat("ampDecay", p.ampDecay);
    setFloat("ampSustain", p.ampSustain);
    setFloat("ampRelease", p.ampRelease);

    setFloat("filterAttack", p.filterAttack);
    setFloat("filterDecay", p.filterDecay);
    setFloat("filterSustain", p.filterSustain);
    setFloat("filterRelease", p.filterRelease);

    setFloat("lfo1Rate", p.lfo1Rate);
    setFloat("lfo1Depth", p.lfo1Depth);

    setFloat("masterVolume", p.masterVolume);

    setBool("fx1Enabled", p.fxSlotEnabled[0]);
    setInt("fx1Type", p.fxSlotType[0]);
    setFloat("fx1Param0", p.fxSlotParam[0][0]);
    setFloat("fx1Param1", p.fxSlotParam[0][1]);
    setFloat("fx1Param2", p.fxSlotParam[0][2]);
    setFloat("fx1Param3", p.fxSlotParam[0][3]);

    setBool("fx2Enabled", p.fxSlotEnabled[1]);
    setInt("fx2Type", p.fxSlotType[1]);
    setFloat("fx2Param0", p.fxSlotParam[1][0]);
    setFloat("fx2Param1", p.fxSlotParam[1][1]);
    setFloat("fx2Param2", p.fxSlotParam[1][2]);
    setFloat("fx2Param3", p.fxSlotParam[1][3]);

    setBool("fx3Enabled", p.fxSlotEnabled[2]);
    setInt("fx3Type", p.fxSlotType[2]);
    setFloat("fx3Param0", p.fxSlotParam[2][0]);
    setFloat("fx3Param1", p.fxSlotParam[2][1]);
    setFloat("fx3Param2", p.fxSlotParam[2][2]);
    setFloat("fx3Param3", p.fxSlotParam[2][3]);
}

} // namespace openamp
