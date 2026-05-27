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
        Voice* stolen = stealVoice();
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

Voice* VoiceAllocator::stealVoice() {
    switch (priorityMode_) {
        case VoicePriorityMode::LOWEST_NOTE:  return stealLowestVoice();
        case VoicePriorityMode::HIGHEST_NOTE: return stealHighestVoice();
        case VoicePriorityMode::ROUND_ROBIN:  return stealRoundRobin();
        case VoicePriorityMode::QUIETEST:     return stealQuietestVoice();
        case VoicePriorityMode::LAST_NOTE:
        default:                              return stealOldestVoice();
    }
}

Voice* VoiceAllocator::stealOldestVoice() {
    // Steal the first voice that's in release, or else the first active voice.
    for (auto& v : voices_) {
        if (v.active && v.ampEnv.state() == Envelope::RELEASE) {
            return &v;
        }
    }
    // Fall back to first active voice
    for (auto& v : voices_) {
        if (v.active) return &v;
    }
    return &voices_[0];
}

Voice* VoiceAllocator::stealLowestVoice() {
    Voice* best = nullptr;
    int lowestNote = 128;
    // Prefer voices in release
    for (auto& v : voices_) {
        if (v.active && v.ampEnv.state() == Envelope::RELEASE) {
            if (v.midiNote < lowestNote) {
                lowestNote = v.midiNote;
                best = &v;
            }
        }
    }
    if (best) return best;
    // Fall back: lowest active note
    for (auto& v : voices_) {
        if (v.active && v.midiNote < lowestNote) {
            lowestNote = v.midiNote;
            best = &v;
        }
    }
    return best ? best : &voices_[0];
}

Voice* VoiceAllocator::stealHighestVoice() {
    Voice* best = nullptr;
    int highestNote = -1;
    // Prefer voices in release
    for (auto& v : voices_) {
        if (v.active && v.ampEnv.state() == Envelope::RELEASE) {
            if (v.midiNote > highestNote) {
                highestNote = v.midiNote;
                best = &v;
            }
        }
    }
    if (best) return best;
    // Fall back: highest active note
    for (auto& v : voices_) {
        if (v.active && v.midiNote > highestNote) {
            highestNote = v.midiNote;
            best = &v;
        }
    }
    return best ? best : &voices_[0];
}

Voice* VoiceAllocator::stealRoundRobin() {
    // Cycle through voices evenly; prefer ones in release first.
    for (int i = 0; i < MAX_VOICES; i++) {
        int idx = (roundRobinNext_ + i) % MAX_VOICES;
        if (voices_[idx].active && voices_[idx].ampEnv.state() == Envelope::RELEASE) {
            roundRobinNext_ = (idx + 1) % MAX_VOICES;
            return &voices_[idx];
        }
    }
    // Fall back: any active voice
    for (int i = 0; i < MAX_VOICES; i++) {
        int idx = (roundRobinNext_ + i) % MAX_VOICES;
        if (voices_[idx].active) {
            roundRobinNext_ = (idx + 1) % MAX_VOICES;
            return &voices_[idx];
        }
    }
    roundRobinNext_ = 0;
    return &voices_[0];
}

Voice* VoiceAllocator::stealQuietestVoice() {
    Voice* best = nullptr;
    float quietestLevel = 2.0f;
    // Prefer voices in release (they're already quiet)
    for (auto& v : voices_) {
        if (v.active && v.ampEnv.state() == Envelope::RELEASE) {
            return &v; // Any releasing voice is "quietest"
        }
    }
    // Fall back: lowest velocity * amplitude product
    for (auto& v : voices_) {
        if (v.active) {
            float loudness = v.velocity; // approximate
            if (loudness < quietestLevel) {
                quietestLevel = loudness;
                best = &v;
            }
        }
    }
    return best ? best : &voices_[0];
}

} // namespace openamp
