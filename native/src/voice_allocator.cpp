#include "voice_allocator.h"
#include <algorithm>

namespace openamp {

VoiceAllocator::VoiceAllocator() {
    for (auto& v : voices_) v.reset();
}

Voice* VoiceAllocator::noteOn(int midiNote, float velocity) {
    // Check if note already active — retrigger
    for (auto& v : voices_) {
        if (v.active && v.midiNote == midiNote) {
            v.noteOn(midiNote, velocity);
            return &v;
        }
    }

    // Find free voice
    int idx = findFreeVoice();
    if (idx < 0) {
        Voice* stolen = stealOldestVoice();
        stolen->noteOn(midiNote, velocity);
        return stolen;
    }

    voices_[idx].noteOn(midiNote, velocity);
    return &voices_[idx];
}

void VoiceAllocator::noteOff(int midiNote) {
    for (auto& v : voices_) {
        if (v.active && v.midiNote == midiNote) {
            if (sustain_) {
                v.sustained = true;
            } else {
                v.noteOff();
            }
            return;
        }
    }
}

void VoiceAllocator::allNotesOff() {
    for (auto& v : voices_) {
        if (v.active) v.noteOff();
    }
    sustain_ = false;
}

void VoiceAllocator::sustain(bool on) {
    sustain_ = on;
    if (!on) {
        // Release all sustained notes
        for (auto& v : voices_) {
            if (v.active && v.sustained) {
                v.noteOff();
            }
        }
    }
}

int VoiceAllocator::activeVoiceCount() const {
    int count = 0;
    for (const auto& v : voices_) {
        if (v.active) count++;
    }
    return count;
}

int VoiceAllocator::findFreeVoice() const {
    for (int i = 0; i < MAX_VOICES; i++) {
        if (!voices_[i].active) return i;
    }
    return -1;
}

Voice* VoiceAllocator::stealOldestVoice() {
    // Simple: steal the first voice that's in release or just the first
    for (auto& v : voices_) {
        if (v.ampEnv.state() == Envelope::RELEASE) {
            return &v;
        }
    }
    return &voices_[0];
}

} // namespace openamp
