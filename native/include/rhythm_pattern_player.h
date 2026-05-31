#pragma once
#include <cstdint>
#include <vector>
#include <array>
#include <atomic>

namespace openamp {

class DrumKit;

// ── Pattern Data Structures ───────────────────────────────────────────────────

/// A single drum hit within a pattern.
struct DrumHit {
    uint8_t note;       // GM2 drum note (e.g. 36=kick, 38=snare)
    uint8_t velocity;   // 0-127
    uint8_t step;       // Position in pattern (0-based 16th notes)
    float   probability; // 0.0-1.0, chance this hit fires (for humanization)
    float   timingShift; // -0.5 to +0.5, micro-timing offset in steps
    float   accent;      // 1.0 = normal, >1.0 = accent, <1.0 = ghost
};

/// A complete drum pattern with metadata.
struct DrumPattern {
    static constexpr int MAX_HITS = 64;
    static constexpr int MAX_STEPS = 64;

    std::array<DrumHit, MAX_HITS> hits;
    int hitCount = 0;
    int steps = 16;           // 16, 32, or 64
    int beatsPerBar = 4;      // 3, 4, 5, 6, 7
    int subdivisions = 4;     // 4 = 16th notes, 3 = triplets, 8 = 32nds
    const char* name = "";
    const char* style = "";
    const char* category = "";
    float defaultTempo = 120.0f;
    float swing = 0.0f;       // 0.0-1.0, even-step delay
};

/// Pattern variation types for song sections.
enum class PatternVariation {
    Intro,
    MainA,
    MainB,
    FillA,
    FillB,
    Ending,
    Count
};

// ── Rhythm Pattern Player ─────────────────────────────────────────────────────

/// Drives the DrumKit with preset patterns, synced to a master tempo.
/// Runs on the audio thread — all state changes are atomic or via param queue.
class RhythmPatternPlayer {
public:
    RhythmPatternPlayer();

    // No copy
    RhythmPatternPlayer(const RhythmPatternPlayer&) = delete;
    RhythmPatternPlayer& operator=(const RhythmPatternPlayer&) = delete;

    // ── Transport ──
    void play();
    void stop();
    bool isPlaying() const { return playing_.load(std::memory_order_acquire); }

    // ── Tempo ──
    void setTempo(float bpm);
    float tempo() const { return tempo_.load(std::memory_order_acquire); }

    // ── Pattern selection ──
    void setPattern(int index);
    void setVariation(PatternVariation var);
    int currentPattern() const { return currentPattern_.load(std::memory_order_acquire); }

    // ── Audio thread process ──
    /// Call this from SynthEngine::process() at block boundaries.
    /// Advances the sequencer and triggers drum hits via the provided DrumKit.
    void process(DrumKit& drumKit, uint32_t numFrames, double sampleRate);

    // ── Step query (for UI) ──
    int currentStep() const { return currentStep_.load(std::memory_order_acquire); }
    int totalSteps() const;

    // ── Pattern library ──
    static const DrumPattern* getPattern(int index);
    static int patternCount();
    static const char* getCategoryName(int categoryIndex);
    static int categoryCount();

    // ── Song mode ──
    void setSongMode(bool enabled) { songMode_ = enabled; }
    bool songMode() const { return songMode_; }
    void nextVariation(); // Auto-advance: Intro -> MainA -> FillA -> MainB -> FillB -> Ending

private:
    std::atomic<bool> playing_{false};
    std::atomic<float> tempo_{120.0f};
    std::atomic<int> currentPattern_{0};
    std::atomic<int> currentStep_{0};
    std::atomic<PatternVariation> currentVariation_{PatternVariation::MainA};

    // Internal timing state (only touched on audio thread)
    double sampleAccumulator_ = 0.0;
    double samplesPerStep_ = 0.0;
    bool songMode_ = false;
    int variationCounter_ = 0; // Bars elapsed in current variation

    void recalcTiming(double sampleRate);
    void triggerStep(DrumKit& drumKit, int step);
    void advanceVariation();
};

} // namespace openamp
