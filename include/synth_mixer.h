#pragma once
#include <cstdint>
#include <vector>
#include "synth_engine.h"
#include "audio_buffer.h"

namespace opensynth {

/// Wraps two SynthEngine instances (Zone A and Zone B) and mixes their
/// audio outputs together with per-zone volume control.
///
/// The audio stream binds to this pair instead of a single engine.
/// Note routing is handled externally (the Dart keyboard_split provider
/// sends note-on/off events to the appropriate engine).
class SynthEnginePair {
public:
    SynthEnginePair(double sampleRate, uint32_t blockSize);
    ~SynthEnginePair();

    // No copy
    SynthEnginePair(const SynthEnginePair&) = delete;
    SynthEnginePair& operator=(const SynthEnginePair&) = delete;

    /// Process both engines and mix their outputs into [output].
    void process(AudioBuffer& output);

    /// Access individual engines for note routing.
    SynthEngine& engineA() { return engineA_; }
    SynthEngine& engineB() { return engineB_; }

    /// Per-zone volume (0.0–1.0). These are applied during mixdown.
    void setMixA(float mix) { mixA_ = mix; }
    void setMixB(float mix) { mixB_ = mix; }
    float mixA() const { return mixA_; }
    float mixB() const { return mixB_; }

    /// Reset both engines.
    void reset();

    /// CPU load from engine A (primary voice tracking).
    float getCpuLoad() const { return engineA_.getCpuLoad(); }

    /// Total active voices across both engines.
    int getActiveVoiceCount() const {
        return engineA_.getActiveVoiceCount() + engineB_.getActiveVoiceCount();
    }

    /// Count voices in each zone.
    int getZoneAVoiceCount() const { return engineA_.getActiveVoiceCount(); }
    int getZoneBVoiceCount() const { return engineB_.getActiveVoiceCount(); }

private:
    SynthEngine engineA_;
    SynthEngine engineB_;

    // Internal temporary buffer for engine B's output
    AudioBuffer tempBuffer_;
    bool tempBufferAllocated_ = false;

    float mixA_ = 1.0f;
    float mixB_ = 1.0f;

    // RAII storage for the temp buffer — no manual free needed
    std::vector<float> tempStorage_;
};

} // namespace opensynth
