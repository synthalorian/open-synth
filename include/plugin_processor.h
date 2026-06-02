#pragma once
#include <juce_audio_processors/juce_audio_processors.h>
#include <juce_dsp/juce_dsp.h>
#include "synth_engine_wrapper.h"

namespace openamp {

class OpenSynthProcessor : public juce::AudioProcessor {
public:
    OpenSynthProcessor();
    ~OpenSynthProcessor() override = default;

    void prepareToPlay(double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;
    void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) override;

    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override { return true; }

    const juce::String getName() const override { return "OpenSynth"; }
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

    // Parameter access for editor
    juce::AudioProcessorValueTreeState& getParameters() { return apvts_; }
    SynthEngineWrapper& getSynth() { return synth_; }

    void handleMidiCC(int ccNumber, float value);

    static juce::AudioProcessorValueTreeState::ParameterLayout createParameterLayout();

private:
    juce::AudioProcessorValueTreeState apvts_;
    SynthEngineWrapper synth_;

    juce::dsp::Limiter<float> outputLimiter_;
    bool limiterEnabled_ = true;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(OpenSynthProcessor)
};

} // namespace openamp
