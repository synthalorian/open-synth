#pragma once
#include <juce_audio_processors/juce_audio_processors.h>
#include <juce_dsp/juce_dsp.h>
#include "synth_engine_wrapper.h"
#include "waveform_display.h"

namespace opensynth {

class OpenSynthProcessor : public juce::AudioProcessor {
public:
    OpenSynthProcessor();
    ~OpenSynthProcessor() override = default;

    void prepareToPlay(double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;
    void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) override;

    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override { return true; }

    const juce::String getName() const override { return "Open Synth"; }
    bool acceptsMidi() const override { return true; }
    bool producesMidi() const override { return false; }
    bool isMidiEffect() const override { return false; }
    double getTailLengthSeconds() const override { return 0.0; }

    int getNumPrograms() override { return 1; }
    int getCurrentProgram() override { return 0; }
    void setCurrentProgram(int) override {}
    const juce::String getProgramName(int) override { return {}; }
    void changeProgramName(int, const juce::String&) override {}

    void getStateInformation(juce::MemoryBlock& destData) override;
    void setStateInformation(const void* data, int sizeInBytes) override;

    // User preset management
    juce::File getUserPresetsDir() const;
    void saveUserPreset(const juce::String& name, const juce::String& category);
    std::vector<juce::String> getUserPresetNames() const;
    bool loadUserPreset(const juce::String& name);

    // Parameter access for editor
    juce::AudioProcessorValueTreeState& getParameters() { return apvts_; }
    SynthEngineWrapper& getSynth() { return synth_; }

    // Undo manager access
    juce::UndoManager& getUndoManager() { return undoManager_; }

    void handleMidiCC(int ccNumber, float value);

    // Inject MIDI from on-screen keyboard or other UI sources
    void injectMidiMessage(const juce::MidiMessage& msg);

    // Waveform display — set by editor, read by processor (atomic-safe)
    void setWaveformDisplay(WaveformDisplay* display) { waveformDisplay_ = display; }

    // Phrase sampler — load a stereo buffer for one-shot playback
    struct PhraseSample {
        juce::AudioBuffer<float> buffer;
        std::atomic<int> playPosition{0};
        std::atomic<bool> playing{false};
        std::atomic<bool> looping{false};
        float volume = 0.8f;
        double sampleRate = 48000.0;

        void stop() { playing.store(false, std::memory_order_release); playPosition.store(0, std::memory_order_release); }
        void start() { playPosition.store(0, std::memory_order_release); playing.store(true, std::memory_order_release); }
        int getNumSamples() const { return buffer.getNumSamples(); }
    };

    PhraseSample phraseSample;

    static juce::AudioProcessorValueTreeState::ParameterLayout createParameterLayout();

private:
    juce::UndoManager undoManager_;
    juce::AudioProcessorValueTreeState apvts_;
    SynthEngineWrapper synth_;

    juce::dsp::Limiter<float> outputLimiter_;
    bool limiterEnabled_ = true;

    // Thread-safe MIDI queue for UI-to-processor communication
    juce::MidiBuffer uiMidiBuffer_;
    juce::CriticalSection midiLock_;

    // Waveform scope (set by editor, lock-free read in processBlock)
    WaveformDisplay* waveformDisplay_ = nullptr;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(OpenSynthProcessor)
};

} // namespace opensynth
