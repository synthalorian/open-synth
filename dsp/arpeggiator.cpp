#include "arpeggiator.h"
#include <cmath>
#include <cstdlib>

namespace opensynth {

Arpeggiator::Arpeggiator() {
    heldNotes_.reserve(32);
    heldVelocities_.reserve(32);
}

void Arpeggiator::noteOn(int midiNote, float velocity) {
    // Don't add duplicates
    for (size_t i = 0; i < heldNotes_.size(); i++) {
        if (heldNotes_[i] == midiNote) {
            heldVelocities_[i] = velocity;
            // Lock held notes when hold mode is active
            if (hold_) heldNotesLocked_ = true;
            return;
        }
    }
    heldNotes_.push_back(midiNote);
    // Sort by pitch ascending
    heldVelocities_.insert(heldVelocities_.begin() + (heldNotes_.size() - 1), velocity);
    // Re-sort velocities to match sorted notes
    std::vector<std::pair<int, float>> pairs;
    for (size_t i = 0; i < heldNotes_.size(); i++) {
        pairs.push_back({heldNotes_[i], heldVelocities_[i]});
    }
    std::sort(pairs.begin(), pairs.end(),
        [](const auto& a, const auto& b) { return a.first < b.first; });
    for (size_t i = 0; i < pairs.size(); i++) {
        heldNotes_[i] = pairs[i].first;
        heldVelocities_[i] = pairs[i].second;
    }
    // Lock held notes when hold mode is active
    if (hold_) heldNotesLocked_ = true;
}

void Arpeggiator::noteOff(int midiNote) {
    // Hold/latch mode: noteOff is a no-op when hold is enabled and notes are locked.
    // Caller must use allNotesOff() to explicitly clear (e.g., on transport stop).
    if (hold_ && heldNotesLocked_) {
        return;
    }
    for (size_t i = 0; i < heldNotes_.size(); i++) {
        if (heldNotes_[i] == midiNote) {
            heldNotes_.erase(heldNotes_.begin() + i);
            heldVelocities_.erase(heldVelocities_.begin() + i);
            return;
        }
    }
}

void Arpeggiator::allNotesOff() {
    heldNotes_.clear();
    heldVelocities_.clear();
    noteIsActive_ = false;
    lastPlayedNote_ = -1;
    heldNotesLocked_ = false;
}

void Arpeggiator::reset() {
    allNotesOff();
    currentStep_ = 0;
    samplesSinceStep_ = 0;
    noteIsActive_ = false;
    activeOctave_ = 0;
    lastPlayedNote_ = -1;
}

uint32_t Arpeggiator::samplesPerStep() const {
    return stepLengthSamples(48000.0); // Will be overridden by process()
}

uint32_t Arpeggiator::stepLengthSamples(double sampleRate) const {
    // Quarter note = 60 / tempo seconds
    double beatSamples = (60.0 / tempo_) * sampleRate;
    switch (resolution_) {
        case QUARTER:       return static_cast<uint32_t>(beatSamples);
        case EIGHTH:        return static_cast<uint32_t>(beatSamples * 0.5);
        case SIXTEENTH:     return static_cast<uint32_t>(beatSamples * 0.25);
        case THIRTYSECOND:  return static_cast<uint32_t>(beatSamples * 0.125);
        default:            return static_cast<uint32_t>(beatSamples * 0.25);
    }
}

void Arpeggiator::process(uint32_t numSamples, double sampleRate, VoiceAllocator& allocator) {
    if (!enabled_ || heldNotes_.empty()) {
        if (noteIsActive_) {
            if (lastPlayedNote_ >= 0) {
                allocator.noteOff(lastPlayedNote_);
            }
            noteIsActive_ = false;
        }
        return;
    }

    uint32_t baseStepSamples = stepLengthSamples(sampleRate);
    if (baseStepSamples < 1) baseStepSamples = 1;

    for (uint32_t s = 0; s < numSamples; s++) {
        samplesSinceStep_++;

        // Compute effective step length with swing:
        // Even steps = normal length, odd steps = longer by swing * 0.33
        uint32_t effectiveStepSamples = baseStepSamples;
        if ((currentStep_ & 1) == 1 && swing_ > 0.0f) {
            uint32_t swingOffset = static_cast<uint32_t>(
                static_cast<float>(baseStepSamples) * swing_ * 0.33f);
            effectiveStepSamples = baseStepSamples + swingOffset;
        }

        // NaN/inf guard on effective step length
        if (effectiveStepSamples < 1) effectiveStepSamples = 1;

        uint32_t gateSamples = static_cast<uint32_t>(
            static_cast<float>(effectiveStepSamples) * gate_);
        if (gateSamples < 1) gateSamples = 1;
        if (gateSamples > effectiveStepSamples) gateSamples = effectiveStepSamples;

        // Check if current note should turn off
        if (noteIsActive_ && samplesSinceStep_ >= gateSamples) {
            if (lastPlayedNote_ >= 0) {
                allocator.noteOff(lastPlayedNote_);
            }
            noteIsActive_ = false;
        }

        // Check if we should advance to next step
        if (samplesSinceStep_ >= effectiveStepSamples) {
            samplesSinceStep_ = 0;
            currentStep_++;

            // Determine how many steps before cycling (notes * octaves)
            int stepsPerCycle = static_cast<int>(heldNotes_.size()) * octaveRange_;
            if (pattern_ == UP_DOWN) {
                stepsPerCycle = stepsPerCycle * 2 - 2;
                if (stepsPerCycle < 1) stepsPerCycle = 1;
            }
            if (stepsPerCycle > 0) {
                currentStep_ %= stepsPerCycle;
            } else {
                currentStep_ = 0;
            }

            // Play the next note
            if (!heldNotes_.empty()) {
                playStep(allocator);
                noteIsActive_ = true;
            }
        }
    }
}

void Arpeggiator::playStep(VoiceAllocator& allocator) {
    int note = noteFromPattern();
    if (note < 0) return;
    lastPlayedNote_ = note;
    lastPlayedVelocity_ = heldVelocities_[0]; // Use first note's velocity
    allocator.noteOn(note, lastPlayedVelocity_);
}

int Arpeggiator::noteFromPattern() const {
    if (heldNotes_.empty()) return -1;

    int numNotes = static_cast<int>(heldNotes_.size());

    switch (pattern_) {
    case UP: {
        // Cycle through notes, then octave up
        int noteIdx = currentStep_ % numNotes;
        int oct = (currentStep_ / numNotes) % octaveRange_;
        return heldNotes_[noteIdx] + oct * 12;
    }

    case DOWN: {
        // Reverse: play highest first
        int numNotes = static_cast<int>(heldNotes_.size());
        int revStep = numNotes - 1 - (currentStep_ % numNotes);
        int oct = (currentStep_ / numNotes) % octaveRange_;
        return heldNotes_[revStep] + oct * 12;
    }

    case UP_DOWN: {
        // Up then down, skipping top and bottom repeats
        int stepsPerOct = numNotes * 2 - 2;
        if (stepsPerOct < 1) stepsPerOct = 1;
        int posInOct = currentStep_ % stepsPerOct;
        int oct = (currentStep_ / stepsPerOct) % octaveRange_;

        int noteIdx;
        if (posInOct < numNotes) {
            noteIdx = posInOct; // Going up
        } else {
            noteIdx = stepsPerOct - posInOct; // Going down (skip bottom repeat)
        }
        return heldNotes_[noteIdx] + oct * 12;
    }

    case RANDOM: {
        int noteIdx = fastRand() % numNotes;
        int oct = fastRand() % octaveRange_;
        return heldNotes_[noteIdx] + oct * 12;
    }

    case CHORD: {
        // Play all held notes at once (first step = chord)
        if (currentStep_ == 0) {
            return heldNotes_[0]; // The voice allocator handles this per note
        }
        // For chord mode, we just play the chord once per step cycle
        // The note-off releases all notes
        return heldNotes_[currentStep_ % numNotes];
    }

    default:
        return heldNotes_[0];
    }
}

void Arpeggiator::releaseStep(VoiceAllocator& allocator) {
    if (lastPlayedNote_ >= 0) {
        allocator.noteOff(lastPlayedNote_);
    }
    noteIsActive_ = false;
}

unsigned int Arpeggiator::fastRand() const {
    randomState_ = randomState_ * 1103515245 + 12345;
    return (randomState_ / 65536) % 32768;
}

int Arpeggiator::totalSteps() const {
    int numNotes = static_cast<int>(heldNotes_.size());
    if (numNotes == 0) return 0;
    int stepsPerCycle = numNotes * octaveRange_;
    if (pattern_ == UP_DOWN) {
        stepsPerCycle = stepsPerCycle * 2 - 2;
        if (stepsPerCycle < 1) stepsPerCycle = 1;
    }
    return stepsPerCycle;
}

} // namespace opensynth