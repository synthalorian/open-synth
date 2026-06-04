#include "fx_engine.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

// ── FX Type Descriptor Table ────────────────────────────────────────────────

FxTypeDescriptor FxProcessor::getDescriptor(int fxTypeId)
{
    FxTypeDescriptor d;
    switch (fxTypeId)
    {
    case 0: // None
        d.name = "None";
        d.numParams = 0;
        break;

    case 1: // Chorus
        d.name = "Chorus";
        d.numParams = 4;
        d.params[0] = {"Rate", 0.1f, 10.0f, 0.5f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Width", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 2: // Delay
        d.name = "Delay";
        d.numParams = 4;
        d.params[0] = {"Time", 10.0f, 2000.0f, 300.0f, "ms"};
        d.params[1] = {"Feedback", 0.0f, 0.95f, 0.3f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Tone", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 3: // Reverb
        d.name = "Reverb";
        d.numParams = 4;
        d.params[0] = {"Size", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Damping", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Width", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 4: // Phaser
        d.name = "Phaser";
        d.numParams = 4;
        d.params[0] = {"Rate", 0.1f, 10.0f, 0.5f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Feedback", 0.0f, 0.95f, 0.3f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 5: // Flanger
        d.name = "Flanger";
        d.numParams = 4;
        d.params[0] = {"Rate", 0.1f, 10.0f, 0.3f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Feedback", 0.0f, 0.95f, 0.3f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 6: // Compressor
        d.name = "Compressor";
        d.numParams = 4;
        d.params[0] = {"Threshold", -60.0f, 0.0f, -20.0f, "dB"};
        d.params[1] = {"Ratio", 1.0f, 20.0f, 3.0f, ":1"};
        d.params[2] = {"Attack", 0.1f, 100.0f, 5.0f, "ms"};
        d.params[3] = {"Release", 1.0f, 1000.0f, 100.0f, "ms"};
        break;

    case 7: // Drive
        d.name = "Drive";
        d.numParams = 4;
        d.params[0] = {"Amount", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Type", 0.0f, 2.0f, 0.0f, ""};
        d.params[2] = {"Tone", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Output", 0.0f, 1.0f, 0.8f, ""};
        break;

    case 8: // Equalizer
        d.name = "EQ";
        d.numParams = 4;
        d.params[0] = {"Low", -18.0f, 18.0f, 0.0f, "dB"};
        d.params[1] = {"Mid", -18.0f, 18.0f, 0.0f, "dB"};
        d.params[2] = {"High", -18.0f, 18.0f, 0.0f, "dB"};
        d.params[3] = {"Freq", 200.0f, 8000.0f, 1000.0f, "Hz"};
        break;

    case 9: // Limiter
        d.name = "Limiter";
        d.numParams = 4;
        d.params[0] = {"Threshold", -20.0f, 0.0f, -3.0f, "dB"};
        d.params[1] = {"Release", 1.0f, 1000.0f, 100.0f, "ms"};
        d.params[2] = {"Ceiling", -12.0f, 0.0f, -0.1f, "dB"};
        d.params[3] = {"Lookahead", 0.0f, 10.0f, 1.0f, "ms"};
        break;

    case 10: // Rotary
        d.name = "Rotary";
        d.numParams = 4;
        d.params[0] = {"Speed", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Drive", 0.0f, 1.0f, 0.0f, ""};
        break;

    case 11: // Tremolo
        d.name = "Tremolo";
        d.numParams = 4;
        d.params[0] = {"Rate", 0.1f, 20.0f, 4.0f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Wave", 0.0f, 3.0f, 0.0f, ""};
        d.params[3] = {"Phase", 0.0f, 1.0f, 0.0f, ""};
        break;

    case 12: // Auto-Wah
        d.name = "Auto-Wah";
        d.numParams = 4;
        d.params[0] = {"Rate", 0.1f, 10.0f, 2.0f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.7f, ""};
        d.params[2] = {"Resonance", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 13: // Bitcrusher
        d.name = "Bitcrusher";
        d.numParams = 4;
        d.params[0] = {"Bits", 1.0f, 16.0f, 8.0f, ""};
        d.params[1] = {"Rate", 0.01f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Fold", 0.0f, 1.0f, 0.0f, ""};
        break;

    case 14: // Ring Mod
        d.name = "Ring Mod";
        d.numParams = 4;
        d.params[0] = {"Freq", 20.0f, 2000.0f, 440.0f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Wave", 0.0f, 3.0f, 0.0f, ""};
        break;

    case 15: // Pitch Shift
        d.name = "Pitch Shift";
        d.numParams = 4;
        d.params[0] = {"Shift", -12.0f, 12.0f, 0.0f, "st"};
        d.params[1] = {"Fine", -100.0f, 100.0f, 0.0f, "ct"};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Quality", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 16: // Multi-tap Delay
        d.name = "Multi-tap";
        d.numParams = 4;
        d.params[0] = {"Time", 10.0f, 1000.0f, 250.0f, "ms"};
        d.params[1] = {"Spread", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Feedback", 0.0f, 0.95f, 0.3f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 17: // Ping-Pong Delay
        d.name = "Ping-Pong";
        d.numParams = 4;
        d.params[0] = {"Time", 10.0f, 1000.0f, 300.0f, "ms"};
        d.params[1] = {"Feedback", 0.0f, 0.95f, 0.4f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Width", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 18: // Spring Reverb
        d.name = "Spring";
        d.numParams = 4;
        d.params[0] = {"Size", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Damping", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Drive", 0.0f, 1.0f, 0.0f, ""};
        break;

    case 19: // Gated Reverb
        d.name = "Gated";
        d.numParams = 4;
        d.params[0] = {"Size", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Gate", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Attack", 0.1f, 50.0f, 1.0f, "ms"};
        break;

    case 20: // Amp Sim
        d.name = "Amp Sim";
        d.numParams = 4;
        d.params[0] = {"Gain", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Tone", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Cab", 0.0f, 3.0f, 0.0f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 21: // Stereo Widener
        d.name = "Widener";
        d.numParams = 4;
        d.params[0] = {"Width", 0.0f, 2.0f, 1.0f, ""};
        d.params[1] = {"Mono", 0.0f, 1.0f, 0.0f, ""};
        d.params[2] = {"Delay", 0.0f, 20.0f, 0.0f, "ms"};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 22: // Vocoder
        d.name = "Vocoder";
        d.numParams = 4;
        d.params[0] = {"Bands", 4.0f, 32.0f, 16.0f, ""};
        d.params[1] = {"Range", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Carrier", 0.0f, 2.0f, 0.0f, ""};
        break;

    // ── Phase 6: Juno-Di FX parity ──
    case 23: // Distortion
        d.name = "Distortion";
        d.numParams = 4;
        d.params[0] = {"Drive", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Tone", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Level", 0.0f, 1.0f, 0.8f, ""};
        d.params[3] = {"Type", 0.0f, 3.0f, 0.0f, ""};
        break;

    case 24: // Overdrive
        d.name = "Overdrive";
        d.numParams = 4;
        d.params[0] = {"Drive", 0.0f, 1.0f, 0.4f, ""};
        d.params[1] = {"Tone", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Level", 0.0f, 1.0f, 0.8f, ""};
        d.params[3] = {"Warmth", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 25: // Fuzz
        d.name = "Fuzz";
        d.numParams = 4;
        d.params[0] = {"Amount", 0.0f, 1.0f, 0.6f, ""};
        d.params[1] = {"Tone", 0.0f, 1.0f, 0.4f, ""};
        d.params[2] = {"Level", 0.0f, 1.0f, 0.7f, ""};
        d.params[3] = {"Sustain", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 26: // Tube Drive
        d.name = "Tube Drive";
        d.numParams = 4;
        d.params[0] = {"Drive", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Bias", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Tone", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Output", 0.0f, 1.0f, 0.8f, ""};
        break;

    case 27: // Resonant Filter
        d.name = "Resonant Filter";
        d.numParams = 4;
        d.params[0] = {"Cutoff", 20.0f, 20000.0f, 2000.0f, "Hz"};
        d.params[1] = {"Resonance", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Env", 0.0f, 1.0f, 0.0f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 28: // Formant Filter
        d.name = "Formant Filter";
        d.numParams = 4;
        d.params[0] = {"Vowel", 0.0f, 4.0f, 0.0f, ""};
        d.params[1] = {"Resonance", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Sweep", 0.0f, 1.0f, 0.0f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 29: // Comb Filter
        d.name = "Comb Filter";
        d.numParams = 4;
        d.params[0] = {"Freq", 20.0f, 5000.0f, 440.0f, "Hz"};
        d.params[1] = {"Feedback", 0.0f, 0.99f, 0.5f, ""};
        d.params[2] = {"Damping", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 30: // Talk Box
        d.name = "Talk Box";
        d.numParams = 4;
        d.params[0] = {"Vowel", 0.0f, 4.0f, 0.0f, ""};
        d.params[1] = {"Intensity", 0.0f, 1.0f, 0.7f, ""};
        d.params[2] = {"Tone", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 31: // Vibrato
        d.name = "Vibrato";
        d.numParams = 4;
        d.params[0] = {"Rate", 0.1f, 20.0f, 5.0f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.3f, ""};
        d.params[2] = {"Wave", 0.0f, 3.0f, 0.0f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 32: // Auto-Pan
        d.name = "Auto-Pan";
        d.numParams = 4;
        d.params[0] = {"Rate", 0.1f, 20.0f, 2.0f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.8f, ""};
        d.params[2] = {"Wave", 0.0f, 3.0f, 0.0f, ""};
        d.params[3] = {"Phase", 0.0f, 1.0f, 0.0f, ""};
        break;

    case 33: // Uni-Vibe
        d.name = "Uni-Vibe";
        d.numParams = 4;
        d.params[0] = {"Rate", 0.1f, 10.0f, 2.0f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.6f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Mode", 0.0f, 1.0f, 0.0f, ""};
        break;

    case 34: // Chorus Ensemble
        d.name = "Chorus Ensemble";
        d.numParams = 4;
        d.params[0] = {"Rate", 0.1f, 10.0f, 0.5f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Voices", 2.0f, 8.0f, 4.0f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.4f, ""};
        break;

    case 35: // Dimension D
        d.name = "Dimension D";
        d.numParams = 4;
        d.params[0] = {"Mode", 0.0f, 3.0f, 0.0f, ""};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Width", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 36: // Reverse Delay
        d.name = "Reverse Delay";
        d.numParams = 4;
        d.params[0] = {"Time", 100.0f, 2000.0f, 500.0f, "ms"};
        d.params[1] = {"Feedback", 0.0f, 0.95f, 0.3f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Tone", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 37: // Tape Delay
        d.name = "Tape Delay";
        d.numParams = 4;
        d.params[0] = {"Time", 50.0f, 1500.0f, 400.0f, "ms"};
        d.params[1] = {"Feedback", 0.0f, 0.95f, 0.4f, ""};
        d.params[2] = {"Wow", 0.0f, 1.0f, 0.1f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 38: // Analog Delay
        d.name = "Analog Delay";
        d.numParams = 4;
        d.params[0] = {"Time", 50.0f, 1000.0f, 350.0f, "ms"};
        d.params[1] = {"Feedback", 0.0f, 0.95f, 0.35f, ""};
        d.params[2] = {"Dark", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 39: // Diffusion Delay
        d.name = "Diffusion Delay";
        d.numParams = 4;
        d.params[0] = {"Time", 10.0f, 1000.0f, 250.0f, "ms"};
        d.params[1] = {"Feedback", 0.0f, 0.99f, 0.5f, ""};
        d.params[2] = {"Diffusion", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 40: // Room Reverb
        d.name = "Room Reverb";
        d.numParams = 4;
        d.params[0] = {"Size", 0.0f, 1.0f, 0.3f, ""};
        d.params[1] = {"Damping", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Width", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 41: // Hall Reverb
        d.name = "Hall Reverb";
        d.numParams = 4;
        d.params[0] = {"Size", 0.0f, 1.0f, 0.7f, ""};
        d.params[1] = {"Damping", 0.0f, 1.0f, 0.4f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Width", 0.0f, 1.0f, 0.8f, ""};
        break;

    case 42: // Plate Reverb
        d.name = "Plate Reverb";
        d.numParams = 4;
        d.params[0] = {"Size", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Damping", 0.0f, 1.0f, 0.3f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Pre-delay", 0.0f, 100.0f, 10.0f, "ms"};
        break;

    case 43: // Shimmer Reverb
        d.name = "Shimmer Reverb";
        d.numParams = 4;
        d.params[0] = {"Size", 0.0f, 1.0f, 0.6f, ""};
        d.params[1] = {"Pitch", -12.0f, 12.0f, 12.0f, "st"};
        d.params[2] = {"Feedback", 0.0f, 0.99f, 0.5f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 44: // Non-Linear Reverb
        d.name = "Non-Linear Reverb";
        d.numParams = 4;
        d.params[0] = {"Size", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Curve", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Gate", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 45: // Harmonizer
        d.name = "Harmonizer";
        d.numParams = 4;
        d.params[0] = {"Interval", -12.0f, 12.0f, 7.0f, "st"};
        d.params[1] = {"Fine", -50.0f, 50.0f, 0.0f, "ct"};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Feedback", 0.0f, 0.95f, 0.0f, ""};
        break;

    case 46: // Octaver
        d.name = "Octaver";
        d.numParams = 4;
        d.params[0] = {"Octave", -2.0f, 2.0f, -1.0f, ""};
        d.params[1] = {"Dry", 0.0f, 1.0f, 0.7f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Tone", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 47: // Detune
        d.name = "Detune";
        d.numParams = 4;
        d.params[0] = {"Amount", 0.0f, 50.0f, 10.0f, "ct"};
        d.params[1] = {"Speed", 0.0f, 1.0f, 0.1f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Stereo", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 48: // Noise Gate
        d.name = "Noise Gate";
        d.numParams = 4;
        d.params[0] = {"Threshold", -80.0f, 0.0f, -40.0f, "dB"};
        d.params[1] = {"Attack", 0.01f, 50.0f, 1.0f, "ms"};
        d.params[2] = {"Release", 1.0f, 1000.0f, 100.0f, "ms"};
        d.params[3] = {"Hold", 0.0f, 500.0f, 50.0f, "ms"};
        break;

    case 49: // De-Esser
        d.name = "De-Esser";
        d.numParams = 4;
        d.params[0] = {"Freq", 2000.0f, 16000.0f, 6000.0f, "Hz"};
        d.params[1] = {"Threshold", -40.0f, 0.0f, -20.0f, "dB"};
        d.params[2] = {"Ratio", 1.0f, 20.0f, 5.0f, ":1"};
        d.params[3] = {"Mix", 0.0f, 1.0f, 1.0f, ""};
        break;

    case 50: // Transient Shaper
        d.name = "Transient Shaper";
        d.numParams = 4;
        d.params[0] = {"Attack", -1.0f, 1.0f, 0.0f, ""};
        d.params[1] = {"Sustain", -1.0f, 1.0f, 0.0f, ""};
        d.params[2] = {"Sensitivity", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Output", 0.0f, 1.0f, 0.8f, ""};
        break;

    case 51: // Multiband Compressor
        d.name = "Multiband Comp";
        d.numParams = 4;
        d.params[0] = {"Low", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Mid", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"High", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Crossover", 200.0f, 8000.0f, 1000.0f, "Hz"};
        break;

    case 52: // Lo-Fi
        d.name = "Lo-Fi";
        d.numParams = 4;
        d.params[0] = {"Bits", 4.0f, 16.0f, 8.0f, ""};
        d.params[1] = {"Rate", 0.01f, 1.0f, 0.5f, ""};
        d.params[2] = {"Noise", 0.0f, 1.0f, 0.1f, ""};
        d.params[3] = {"Jitter", 0.0f, 1.0f, 0.1f, ""};
        break;

    case 53: // Vinyl Simulator
        d.name = "Vinyl Sim";
        d.numParams = 4;
        d.params[0] = {"Wow", 0.0f, 1.0f, 0.1f, ""};
        d.params[1] = {"Flutter", 0.0f, 1.0f, 0.05f, ""};
        d.params[2] = {"Dust", 0.0f, 1.0f, 0.1f, ""};
        d.params[3] = {"Age", 0.0f, 1.0f, 0.2f, ""};
        break;

    case 54: // Radio Simulator
        d.name = "Radio Sim";
        d.numParams = 4;
        d.params[0] = {"Freq", 200.0f, 8000.0f, 1000.0f, "Hz"};
        d.params[1] = {"Bandwidth", 200.0f, 4000.0f, 2000.0f, "Hz"};
        d.params[2] = {"Noise", 0.0f, 1.0f, 0.2f, ""};
        d.params[3] = {"Distortion", 0.0f, 1.0f, 0.1f, ""};
        break;

    case 55: // Telephone Simulator
        d.name = "Telephone Sim";
        d.numParams = 4;
        d.params[0] = {"LowCut", 100.0f, 1000.0f, 300.0f, "Hz"};
        d.params[1] = {"HighCut", 2000.0f, 8000.0f, 3400.0f, "Hz"};
        d.params[2] = {"Compression", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Noise", 0.0f, 1.0f, 0.1f, ""};
        break;

    case 56: // Cabinet Simulator
        d.name = "Cabinet Sim";
        d.numParams = 4;
        d.params[0] = {"Type", 0.0f, 5.0f, 0.0f, ""};
        d.params[1] = {"Mic", 0.0f, 2.0f, 0.0f, ""};
        d.params[2] = {"Distance", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 57: // Graphic EQ
        d.name = "Graphic EQ";
        d.numParams = 4;
        d.params[0] = {"Low", -18.0f, 18.0f, 0.0f, "dB"};
        d.params[1] = {"Mid-Low", -18.0f, 18.0f, 0.0f, "dB"};
        d.params[2] = {"Mid-High", -18.0f, 18.0f, 0.0f, "dB"};
        d.params[3] = {"High", -18.0f, 18.0f, 0.0f, "dB"};
        break;

    case 58: // Parametric EQ
        d.name = "Parametric EQ";
        d.numParams = 4;
        d.params[0] = {"Freq", 20.0f, 20000.0f, 1000.0f, "Hz"};
        d.params[1] = {"Gain", -18.0f, 18.0f, 0.0f, "dB"};
        d.params[2] = {"Q", 0.1f, 10.0f, 1.0f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 1.0f, ""};
        break;

    case 59: // Wah-Wah
        d.name = "Wah-Wah";
        d.numParams = 4;
        d.params[0] = {"Position", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Range", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Resonance", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 60: // Maximizer
        d.name = "Maximizer";
        d.numParams = 4;
        d.params[0] = {"Ceiling", -12.0f, 0.0f, -0.1f, "dB"};
        d.params[1] = {"Release", 1.0f, 1000.0f, 100.0f, "ms"};
        d.params[2] = {"Saturation", 0.0f, 1.0f, 0.2f, ""};
        d.params[3] = {"Output", 0.0f, 1.0f, 0.9f, ""};
        break;

    case 61: // Exciter
        d.name = "Exciter";
        d.numParams = 4;
        d.params[0] = {"Amount", 0.0f, 1.0f, 0.3f, ""};
        d.params[1] = {"Freq", 2000.0f, 16000.0f, 8000.0f, "Hz"};
        d.params[2] = {"Harmonics", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 62: // Stereo Imager
        d.name = "Stereo Imager";
        d.numParams = 4;
        d.params[0] = {"Width", 0.0f, 2.0f, 1.0f, ""};
        d.params[1] = {"Mono", 0.0f, 1.0f, 0.0f, ""};
        d.params[2] = {"Balance", -1.0f, 1.0f, 0.0f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 1.0f, ""};
        break;

    case 63: // Resonator
        d.name = "Resonator";
        d.numParams = 4;
        d.params[0] = {"Freq", 20.0f, 5000.0f, 440.0f, "Hz"};
        d.params[1] = {"Resonance", 0.0f, 1.0f, 0.7f, ""};
        d.params[2] = {"Decay", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 64: // Grain Delay
        d.name = "Grain Delay";
        d.numParams = 4;
        d.params[0] = {"Size", 10.0f, 500.0f, 100.0f, "ms"};
        d.params[1] = {"Density", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Pitch", -12.0f, 12.0f, 0.0f, "st"};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 65: // Spectral Freeze
        d.name = "Spectral Freeze";
        d.numParams = 4;
        d.params[0] = {"Threshold", -80.0f, 0.0f, -30.0f, "dB"};
        d.params[1] = {"Decay", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Shift", -12.0f, 12.0f, 0.0f, "st"};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        break;

    default:
        d.name = "Unknown";
        d.numParams = 0;
        break;
    }
    return d;
}

void FxEngine::process(float& left, float& right, double sampleRate) {
    if (!masterEnabled_) return;
    switch (routing_) {
    case FxRouting::PARALLEL_MFX:
        processParallelMfx(left, right, sampleRate);
        break;
    case FxRouting::SERIES:
    default:
        processSeries(left, right, sampleRate);
        break;
    }
}

void FxEngine::processSeries(float& left, float& right, double sampleRate) {
    for (int i = 0; i < MAX_FX_SLOTS; i++) {
        slots_[i].process(left, right, sampleRate);
    }
}

void FxEngine::processParallelMfx(float& left, float& right, double sampleRate) {
    float dryLeft = left, dryRight = right;
    float mfxLeft = 0.0f, mfxRight = 0.0f;

    // Process 3 MFX slots in parallel, sum outputs
    for (int i = 0; i < MAX_MFX_SLOTS; i++) {
        float busL = dryLeft, busR = dryRight;
        slots_[i].process(busL, busR, sampleRate);
        mfxLeft += busL * busGains_[i];
        mfxRight += busR * busGains_[i];
    }

    // Normalize parallel mix
    float mfxSum = busGains_[0] + busGains_[1] + busGains_[2];
    if (mfxSum > 0.0f) {
        mfxLeft /= mfxSum;
        mfxRight /= mfxSum;
    }

    // Reverb (slot 3) processes the MFX sum
    float revLeft = mfxLeft, revRight = mfxRight;
    slots_[3].process(revLeft, revRight, sampleRate);

    // Chorus (slot 4) processes the reverb output
    float choLeft = revLeft, choRight = revRight;
    slots_[4].process(choLeft, choRight, sampleRate);

    left = choLeft;
    right = choRight;
}

void FxEngine::setBusGain(int bus, float gain) {
    if (bus >= 0 && bus < MAX_FX_SLOTS) busGains_[bus] = gain;
}

float FxEngine::busGain(int bus) const {
    if (bus >= 0 && bus < MAX_FX_SLOTS) return busGains_[bus];
    return 1.0f;
}

void FxEngine::reset() {
    for (int i = 0; i < MAX_FX_SLOTS; i++) {
        slots_[i].reset();
    }
}

void FxEngine::setSlotProcessor(int index, FxProcessor* processor) {
    if (index >= 0 && index < MAX_FX_SLOTS) {
        slots_[index].setProcessor(processor);
    }
}

void FxEngine::setSlotEnabled(int index, bool enabled) {
    if (index >= 0 && index < MAX_FX_SLOTS && slots_[index].processor) {
        slots_[index].processor->setEnabled(enabled);
    }
}

void FxEngine::setSlotBypassed(int index, bool bypassed) {
    if (index >= 0 && index < MAX_FX_SLOTS) {
        slots_[index].bypassed = bypassed;
    }
}

void FxEngine::setSlotParam(int index, int paramIdx, float value) {
    if (index >= 0 && index < MAX_FX_SLOTS && slots_[index].processor) {
        slots_[index].processor->setParam(paramIdx, value);
    }
}

void FxEngine::setSlotParamNormalized(int slotIndex, int fxTypeId, int paramIdx, float normalized) {
    if (slotIndex >= 0 && slotIndex < MAX_FX_SLOTS && slots_[slotIndex].processor) {
        // Simple linear mapping for now — each param is 0-1 in the engine
        slots_[slotIndex].processor->setParam(paramIdx, normalized);
    }
}

void FxEngine::getSlotParams(int index, float* out, int maxCount) const {
    if (index >= 0 && index < MAX_FX_SLOTS && slots_[index].processor) {
        auto* proc = slots_[index].processor;
        int count = std::min(maxCount, proc->paramCount());
        for (int i = 0; i < count; i++) {
            out[i] = proc->getParam(i);
        }
    }
}

int FxEngine::activeSlotCount() const {
    int count = 0;
    for (int i = 0; i < MAX_FX_SLOTS; i++) {
        if (slots_[i].type() != FxType::None) count++;
    }
    return count;
}

} // namespace opensynth
