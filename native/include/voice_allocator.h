#pragma once
#include <array>
#include "voice.h"

namespace openamp {

class VoiceAllocator {
public:
    static constexpr int MAX_VOICES = 64;

    VoiceAllocator();

    Voice* noteOn(int midiNote, float velocity);
    void noteOff(int midiNote);
    void allNotesOff();
    void sustain(bool on);
    int activeVoiceCount() const;
    Voice* voice(int index) { return &voices_[index]; }
    const Voice* voice(int index) const { return &voices_[index]; }

private:
    std::array<Voice, MAX_VOICES> voices_;
    bool sustain_ = false;

    int findFreeVoice() const;
    Voice* stealOldestVoice();
};

} // namespace openamp
