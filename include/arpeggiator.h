#pragma once
#include <cstdint>
#include <vector>
#include <array>
#include <algorithm>
#include "voice_allocator.h"

namespace opensynth {

/// A single step in a programmable arpeggiator pattern.
/// stepValue: 0=rest, 1=note+1 (first held note), 2=note+2, etc.
/// velocity: 0.0-1.0 multiplier for this step.
/// gate: 0.0-1.0 override for this step (1.0 = use global gate).
struct ArpStep {
    uint8_t stepValue = 1;  // 0=rest, 1-16=note index
    float velocity = 1.0f;
    float gate = 1.0f;      // 1.0 = use global gate
};

/// A programmable 16-step arpeggiator pattern.
struct ArpPattern {
    char name[32] = "User";
    std::array<ArpStep, 16> steps;
    int length = 16;  // 1-16
};

class Arpeggiator {
public:
    // Built-in patterns (match original enum for backward compat)
    enum Pattern : int {
        UP = 0,
        DOWN = 1,
        UP_DOWN = 2,
        RANDOM = 3,
        CHORD = 4,
        // New built-ins
        DOWN_UP,
        PLAYED_ORDER,
        PING_PONG,
        PING_PONG_REV,
        TWO_OCTAVE_UP,
        TWO_OCTAVE_DOWN,
        TWO_OCTAVE_UP_DOWN,
        THREE_OCTAVE_UP,
        THREE_OCTAVE_DOWN,
        THREE_OCTAVE_UP_DOWN,
        OCTAVE_JUMP_UP,
        OCTAVE_JUMP_DOWN,
        FIFTH_UP,
        FIFTH_DOWN,
        FIFTH_UP_DOWN,
        PATTERN_COUNT_BUILTIN
    };

    // Preset pattern banks
    static constexpr int NUM_PRESET_PATTERNS = 128;
    static constexpr int NUM_USER_PATTERNS = 32;
    static constexpr int TOTAL_PATTERNS = NUM_PRESET_PATTERNS + NUM_USER_PATTERNS;

    enum Resolution : int {
        QUARTER = 0,
        EIGHTH = 1,
        SIXTEENTH = 2,
        THIRTYSECOND = 3
    };

    Arpeggiator();

    void setEnabled(bool e) { enabled_ = e; }
    bool enabled() const { return enabled_; }

    void setTempo(float bpm) { tempo_ = std::clamp(bpm, 20.0f, 300.0f); }
    float tempo() const { return tempo_; }

    void setPattern(int p) { pattern_ = std::clamp(p, 0, TOTAL_PATTERNS - 1); }
    int pattern() const { return pattern_; }

    void setOctaveRange(int oct) { octaveRange_ = std::clamp(oct, 1, 4); }
    int octaveRange() const { return octaveRange_; }

    void setGate(float g) { gate_ = std::clamp(g, 0.0f, 1.0f); }
    float gate() const { return gate_; }

    void setSwing(float s) { swing_ = std::clamp(s, 0.0f, 1.0f); }
    float swing() const { return swing_; }

    void setHold(bool h) { hold_ = h; if (!h) heldNotesLocked_ = false; }
    bool hold() const { return hold_; }

    void setResolution(int r) { resolution_ = std::clamp(r, 0, 3); }
    int resolution() const { return resolution_; }

    void noteOn(int midiNote, float velocity);
    void noteOff(int midiNote);
    void allNotesOff();

    /// Called from SynthEngine::process() at block boundaries.
    void process(uint32_t numSamples, double sampleRate, VoiceAllocator& allocator);

    /// Reset internal state.
    void reset();

    /// Get the current step (0-indexed) for UI display.
    int currentStep() const { return currentStep_; }

    /// Get total steps in one arp cycle.
    int totalSteps() const;

    // ── Programmable pattern access ──
    ArpPattern& userPattern(int index) { return userPatterns_[index]; }
    const ArpPattern& userPattern(int index) const { return userPatterns_[index]; }

    /// Get pattern name for display.
    const char* patternName(int index) const;

    /// Is this a programmable (user) pattern?
    bool isUserPattern(int index) const { return index >= NUM_PRESET_PATTERNS; }

private:
    bool enabled_ = false;
    float tempo_ = 120.0f;
    int pattern_ = UP;
    int octaveRange_ = 1;
    float gate_ = 0.5f;
    int resolution_ = SIXTEENTH;

    float swing_ = 0.0f;

    bool hold_ = false;
    bool heldNotesLocked_ = false;

    std::vector<int> heldNotes_;
    std::vector<float> heldVelocities_;

    int currentStep_ = 0;
    uint64_t samplesSinceStep_ = 0;
    bool noteIsActive_ = false;
    int activeOctave_ = 0;
    int lastPlayedNote_ = -1;
    float lastPlayedVelocity_ = 0.0f;

    mutable unsigned int randomState_ = 42;

    // User-programmable patterns
    std::array<ArpPattern, NUM_USER_PATTERNS> userPatterns_;

    uint32_t samplesPerStep() const;
    uint32_t stepLengthSamples(double sampleRate) const;
    void playStep(VoiceAllocator& allocator);
    void releaseStep(VoiceAllocator& allocator);
    int noteFromPattern() const;
    int noteFromProgrammablePattern() const;
    unsigned int fastRand() const;

    void initPresetPatterns();
    int noteFromBuiltinPattern() const;
};

} // namespace opensynth