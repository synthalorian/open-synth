#pragma once
#include <juce_audio_basics/juce_audio_basics.h>
#include <vector>
#include <memory>

// Forward declarations for our existing C++ engine
namespace opensynth {
class SynthEngine;
class FxProcessor;
}

namespace opensynth {

/// Bridges the existing OpenSynth C++ engine to JUCE's audio pipeline.
/// Owns a SynthEngine instance and feeds it MIDI + pulls audio blocks.
class SynthEngineWrapper {
public:
    SynthEngineWrapper();
    ~SynthEngineWrapper();

    void prepare(double sampleRate, int maxBlockSize);
    void render(juce::AudioBuffer<float>& output, const juce::MidiBuffer& midi);
    void reset();

    // Parameter setters (called from editor -> processor -> here)
    void setOsc1Waveform(int w);
    void setOsc1Octave(int oct);
    void setOsc1Detune(float cents);
    void setOsc1Volume(float vol);

    void setOsc2Waveform(int w);
    void setOsc2Octave(int oct);
    void setOsc2Detune(float cents);
    void setOsc2Volume(float vol);
    void setOscMix(float mix);

    void setFilterCutoff(float hz);
    void setFilterResonance(float q);
    void setFilterEnvAmount(float amt);
    void setFilterDrive(float d);

    void setAmpAttack(float ms);
    void setAmpDecay(float ms);
    void setAmpSustain(float level);
    void setAmpRelease(float ms);

    void setFilterAttack(float ms);
    void setFilterDecay(float ms);
    void setFilterSustain(float level);
    void setFilterRelease(float ms);

    void setLfo1Rate(float hz);
    void setLfo1Depth(float d);

    void setMasterVolume(float vol);

    void setFxEnabled(int slot, bool e);
    void setFxType(int slot, int type);
    void setFxParam(int slot, int param, float value);

    // Arpeggiator
    void setArpEnabled(bool e);
    void setArpPattern(int p);
    void setArpTempo(float bpm);
    void setArpGate(float g);
    void setArpSwing(float s);
    void setArpOctaveRange(int o);

    // Instrument realism
    void setRealismBodyType(int t);
    void setRealismBodyMix(float m);
    void setRealismClickMix(float m);
    void setRealismSympatheticMix(float m);
    void setRealismAttackCurve(int c);
    void setRealismBrightnessSens(float s);

    int getActiveVoiceCount() const;
    float getCpuLoad() const;

    // Oscilloscope: get the last rendered interleaved buffer (left + right mixed)
    std::vector<float> getLastAudioBuffer() const;

private:
    std::unique_ptr<SynthEngine> engine_;
    std::vector<float> tempBuffer_;
    std::vector<float> scopeBuffer_; // copy for thread-safe UI read
    mutable juce::CriticalSection scopeLock_;
    double sampleRate_ = 48000.0;
    int blockSize_ = 512;
};

} // namespace opensynth
