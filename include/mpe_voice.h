#pragma once
#include <cstdint>
#include <cmath>

namespace opensynth {

// ── MPE (MIDI Polyphonic Expression) Voice State ─────────────────────────────
//
// MPE allows per-note expression: each note gets its own pitch bend, pressure,
// and slide (CC74) values, independent of other held notes.
//
// This struct lives on each Voice and stores the MPE state for that note.
// The VoiceAllocator assigns a unique "note ID" (MIDI channel in MPE mode)
// to each active voice.

struct MpeVoiceState {
    // Per-note pitch bend in semitones (-24 to +24, typically ±48 in MPE)
    float perNotePitchBend = 0.0f;

    // Per-note pressure (0-1, replaces global aftertouch)
    float perNotePressure = 0.0f;

    // Per-note slide / timbre (CC74, 0-1)
    float perNoteSlide = 0.0f;

    // MPE zone: lower zone = ch 1 master, ch 2-15 notes
    //           upper zone = ch 16 master, ch 1-15 notes
    bool mpeEnabled = false;
    int mpeZone = 0;  // 0 = lower (ch 1 master), 1 = upper (ch 16 master)
    int mpeNoteChannel = 0;  // The MIDI channel assigned to this note (2-15)

    void reset() {
        perNotePitchBend = 0.0f;
        perNotePressure = 0.0f;
        perNoteSlide = 0.0f;
        mpeEnabled = false;
        mpeZone = 0;
        mpeNoteChannel = 0;
    }
};

// ── MPE Controller ───────────────────────────────────────────────────────────
// Manages MPE zone configuration and routes per-note MIDI to the correct voice.

class MpeController {
public:
    void setEnabled(bool e) { enabled_ = e; }
    bool enabled() const { return enabled_; }

    // Configure MPE zone
    // lowerZone: true = ch 1 master, ch 2-15 notes
    //            false = ch 16 master, ch 1-15 notes
    void setLowerZone(bool lower) { lowerZone_ = lower; }
    bool lowerZone() const { return lowerZone_; }

    // Get the master channel for the current zone
    int masterChannel() const { return lowerZone_ ? 0 : 15; }

    // Check if a channel is a member channel (not master)
    bool isMemberChannel(int channel) const {
        if (!enabled_) return false;
        if (lowerZone_) return channel >= 1 && channel <= 14;
        return channel >= 0 && channel <= 14;
    }

    // Convert member channel to note index (0-13)
    int channelToNoteIndex(int channel) const {
        if (lowerZone_) return channel - 1;
        return channel;
    }

    // MPE pitch bend range (default ±48 semitones)
    void setPitchBendRange(float semitones) { pitchBendRange_ = semitones; }
    float pitchBendRange() const { return pitchBendRange_; }

    // Convert MIDI pitch wheel (0-16383) to semitones
    float pitchWheelToSemitones(int wheelValue) const {
        float normalized = (wheelValue - 8192) / 8192.0f;
        return normalized * pitchBendRange_;
    }

private:
    bool enabled_ = false;
    bool lowerZone_ = true;  // Default: lower zone
    float pitchBendRange_ = 48.0f;  // MPE default ±48 semitones
};

} // namespace opensynth
