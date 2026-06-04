#pragma once
#include "sample_stream.h"
#include <juce_audio_basics/juce_audio_basics.h>
#include <vector>
#include <memory>
#include <string>
#include <array>
#include <atomic>
#include <thread>
#include <future>
#include <mutex>

namespace opensynth {

// ── Sample Player / ROMpler Layer ────────────────────────────────────────────
//
// A lightweight sample playback engine for adding real instrument recordings
// (piano multisamples, orchestral stabs, vocal chops) on top of the synth.
//
// Features:
//   - WAV/AIFF file loading via JUCE AudioFormatManager
//   - Disk streaming for large samples (memory-mapped with preload cache)
//   - Multi-sample key mapping (one sample per zone or full keyboard stretch)
//   - Pitch-shifted playback with linear interpolation
//   - ADSR envelope per voice
//   - Velocity layers (up to 4 per key zone)
//   - Loop points for sustained sounds
//   - Async sample preload on preset load
//   - Block-based processing for efficiency
//
// This is intentionally simple — not a full Kontakt competitor, but enough
// to layer a realistic piano sample under the subtractive synth for hybrid sounds.

enum class VelocityLayer {
    Soft = 0,    // 0-50
    Medium,      // 51-90
    Loud,        // 91-127
    Count
};

struct SampleZone {
    int rootNote = 60;           // MIDI note the sample was recorded at
    int minNote = 0;             // Lowest note this zone covers
    int maxNote = 127;           // Highest note this zone covers
    float minVelocity = 0.0f;    // Velocity range for this layer (0.0-1.0 normalized)
    float maxVelocity = 1.0f;
    bool loopEnabled = false;
    int loopStart = 0;
    int loopEnd = 0;
    int crossfadeSamples = 256; // Crossfade length for smooth looping

    // Velocity layers: up to 3 streams per zone (soft/medium/loud)
    // Index by static_cast<int>(VelocityLayer)
    std::array<std::shared_ptr<SampleStream>, static_cast<int>(VelocityLayer::Count)> streams;
    double sampleRate = 48000.0;

    // Round-robin group and streams (up to 8 alternates)
    int rrGroup = 0;
    std::array<std::shared_ptr<SampleStream>, 8> rrStreams;

    // Start offset (in samples) and randomization (0-1 fraction of total samples)
    int startOffset = 0;
    float startOffsetRandom = 0.0f;

    // Release sample: triggered on note-off, plays once with no loop
    bool isReleaseSample = false;
};

struct SampleVoice {
    bool active = false;
    int midiNote = 60;
    float velocity = 1.0f;
    double position = 0.0;       // Fractional sample position
    double pitchRatio = 1.0;     // Playback speed for pitch shift
    const SampleZone* zone = nullptr;

    // Crossfade looping state
    bool inCrossfade = false;
    double crossfadePos = 0.0;   // Position in crossfade zone (0..crossfadeSamples)
    double loopStartPos = 0.0;   // Where to jump back to

    // Simple ADSR
    float amp = 0.0f;
    float ampEnv = 0.0f;
    enum { ATTACK, DECAY, SUSTAIN, RELEASE, IDLE } envState = IDLE;
    float attackRate = 0.01f;
    float decayRate = 0.001f;
    float sustainLevel = 1.0f;
    float releaseRate = 0.005f;

    // Per-voice anti-aliasing filter state (was static — thread unsafe)
    float aaStateL = 0.0f;
    float aaStateR = 0.0f;

    // Voice age for oldest-first stealing
    uint32_t voiceAge = 0;
    uint32_t startFrame = 0;

    // Round-robin stream index override (-1 = use zone default streams)
    int rrStreamIndex = -1;

    void noteOn(int note, float vel, const SampleZone* z, double sr);
    void noteOff();
    void reset();

    // Process a single sample (mono mix). Kept for backward compat.
    float process(double sampleRate);

    // Process a block of samples into stereo output buffers.
    // 'numFrames' <= 512 typical. Returns number of frames written.
    int processBlock(float* outL, float* outR, int numFrames, double sampleRate, float pitchBendSemitones = 0.0f);
};

class SamplePlayer {
public:
    static constexpr int MAX_VOICES = 16;

    SamplePlayer();
    ~SamplePlayer() = default;

    // Load a single sample file into a zone (backward compat)
    bool loadSample(const std::string& path, int rootNote, int minNote, int maxNote);

    // Load multiple zones from a directory or JSON manifest
    bool loadMultiSample(const std::string& manifestPath);

    // Add a zone programmatically (used by loadMultiSample)
    bool addZone(const SampleZone& zone);

    // Clear all zones
    void clear();

    // MIDI
    void noteOn(int midiNote, float velocity);
    void noteOff(int midiNote);
    void allNotesOff();

    // Audio
    void prepare(double sampleRate);

    // Legacy per-sample process (inefficient, kept for compat)
    [[deprecated("Use processBlock instead")]]
    void process(float& left, float& right, int numFrames);

    // Block-based process: render into a stereo buffer.
    // 'numFrames' is the block size. Caller must ensure buffer is large enough.
    void processBlock(float* outL, float* outR, int numFrames);

    // Mix level (0-1) into the synth output
    void setMixLevel(float level) { mixLevel_ = level; }
    float getMixLevel() const { return mixLevel_; }

    // Global pitch bend in semitones (+/- range typical)
    void setPitchBend(float semitones) { pitchBend_ = semitones; }
    float getPitchBend() const { return pitchBend_; }

    // Global ADSR
    void setAttack(float ms);
    void setDecay(float ms);
    void setSustain(float level);
    void setRelease(float ms);

    // Stream buffer size configuration (applies to future loads)
    void setStreamBufferSize(int size) { streamBufferSize_ = size; }
    int getStreamBufferSize() const { return streamBufferSize_; }

    // Status
    int activeVoiceCount() const;
    int zoneCount() const { return static_cast<int>(zones_.size()); }

    // Zone access for UI
    const std::vector<std::unique_ptr<SampleZone>>& getZones() const { return zones_; }

    // Release zone access for UI
    const std::vector<std::unique_ptr<SampleZone>>& getReleaseZones() const { return releaseZones_; }

    // Add a release zone programmatically
    bool addReleaseZone(const SampleZone& zone);

    // Velocity layer helper
    static VelocityLayer velocityToLayer(float velocity);

    // Async preload: launch background threads to open all zone streams.
    // Call waitForPreload() before playback to ensure readiness.
    void preloadAsync();
    void waitForPreload();
    bool isPreloadComplete() const;

    // Aggregate metrics from all streams
    struct AggregateMetrics {
        double cacheHitRate = 0.0;
        uint64_t underruns = 0;
        uint64_t totalRequests = 0;
    };
    AggregateMetrics getMetrics() const;
    void resetMetrics();

private:
    std::vector<std::unique_ptr<SampleZone>> zones_;
    std::vector<std::unique_ptr<SampleZone>> releaseZones_;
    std::array<SampleVoice, MAX_VOICES> voices_;
    double sampleRate_ = 48000.0;
    float mixLevel_ = 0.0f;
    int streamBufferSize_ = SampleStream::DEFAULT_BUFFER_SIZE;

    // Global envelope params
    float attackMs_ = 10.0f;
    float decayMs_ = 100.0f;
    float sustainLevel_ = 1.0f;
    float releaseMs_ = 200.0f;

    // Global pitch bend (semitones)
    float pitchBend_ = 0.0f;

    // Async preload state
    mutable std::mutex preloadMutex_;
    std::vector<std::future<void>> preloadFutures_;
    mutable bool preloadComplete_ = true;

    // Round-robin index and voice age counter
    int rrIndex_ = 0;
    uint32_t nextVoiceAge_ = 1;

    // Scratch buffers for block-based processing (removes 512-frame stack limit)
    std::vector<float> scratchL_;
    std::vector<float> scratchR_;

    const SampleZone* findZone(int midiNote, float velocity) const;
    const SampleZone* findReleaseZone(int midiNote) const;
    SampleVoice* findFreeVoice();
};

} // namespace opensynth
