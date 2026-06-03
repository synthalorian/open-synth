#pragma once
#include <array>
#include "voice.h"

namespace opensynth {

/// Voice stealing priority mode.
enum class VoicePriorityMode : int {
    LAST_NOTE = 0,     // Steal the oldest note (default, natural)
    LOWEST_NOTE = 1,   // Steal the lowest note
    HIGHEST_NOTE = 2,  // Steal the highest note
    ROUND_ROBIN = 3,   // Cycle through voices evenly
    QUIETEST = 4,      // Steal the quietest voice (lowest velocity * amp level)
};

class VoiceAllocator {
public:
    static constexpr int MAX_VOICES = 64;

    VoiceAllocator();

    Voice* noteOn(int midiNote, float velocity, int partIndex = 0, int mpeChannel = -1);
    void noteOff(int midiNote, int partIndex = -1, int mpeChannel = -1);
    void allNotesOff(int partIndex = -1);
    void sustain(bool on);
    int activeVoiceCount() const;
    Voice* voice(int index) { return &voices_[index]; }
    const Voice* voice(int index) const { return &voices_[index]; }

    /// Set voice stealing priority mode.
    void setPriorityMode(VoicePriorityMode mode) { priorityMode_ = mode; }
    VoicePriorityMode priorityMode() const { return priorityMode_; }

private:
    std::array<Voice, MAX_VOICES> voices_;
    bool sustain_ = false;
    VoicePriorityMode priorityMode_ = VoicePriorityMode::LAST_NOTE;
    int roundRobinNext_ = 0;  // For ROUND_ROBIN mode

    int findFreeVoice() const;
    Voice* stealVoice();
    Voice* stealOldestVoice();     // LAST_NOTE: steal oldest active
    Voice* stealLowestVoice();     // LOWEST_NOTE
    Voice* stealHighestVoice();    // HIGHEST_NOTE
    Voice* stealRoundRobin();      // ROUND_ROBIN
    Voice* stealQuietestVoice();   // QUIETEST
};

} // namespace opensynth
