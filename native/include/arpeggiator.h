#pragma once
#include <cstdint>
#include <vector>
#include <algorithm>
#include "voice_allocator.h"

namespace openamp {

class Arpeggiator {
public:
    enum Pattern : int {
        UP = 0,
        DOWN = 1,
        UP_DOWN = 2,
        RANDOM = 3,
        CHORD = 4,
        PATTERN_COUNT
    };

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

    void setPattern(int p) { pattern_ = std::clamp(p, 0, PATTERN_COUNT - 1); }
    int pattern() const { return pattern_; }

    void setOctaveRange(int oct) { octaveRange_ = std::clamp(oct, 1, 4); }
    int octaveRange() const { return octaveRange_; }

    void setGate(float g) { gate_ = std::clamp(g, 0.0f, 1.0f); }
    float gate() const { return gate_; }

    void setResolution(int r) { resolution_ = std::clamp(r, 0, 3); }
    int resolution() const { return resolution_; }

    void noteOn(int midiNote, float velocity);
    void noteOff(int midiNote);
    void allNotesOff();

    /// Called from SynthEngine::process() at block boundaries.
    /// Generates note on/off events into [allocator] based on current pattern
    /// and held notes.
    void process(uint32_t numSamples, double sampleRate, VoiceAllocator& allocator);

    /// Reset internal state (call on transport stop or arpeggiator disable).
    void reset();

    /// Get the current step (0-indexed) for UI display.
    int currentStep() const { return currentStep_; }

private:
    bool enabled_ = false;
    float tempo_ = 120.0f;
    int pattern_ = UP;
    int octaveRange_ = 1;
    float gate_ = 0.5f;
    int resolution_ = SIXTEENTH;

    // Held notes (sorted by pitch for pattern generation)
    std::vector<int> heldNotes_;
    std::vector<float> heldVelocities_;

    // Step state
    int currentStep_ = 0;
    uint64_t samplesSinceStep_ = 0;
    bool noteIsActive_ = false;
    int activeOctave_ = 0;
    int lastPlayedNote_ = -1;
    float lastPlayedVelocity_ = 0.0f;

    // Random state
    mutable unsigned int randomState_ = 42;

    // Internal
    uint32_t samplesPerStep() const;
    uint32_t stepLengthSamples(double sampleRate) const;
    void playStep(VoiceAllocator& allocator);
    void releaseStep(VoiceAllocator& allocator);
    int noteFromPattern() const;
    unsigned int fastRand() const;
};

} // namespace openamp
