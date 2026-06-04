#pragma once
#include <juce_core/juce_core.h>

#include <juce_audio_processors/juce_audio_processors.h>

namespace opensynth {

// Full parameter set for a single preset.
// Mirrors the Dart SynthPreset model but uses POD types for compile-time embedding.
struct PresetData {
    // Identity
    const char* id;
    const char* name;
    const char* category;

    // Oscillator 1
    int   osc1Waveform = 0;      // 0=sine, 1=tri, 2=saw, 3=square, 4=pulse, 5=noise, 6=sub, 7=fm, 8=wavetable, 9=pmKarplus, 10=pmKarplusBright, 11=pmKarplusBass, 12=pmModalMallet, 13=pmModalVibraphone, 14=pmModalSteel
    int   osc1Octave = 0;        // -2 .. +2
    float osc1Detune = 0.0f;     // cents
    float osc1PulseWidth = 0.5f;
    float osc1Volume = 0.8f;
    int   osc1NoiseType = 0;
    int   osc1SubOscMode = 0;
    float osc1SubOscVolume = 0.0f;
    bool  osc1FmEnabled = false;
    float osc1FmAmount = 0.0f;
    int   osc1UnisonVoices = 1;
    float osc1UnisonDetune = 0.0f;
    float osc1UnisonStereo = 0.0f;
    float osc1UnisonMix = 0.0f;

    // Oscillator 2
    int   osc2Waveform = 0;
    int   osc2Octave = 0;
    float osc2Detune = 0.0f;
    float osc2PulseWidth = 0.5f;
    float osc2Volume = 0.0f;
    int   osc2NoiseType = 0;
    int   osc2SubOscMode = 0;
    float osc2SubOscVolume = 0.0f;
    bool  osc2FmEnabled = false;
    float osc2FmAmount = 0.0f;
    int   osc2UnisonVoices = 1;
    float osc2UnisonDetune = 0.0f;
    float osc2UnisonStereo = 0.0f;
    float osc2UnisonMix = 0.0f;

    float oscMix = 0.5f;

    // Filter
    int   filterType = 0;        // 0=LP, 1=HP, 2=BP, 3=Notch, 4=Comb
    float filterCutoff = 2000.0f;
    float filterResonance = 0.3f;
    float filterEnvAmount = 0.5f;
    float filterKeyTracking = 0.0f;
    float filterDrive = 0.0f;

    // Amp Envelope
    float ampAttack = 10.0f;
    float ampDecay = 200.0f;
    float ampSustain = 0.7f;
    float ampRelease = 300.0f;
    float ampDelay = 0.0f;
    float ampHold = 0.0f;
    int   ampAttackCurve = 0;
    int   ampDecayCurve = 0;
    int   ampReleaseCurve = 0;

    // Filter Envelope
    float filterAttack = 10.0f;
    float filterDecay = 200.0f;
    float filterSustain = 0.5f;
    float filterRelease = 300.0f;
    float filterDelay = 0.0f;
    float filterHold = 0.0f;
    int   filterAttackCurve = 0;
    int   filterDecayCurve = 0;
    int   filterReleaseCurve = 0;

    // Pitch Envelope
    float pitchAttack = 0.0f;
    float pitchDecay = 0.0f;
    float pitchSustain = 0.0f;
    float pitchRelease = 0.0f;
    float pitchEnvAmount = 0.0f;

    // LFO 1
    int   lfo1Waveform = 0;
    float lfo1Rate = 4.0f;
    float lfo1Depth = 0.3f;
    int   lfo1Target = 0;        // 0=none, 1=pitch, 2=filter, 3=amp
    float lfo1FadeIn = 0.0f;
    bool  lfo1TempoSync = false;
    int   lfo1TempoDivision = 4; // 1/16

    // LFO 2
    int   lfo2Waveform = 0;
    float lfo2Rate = 4.0f;
    float lfo2Depth = 0.0f;
    int   lfo2Target = 0;
    float lfo2FadeIn = 0.0f;
    bool  lfo2TempoSync = false;
    int   lfo2TempoDivision = 4;

    // Legacy FX (slot 0)
    bool  chorusEnabled = false;
    float chorusRate = 1.0f;
    float chorusDepth = 0.3f;
    float chorusMix = 0.5f;

    bool  delayEnabled = false;
    float delayTime = 400.0f;
    float delayFeedback = 0.3f;
    float delayMix = 0.3f;

    bool  reverbEnabled = false;
    float reverbSize = 0.5f;
    float reverbDamping = 0.5f;
    float reverbMix = 0.3f;

    bool  phaserEnabled = false;
    float phaserRate = 0.5f;
    float phaserDepth = 0.5f;
    float phaserFeedback = 0.3f;
    float phaserMix = 0.3f;

    bool  flangerEnabled = false;
    float flangerRate = 0.3f;
    float flangerDepth = 0.5f;
    float flangerFeedback = 0.3f;
    float flangerMix = 0.3f;

    bool  compressorEnabled = false;
    float compressorThreshold = -20.0f;
    float compressorRatio = 4.0f;
    float compressorAttack = 10.0f;
    float compressorRelease = 100.0f;
    float compressorMakeup = 0.0f;

    bool  driveEnabled = false;
    float driveAmount = 0.3f;
    int   driveType = 0;

    // Multi-slot FX (slots 1-3)
    // slot 0 = legacy (above), slots 1-3 = individual processors
    int   fxSlotType[3] = {0, 0, 0};       // 0=None, 1=Chorus, 2=Delay, 3=Reverb, ...
    bool  fxSlotEnabled[3] = {false, false, false};
    float fxSlotParam[3][4] = {};

    // Master
    float masterVolume = 0.8f;

    // Sample player mix (0 = synth only, 1 = sample only)
    float sampleMix = 0.0f;

    // Meta
    bool  isBassPreset = false;

    // ── Instrument Realism ─────────────────────────────────────────────
    // Body resonance: 0=none, 1=piano, 2=guitar, 3=violin
    int   realismBodyType = 0;
    float realismBodyMix = 0.0f;
    // Key click/hammer noise: 0-1 mix level
    float realismClickMix = 0.0f;
    // Sympathetic resonance: 0-1 mix level
    float realismSympatheticMix = 0.0f;
    // Attack curve: 0=linear, 1=exponential(piano), 2=logarithmic(organ), 3=double-exp(plucked)
    int   realismAttackCurve = 0;
    // Velocity brightness sensitivity: 0-1
    float realismBrightnessSens = 0.0f;

    // Arpeggiator (added at end to preserve preset library aggregate initializers)
    bool  arpEnabled = false;
    int   arpPattern = 0;
    float arpTempo = 120.0f;
    float arpGate = 0.5f;
    float arpSwing = 0.0f;
    int   arpOctave = 1;

    // Sample manifest ID (empty = no samples, use synthesis only)
    // Added at the very end to preserve aggregate initializer ordering
    const char* sampleManifestId = "";
};

// Parameter-applier helper.
// Given a PresetData, pushes every field into the engine via the wrapper.
class SynthEngineWrapper;
void applyPresetToEngine(const PresetData& preset, SynthEngineWrapper& engine);

// APVTS applier — updates all parameters in the value tree so the UI reflects the preset.
void applyPresetToAPVTS(const PresetData& preset, juce::AudioProcessorValueTreeState& apvts);

} // namespace opensynth
