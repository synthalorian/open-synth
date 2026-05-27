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

        // Osc 2
        OSC2_WAVEFORM = 20,
        OSC2_OCTAVE = 21,
        OSC2_DETUNE = 22,
        OSC2_PULSE_WIDTH = 23,
        OSC2_VOLUME = 24,
        OSC_MIX = 25,

        // Filter
        FILTER_TYPE = 30,
        FILTER_CUTOFF = 31,
        FILTER_RESONANCE = 32,
        FILTER_ENV_AMOUNT = 33,

        // Amp envelope
        AMP_ATTACK = 40,
        AMP_DECAY = 41,
        AMP_SUSTAIN = 42,
        AMP_RELEASE = 43,

        // Filter envelope
        FILTER_ATTACK = 50,
        FILTER_DECAY = 51,
        FILTER_SUSTAIN = 52,
        FILTER_RELEASE = 53,

        // LFO 1
        LFO1_WAVEFORM = 60,
        LFO1_RATE = 61,
        LFO1_DEPTH = 62,
        LFO1_TARGET = 63,

        // LFO 2
        LFO2_WAVEFORM = 70,
        LFO2_RATE = 71,
        LFO2_DEPTH = 72,
        LFO2_TARGET = 73,

        // FX: Chorus
        CHORUS_ENABLED = 80,
        CHORUS_RATE = 81,
        CHORUS_DEPTH = 82,
        CHORUS_MIX = 83,

        // FX: Delay
        DELAY_ENABLED = 84,
        DELAY_TIME = 85,
        DELAY_FEEDBACK = 86,
        DELAY_MIX = 87,

        // FX: Reverb
        REVERB_ENABLED = 88,
        REVERB_SIZE = 89,
        REVERB_DAMPING = 90,
        REVERB_MIX = 91,

        // FX: Phaser
        PHASER_ENABLED = 92,
        PHASER_RATE = 93,
        PHASER_DEPTH = 94,
        PHASER_FEEDBACK = 95,
        PHASER_MIX = 96,

        // FX: Drive
        DRIVE_ENABLED = 97,
        DRIVE_AMOUNT = 98,
        DRIVE_TYPE = 99,

        // FX: Flanger
        FLANGER_ENABLED = 100,
        FLANGER_RATE = 101,
        FLANGER_DEPTH = 102,
        FLANGER_FEEDBACK = 103,
        FLANGER_MIX = 104,

        // FX: Compressor
        COMPRESSOR_ENABLED = 105,
        COMPRESSOR_THRESHOLD = 106,
        COMPRESSOR_RATIO = 107,
        COMPRESSOR_ATTACK = 108,
        COMPRESSOR_RELEASE = 109,
        COMPRESSOR_MAKEUP_GAIN = 110,

        // Master
        MASTER_VOLUME = 120,

        // Unison 1
        OSC1_UNISON_VOICE_COUNT = 130,
        OSC1_UNISON_DETUNE_SPREAD = 131,
        OSC1_UNISON_STEREO_SPREAD = 132,
        OSC1_UNISON_MIX = 133,

        // Unison 2
        OSC2_UNISON_VOICE_COUNT = 140,
        OSC2_UNISON_DETUNE_SPREAD = 141,
        OSC2_UNISON_STEREO_SPREAD = 142,
        OSC2_UNISON_MIX = 143,

        // Reset
        RESET = 200,

        // Arpeggiator
        ARP_ENABLED = 150,
        ARP_TEMPO = 151,
        ARP_PATTERN = 152,
        ARP_OCTAVE_RANGE = 153,
        ARP_GATE = 154,
        ARP_RESOLUTION = 155,
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
