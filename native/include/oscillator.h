#pragma once
#include <cstdint>
#include <cmath>
#include <algorithm>
#include "wavetable_oscillator.h"

namespace openamp {

enum class OscWaveform : int {
    SAW = 0,
    SQUARE = 1,
    TRIANGLE = 2,
    SINE = 3,
    NOISE = 4,
    PULSE = 5,
    WT_PIANO = 6,
    WT_GUITAR = 7,
    WT_CHOIR = 8,
    WT_BRASS = 9,
    WT_STRINGS = 10,
    WT_WOODWIND = 11,
    WT_ORGAN = 12,
    WT_BELL = 13,
    WT_SYNTH_BASS = 14,
    WT_SYNTH_LEAD = 15,
    WT_PAD = 16,
    WT_EPIANO = 17,
    PM_KARPLUS = 18,
    PM_KARPLUS_BRIGHT = 19,
    PM_KARPLUS_BASS = 20,
    PM_MODAL_MALLET = 21,
    PM_MODAL_VIBRAPHONE = 22,
    PM_MODAL_STEEL = 23,
};

/// Noise color types for the NOISE waveform.
enum class NoiseType : int {
    WHITE = 0,
    PINK = 1,
    BROWN = 2,
};

/// Sub-oscillator mode.
enum class SubOscMode : int {
    OFF = 0,
    SQUARE_1OCT = 1,   // Square wave, 1 octave below
    SQUARE_2OCT = 2,   // Square wave, 2 octaves below
    SINE_1OCT = 3,     // Sine wave, 1 octave below
};

class UnisonConfig {
public:
    int voiceCount = 1;        // 1-8, 1 = off
    float detuneSpread = 10.0f; // cents
    float stereoSpread = 0.5f;  // 0-1 pan spread
    float mix = 1.0f;           // 0-1 wet/dry
};

class Oscillator {
public:
    Oscillator() = default;

    void setWaveform(int w);
    void setOctave(int oct);
    void setDetune(float cents);
    void setPulseWidth(float pw);
    void setVolume(float vol);

    // Noise
    void setNoiseType(int nt);
    int noiseType() const { return static_cast<int>(noiseType_); }

    // Sub oscillator
    void setSubOscMode(int mode);
    void setSubOscVolume(float vol);
    int subOscMode() const { return static_cast<int>(subOscMode_); }
    float subOscVolume() const { return subOscVolume_; }

    // FM synthesis
    void setFmEnabled(bool e) { fmEnabled_ = e; }
    void setFmAmount(float a) { fmAmount_ = std::clamp(a, 0.0f, 1.0f); }
    bool fmEnabled() const { return fmEnabled_; }
    float fmAmount() const { return fmAmount_; }

    // Unison
    void setUnisonVoiceCount(int count);
    void setUnisonDetuneSpread(float cents);
    void setUnisonStereoSpread(float spread);
    void setUnisonMix(float mix);

    // Generate one sample for a given voice (0 = main, 1..N = unison)
    // freq = base frequency of the note this oscillator belongs to
    float process(float phase, int voiceIndex, float freq, double sampleRate) const;

    float phaseIncrement(float midiNoteFreq, int voiceIndex) const;
    float voiceDetuneCents(int voiceIndex) const;
    float voicePan(int voiceIndex) const;

    int waveform() const { return waveform_; }
    int octave() const { return octave_; }
    float detune() const { return detune_; }
    float pulseWidth() const { return pulseWidth_; }
    float volume() const { return volume_; }
    const UnisonConfig& unison() const { return unison_; }

    void reset();

private:
    int waveform_ = 0;
    int octave_ = 0;
    float detune_ = 0.0f;
    float pulseWidth_ = 0.5f;
    float volume_ = 0.8f;
    NoiseType noiseType_ = NoiseType::WHITE;
    SubOscMode subOscMode_ = SubOscMode::OFF;
    float subOscVolume_ = 0.5f;
    bool fmEnabled_ = false;
    float fmAmount_ = 0.5f;
    UnisonConfig unison_;

    mutable WavetableOscillator wtOsc_;

    float generateWaveform(float phase) const;
};

} // namespace openamp
