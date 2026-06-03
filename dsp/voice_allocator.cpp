#include "voice_allocator.h"
#include <algorithm>

namespace opensynth {

VoiceAllocator::VoiceAllocator() {
    for (auto& v : voices_) {
        v.reset();
        v.physicalModel.init(48000.0, 4096);
    }
}

Voice* VoiceAllocator::noteOn(int midiNote, float velocity, int partIndex) {
    // Check if note already active on this part — retrigger
    for (auto& v : voices_) {
        if (v.active && v.midiNote == midiNote && v.partIndex == partIndex) {
            v.noteOn(midiNote, velocity);
            v.partIndex = partIndex;
            return &v;
        }
    }

    // Find free voice
    int idx = findFreeVoice();
    if (idx < 0) {
        Voice* stolen = stealVoice();
        stolen->noteOn(midiNote, velocity);
        stolen->partIndex = partIndex;
        return stolen;
    }

    voices_[idx].noteOn(midiNote, velocity);
    voices_[idx].partIndex = partIndex;
    return &voices_[idx];
}

void VoiceAllocator::noteOff(int midiNote, int partIndex) {
    for (auto& v : voices_) {
        if (v.active && v.midiNote == midiNote) {
            if (partIndex >= 0 && v.partIndex != partIndex) continue;
            if (sustain_) {
                v.sustained = true;
            } else {
                v.noteOff();
            }
            return;
        }
    }
}

void VoiceAllocator::allNotesOff(int partIndex) {
    for (auto& v : voices_) {
        if (v.active) {
            if (partIndex >= 0 && v.partIndex != partIndex) continue;
            v.noteOff();
        }
    }
    if (partIndex < 0) sustain_ = false;
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

} // namespace opensynth
