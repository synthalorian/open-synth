#include "plugin_processor.h"
#include "plugin_editor.h"

namespace openamp {

OpenSynthProcessor::OpenSynthProcessor()
    : AudioProcessor(BusesProperties()
                         .withOutput("Output", juce::AudioChannelSet::stereo(), true)
                         .withInput("Input", juce::AudioChannelSet::stereo(), false)),
      apvts_(*this, nullptr, "PARAMETERS", createParameterLayout())
{
}

juce::AudioProcessorValueTreeState::ParameterLayout OpenSynthProcessor::createParameterLayout()
{
    std::vector<std::unique_ptr<juce::RangedAudioParameter>> params;

    // Oscillator 1
    params.push_back(std::make_unique<juce::AudioParameterInt>("osc1Waveform", "Osc1 Waveform", 0, 23, 0));
    params.push_back(std::make_unique<juce::AudioParameterInt>("osc1Octave", "Osc1 Octave", -2, 2, 0));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("osc1Detune", "Osc1 Detune", -100.0f, 100.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("osc1Volume", "Osc1 Volume", 0.0f, 1.0f, 0.8f));

    // Oscillator 2
    params.push_back(std::make_unique<juce::AudioParameterInt>("osc2Waveform", "Osc2 Waveform", 0, 23, 0));
    params.push_back(std::make_unique<juce::AudioParameterInt>("osc2Octave", "Osc2 Octave", -2, 2, 0));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("osc2Detune", "Osc2 Detune", -100.0f, 100.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("osc2Volume", "Osc2 Volume", 0.0f, 1.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("oscMix", "Osc Mix", 0.0f, 1.0f, 0.5f));

    // Filter
    params.push_back(std::make_unique<juce::AudioParameterFloat>("filterCutoff", "Filter Cutoff", 20.0f, 20000.0f, 2000.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("filterResonance", "Filter Resonance", 0.0f, 1.0f, 0.3f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("filterEnvAmt", "Filter Env Amt", -1.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("filterDrive", "Filter Drive", 0.0f, 1.0f, 0.0f));

    // Amp Envelope
    params.push_back(std::make_unique<juce::AudioParameterFloat>("ampAttack", "Amp Attack", 0.1f, 5000.0f, 10.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("ampDecay", "Amp Decay", 0.1f, 5000.0f, 200.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("ampSustain", "Amp Sustain", 0.0f, 1.0f, 0.7f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("ampRelease", "Amp Release", 0.1f, 10000.0f, 300.0f));

    // Filter Envelope
    params.push_back(std::make_unique<juce::AudioParameterFloat>("filterAttack", "Filter Attack", 0.1f, 5000.0f, 10.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("filterDecay", "Filter Decay", 0.1f, 5000.0f, 200.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("filterSustain", "Filter Sustain", 0.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("filterRelease", "Filter Release", 0.1f, 10000.0f, 300.0f));

    // LFO
    params.push_back(std::make_unique<juce::AudioParameterFloat>("lfo1Rate", "LFO1 Rate", 0.1f, 20.0f, 4.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("lfo1Depth", "LFO1 Depth", 0.0f, 1.0f, 0.3f));

    // Master
    params.push_back(std::make_unique<juce::AudioParameterFloat>("masterVolume", "Master Volume", 0.0f, 1.0f, 0.8f));

    // FX Slot 1
    params.push_back(std::make_unique<juce::AudioParameterInt>("fx1Type", "FX1 Type", 0, 21, 0));
    params.push_back(std::make_unique<juce::AudioParameterBool>("fx1Enabled", "FX1 On", false));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fx1Param0", "FX1 P1", 0.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fx1Param1", "FX1 P2", 0.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fx1Param2", "FX1 P3", 0.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fx1Param3", "FX1 P4", 0.0f, 1.0f, 0.5f));

    // FX Slot 2
    params.push_back(std::make_unique<juce::AudioParameterInt>("fx2Type", "FX2 Type", 0, 21, 0));
    params.push_back(std::make_unique<juce::AudioParameterBool>("fx2Enabled", "FX2 On", false));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fx2Param0", "FX2 P1", 0.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fx2Param1", "FX2 P2", 0.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fx2Param2", "FX2 P3", 0.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fx2Param3", "FX2 P4", 0.0f, 1.0f, 0.5f));

    // FX Slot 3
    params.push_back(std::make_unique<juce::AudioParameterInt>("fx3Type", "FX3 Type", 0, 21, 0));
    params.push_back(std::make_unique<juce::AudioParameterBool>("fx3Enabled", "FX3 On", false));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fx3Param0", "FX3 P1", 0.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fx3Param1", "FX3 P2", 0.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fx3Param2", "FX3 P3", 0.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fx3Param3", "FX3 P4", 0.0f, 1.0f, 0.5f));

    return { params.begin(), params.end() };
}

void OpenSynthProcessor::prepareToPlay(double sampleRate, int samplesPerBlock)
{
    synth_.prepare(sampleRate, samplesPerBlock);

    juce::dsp::ProcessSpec spec;
    spec.sampleRate = sampleRate;
    spec.maximumBlockSize = static_cast<juce::uint32>(samplesPerBlock);
    spec.numChannels = 2;
    outputLimiter_.prepare(spec);
    outputLimiter_.setThreshold(-3.0f);
    outputLimiter_.setRelease(100.0f);
}

void OpenSynthProcessor::releaseResources()
{
    synth_.reset();
}

void OpenSynthProcessor::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    juce::ScopedNoDenormals noDenormals;

    auto totalNumInputChannels  = getTotalNumInputChannels();
    auto totalNumOutputChannels = getTotalNumOutputChannels();

    for (auto i = totalNumInputChannels; i < totalNumOutputChannels; ++i)
        buffer.clear(i, 0, buffer.getNumSamples());

    // Pull parameters from APVTS into engine
    synth_.setOsc1Waveform(*apvts_.getRawParameterValue("osc1Waveform"));
    synth_.setOsc1Octave(*apvts_.getRawParameterValue("osc1Octave"));
    synth_.setOsc1Detune(*apvts_.getRawParameterValue("osc1Detune"));
    synth_.setOsc1Volume(*apvts_.getRawParameterValue("osc1Volume"));

    synth_.setOsc2Waveform(*apvts_.getRawParameterValue("osc2Waveform"));
    synth_.setOsc2Octave(*apvts_.getRawParameterValue("osc2Octave"));
    synth_.setOsc2Detune(*apvts_.getRawParameterValue("osc2Detune"));
    synth_.setOsc2Volume(*apvts_.getRawParameterValue("osc2Volume"));
    synth_.setOscMix(*apvts_.getRawParameterValue("oscMix"));

    synth_.setFilterCutoff(*apvts_.getRawParameterValue("filterCutoff"));
    synth_.setFilterResonance(*apvts_.getRawParameterValue("filterResonance"));
    synth_.setFilterEnvAmount(*apvts_.getRawParameterValue("filterEnvAmt"));
    synth_.setFilterDrive(*apvts_.getRawParameterValue("filterDrive"));

    synth_.setAmpAttack(*apvts_.getRawParameterValue("ampAttack"));
    synth_.setAmpDecay(*apvts_.getRawParameterValue("ampDecay"));
    synth_.setAmpSustain(*apvts_.getRawParameterValue("ampSustain"));
    synth_.setAmpRelease(*apvts_.getRawParameterValue("ampRelease"));

    synth_.setFilterAttack(*apvts_.getRawParameterValue("filterAttack"));
    synth_.setFilterDecay(*apvts_.getRawParameterValue("filterDecay"));
    synth_.setFilterSustain(*apvts_.getRawParameterValue("filterSustain"));
    synth_.setFilterRelease(*apvts_.getRawParameterValue("filterRelease"));

    synth_.setLfo1Rate(*apvts_.getRawParameterValue("lfo1Rate"));
    synth_.setLfo1Depth(*apvts_.getRawParameterValue("lfo1Depth"));

    synth_.setMasterVolume(*apvts_.getRawParameterValue("masterVolume"));

    // FX slots
    synth_.setFxEnabled(1, *apvts_.getRawParameterValue("fx1Enabled") > 0.5f);
    synth_.setFxParam(1, 0, *apvts_.getRawParameterValue("fx1Param0"));
    synth_.setFxParam(1, 1, *apvts_.getRawParameterValue("fx1Param1"));
    synth_.setFxParam(1, 2, *apvts_.getRawParameterValue("fx1Param2"));
    synth_.setFxParam(1, 3, *apvts_.getRawParameterValue("fx1Param3"));

    synth_.setFxEnabled(2, *apvts_.getRawParameterValue("fx2Enabled") > 0.5f);
    synth_.setFxParam(2, 0, *apvts_.getRawParameterValue("fx2Param0"));
    synth_.setFxParam(2, 1, *apvts_.getRawParameterValue("fx2Param1"));
    synth_.setFxParam(2, 2, *apvts_.getRawParameterValue("fx2Param2"));
    synth_.setFxParam(2, 3, *apvts_.getRawParameterValue("fx2Param3"));

    synth_.setFxEnabled(3, *apvts_.getRawParameterValue("fx3Enabled") > 0.5f);
    synth_.setFxParam(3, 0, *apvts_.getRawParameterValue("fx3Param0"));
    synth_.setFxParam(3, 1, *apvts_.getRawParameterValue("fx3Param1"));
    synth_.setFxParam(3, 2, *apvts_.getRawParameterValue("fx3Param2"));
    synth_.setFxParam(3, 3, *apvts_.getRawParameterValue("fx3Param3"));

    // Render audio
    synth_.render(buffer, midiMessages);

    // Output limiter
    if (limiterEnabled_)
    {
        juce::dsp::AudioBlock<float> block(buffer);
        juce::dsp::ProcessContextReplacing<float> context(block);
        outputLimiter_.process(context);
    }
}

void OpenSynthProcessor::handleMidiCC(int ccNumber, float value)
{
    // Route to editor if it exists for MIDI Learn
    if (auto* editor = dynamic_cast<OpenSynthEditor*>(getActiveEditor()))
    {
        // Editor will handle mapping and parameter updates
        juce::ignoreUnused(editor);
    }
    juce::ignoreUnused(ccNumber, value);
}

juce::AudioProcessorEditor* OpenSynthProcessor::createEditor()
{
    return new OpenSynthEditor(*this);
}

void OpenSynthProcessor::getStateInformation(juce::MemoryBlock& destData)
{
    auto state = apvts_.copyState();
    std::unique_ptr<juce::XmlElement> xml(state.createXml());
    copyXmlToBinary(*xml, destData);
}

void OpenSynthProcessor::setStateInformation(const void* data, int sizeInBytes)
{
    std::unique_ptr<juce::XmlElement> xmlState(getXmlFromBinary(data, sizeInBytes));
    if (xmlState != nullptr)
        if (xmlState->hasTagName(apvts_.state.getType()))
            apvts_.replaceState(juce::ValueTree::fromXml(*xmlState));
}

} // namespace openamp

// ── Factory function ────────────────────────────────────────────────────────
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new openamp::OpenSynthProcessor();
}
