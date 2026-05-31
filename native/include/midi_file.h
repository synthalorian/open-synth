#pragma once
#include <cstdint>
#include <vector>
#include <string>
#include <functional>

namespace openamp {

// ── MIDI event types ─────────────────────────────────────────────────────────

struct MidiEvent {
    uint32_t tick = 0;      // Absolute tick position
    uint8_t status = 0;     // MIDI status byte
    uint8_t data1 = 0;      // First data byte
    uint8_t data2 = 0;      // Second data byte (if applicable)
    std::vector<uint8_t> sysex; // For SysEx/meta events

    bool isNoteOn() const { return (status & 0xF0) == 0x90 && data2 > 0; }
    bool isNoteOff() const { return (status & 0xF0) == 0x80 || ((status & 0xF0) == 0x90 && data2 == 0); }
    int channel() const { return status & 0x0F; }
    int note() const { return data1; }
    int velocity() const { return data2; }
};

// ── MIDI track ───────────────────────────────────────────────────────────────

struct MidiTrack {
    std::string name;
    std::vector<MidiEvent> events;
};

// ── MIDI file ────────────────────────────────────────────────────────────────

struct MidiFile {
    int format = 1;           // 0 = single track, 1 = multi-track, 2 = multi-sequence
    int ticksPerQuarter = 480; // PPQN (pulses per quarter note)
    float tempoBpm = 120.0f;  // Default tempo
    std::vector<MidiTrack> tracks;

    void clear();
    uint32_t totalTicks() const;
    float durationSeconds() const;
};

// ── MIDI file reader ─────────────────────────────────────────────────────────

class MidiFileReader {
public:
    // Read a MIDI file from disk. Returns true on success.
    static bool read(const char* path, MidiFile& out);

    // Read from memory buffer.
    static bool read(const uint8_t* data, size_t size, MidiFile& out);

private:
    static bool parseHeader(const uint8_t* data, size_t size, size_t& pos, MidiFile& out);
    static bool parseTrack(const uint8_t* data, size_t size, size_t& pos, MidiTrack& track);
    static uint32_t readVariableLength(const uint8_t* data, size_t size, size_t& pos);
};

// ── MIDI file writer ─────────────────────────────────────────────────────────

class MidiFileWriter {
public:
    // Write a MIDI file to disk. Returns true on success.
    static bool write(const char* path, const MidiFile& midi);

    // Write to memory buffer.
    static bool write(const MidiFile& midi, std::vector<uint8_t>& out);

private:
    static void writeHeader(std::vector<uint8_t>& out, const MidiFile& midi);
    static void writeTrack(std::vector<uint8_t>& out, const MidiTrack& track, int ticksPerQuarter);
    static void writeVariableLength(std::vector<uint8_t>& out, uint32_t value);
    static void writeU16(std::vector<uint8_t>& out, uint16_t v);
    static void writeU32(std::vector<uint8_t>& out, uint32_t v);
};

// ── MIDI file playback callback ──────────────────────────────────────────────

using MidiEventCallback = std::function<void(const MidiEvent& event, float seconds)>;

// Iterate through MIDI events in time order, calling callback for each.
// Useful for scheduling playback.
void iterateMidiEvents(const MidiFile& midi, MidiEventCallback callback);

} // namespace openamp
