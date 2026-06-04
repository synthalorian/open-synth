#include "plugin_processor.h"
#include "plugin_editor.h"
#include "synth_engine.h"

namespace opensynth {

OpenSynthProcessor::OpenSynthProcessor()
    : AudioProcessor(BusesProperties()
                         .withOutput("Output", juce::AudioChannelSet::stereo(), true)
                         .withInput("Input", juce::AudioChannelSet::stereo(), false)),
      apvts_(*this, &undoManager_, "PARAMETERS", createParameterLayout())
{
}

juce::AudioProcessorValueTreeState::ParameterLayout OpenSynthProcessor::createParameterLayout()
{
    juce::AudioProcessorValueTreeState::ParameterLayout layout;

    // ── Oscillator 1 ─────────────────────────────────────────────────────────
    {
        auto osc1Group = std::make_unique<juce::AudioProcessorParameterGroup>("osc1", "Oscillator 1", "|");
        osc1Group->addChild(std::make_unique<juce::AudioParameterInt>("osc1Waveform", "Waveform", 0, 23, 0));
        osc1Group->addChild(std::make_unique<juce::AudioParameterInt>("osc1Octave", "Octave", -2, 2, 0));
        osc1Group->addChild(std::make_unique<juce::AudioParameterFloat>("osc1Detune", "Detune", juce::NormalisableRange<float>(-100.0f, 100.0f, 0.1f), 0.0f, "cents"));
        osc1Group->addChild(std::make_unique<juce::AudioParameterFloat>("osc1Volume", "Volume", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.8f));
        layout.add(std::move(osc1Group));
    }

    // ── Oscillator 2 ─────────────────────────────────────────────────────────
    {
        auto osc2Group = std::make_unique<juce::AudioProcessorParameterGroup>("osc2", "Oscillator 2", "|");
        osc2Group->addChild(std::make_unique<juce::AudioParameterInt>("osc2Waveform", "Waveform", 0, 23, 0));
        osc2Group->addChild(std::make_unique<juce::AudioParameterInt>("osc2Octave", "Octave", -2, 2, 0));
        osc2Group->addChild(std::make_unique<juce::AudioParameterFloat>("osc2Detune", "Detune", juce::NormalisableRange<float>(-100.0f, 100.0f, 0.1f), 0.0f, "cents"));
        osc2Group->addChild(std::make_unique<juce::AudioParameterFloat>("osc2Volume", "Volume", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.0f));
        osc2Group->addChild(std::make_unique<juce::AudioParameterFloat>("oscMix", "Osc Mix", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        layout.add(std::move(osc2Group));
    }

    // ── Filter ───────────────────────────────────────────────────────────────
    {
        auto filterGroup = std::make_unique<juce::AudioProcessorParameterGroup>("filter", "Filter", "|");
        filterGroup->addChild(std::make_unique<juce::AudioParameterFloat>("filterCutoff", "Cutoff", juce::NormalisableRange<float>(20.0f, 20000.0f, 1.0f, 0.3f), 2000.0f, "Hz"));
        filterGroup->addChild(std::make_unique<juce::AudioParameterFloat>("filterResonance", "Resonance", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.3f));
        filterGroup->addChild(std::make_unique<juce::AudioParameterFloat>("filterEnvAmt", "Env Amt", juce::NormalisableRange<float>(-1.0f, 1.0f, 0.01f), 0.5f));
        filterGroup->addChild(std::make_unique<juce::AudioParameterFloat>("filterDrive", "Drive", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.0f));
        layout.add(std::move(filterGroup));
    }

    // ── Amp Envelope ─────────────────────────────────────────────────────────
    {
        auto ampEnvGroup = std::make_unique<juce::AudioProcessorParameterGroup>("ampEnv", "Amp Envelope", "|");
        ampEnvGroup->addChild(std::make_unique<juce::AudioParameterFloat>("ampAttack", "Attack", juce::NormalisableRange<float>(0.1f, 5000.0f, 0.1f, 0.3f), 10.0f, "ms"));
        ampEnvGroup->addChild(std::make_unique<juce::AudioParameterFloat>("ampDecay", "Decay", juce::NormalisableRange<float>(0.1f, 5000.0f, 0.1f, 0.3f), 200.0f, "ms"));
        ampEnvGroup->addChild(std::make_unique<juce::AudioParameterFloat>("ampSustain", "Sustain", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.7f));
        ampEnvGroup->addChild(std::make_unique<juce::AudioParameterFloat>("ampRelease", "Release", juce::NormalisableRange<float>(0.1f, 10000.0f, 0.1f, 0.3f), 300.0f, "ms"));
        layout.add(std::move(ampEnvGroup));
    }

    // ── Filter Envelope ──────────────────────────────────────────────────────
    {
        auto filterEnvGroup = std::make_unique<juce::AudioProcessorParameterGroup>("filterEnv", "Filter Envelope", "|");
        filterEnvGroup->addChild(std::make_unique<juce::AudioParameterFloat>("filterAttack", "Attack", juce::NormalisableRange<float>(0.1f, 5000.0f, 0.1f, 0.3f), 10.0f, "ms"));
        filterEnvGroup->addChild(std::make_unique<juce::AudioParameterFloat>("filterDecay", "Decay", juce::NormalisableRange<float>(0.1f, 5000.0f, 0.1f, 0.3f), 200.0f, "ms"));
        filterEnvGroup->addChild(std::make_unique<juce::AudioParameterFloat>("filterSustain", "Sustain", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        filterEnvGroup->addChild(std::make_unique<juce::AudioParameterFloat>("filterRelease", "Release", juce::NormalisableRange<float>(0.1f, 10000.0f, 0.1f, 0.3f), 300.0f, "ms"));
        layout.add(std::move(filterEnvGroup));
    }

    // ── LFO ──────────────────────────────────────────────────────────────────
    {
        auto lfoGroup = std::make_unique<juce::AudioProcessorParameterGroup>("lfo", "LFO", "|");
        lfoGroup->addChild(std::make_unique<juce::AudioParameterFloat>("lfo1Rate", "Rate", juce::NormalisableRange<float>(0.1f, 20.0f, 0.01f, 0.5f), 4.0f, "Hz"));
        lfoGroup->addChild(std::make_unique<juce::AudioParameterFloat>("lfo1Depth", "Depth", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.3f));
        layout.add(std::move(lfoGroup));
    }

    // ── Master ───────────────────────────────────────────────────────────────
    {
        auto masterGroup = std::make_unique<juce::AudioProcessorParameterGroup>("master", "Master", "|");
        masterGroup->addChild(std::make_unique<juce::AudioParameterFloat>("masterVolume", "Volume", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.8f));
        layout.add(std::move(masterGroup));
    }

    // ── Sample Player ────────────────────────────────────────────────────────
    {
        auto sampleGroup = std::make_unique<juce::AudioProcessorParameterGroup>("sample", "Sample Player", "|");
        sampleGroup->addChild(std::make_unique<juce::AudioParameterFloat>("sampleMix", "Sample Mix", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.0f));
        sampleGroup->addChild(std::make_unique<juce::AudioParameterFloat>("sampleAttack", "Sample Attack", juce::NormalisableRange<float>(0.1f, 5000.0f, 0.1f, 0.3f), 10.0f));
        sampleGroup->addChild(std::make_unique<juce::AudioParameterFloat>("sampleDecay", "Sample Decay", juce::NormalisableRange<float>(1.0f, 5000.0f, 0.1f, 0.3f), 100.0f));
        sampleGroup->addChild(std::make_unique<juce::AudioParameterFloat>("sampleSustain", "Sample Sustain", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 1.0f));
        sampleGroup->addChild(std::make_unique<juce::AudioParameterFloat>("sampleRelease", "Sample Release", juce::NormalisableRange<float>(1.0f, 10000.0f, 0.1f, 0.3f), 200.0f));
        layout.add(std::move(sampleGroup));
    }

    // ── FX Slot 1 ────────────────────────────────────────────────────────────
    {
        auto fx1Group = std::make_unique<juce::AudioProcessorParameterGroup>("fx1", "FX 1", "|");
        fx1Group->addChild(std::make_unique<juce::AudioParameterInt>("fx1Type", "Type", 0, 65, 0));
        fx1Group->addChild(std::make_unique<juce::AudioParameterBool>("fx1Enabled", "On", false));
        fx1Group->addChild(std::make_unique<juce::AudioParameterFloat>("fx1Param0", "P1", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        fx1Group->addChild(std::make_unique<juce::AudioParameterFloat>("fx1Param1", "P2", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        fx1Group->addChild(std::make_unique<juce::AudioParameterFloat>("fx1Param2", "P3", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        fx1Group->addChild(std::make_unique<juce::AudioParameterFloat>("fx1Param3", "P4", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        layout.add(std::move(fx1Group));
    }

    // ── FX Slot 2 ────────────────────────────────────────────────────────────
    {
        auto fx2Group = std::make_unique<juce::AudioProcessorParameterGroup>("fx2", "FX 2", "|");
        fx2Group->addChild(std::make_unique<juce::AudioParameterInt>("fx2Type", "Type", 0, 65, 0));
        fx2Group->addChild(std::make_unique<juce::AudioParameterBool>("fx2Enabled", "On", false));
        fx2Group->addChild(std::make_unique<juce::AudioParameterFloat>("fx2Param0", "P1", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        fx2Group->addChild(std::make_unique<juce::AudioParameterFloat>("fx2Param1", "P2", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        fx2Group->addChild(std::make_unique<juce::AudioParameterFloat>("fx2Param2", "P3", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        fx2Group->addChild(std::make_unique<juce::AudioParameterFloat>("fx2Param3", "P4", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        layout.add(std::move(fx2Group));
    }

    // ── FX Slot 3 ────────────────────────────────────────────────────────────
    {
        auto fx3Group = std::make_unique<juce::AudioProcessorParameterGroup>("fx3", "FX 3", "|");
        fx3Group->addChild(std::make_unique<juce::AudioParameterInt>("fx3Type", "Type", 0, 65, 0));
        fx3Group->addChild(std::make_unique<juce::AudioParameterBool>("fx3Enabled", "On", false));
        fx3Group->addChild(std::make_unique<juce::AudioParameterFloat>("fx3Param0", "P1", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        fx3Group->addChild(std::make_unique<juce::AudioParameterFloat>("fx3Param1", "P2", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        fx3Group->addChild(std::make_unique<juce::AudioParameterFloat>("fx3Param2", "P3", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        fx3Group->addChild(std::make_unique<juce::AudioParameterFloat>("fx3Param3", "P4", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        layout.add(std::move(fx3Group));
    }

    // ── Arpeggiator ──────────────────────────────────────────────────────────
    {
        auto arpGroup = std::make_unique<juce::AudioProcessorParameterGroup>("arp", "Arpeggiator", "|");
        arpGroup->addChild(std::make_unique<juce::AudioParameterBool>("arpEnabled", "On", false));
        arpGroup->addChild(std::make_unique<juce::AudioParameterInt>("arpPattern", "Pattern", 0, 159, 0));
        arpGroup->addChild(std::make_unique<juce::AudioParameterFloat>("arpTempo", "Tempo", juce::NormalisableRange<float>(20.0f, 300.0f, 0.1f), 120.0f, "BPM"));
        arpGroup->addChild(std::make_unique<juce::AudioParameterFloat>("arpGate", "Gate", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.5f));
        arpGroup->addChild(std::make_unique<juce::AudioParameterFloat>("arpSwing", "Swing", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.0f));
        arpGroup->addChild(std::make_unique<juce::AudioParameterInt>("arpOctave", "Octave", 1, 4, 1));
        layout.add(std::move(arpGroup));
    }

    // ── D-Beam Controller ────────────────────────────────────────────────────
    {
        auto dbeamGroup = std::make_unique<juce::AudioProcessorParameterGroup>("dbeam", "D-Beam", "|");
        dbeamGroup->addChild(std::make_unique<juce::AudioParameterInt>("dbeamTarget", "Target", 0, 3, 0));
        dbeamGroup->addChild(std::make_unique<juce::AudioParameterFloat>("dbeamValue", "Value", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.0f));
        layout.add(std::move(dbeamGroup));
    }

    // ── Performance Controls ─────────────────────────────────────────────────
    {
        auto perfGroup = std::make_unique<juce::AudioProcessorParameterGroup>("perf", "Performance", "|");
        perfGroup->addChild(std::make_unique<juce::AudioParameterInt>("perfSplitPoint", "Split Point", 21, 108, 60));
        perfGroup->addChild(std::make_unique<juce::AudioParameterBool>("perfLayerEnabled", "Layer On", false));
        perfGroup->addChild(std::make_unique<juce::AudioParameterInt>("perfTranspose", "Transpose", -12, 12, 0));
        layout.add(std::move(perfGroup));
    }

    // ── Instrument Realism ───────────────────────────────────────────────────
    {
        auto realismGroup = std::make_unique<juce::AudioProcessorParameterGroup>("realism", "Instrument Realism", "|");
        realismGroup->addChild(std::make_unique<juce::AudioParameterInt>("realismBodyType", "Body Type", 0, 7, 0));
        realismGroup->addChild(std::make_unique<juce::AudioParameterFloat>("realismBodyMix", "Body Mix", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.0f));
        realismGroup->addChild(std::make_unique<juce::AudioParameterFloat>("realismClickMix", "Click Mix", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.0f));
        realismGroup->addChild(std::make_unique<juce::AudioParameterFloat>("realismSympatheticMix", "Sympathetic", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.0f));
        realismGroup->addChild(std::make_unique<juce::AudioParameterInt>("realismAttackCurve", "Attack Curve", 0, 3, 0));
        realismGroup->addChild(std::make_unique<juce::AudioParameterFloat>("realismBrightnessSens", "Brightness", juce::NormalisableRange<float>(0.0f, 1.0f, 0.01f), 0.0f));
        layout.add(std::move(realismGroup));
    }

    // ── MPE Settings ─────────────────────────────────────────────────────────
    {
        auto mpeGroup = std::make_unique<juce::AudioProcessorParameterGroup>("mpe", "MPE", "|");
        mpeGroup->addChild(std::make_unique<juce::AudioParameterBool>("mpeEnabled", "MPE On", false));
        mpeGroup->addChild(std::make_unique<juce::AudioParameterInt>("mpeZone", "Zone", 0, 1, 0));
        mpeGroup->addChild(std::make_unique<juce::AudioParameterFloat>("mpeBendRange", "Bend Range", juce::NormalisableRange<float>(2.0f, 96.0f, 1.0f), 48.0f, "st"));
        layout.add(std::move(mpeGroup));
    }

    return layout;
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

    // Merge UI-injected MIDI (from on-screen keyboard) into host MIDI buffer
    {
        juce::ScopedLock lock(midiLock_);
        if (!uiMidiBuffer_.isEmpty())
        {
            midiMessages.addEvents(uiMidiBuffer_, 0, buffer.getNumSamples(), 0);
            uiMidiBuffer_.clear();
        }
    }

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

    // Sample player mix + envelope
    if (auto* engine = synth_.getEngine())
    {
        if (auto* sp = engine->getSamplePlayer()) {
            sp->setMixLevel(*apvts_.getRawParameterValue("sampleMix"));
            sp->setAttack(*apvts_.getRawParameterValue("sampleAttack"));
            sp->setDecay(*apvts_.getRawParameterValue("sampleDecay"));
            sp->setSustain(*apvts_.getRawParameterValue("sampleSustain"));
            sp->setRelease(*apvts_.getRawParameterValue("sampleRelease"));
        }
    }

    // FX slots
    synth_.setFxEnabled(1, *apvts_.getRawParameterValue("fx1Enabled") > 0.5f);
    synth_.setFxType(1, static_cast<int>(*apvts_.getRawParameterValue("fx1Type")));
    synth_.setFxParam(1, 0, *apvts_.getRawParameterValue("fx1Param0"));
    synth_.setFxParam(1, 1, *apvts_.getRawParameterValue("fx1Param1"));
    synth_.setFxParam(1, 2, *apvts_.getRawParameterValue("fx1Param2"));
    synth_.setFxParam(1, 3, *apvts_.getRawParameterValue("fx1Param3"));

    synth_.setFxEnabled(2, *apvts_.getRawParameterValue("fx2Enabled") > 0.5f);
    synth_.setFxType(2, static_cast<int>(*apvts_.getRawParameterValue("fx2Type")));
    synth_.setFxParam(2, 0, *apvts_.getRawParameterValue("fx2Param0"));
    synth_.setFxParam(2, 1, *apvts_.getRawParameterValue("fx2Param1"));
    synth_.setFxParam(2, 2, *apvts_.getRawParameterValue("fx2Param2"));
    synth_.setFxParam(2, 3, *apvts_.getRawParameterValue("fx2Param3"));

    synth_.setFxEnabled(3, *apvts_.getRawParameterValue("fx3Enabled") > 0.5f);
    synth_.setFxType(3, static_cast<int>(*apvts_.getRawParameterValue("fx3Type")));
    synth_.setFxParam(3, 0, *apvts_.getRawParameterValue("fx3Param0"));
    synth_.setFxParam(3, 1, *apvts_.getRawParameterValue("fx3Param1"));
    synth_.setFxParam(3, 2, *apvts_.getRawParameterValue("fx3Param2"));
    synth_.setFxParam(3, 3, *apvts_.getRawParameterValue("fx3Param3"));

    // Arpeggiator
    synth_.setArpEnabled(*apvts_.getRawParameterValue("arpEnabled") > 0.5f);
    synth_.setArpPattern(static_cast<int>(*apvts_.getRawParameterValue("arpPattern")));
    synth_.setArpTempo(*apvts_.getRawParameterValue("arpTempo"));
    synth_.setArpGate(*apvts_.getRawParameterValue("arpGate"));
    synth_.setArpSwing(*apvts_.getRawParameterValue("arpSwing"));
    synth_.setArpOctaveRange(static_cast<int>(*apvts_.getRawParameterValue("arpOctave")));

    // Instrument Realism
    synth_.setRealismBodyType(static_cast<int>(*apvts_.getRawParameterValue("realismBodyType")));
    synth_.setRealismBodyMix(*apvts_.getRawParameterValue("realismBodyMix"));
    synth_.setRealismClickMix(*apvts_.getRawParameterValue("realismClickMix"));
    synth_.setRealismSympatheticMix(*apvts_.getRawParameterValue("realismSympatheticMix"));
    synth_.setRealismAttackCurve(static_cast<int>(*apvts_.getRawParameterValue("realismAttackCurve")));
    synth_.setRealismBrightnessSens(*apvts_.getRawParameterValue("realismBrightnessSens"));

    // MPE
    synth_.setMpeEnabled(*apvts_.getRawParameterValue("mpeEnabled") > 0.5f);
    synth_.setMpeZone(static_cast<int>(*apvts_.getRawParameterValue("mpeZone")));
    synth_.setMpeBendRange(*apvts_.getRawParameterValue("mpeBendRange"));

    // Render audio
    synth_.render(buffer, midiMessages);

    // Output limiter
    if (limiterEnabled_)
    {
        juce::dsp::AudioBlock<float> block(buffer);
        juce::dsp::ProcessContextReplacing<float> context(block);
        outputLimiter_.process(context);
    }

    // Push to waveform scope (lock-free, safe from audio thread)
    if (waveformDisplay_ && totalNumOutputChannels >= 2)
    {
        auto* left  = buffer.getReadPointer(0);
        auto* right = buffer.getReadPointer(1);
        waveformDisplay_->pushSamples(left, right, buffer.getNumSamples());
    }

    // Phrase sampler mix-in
    if (phraseSample.playing.load(std::memory_order_acquire))
    {
        int pos = phraseSample.playPosition.load(std::memory_order_relaxed);
        int numBufSamples = phraseSample.getNumSamples();
        int numFrames = buffer.getNumSamples();
        float vol = phraseSample.volume;

        if (numBufSamples > 0 && pos < numBufSamples)
        {
            int samplesToPlay = std::min(numFrames, numBufSamples - pos);
            auto* outL = buffer.getWritePointer(0);
            auto* outR = totalNumOutputChannels >= 2 ? buffer.getWritePointer(1) : outL;

            if (phraseSample.buffer.getNumChannels() >= 2)
            {
                const float* srcL = phraseSample.buffer.getReadPointer(0);
                const float* srcR = phraseSample.buffer.getReadPointer(1);
                for (int i = 0; i < samplesToPlay; ++i)
                {
                    outL[i] += srcL[pos + i] * vol;
                    outR[i] += srcR[pos + i] * vol;
                }
            }
            else
            {
                const float* src = phraseSample.buffer.getReadPointer(0);
                for (int i = 0; i < samplesToPlay; ++i)
                {
                    outL[i] += src[pos + i] * vol;
                    outR[i] += src[pos + i] * vol;
                }
            }

            pos += samplesToPlay;
            if (pos >= numBufSamples)
            {
                if (phraseSample.looping.load(std::memory_order_relaxed))
                {
                    pos = 0;
                }
                else
                {
                    phraseSample.playing.store(false, std::memory_order_release);
                }
            }
            phraseSample.playPosition.store(pos, std::memory_order_release);
        }
        else
        {
            phraseSample.playing.store(false, std::memory_order_release);
        }
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

void OpenSynthProcessor::injectMidiMessage(const juce::MidiMessage& msg)
{
    juce::ScopedLock lock(midiLock_);
    uiMidiBuffer_.addEvent(msg, 0);
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

juce::File OpenSynthProcessor::getUserPresetsDir() const
{
    auto dir = juce::File::getSpecialLocation(juce::File::userApplicationDataDirectory)
                   .getChildFile("open-synth")
                   .getChildFile("presets");
    dir.createDirectory();
    return dir;
}

void OpenSynthProcessor::saveUserPreset(const juce::String& name, const juce::String& category)
{
    auto file = getUserPresetsDir().getChildFile(name + ".osj");
    auto state = apvts_.copyState();
    std::unique_ptr<juce::XmlElement> xml(state.createXml());
    xml->setAttribute("presetName", name);
    xml->setAttribute("presetCategory", category);
    xml->writeTo(file);
}

std::vector<juce::String> OpenSynthProcessor::getUserPresetNames() const
{
    std::vector<juce::String> names;
    auto dir = getUserPresetsDir();
    for (auto& f : dir.findChildFiles(juce::File::findFiles, false, "*.osj"))
        names.push_back(f.getFileNameWithoutExtension());
    return names;
}

bool OpenSynthProcessor::loadUserPreset(const juce::String& name)
{
    auto file = getUserPresetsDir().getChildFile(name + ".osj");
    if (!file.existsAsFile()) return false;
    auto xml = juce::XmlDocument::parse(file);
    if (xml != nullptr && xml->hasTagName(apvts_.state.getType()))
    {
        apvts_.replaceState(juce::ValueTree::fromXml(*xml));
        return true;
    }
    return false;
}

} // namespace opensynth

// ── Factory function ────────────────────────────────────────────────────────
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new opensynth::OpenSynthProcessor();
}
