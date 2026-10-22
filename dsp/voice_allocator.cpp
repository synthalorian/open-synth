#include "voice_allocator.h"
#include <algorithm>

namespace opensynth {

VoiceAllocator::VoiceAllocator() {
    for (auto& v : voices_) {
        v.reset();
        v.physicalModel.init(48000.0, 4096);
    }
}

void VoiceAllocator::setSampleRate(double sampleRate) {
    stealFadeSamples_ = std::max(1, static_cast<int>(sampleRate * 0.003 + 0.5));
}

void VoiceAllocator::startPendingNote(Voice& v) {
    if (!v.hasPending) return;
    const int note = v.pendingNote;
    const float vel = v.pendingVelocity;
    const int part = v.pendingPart;
    const int mpeChannel = v.pendingMpeChannel;
    const bool released = v.pendingReleased;
    const bool sustained = v.pendingSustained;
    v.noteOn(note, vel);
    v.partIndex = part;
    if (mpeChannel >= 0) {
        v.mpe.mpeEnabled = true;
        v.mpe.mpeNoteChannel = mpeChannel;
    }
    if (sustained) {
        v.sustained = true;
    } else if (released) {
        v.noteOff();
    }
}

Voice* VoiceAllocator::firstPendingOrZero() {
    for (auto& v : voices_) {
        if (v.hasPending) return &v;
    }
    return &voices_[0];
}

Voice* VoiceAllocator::noteOn(int midiNote, float velocity, int partIndex, int mpeChannel) {
    // A note already waiting on a steal fade: just update its velocity.
    for (auto& v : voices_) {
        if (v.hasPending && v.pendingNote == midiNote && v.pendingPart == partIndex &&
            (mpeChannel < 0 || v.pendingMpeChannel == mpeChannel)) {
            v.pendingVelocity = std::clamp(velocity, 0.0f, 1.0f);
            v.pendingReleased = false;
            v.pendingSustained = false;
            return &v;
        }
    }
    // In MPE mode, check if note already active on this exact channel
    if (mpeChannel >= 0) {
        for (auto& v : voices_) {
            if (stealable(v) && v.midiNote == midiNote && v.mpe.mpeNoteChannel == mpeChannel) {
                v.retrigger(midiNote, velocity);
                v.startOrder = ++noteCounter_;
                v.partIndex = partIndex;
                v.mpe.mpeNoteChannel = mpeChannel;
                return &v;
            }
        }
    } else {
        // Check if note already active on this part — retrigger
        for (auto& v : voices_) {
            if (stealable(v) && v.midiNote == midiNote && v.partIndex == partIndex) {
                v.retrigger(midiNote, velocity);
                v.startOrder = ++noteCounter_;
                v.partIndex = partIndex;
                return &v;
            }
        }
    }

    // Find free voice
    int idx = findFreeVoice();
    if (idx < 0) {
        Voice* stolen = stealVoice();
        stolen->startOrder = ++noteCounter_;
        if (stolen->active) {
            // Fade the old note out; the engine starts the new one when the
            // fade completes (see startPendingNote).
            stolen->beginSteal(midiNote, std::clamp(velocity, 0.0f, 1.0f), partIndex,
                               mpeChannel, stealFadeSamples_);
            return stolen;
        }
        stolen->noteOn(midiNote, velocity);
        stolen->partIndex = partIndex;
        if (mpeChannel >= 0) {
            stolen->mpe.mpeEnabled = true;
            stolen->mpe.mpeNoteChannel = mpeChannel;
        }
        return stolen;
    }

    voices_[idx].noteOn(midiNote, velocity);
    voices_[idx].startOrder = ++noteCounter_;
    voices_[idx].partIndex = partIndex;
    if (mpeChannel >= 0) {
        voices_[idx].mpe.mpeEnabled = true;
        voices_[idx].mpe.mpeNoteChannel = mpeChannel;
    }
    return &voices_[idx];
}

void VoiceAllocator::noteOff(int midiNote, int partIndex, int mpeChannel) {
    // A note still waiting for its steal fade is released once it starts.
    for (auto& v : voices_) {
        if (v.hasPending && v.pendingNote == midiNote) {
            if (partIndex >= 0 && v.pendingPart != partIndex) continue;
            if (mpeChannel >= 0 && v.pendingMpeChannel != mpeChannel) continue;
            if (sustain_) v.pendingSustained = true;
            else v.pendingReleased = true;
            return;
        }
    }
    for (auto& v : voices_) {
        // The old note of a voice being stolen is already fading out.
        if (stealable(v) && v.midiNote == midiNote) {
            if (partIndex >= 0 && v.partIndex != partIndex) continue;
            if (mpeChannel >= 0 && v.mpe.mpeNoteChannel != mpeChannel) continue;
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
        if (v.hasPending) {
            if (partIndex >= 0 && v.pendingPart != partIndex) continue;
            v.pendingReleased = true;
            v.pendingSustained = false;
            continue;
        }
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
            if (v.hasPending && v.pendingSustained) {
                v.pendingSustained = false;
                v.pendingReleased = true;
            } else if (stealable(v) && v.sustained) {
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
    // Prefer the oldest voice already in release, then the oldest active one.
    Voice* best = nullptr;
    for (auto& v : voices_) {
        if (releasing(v) && (!best || v.startOrder < best->startOrder)) best = &v;
    }
    if (best) return best;
    for (auto& v : voices_) {
        if (stealable(v) && (!best || v.startOrder < best->startOrder)) best = &v;
    }
    return best ? best : firstPendingOrZero();
}

Voice* VoiceAllocator::stealLowestVoice() {
    Voice* best = nullptr;
    int lowestNote = 128;
    // Prefer voices in release
    for (auto& v : voices_) {
        if (releasing(v)) {
            if (v.midiNote < lowestNote) {
                lowestNote = v.midiNote;
                best = &v;
            }
        }
    }
    if (best) return best;
    // Fall back: lowest active note
    for (auto& v : voices_) {
        if (stealable(v) && v.midiNote < lowestNote) {
            lowestNote = v.midiNote;
            best = &v;
        }
    }
    return best ? best : firstPendingOrZero();
}

Voice* VoiceAllocator::stealHighestVoice() {
    Voice* best = nullptr;
    int highestNote = -1;
    // Prefer voices in release
    for (auto& v : voices_) {
        if (releasing(v)) {
            if (v.midiNote > highestNote) {
                highestNote = v.midiNote;
                best = &v;
            }
        }
    }
    if (best) return best;
    // Fall back: highest active note
    for (auto& v : voices_) {
        if (stealable(v) && v.midiNote > highestNote) {
            highestNote = v.midiNote;
            best = &v;
        }
    }
    return best ? best : firstPendingOrZero();
}

Voice* VoiceAllocator::stealRoundRobin() {
    // Cycle through voices evenly; prefer ones in release first.
    for (int i = 0; i < MAX_VOICES; i++) {
        int idx = (roundRobinNext_ + i) % MAX_VOICES;
        if (releasing(voices_[idx])) {
            roundRobinNext_ = (idx + 1) % MAX_VOICES;
            return &voices_[idx];
        }
    }
    // Fall back: any active voice
    for (int i = 0; i < MAX_VOICES; i++) {
        int idx = (roundRobinNext_ + i) % MAX_VOICES;
        if (stealable(voices_[idx])) {
            roundRobinNext_ = (idx + 1) % MAX_VOICES;
            return &voices_[idx];
        }
    }
    roundRobinNext_ = 0;
    return firstPendingOrZero();
}

Voice* VoiceAllocator::stealQuietestVoice() {
    Voice* best = nullptr;
    float quietestLevel = 2.0f;
    // Prefer voices in release (they're already quiet)
    for (auto& v : voices_) {
        if (releasing(v)) {
            return &v; // Any releasing voice is "quietest"
        }
    }
    // Fall back: lowest velocity * amplitude product
    for (auto& v : voices_) {
        if (stealable(v)) {
            float loudness = v.velocity; // approximate
            if (loudness < quietestLevel) {
                quietestLevel = loudness;
                best = &v;
            }
        }
    }
    return best ? best : firstPendingOrZero();
}

} // namespace opensynth
