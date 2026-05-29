#pragma once
#include <cstdint>
#include <array>
#include "audio_buffer.h"
#include "oscillator.h"
#include "filter.h"
#include "lfo.h"
#include "voice_allocator.h"
#include "param_queue.h"
#include "arpeggiator.h"
#include "drum_synth.h"
#include "fx_engine.h"

namespace openamp {

// Forward declaration for the LegacyFxProcessor used in slot 0 of the FxEngine.
class LegacyFxProcessor;

class SynthEngine {
public:
    SynthEngine(double sampleRate, uint32_t blockSize);
    ~SynthEngine();

    // No copy
    SynthEngine(const SynthEngine&) = delete;
    SynthEngine& operator=(const SynthEngine&) = delete;

    void process(AudioBuffer& output);
    void reset();

    // MIDI (thread-safe via queue)
    void noteOn(int midiNote, float velocity);
    void noteOff(int midiNote);
    void allNotesOff();

    // Arpeggiator
    Arpeggiator& arpeggiator() { return arpeggiator_; }
    void setArpEnabled(bool e) { arpeggiator_.setEnabled(e); }
    void setArpTempo(float bpm) { arpeggiator_.setTempo(bpm); }
    void setArpPattern(int p) { arpeggiator_.setPattern(p); }
    void setArpOctaveRange(int o) { arpeggiator_.setOctaveRange(o); }
    void setArpGate(float g) { arpeggiator_.setGate(g); }
    void setArpResolution(int r) { arpeggiator_.setResolution(r); }
    void setArpSwing(float s) { arpeggiator_.setSwing(s); }
    void setArpHold(bool h) { arpeggiator_.setHold(h); }
    int getArpCurrentStep() const { return arpeggiator_.currentStep(); }
    int getArpTotalSteps() const { return arpeggiator_.totalSteps(); }

    // Voice allocation
    VoiceAllocator& allocator() { return allocator_; }
    void setVoicePriorityMode(int m) { allocator_.setPriorityMode(static_cast<VoicePriorityMode>(m)); }

    // Thread-safe parameter queue — UI thread enqueues, audio thread drains.
    ParamQueue& paramQueue() { return paramQueue_; }

    // Direct parameter setters (DEPRECATED — prefer queue for thread safety).
    // These still exist for the FFI layer but should eventually all go through
    // the queue. For now they directly modify parameters (unsafe if audio is
    // running; use queue instead).

    // Osc 1
    void setOsc1Waveform(int w) { osc1_.setWaveform(w); }
    void setOsc1Octave(int oct) { osc1_.setOctave(oct); }
    void setOsc1Detune(float cents) { osc1_.setDetune(cents); }
    void setOsc1PulseWidth(float pw) { osc1_.setPulseWidth(pw); }
    void setOsc1Volume(float vol) { osc1_.setVolume(vol); }
    void setOsc1NoiseType(int nt) { osc1_.setNoiseType(nt); }
    void setOsc1SubOscMode(int m) { osc1_.setSubOscMode(m); }
    void setOsc1SubOscVolume(float v) { osc1_.setSubOscVolume(v); }
    void setOsc1FmEnabled(bool e) { osc1_.setFmEnabled(e); }
    void setOsc1FmAmount(float a) { osc1_.setFmAmount(a); }

    // Osc 2
    void setOsc2Waveform(int w) { osc2_.setWaveform(w); }
    void setOsc2Octave(int oct) { osc2_.setOctave(oct); }
    void setOsc2Detune(float cents) { osc2_.setDetune(cents); }
    void setOsc2PulseWidth(float pw) { osc2_.setPulseWidth(pw); }
    void setOsc2Volume(float vol) { osc2_.setVolume(vol); }
    void setOsc2NoiseType(int nt) { osc2_.setNoiseType(nt); }
    void setOsc2SubOscMode(int m) { osc2_.setSubOscMode(m); }
    void setOsc2SubOscVolume(float v) { osc2_.setSubOscVolume(v); }
    void setOsc2FmEnabled(bool e) { osc2_.setFmEnabled(e); }
    void setOsc2FmAmount(float a) { osc2_.setFmAmount(a); }
    void setOscMix(float mix) { oscMix_ = mix; }

    // Unison
    void setOsc1UnisonVoiceCount(int c) { osc1_.setUnisonVoiceCount(c); }
    void setOsc1UnisonDetuneSpread(float s) { osc1_.setUnisonDetuneSpread(s); }
    void setOsc1UnisonStereoSpread(float s) { osc1_.setUnisonStereoSpread(s); }
    void setOsc1UnisonMix(float m) { osc1_.setUnisonMix(m); }

    void setOsc2UnisonVoiceCount(int c) { osc2_.setUnisonVoiceCount(c); }
    void setOsc2UnisonDetuneSpread(float s) { osc2_.setUnisonDetuneSpread(s); }
    void setOsc2UnisonStereoSpread(float s) { osc2_.setUnisonStereoSpread(s); }
    void setOsc2UnisonMix(float m) { osc2_.setUnisonMix(m); }

    // Filter
    void setFilterType(int t) { filter_.setType(t); }
    void setFilterCutoff(float hz) { filter_.setCutoff(hz); }
    void setFilterResonance(float q) { filter_.setResonance(q); }
    void setFilterEnvAmount(float a) { filter_.setEnvAmount(a); }
    void setFilterKeyTracking(float kt) { filter_.setKeyTracking(kt); }
    void setFilterDrive(float d) { filter_.setDrive(d); }

    // Amp envelope
    void setAmpAttack(float ms) { ampAttack_ = ms; }
    void setAmpDecay(float ms) { ampDecay_ = ms; }
    void setAmpSustain(float level) { ampSustain_ = level; }
    void setAmpRelease(float ms) { ampRelease_ = ms; }
    void setAmpDelay(float ms) { ampDelay_ = ms; }
    void setAmpHold(float ms) { ampHold_ = ms; }
    void setAmpAttackCurve(int c) { ampAttackCurve_ = c; }
    void setAmpDecayCurve(int c) { ampDecayCurve_ = c; }
    void setAmpReleaseCurve(int c) { ampReleaseCurve_ = c; }

    // Filter envelope
    void setFilterAttack(float ms) { filterAttack_ = ms; }
    void setFilterDecay(float ms) { filterDecay_ = ms; }
    void setFilterSustain(float level) { filterSustain_ = level; }
    void setFilterRelease(float ms) { filterRelease_ = ms; }
    void setFilterDelay(float ms) { filterDelay_ = ms; }
    void setFilterHold(float ms) { filterHold_ = ms; }
    void setFilterAttackCurve(int c) { filterAttackCurve_ = c; }
    void setFilterDecayCurve(int c) { filterDecayCurve_ = c; }
    void setFilterReleaseCurve(int c) { filterReleaseCurve_ = c; }

    // Pitch envelope
    void setPitchEnvAttack(float ms) { pitchEnvAttack_ = ms; }
    void setPitchEnvDecay(float ms) { pitchEnvDecay_ = ms; }
    void setPitchEnvSustain(float level) { pitchEnvSustain_ = level; }
    void setPitchEnvRelease(float ms) { pitchEnvRelease_ = ms; }
    void setPitchEnvAmount(float a) { pitchEnvAmount_ = a; }

    // LFO 1
    void setLfo1Waveform(int w) { lfo1_.setWaveform(w); }
    void setLfo1Rate(float hz) { lfo1_.setRate(hz); }
    void setLfo1Depth(float d) { lfo1_.setDepth(d); }
    void setLfo1Target(int t) { lfo1_.setTarget(t); }
    void setLfo1FadeIn(float s) { lfo1_.setFadeIn(s); }
    void setLfo1TempoSync(bool e) { lfo1_.setTempoSync(e); }
    void setLfo1TempoDivision(int d) { lfo1_.setTempoNoteDivision(d); }

    // LFO 2
    void setLfo2Waveform(int w) { lfo2_.setWaveform(w); }
    void setLfo2Rate(float hz) { lfo2_.setRate(hz); }
    void setLfo2Depth(float d) { lfo2_.setDepth(d); }
    void setLfo2Target(int t) { lfo2_.setTarget(t); }
    void setLfo2FadeIn(float s) { lfo2_.setFadeIn(s); }
    void setLfo2TempoSync(bool e) { lfo2_.setTempoSync(e); }
    void setLfo2TempoDivision(int d) { lfo2_.setTempoNoteDivision(d); }

    // FX Engine — access to the multi-FX slot architecture
    FxEngine& fxEngine() { return fxEngine_; }
    const FxEngine& fxEngine() const { return fxEngine_; }

    // Legacy FX setters — forward to the legacy fx slot (slot 0)
    void setChorusEnabled(bool e);
    void setChorusRate(float hz);
    void setChorusDepth(float d);
    void setChorusMix(float m);

    void setDelayEnabled(bool e);
    void setDelayTime(float ms);
    void setDelayFeedback(float fb);
    void setDelayMix(float m);

    void setReverbEnabled(bool e);
    void setReverbSize(float s);
    void setReverbDamping(float d);
    void setReverbMix(float m);

    void setPhaserEnabled(bool e);
    void setPhaserRate(float hz);
    void setPhaserDepth(float d);
    void setPhaserFeedback(float fb);
    void setPhaserMix(float m);

    void setFlangerEnabled(bool e);
    void setFlangerRate(float hz);
    void setFlangerDepth(float d);
    void setFlangerFeedback(float fb);
    void setFlangerMix(float m);

    void setCompressorEnabled(bool e);
    void setCompressorThreshold(float t);
    void setCompressorRatio(float r);
    void setCompressorAttack(float a);
    void setCompressorRelease(float r);
    void setCompressorMakeupGain(float g);

    void setDriveEnabled(bool e);
    void setDriveAmount(float a);
    void setDriveType(int t);

    // Master
    void setMasterVolume(float vol) { masterVolume_ = vol; }
    int getActiveVoiceCount() const { return allocator_.activeVoiceCount(); }

    // CPU profiling — returns % of real-time budget used (0.0–1.0+)
    float getCpuLoad() const { return cpuLoad_; }
    void resetCpuLoad() { cpuLoad_ = 0.0f; cpuLoadAlpha_ = 0.0f; }

    // Preset
    int loadPreset(const char* path);
    int savePreset(const char* path) const;

    // Info
    const char* getName() const { return "OpenAmp Synth Engine"; }
    const char* getVersion() const { return "2.0.0"; }

private:
    double sampleRate_;
    uint32_t blockSize_;

    // Lock-free parameter queue (UI thread -> audio thread)
    ParamQueue paramQueue_;

    Oscillator osc1_;
    Oscillator osc2_;
    float oscMix_ = 0.5f;

    StateVariableFilter filter_;
    float ampAttack_ = 10.0f;
    float ampDecay_ = 100.0f;
    float ampSustain_ = 0.8f;
    float ampRelease_ = 200.0f;
    float ampDelay_ = 0.0f;
    float ampHold_ = 0.0f;
    int ampAttackCurve_ = 0;
    int ampDecayCurve_ = 0;
    int ampReleaseCurve_ = 0;
    float filterAttack_ = 20.0f;
    float filterDecay_ = 200.0f;
    float filterSustain_ = 0.5f;
    float filterRelease_ = 300.0f;
    float filterDelay_ = 0.0f;
    float filterHold_ = 0.0f;
    int filterAttackCurve_ = 0;
    int filterDecayCurve_ = 0;
    int filterReleaseCurve_ = 0;
    float pitchEnvAttack_ = 10.0f;
    float pitchEnvDecay_ = 100.0f;
    float pitchEnvSustain_ = 0.0f;
    float pitchEnvRelease_ = 100.0f;
    float pitchEnvAmount_ = 0.0f;
    bool lfoPerVoice_ = false;

    LFO lfo1_;
    LFO lfo2_;

    // Multi-FX engine with pluggable slots
    FxEngine fxEngine_;

    float masterVolume_ = 0.8f;

    VoiceAllocator allocator_;

    // Arpeggiator
    Arpeggiator arpeggiator_;

    // Drum Kit — dedicated drum synthesis engine
    DrumKit drumKit_;

    // Public drum API
    DrumKit& drumKit() { return drumKit_; }
    const DrumKit& drumKit() const { return drumKit_; }
    void drumNoteOn(int midiNote, float velocity) { drumKit_.noteOn(midiNote, velocity); }
    void drumNoteOff(int midiNote) { drumKit_.noteOff(midiNote); }
    void setDrumKitPreset(int index) { drumKit_.setKitPreset(index); }
    void setDrumKitLevel(float level) { drumKit_.setLevel(level); }

    // Legacy FX accessor — retrieves the LegacyFxProcessor from slot 0
    LegacyFxProcessor* getLegacyFx() const;

    // Legacy FX slot initialization — creates and assigns LegacyFxProcessor to slot 0
    void initLegacyFxSlot();

    // Factory — creates an FxProcessor from a type ID
    FxProcessor* createFxProcessor(int fxTypeId);

    // CPU profiling
    mutable float cpuLoad_ = 0.0f;
    mutable float cpuLoadAlpha_ = 0.0f;

    template<typename T>
    static T clamp(T v, T lo, T hi) { return v < lo ? lo : (v > hi ? hi : v); }

    void drainQueue();
    void applyParam(const ParamQueue::Entry& e);
};

} // namespace openamp
