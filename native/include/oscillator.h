#pragma once
#include <cstdint>
#include <cmath>

namespace openamp {

enum class OscWaveform : int {
    SAW = 0,
    SQUARE = 1,
    TRIANGLE = 2,
    SINE = 3,
    NOISE = 4,
    PULSE = 5,
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
    UnisonConfig unison_;

    float generateWaveform(float phase) const;
};

} // namespace openamp
