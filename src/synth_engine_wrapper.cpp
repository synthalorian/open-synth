#include "synth_engine_wrapper.h"
#include "synth_engine.h"
#include "legacy_fx.h"
#include "audio_buffer.h"
#include <cstring>

namespace openamp {

SynthEngineWrapper::SynthEngineWrapper() = default;
SynthEngineWrapper::~SynthEngineWrapper() = default;

void SynthEngineWrapper::prepare(double sampleRate, int maxBlockSize)
{
    sampleRate_ = sampleRate;
    blockSize_ = maxBlockSize;
    engine_ = std::make_unique<SynthEngine>(sampleRate, static_cast<uint32_t>(maxBlockSize));
    tempBuffer_.resize(static_cast<size_t>(maxBlockSize * 2));
}

void SynthEngineWrapper::render(juce::AudioBuffer<float>& output, const juce::MidiBuffer& midi)
{
    if (!engine_) return;

    // Process MIDI
    for (const auto& msg : midi)
    {
        auto midiMsg = msg.getMessage();
        if (midiMsg.isNoteOn())
        {
            engine_->noteOn(midiMsg.getNoteNumber(), midiMsg.getFloatVelocity(), midiMsg.getChannel() - 1);
        }
        else if (midiMsg.isNoteOff())
        {
            engine_->noteOff(midiMsg.getNoteNumber(), midiMsg.getChannel() - 1);
        }
        else if (midiMsg.isAllNotesOff())
        {
            engine_->allNotesOff();
        }
    }

    // Render audio
    int numSamples = output.getNumSamples();
    int numChannels = output.getNumChannels();

    // Zero temp buffer
    std::fill(tempBuffer_.begin(), tempBuffer_.end(), 0.0f);

    // Create interleaved buffer for engine
    AudioBuffer engineBuf;
    engineBuf.numChannels = 2;
    engineBuf.numFrames = static_cast<uint32_t>(numSamples);
    engineBuf.data = tempBuffer_.data();

    engine_->process(engineBuf);

    // Copy from interleaved to planar JUCE buffer
    for (int ch = 0; ch < numChannels && ch < 2; ++ch)
    {
        float* dest = output.getWritePointer(ch);
        for (int s = 0; s < numSamples; ++s)
        {
            dest[s] = tempBuffer_[s * 2 + ch];
        }
    }
}

void SynthEngineWrapper::reset()
{
    if (engine_) engine_->reset();
}

// Parameter setters
void SynthEngineWrapper::setOsc1Waveform(int w) { if (engine_) engine_->setOsc1Waveform(w); }
void SynthEngineWrapper::setOsc1Octave(int oct) { if (engine_) engine_->setOsc1Octave(oct); }
void SynthEngineWrapper::setOsc1Detune(float cents) { if (engine_) engine_->setOsc1Detune(cents); }
void SynthEngineWrapper::setOsc1Volume(float vol) { if (engine_) engine_->setOsc1Volume(vol); }

void SynthEngineWrapper::setOsc2Waveform(int w) { if (engine_) engine_->setOsc2Waveform(w); }
void SynthEngineWrapper::setOsc2Octave(int oct) { if (engine_) engine_->setOsc2Octave(oct); }
void SynthEngineWrapper::setOsc2Detune(float cents) { if (engine_) engine_->setOsc2Detune(cents); }
void SynthEngineWrapper::setOsc2Volume(float vol) { if (engine_) engine_->setOsc2Volume(vol); }
void SynthEngineWrapper::setOscMix(float mix) { if (engine_) engine_->setOscMix(mix); }

void SynthEngineWrapper::setFilterCutoff(float hz) { if (engine_) engine_->setFilterCutoff(hz); }
void SynthEngineWrapper::setFilterResonance(float q) { if (engine_) engine_->setFilterResonance(q); }
void SynthEngineWrapper::setFilterEnvAmount(float amt) { if (engine_) engine_->setFilterEnvAmount(amt); }
void SynthEngineWrapper::setFilterDrive(float d) { if (engine_) engine_->setFilterDrive(d); }

void SynthEngineWrapper::setAmpAttack(float ms) { if (engine_) engine_->setAmpAttack(ms); }
void SynthEngineWrapper::setAmpDecay(float ms) { if (engine_) engine_->setAmpDecay(ms); }
void SynthEngineWrapper::setAmpSustain(float level) { if (engine_) engine_->setAmpSustain(level); }
void SynthEngineWrapper::setAmpRelease(float ms) { if (engine_) engine_->setAmpRelease(ms); }

void SynthEngineWrapper::setFilterAttack(float ms) { if (engine_) engine_->setFilterAttack(ms); }
void SynthEngineWrapper::setFilterDecay(float ms) { if (engine_) engine_->setFilterDecay(ms); }
void SynthEngineWrapper::setFilterSustain(float level) { if (engine_) engine_->setFilterSustain(level); }
void SynthEngineWrapper::setFilterRelease(float ms) { if (engine_) engine_->setFilterRelease(ms); }

void SynthEngineWrapper::setLfo1Rate(float hz) { if (engine_) engine_->part(0).lfo1.setRate(hz); }
void SynthEngineWrapper::setLfo1Depth(float d) { if (engine_) engine_->part(0).lfo1.setDepth(d); }

void SynthEngineWrapper::setMasterVolume(float vol) { if (engine_) engine_->setMasterVolume(vol); }

void SynthEngineWrapper::setFxEnabled(int slot, bool e)
{
    if (!engine_) return;
    if (slot == 0) {
        // Legacy FX slot - use engine's public method
        engine_->setChorusEnabled(e); // This is a simplification
    } else {
        engine_->fxEngine().setSlotEnabled(slot, e);
    }
}

void SynthEngineWrapper::setFxParam(int slot, int param, float value)
{
    if (!engine_) return;
    engine_->fxEngine().setSlotParam(slot, param, value);
}

void SynthEngineWrapper::setRealismBodyType(int t) { if (engine_) engine_->part(0).realismBodyType = t; }
void SynthEngineWrapper::setRealismBodyMix(float m) { if (engine_) engine_->part(0).realismBodyMix = m; }
void SynthEngineWrapper::setRealismClickMix(float m) { if (engine_) engine_->part(0).realismClickMix = m; }
void SynthEngineWrapper::setRealismSympatheticMix(float m) { if (engine_) engine_->part(0).realismSympatheticMix = m; }
void SynthEngineWrapper::setRealismAttackCurve(int c) { if (engine_) engine_->part(0).realismAttackCurve = c; }
void SynthEngineWrapper::setRealismBrightnessSens(float s) { if (engine_) engine_->part(0).realismBrightnessSens = s; }

int SynthEngineWrapper::getActiveVoiceCount() const
{
    return engine_ ? engine_->getActiveVoiceCount() : 0;
}

float SynthEngineWrapper::getCpuLoad() const
{
    return engine_ ? engine_->getCpuLoad() : 0.0f;
}

} // namespace openamp
