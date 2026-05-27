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

namespace openamp {

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

    // Osc 2
    void setOsc2Waveform(int w) { osc2_.setWaveform(w); }
    void setOsc2Octave(int oct) { osc2_.setOctave(oct); }
    void setOsc2Detune(float cents) { osc2_.setDetune(cents); }
    void setOsc2PulseWidth(float pw) { osc2_.setPulseWidth(pw); }
    void setOsc2Volume(float vol) { osc2_.setVolume(vol); }
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

    // Amp envelope
    void setAmpAttack(float ms) { ampAttack_ = ms; }
    void setAmpDecay(float ms) { ampDecay_ = ms; }
    void setAmpSustain(float level) { ampSustain_ = level; }
    void setAmpRelease(float ms) { ampRelease_ = ms; }

    // Filter envelope
    void setFilterAttack(float ms) { filterAttack_ = ms; }
    void setFilterDecay(float ms) { filterDecay_ = ms; }
    void setFilterSustain(float level) { filterSustain_ = level; }
    void setFilterRelease(float ms) { filterRelease_ = ms; }

    // LFO 1
    void setLfo1Waveform(int w) { lfo1_.setWaveform(w); }
    void setLfo1Rate(float hz) { lfo1_.setRate(hz); }
    void setLfo1Depth(float d) { lfo1_.setDepth(d); }
    void setLfo1Target(int t) { lfo1_.setTarget(t); }

    // LFO 2
    void setLfo2Waveform(int w) { lfo2_.setWaveform(w); }
    void setLfo2Rate(float hz) { lfo2_.setRate(hz); }
    void setLfo2Depth(float d) { lfo2_.setDepth(d); }
    void setLfo2Target(int t) { lfo2_.setTarget(t); }

    // FX: Chorus
    void setChorusEnabled(bool e) { chorusEnabled_ = e; }
    void setChorusRate(float hz) { chorusRate_ = hz; }
    void setChorusDepth(float d) { chorusDepth_ = d; }
    void setChorusMix(float m) { chorusMix_ = m; }

    // FX: Delay
    void setDelayEnabled(bool e) { delayEnabled_ = e; }
    void setDelayTime(float ms) { delayTimeMs_ = ms; }
    void setDelayFeedback(float fb) { delayFeedback_ = fb; }
    void setDelayMix(float m) { delayMix_ = m; }

    // FX: Reverb
    void setReverbEnabled(bool e) { reverbEnabled_ = e; }
    void setReverbSize(float s) { reverbSize_ = s; }
    void setReverbDamping(float d) { reverbDamping_ = d; }
    void setReverbMix(float m) { reverbMix_ = m; }

    // FX: Phaser
    void setPhaserEnabled(bool e) { phaserEnabled_ = e; }
    void setPhaserRate(float hz) { phaserRate_ = hz; }
    void setPhaserDepth(float d) { phaserDepth_ = d; }
    void setPhaserFeedback(float fb) { phaserFeedback_ = fb; }
    void setPhaserMix(float m) { phaserMix_ = m; }

    // FX: Flanger
    void setFlangerEnabled(bool e) { flangerEnabled_ = e; }
    void setFlangerRate(float hz) { flangerRate_ = hz; }
    void setFlangerDepth(float d) { flangerDepth_ = d; }
    void setFlangerFeedback(float fb) { flangerFeedback_ = fb; }
    void setFlangerMix(float m) { flangerMix_ = m; }

    // FX: Compressor
    void setCompressorEnabled(bool e) { compressorEnabled_ = e; }
    void setCompressorThreshold(float t) { compressorThreshold_ = t; }
    void setCompressorRatio(float r) { compressorRatio_ = r; }
    void setCompressorAttack(float a) { compressorAttack_ = a; }
    void setCompressorRelease(float r) { compressorRelease_ = r; }
    void setCompressorMakeupGain(float g) { compressorMakeupGain_ = g; }

    // FX: Drive
    void setDriveEnabled(bool e) { driveEnabled_ = e; }
    void setDriveAmount(float a) { driveAmount_ = a; }
    void setDriveType(int t) { driveType_ = t; }

    // Master
    void setMasterVolume(float vol) { masterVolume_ = vol; }
    int getActiveVoiceCount() const { return allocator_.activeVoiceCount(); }

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
    float filterAttack_ = 20.0f;
    float filterDecay_ = 200.0f;
    float filterSustain_ = 0.5f;
    float filterRelease_ = 300.0f;

    LFO lfo1_;
    LFO lfo2_;

    bool chorusEnabled_ = false;
    float chorusRate_ = 0.5f;
    float chorusDepth_ = 0.5f;
    float chorusMix_ = 0.3f;

    bool delayEnabled_ = false;
    float delayTimeMs_ = 300.0f;
    float delayFeedback_ = 0.3f;
    float delayMix_ = 0.3f;

    bool reverbEnabled_ = false;
    float reverbSize_ = 0.5f;
    float reverbDamping_ = 0.5f;
    float reverbMix_ = 0.3f;

    bool phaserEnabled_ = false;
    float phaserRate_ = 0.5f;
    float phaserDepth_ = 0.3f;
    float phaserFeedback_ = 0.5f;
    float phaserMix_ = 0.3f;

    bool driveEnabled_ = false;
    float driveAmount_ = 0.5f;
    int driveType_ = 0;

    float masterVolume_ = 0.8f;

    VoiceAllocator allocator_;

    // Arpeggiator
    Arpeggiator arpeggiator_;

    // Delay buffer
    static constexpr int MAX_DELAY_SAMPLES = 48000 * 2; // 2 seconds at 48k
    float* delayBuffer_ = nullptr;
    uint32_t delayWritePos_ = 0;
    uint32_t delayBufferSize_ = 0;

    // Reverb state (simple Schroder)
    float reverbState_[4] = {};
    float reverbDelay_[4][4800] = {}; // ~100ms at 48k
    uint32_t reverbPos_[4] = {};

    // Flanger (stereo — separate L/R delay lines)
    bool flangerEnabled_ = false;
    float flangerRate_ = 0.3f;
    float flangerDepth_ = 0.6f;
    float flangerFeedback_ = 0.4f;
    float flangerMix_ = 0.5f;
    float flangerPhase_ = 0.0f;
    uint32_t flangerWritePos_ = 0;
    static constexpr int FLANGER_DELAY_SAMPLES = 2048;
    float flangerDelayL_[FLANGER_DELAY_SAMPLES] = {};
    float flangerDelayR_[FLANGER_DELAY_SAMPLES] = {};

    // Compressor
    bool compressorEnabled_ = false;
    float compressorThreshold_ = 0.5f;
    float compressorRatio_ = 4.0f;
    float compressorAttack_ = 10.0f;
    float compressorRelease_ = 100.0f;
    float compressorMakeupGain_ = 0.0f;
    float compressorEnvelope_ = 0.0f;

    // Chorus / phaser state (per-engine, not static)
    float chorusPhase_ = 0.0f;
    float phaserPhase_ = 0.0f;
    float phaserState1L_ = 0.0f, phaserState2L_ = 0.0f;
    float phaserState1R_ = 0.0f, phaserState2R_ = 0.0f;

    template<typename T>
    static T clamp(T v, T lo, T hi) { return v < lo ? lo : (v > hi ? hi : v); }

    void applyEffects(float& left, float& right);
    void updateDelayBufferSize();
    float applyDistortion(float sample);
    void drainQueue();
    void applyParam(const ParamQueue::Entry& e);
};

} // namespace openamp
