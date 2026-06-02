#pragma once
#include <cstdint>
#include <cstring>
#include <atomic>

namespace openamp {

/// Lock-free single-producer single-consumer (SPSC) parameter queue.
///
/// The UI thread (Dart) calls enqueue() to push parameter changes.
/// The audio thread calls drain() at the start of each process block
/// to apply all pending changes. No allocations, no locks, no waits.
///
/// Each entry is a (param_id, float_value) pair. The param_id maps
/// to a specific synth parameter in SynthEngine::applyParam().
class ParamQueue {
public:
    /// Parameter IDs -- one per controllable synth parameter.
    /// Must stay in sync with SynthEngine::applyParam().
    enum ParamId : uint16_t {
        // MIDI
        NOTE_ON = 0,
        NOTE_OFF = 1,
        ALL_NOTES_OFF = 2,

        // Osc 1
        OSC1_WAVEFORM = 10,
        OSC1_OCTAVE = 11,
        OSC1_DETUNE = 12,
        OSC1_PULSE_WIDTH = 13,
        OSC1_VOLUME = 14,
        OSC1_NOISE_TYPE = 15,
        OSC1_SUB_OSC_MODE = 16,
        OSC1_SUB_OSC_VOLUME = 17,
        OSC1_FM_ENABLED = 18,
        OSC1_FM_AMOUNT = 19,

        // Osc 2
        OSC2_WAVEFORM = 20,
        OSC2_OCTAVE = 21,
        OSC2_DETUNE = 22,
        OSC2_PULSE_WIDTH = 23,
        OSC2_VOLUME = 24,
        OSC_MIX = 25,
        OSC2_NOISE_TYPE = 26,
        OSC2_SUB_OSC_MODE = 27,
        OSC2_SUB_OSC_VOLUME = 28,
        OSC2_FM_ENABLED = 29,
        OSC2_FM_AMOUNT = 30,

        // Filter
        FILTER_TYPE = 40,
        FILTER_CUTOFF = 41,
        FILTER_RESONANCE = 42,
        FILTER_ENV_AMOUNT = 43,
        FILTER_KEY_TRACKING = 44,
        FILTER_DRIVE = 45,

        // Amp envelope
        AMP_ATTACK = 50,
        AMP_DECAY = 51,
        AMP_SUSTAIN = 52,
        AMP_RELEASE = 53,
        AMP_DELAY = 54,
        AMP_HOLD = 55,
        AMP_ATTACK_CURVE = 56,
        AMP_DECAY_CURVE = 57,
        AMP_RELEASE_CURVE = 58,

        // Filter envelope
        FILTER_ATTACK = 60,
        FILTER_DECAY = 61,
        FILTER_SUSTAIN = 62,
        FILTER_RELEASE = 63,
        FILTER_DELAY = 64,
        FILTER_HOLD = 65,
        FILTER_ATTACK_CURVE = 66,
        FILTER_DECAY_CURVE = 67,
        FILTER_RELEASE_CURVE = 68,

        // LFO 1
        LFO1_WAVEFORM = 70,
        LFO1_RATE = 71,
        LFO1_DEPTH = 72,
        LFO1_TARGET = 73,
        LFO1_FADE_IN = 74,
        LFO1_TEMPO_SYNC = 75,
        LFO1_TEMPO_DIVISION = 76,

        // LFO 2
        LFO2_WAVEFORM = 80,
        LFO2_RATE = 81,
        LFO2_DEPTH = 82,
        LFO2_TARGET = 83,
        LFO2_FADE_IN = 84,
        LFO2_TEMPO_SYNC = 85,
        LFO2_TEMPO_DIVISION = 86,

        // FX: Chorus
        CHORUS_ENABLED = 90,
        CHORUS_RATE = 91,
        CHORUS_DEPTH = 92,
        CHORUS_MIX = 93,

        // FX: Delay
        DELAY_ENABLED = 94,
        DELAY_TIME = 95,
        DELAY_FEEDBACK = 96,
        DELAY_MIX = 97,

        // FX: Reverb
        REVERB_ENABLED = 98,
        REVERB_SIZE = 99,
        REVERB_DAMPING = 100,
        REVERB_MIX = 101,

        // FX: Phaser
        PHASER_ENABLED = 102,
        PHASER_RATE = 103,
        PHASER_DEPTH = 104,
        PHASER_FEEDBACK = 105,
        PHASER_MIX = 106,

        // FX: Drive
        DRIVE_ENABLED = 107,
        DRIVE_AMOUNT = 108,
        DRIVE_TYPE = 109,

        // FX: Flanger
        FLANGER_ENABLED = 110,
        FLANGER_RATE = 111,
        FLANGER_DEPTH = 112,
        FLANGER_FEEDBACK = 113,
        FLANGER_MIX = 114,

        // FX: Compressor
        COMPRESSOR_ENABLED = 115,
        COMPRESSOR_THRESHOLD = 116,
        COMPRESSOR_RATIO = 117,
        COMPRESSOR_ATTACK = 118,
        COMPRESSOR_RELEASE = 119,
        COMPRESSOR_MAKEUP_GAIN = 120,

        // Master
        MASTER_VOLUME = 130,

        // Unison 1
        OSC1_UNISON_VOICE_COUNT = 140,
        OSC1_UNISON_DETUNE_SPREAD = 141,
        OSC1_UNISON_STEREO_SPREAD = 142,
        OSC1_UNISON_MIX = 143,

        // Unison 2
        OSC2_UNISON_VOICE_COUNT = 150,
        OSC2_UNISON_DETUNE_SPREAD = 151,
        OSC2_UNISON_STEREO_SPREAD = 152,
        OSC2_UNISON_MIX = 153,

        // Arpeggiator
        ARP_ENABLED = 160,
        ARP_TEMPO = 161,
        ARP_PATTERN = 162,
        ARP_OCTAVE_RANGE = 163,
        ARP_GATE = 164,
        ARP_RESOLUTION = 165,
        ARP_SWING = 166,
        ARP_HOLD = 167,

        // Voice priority
        VOICE_PRIORITY_MODE = 170,

        // New FX: EQ (slot 1)
        FX_SLOT1_TYPE = 180,
        FX_SLOT1_ENABLED = 181,
        FX_SLOT1_PARAM0 = 182,
        FX_SLOT1_PARAM1 = 183,
        FX_SLOT1_PARAM2 = 184,
        FX_SLOT1_PARAM3 = 185,
        FX_SLOT1_PARAM4 = 186,
        FX_SLOT1_PARAM5 = 187,
        FX_SLOT1_PARAM6 = 188,
        FX_SLOT1_PARAM7 = 189,

        // New FX: Limiter (slot 2)
        FX_SLOT2_TYPE = 190,
        FX_SLOT2_ENABLED = 191,
        FX_SLOT2_PARAM0 = 192,
        FX_SLOT2_PARAM1 = 193,
        FX_SLOT2_PARAM2 = 194,
        FX_SLOT2_PARAM3 = 195,
        FX_SLOT2_PARAM4 = 196,

        // New FX: Rotary / Tremolo (slot 3)
        FX_SLOT3_TYPE = 197,
        FX_SLOT3_ENABLED = 198,
        FX_SLOT3_PARAM0 = 199,
        FX_SLOT3_PARAM1 = 200,
        FX_SLOT3_PARAM2 = 201,
        FX_SLOT3_PARAM3 = 202,
        FX_SLOT3_PARAM4 = 203,
        FX_SLOT3_PARAM5 = 204,

        // FX Engine master
        FX_MASTER_ENABLED = 205,
        FX_MASTER_MIX = 206,

        // Phase 5: New FX slot param ranges (slots can hold any FX type now)
        // Param IDs 210-249 reserved for future FX expansion

        // Reset
        RESET = 250,

        // Drum Kit
        DRUM_KIT_PRESET = 260,
        DRUM_LEVEL = 261,
        DRUM_NOTE_ON = 262,
        DRUM_NOTE_OFF = 263,

        // Rhythm Pattern Player
        RHYTHM_PATTERN = 270,
        RHYTHM_PLAY = 271,
        RHYTHM_STOP = 272,
        RHYTHM_TEMPO = 273,
        RHYTHM_VOLUME = 274,
        RHYTHM_VARIATION = 275,
        RHYTHM_SONG_MODE = 276,
    };

    struct Entry {
        uint16_t paramId;
        int16_t  intData;    // Used for note number, waveform, etc.
        float    floatData;  // Used for continuous params.
    };

    static constexpr size_t CAPACITY = 1024; // Must be power of 2

    ParamQueue() : head_(0), tail_(0) {
        memset(buf_, 0, sizeof(buf_));
    }

    /// Enqueue a float parameter (called from UI thread).
    /// Returns false if the queue is full (should never happen in practice).
    bool enqueue(ParamId id, float value) {
        size_t next = (tail_.load(std::memory_order_relaxed) + 1) & (CAPACITY - 1);
        if (next == head_.load(std::memory_order_acquire)) {
            return false; // Full
        }
        auto& slot = buf_[tail_.load(std::memory_order_relaxed)];
        slot.paramId = static_cast<uint16_t>(id);
        slot.intData = 0;
        slot.floatData = value;
        tail_.store(next, std::memory_order_release);
        return true;
    }

    /// Enqueue an int parameter (called from UI thread).
    bool enqueueInt(ParamId id, int16_t value) {
        size_t next = (tail_.load(std::memory_order_relaxed) + 1) & (CAPACITY - 1);
        if (next == head_.load(std::memory_order_acquire)) {
            return false;
        }
        auto& slot = buf_[tail_.load(std::memory_order_relaxed)];
        slot.paramId = static_cast<uint16_t>(id);
        slot.intData = value;
        slot.floatData = 0.0f;
        tail_.store(next, std::memory_order_release);
        return true;
    }

    /// Enqueue a note-on event (note + velocity).
    bool enqueueNoteOn(int16_t note, float velocity) {
        size_t next = (tail_.load(std::memory_order_relaxed) + 1) & (CAPACITY - 1);
        if (next == head_.load(std::memory_order_acquire)) return false;
        auto& slot = buf_[tail_.load(std::memory_order_relaxed)];
        slot.paramId = NOTE_ON;
        slot.intData = note;
        slot.floatData = velocity;
        tail_.store(next, std::memory_order_release);
        return true;
    }

    /// Enqueue a note-off event.
    bool enqueueNoteOff(int16_t note) {
        size_t next = (tail_.load(std::memory_order_relaxed) + 1) & (CAPACITY - 1);
        if (next == head_.load(std::memory_order_acquire)) return false;
        auto& slot = buf_[tail_.load(std::memory_order_relaxed)];
        slot.paramId = NOTE_OFF;
        slot.intData = note;
        slot.floatData = 0.0f;
        tail_.store(next, std::memory_order_release);
        return true;
    }

    /// Try to dequeue one entry (called from audio thread).
    bool dequeue(Entry& out) {
        size_t h = head_.load(std::memory_order_relaxed);
        if (h == tail_.load(std::memory_order_acquire)) {
            return false; // Empty
        }
        out = buf_[h];
        head_.store((h + 1) & (CAPACITY - 1), std::memory_order_release);
        return true;
    }

    /// Drain all pending entries (convenience for audio thread).
    template<typename Fn>
    void drainAll(Fn&& fn) {
        Entry e;
        while (dequeue(e)) {
            fn(e);
        }
    }

    /// Approximate number of pending entries.
    size_t size() const {
        size_t t = tail_.load(std::memory_order_relaxed);
        size_t h = head_.load(std::memory_order_relaxed);
        return (t >= h) ? (t - h) : (CAPACITY - h + t);
    }

private:
    alignas(64) Entry buf_[CAPACITY];
    alignas(64) std::atomic<size_t> head_;
    alignas(64) std::atomic<size_t> tail_;
};

} // namespace openamp
