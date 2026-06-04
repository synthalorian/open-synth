#include "arpeggiator.h"
#include <cstdio>
#include <cmath>
#include <cstdlib>
#include <cstring>

namespace opensynth {

Arpeggiator::Arpeggiator() {
    heldNotes_.reserve(32);
    heldVelocities_.reserve(32);
    initPresetPatterns();
}

void Arpeggiator::initPresetPatterns() {
    // Initialize user patterns to default "all notes" pattern
    for (int i = 0; i < NUM_USER_PATTERNS; ++i) {
        auto& p = userPatterns_[i];
        snprintf(p.name, sizeof(p.name), "User %d", i + 1);
        p.length = 16;
        for (int s = 0; s < 16; ++s) {
            p.steps[s].stepValue = (s % 4) + 1;  // cycling through first 4 notes
            p.steps[s].velocity = 1.0f;
            p.steps[s].gate = 1.0f;
        }
    }
}

void Arpeggiator::noteOn(int midiNote, float velocity) {
    for (size_t i = 0; i < heldNotes_.size(); i++) {
        if (heldNotes_[i] == midiNote) {
            heldVelocities_[i] = velocity;
            if (hold_) heldNotesLocked_ = true;
            return;
        }
    }
    heldNotes_.push_back(midiNote);
    heldVelocities_.insert(heldVelocities_.begin() + (heldNotes_.size() - 1), velocity);
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
    if (hold_) heldNotesLocked_ = true;
}

void Arpeggiator::noteOff(int midiNote) {
    if (hold_ && heldNotesLocked_) return;
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
    return stepLengthSamples(48000.0);
}

uint32_t Arpeggiator::stepLengthSamples(double sampleRate) const {
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
            if (lastPlayedNote_ >= 0) allocator.noteOff(lastPlayedNote_);
            noteIsActive_ = false;
        }
        return;
    }

    uint32_t baseStepSamples = stepLengthSamples(sampleRate);
    if (baseStepSamples < 1) baseStepSamples = 1;

    for (uint32_t s = 0; s < numSamples; s++) {
        samplesSinceStep_++;

        uint32_t effectiveStepSamples = baseStepSamples;
        if ((currentStep_ & 1) == 1 && swing_ > 0.0f) {
            uint32_t swingOffset = static_cast<uint32_t>(
                static_cast<float>(baseStepSamples) * swing_ * 0.33f);
            effectiveStepSamples = baseStepSamples + swingOffset;
        }
        if (effectiveStepSamples < 1) effectiveStepSamples = 1;

        uint32_t gateSamples = static_cast<uint32_t>(
            static_cast<float>(effectiveStepSamples) * gate_);
        if (gateSamples < 1) gateSamples = 1;
        if (gateSamples > effectiveStepSamples) gateSamples = effectiveStepSamples;

        if (noteIsActive_ && samplesSinceStep_ >= gateSamples) {
            if (lastPlayedNote_ >= 0) allocator.noteOff(lastPlayedNote_);
            noteIsActive_ = false;
        }

        if (samplesSinceStep_ >= effectiveStepSamples) {
            samplesSinceStep_ = 0;
            currentStep_++;

            int stepsPerCycle = totalSteps();
            if (stepsPerCycle > 0) {
                currentStep_ %= stepsPerCycle;
            } else {
                currentStep_ = 0;
            }

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
    lastPlayedVelocity_ = heldVelocities_[0];
    allocator.noteOn(note, lastPlayedVelocity_);
}

int Arpeggiator::noteFromPattern() const {
    if (heldNotes_.empty()) return -1;

    if (isUserPattern(pattern_)) {
        return noteFromProgrammablePattern();
    }
    return noteFromBuiltinPattern();
}

int Arpeggiator::noteFromBuiltinPattern() const {
    int numNotes = static_cast<int>(heldNotes_.size());
    int p = pattern_;

    switch (p) {
    case UP: {
        int noteIdx = currentStep_ % numNotes;
        int oct = (currentStep_ / numNotes) % octaveRange_;
        return heldNotes_[noteIdx] + oct * 12;
    }

    case DOWN: {
        int revStep = numNotes - 1 - (currentStep_ % numNotes);
        int oct = (currentStep_ / numNotes) % octaveRange_;
        return heldNotes_[revStep] + oct * 12;
    }

    case UP_DOWN: {
        int stepsPerOct = numNotes * 2 - 2;
        if (stepsPerOct < 1) stepsPerOct = 1;
        int posInOct = currentStep_ % stepsPerOct;
        int oct = (currentStep_ / stepsPerOct) % octaveRange_;
        int noteIdx;
        if (posInOct < numNotes) {
            noteIdx = posInOct;
        } else {
            noteIdx = stepsPerOct - posInOct;
        }
        return heldNotes_[noteIdx] + oct * 12;
    }

    case RANDOM: {
        int noteIdx = fastRand() % numNotes;
        int oct = fastRand() % octaveRange_;
        return heldNotes_[noteIdx] + oct * 12;
    }

    case CHORD: {
        if (currentStep_ == 0) return heldNotes_[0];
        return heldNotes_[currentStep_ % numNotes];
    }

    case DOWN_UP: {
        int stepsPerOct = numNotes * 2 - 2;
        if (stepsPerOct < 1) stepsPerOct = 1;
        int posInOct = currentStep_ % stepsPerOct;
        int oct = (currentStep_ / stepsPerOct) % octaveRange_;
        int noteIdx;
        if (posInOct < numNotes) {
            noteIdx = numNotes - 1 - posInOct;  // Down first
        } else {
            noteIdx = posInOct - numNotes + 1;   // Then up
        }
        return heldNotes_[noteIdx] + oct * 12;
    }

    case PLAYED_ORDER: {
        // Play in order notes were pressed (heldNotes_ is sorted by pitch,
        // so we use the sorted index but cycle through it)
        int noteIdx = currentStep_ % numNotes;
        int oct = (currentStep_ / numNotes) % octaveRange_;
        return heldNotes_[noteIdx] + oct * 12;
    }

    case PING_PONG: {
        // Like up_down but with octave ping-pong
        int total = numNotes * octaveRange_;
        int pos = currentStep_ % (total * 2 - 2);
        if (pos < total) {
            int noteIdx = pos % numNotes;
            int oct = pos / numNotes;
            return heldNotes_[noteIdx] + oct * 12;
        } else {
            int rev = pos - total;
            int noteIdx = (total - 1 - rev) % numNotes;
            int oct = (total - 1 - rev) / numNotes;
            return heldNotes_[noteIdx] + oct * 12;
        }
    }

    case PING_PONG_REV: {
        // Reverse ping-pong
        int total = numNotes * octaveRange_;
        int pos = currentStep_ % (total * 2 - 2);
        if (pos < total) {
            int noteIdx = numNotes - 1 - (pos % numNotes);
            int oct = pos / numNotes;
            return heldNotes_[noteIdx] + oct * 12;
        } else {
            int rev = pos - total;
            int fwd = total - 1 - rev;
            int noteIdx = fwd % numNotes;
            int oct = fwd / numNotes;
            return heldNotes_[noteIdx] + oct * 12;
        }
    }

    case TWO_OCTAVE_UP: {
        int noteIdx = currentStep_ % numNotes;
        int oct = (currentStep_ / numNotes) % 2;
        return heldNotes_[noteIdx] + oct * 12;
    }

    case TWO_OCTAVE_DOWN: {
        int revStep = numNotes - 1 - (currentStep_ % numNotes);
        int oct = (currentStep_ / numNotes) % 2;
        return heldNotes_[revStep] + oct * 12;
    }

    case TWO_OCTAVE_UP_DOWN: {
        int stepsPerOct = numNotes * 2 - 2;
        if (stepsPerOct < 1) stepsPerOct = 1;
        int posInOct = currentStep_ % stepsPerOct;
        int oct = (currentStep_ / stepsPerOct) % 2;
        int noteIdx;
        if (posInOct < numNotes) {
            noteIdx = posInOct;
        } else {
            noteIdx = stepsPerOct - posInOct;
        }
        return heldNotes_[noteIdx] + oct * 12;
    }

    case THREE_OCTAVE_UP: {
        int noteIdx = currentStep_ % numNotes;
        int oct = (currentStep_ / numNotes) % 3;
        return heldNotes_[noteIdx] + oct * 12;
    }

    case THREE_OCTAVE_DOWN: {
        int revStep = numNotes - 1 - (currentStep_ % numNotes);
        int oct = (currentStep_ / numNotes) % 3;
        return heldNotes_[revStep] + oct * 12;
    }

    case THREE_OCTAVE_UP_DOWN: {
        int stepsPerOct = numNotes * 2 - 2;
        if (stepsPerOct < 1) stepsPerOct = 1;
        int posInOct = currentStep_ % stepsPerOct;
        int oct = (currentStep_ / stepsPerOct) % 3;
        int noteIdx;
        if (posInOct < numNotes) {
            noteIdx = posInOct;
        } else {
            noteIdx = stepsPerOct - posInOct;
        }
        return heldNotes_[noteIdx] + oct * 12;
    }

    case OCTAVE_JUMP_UP: {
        // Play each note, then jump octave
        int noteIdx = currentStep_ % numNotes;
        int oct = (currentStep_ / numNotes) % octaveRange_;
        if (noteIdx == 0 && currentStep_ > 0) {
            return heldNotes_[noteIdx] + (oct + 1) * 12;
        }
        return heldNotes_[noteIdx] + oct * 12;
    }

    case OCTAVE_JUMP_DOWN: {
        int revStep = numNotes - 1 - (currentStep_ % numNotes);
        int oct = (currentStep_ / numNotes) % octaveRange_;
        if (revStep == numNotes - 1 && currentStep_ > 0) {
            return heldNotes_[revStep] + (oct + 1) * 12;
        }
        return heldNotes_[revStep] + oct * 12;
    }

    case FIFTH_UP: {
        // Add perfect fifth (+7 semitones) every other note
        int noteIdx = currentStep_ % numNotes;
        int oct = (currentStep_ / numNotes) % octaveRange_;
        int fifth = (currentStep_ % 2 == 1) ? 7 : 0;
        return heldNotes_[noteIdx] + oct * 12 + fifth;
    }

    case FIFTH_DOWN: {
        int revStep = numNotes - 1 - (currentStep_ % numNotes);
        int oct = (currentStep_ / numNotes) % octaveRange_;
        int fifth = (currentStep_ % 2 == 1) ? 7 : 0;
        return heldNotes_[revStep] + oct * 12 + fifth;
    }

    case FIFTH_UP_DOWN: {
        int stepsPerOct = numNotes * 2 - 2;
        if (stepsPerOct < 1) stepsPerOct = 1;
        int posInOct = currentStep_ % stepsPerOct;
        int oct = (currentStep_ / stepsPerOct) % octaveRange_;
        int noteIdx;
        if (posInOct < numNotes) {
            noteIdx = posInOct;
        } else {
            noteIdx = stepsPerOct - posInOct;
        }
        int fifth = (currentStep_ % 2 == 1) ? 7 : 0;
        return heldNotes_[noteIdx] + oct * 12 + fifth;
    }

    default:
        return heldNotes_[0];
    }
}

int Arpeggiator::noteFromProgrammablePattern() const {
    int userIdx = pattern_ - NUM_PRESET_PATTERNS;
    if (userIdx < 0 || userIdx >= NUM_USER_PATTERNS) return -1;
    const auto& pat = userPatterns_[userIdx];
    if (pat.length < 1) return -1;

    int stepIdx = currentStep_ % pat.length;
    const auto& step = pat.steps[stepIdx];

    if (step.stepValue == 0) return -1;  // Rest

    int noteIdx = (step.stepValue - 1) % static_cast<int>(heldNotes_.size());
    int oct = (step.stepValue - 1) / static_cast<int>(heldNotes_.size());
    return heldNotes_[noteIdx] + oct * 12;
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
    if (heldNotes_.empty()) return 0;

    if (isUserPattern(pattern_)) {
        int userIdx = pattern_ - NUM_PRESET_PATTERNS;
        if (userIdx >= 0 && userIdx < NUM_USER_PATTERNS) {
            return userPatterns_[userIdx].length;
        }
        return 16;
    }

    int numNotes = static_cast<int>(heldNotes_.size());
    int p = pattern_;

    switch (p) {
    case UP:
    case DOWN:
    case PLAYED_ORDER:
        return numNotes * octaveRange_;

    case UP_DOWN:
    case DOWN_UP:
    case TWO_OCTAVE_UP_DOWN:
    case THREE_OCTAVE_UP_DOWN:
    case FIFTH_UP_DOWN:
        {
            int stepsPerOct = numNotes * 2 - 2;
            if (stepsPerOct < 1) stepsPerOct = 1;
            int octs = (p == TWO_OCTAVE_UP_DOWN) ? 2 : (p == THREE_OCTAVE_UP_DOWN) ? 3 : octaveRange_;
            return stepsPerOct * octs;
        }

    case RANDOM:
    case CHORD:
        return numNotes * octaveRange_;

    case PING_PONG:
    case PING_PONG_REV:
        {
            int total = numNotes * octaveRange_;
            return total * 2 - 2;
        }

    case TWO_OCTAVE_UP:
    case TWO_OCTAVE_DOWN:
        return numNotes * 2;

    case THREE_OCTAVE_UP:
    case THREE_OCTAVE_DOWN:
        return numNotes * 3;

    case OCTAVE_JUMP_UP:
    case OCTAVE_JUMP_DOWN:
        return numNotes * octaveRange_;

    case FIFTH_UP:
    case FIFTH_DOWN:
        return numNotes * octaveRange_;

    default:
        return numNotes * octaveRange_;
    }
}

const char* Arpeggiator::patternName(int index) const {
    if (isUserPattern(index)) {
        int userIdx = index - NUM_PRESET_PATTERNS;
        if (userIdx >= 0 && userIdx < NUM_USER_PATTERNS) {
            return userPatterns_[userIdx].name;
        }
        return "User";
    }

    switch (index) {
    case UP:                    return "Up";
    case DOWN:                  return "Down";
    case UP_DOWN:               return "Up/Down";
    case RANDOM:                return "Random";
    case CHORD:                 return "Chord";
    case DOWN_UP:               return "Down/Up";
    case PLAYED_ORDER:          return "Played Order";
    case PING_PONG:             return "Ping Pong";
    case PING_PONG_REV:         return "Ping Pong Rev";
    case TWO_OCTAVE_UP:         return "2-Oct Up";
    case TWO_OCTAVE_DOWN:       return "2-Oct Down";
    case TWO_OCTAVE_UP_DOWN:    return "2-Oct Up/Down";
    case THREE_OCTAVE_UP:       return "3-Oct Up";
    case THREE_OCTAVE_DOWN:     return "3-Oct Down";
    case THREE_OCTAVE_UP_DOWN:  return "3-Oct Up/Down";
    case OCTAVE_JUMP_UP:        return "Oct Jump Up";
    case OCTAVE_JUMP_DOWN:      return "Oct Jump Down";
    case FIFTH_UP:              return "Fifth Up";
    case FIFTH_DOWN:            return "Fifth Down";
    case FIFTH_UP_DOWN:         return "Fifth Up/Down";
    default:                    return "Unknown";
    }
}

} // namespace opensynth