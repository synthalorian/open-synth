#include "midi_file.h"
#include <cstdio>
#include <cstring>
#include <algorithm>

namespace opensynth {

// ── MidiFile helpers ──────────────────────────────────────────────────────────

void MidiFile::clear() {
    tracks.clear();
    tempoBpm = 120.0f;
    ticksPerQuarter = 480;
}

uint32_t MidiFile::totalTicks() const {
    uint32_t maxTick = 0;
    for (const auto& track : tracks) {
        for (const auto& ev : track.events) {
            if (ev.tick > maxTick) maxTick = ev.tick;
        }
    }
    return maxTick;
}

float MidiFile::durationSeconds() const {
    return totalTicks() / (ticksPerQuarter * (tempoBpm / 60.0f));
}

// ── MidiFileReader ────────────────────────────────────────────────────────────

static uint16_t readU16(const uint8_t* data, size_t& pos) {
    uint16_t v = (data[pos] << 8) | data[pos + 1];
    pos += 2;
    return v;
}

static uint32_t readU32(const uint8_t* data, size_t& pos) {
    uint32_t v = (data[pos] << 24) | (data[pos + 1] << 16) | (data[pos + 2] << 8) | data[pos + 3];
    pos += 4;
    return v;
}

uint32_t MidiFileReader::readVariableLength(const uint8_t* data, size_t size, size_t& pos) {
    uint32_t value = 0;
    uint8_t byte;
    do {
        if (pos >= size) return 0;
        byte = data[pos++];
        value = (value << 7) | (byte & 0x7F);
    } while (byte & 0x80);
    return value;
}

bool MidiFileReader::read(const char* path, MidiFile& out) {
    FILE* f = std::fopen(path, "rb");
    if (!f) return false;
    std::fseek(f, 0, SEEK_END);
    long size = std::ftell(f);
    std::fseek(f, 0, SEEK_SET);
    std::vector<uint8_t> data(size);
    std::fread(data.data(), 1, size, f);
    std::fclose(f);
    return read(data.data(), data.size(), out);
}

bool MidiFileReader::read(const uint8_t* data, size_t size, MidiFile& out) {
    out.clear();
    size_t pos = 0;
    if (!parseHeader(data, size, pos, out)) return false;
    for (int i = 0; i < (int)out.tracks.size(); ++i) {
        if (!parseTrack(data, size, pos, out.tracks[i])) return false;
    }
    return true;
}

bool MidiFileReader::parseHeader(const uint8_t* data, size_t size, size_t& pos, MidiFile& out) {
    if (size < 14) return false;
    if (std::memcmp(data, "MThd", 4) != 0) return false;
    pos = 4;
    uint32_t headerLen = readU32(data, pos);
    if (headerLen != 6) return false;
    out.format = readU16(data, pos);
    int numTracks = readU16(data, pos);
    out.ticksPerQuarter = readU16(data, pos);
    if (out.ticksPerQuarter & 0x8000) {
        // SMPTE format (not supported, fallback)
        out.ticksPerQuarter = 480;
    }
    out.tracks.resize(numTracks);
    return true;
}

bool MidiFileReader::parseTrack(const uint8_t* data, size_t size, size_t& pos, MidiTrack& track) {
    if (pos + 8 > size) return false;
    if (std::memcmp(data + pos, "MTrk", 4) != 0) return false;
    pos += 4;
    uint32_t trackLen = readU32(data, pos);
    size_t trackEnd = pos + trackLen;
    if (trackEnd > size) return false;

    uint32_t absoluteTick = 0;
    uint8_t runningStatus = 0;

    while (pos < trackEnd) {
        uint32_t delta = readVariableLength(data, trackEnd, pos);
        absoluteTick += delta;

        if (pos >= trackEnd) break;
        uint8_t status = data[pos];

        // Meta event
        if (status == 0xFF) {
            pos++;
            if (pos >= trackEnd) break;
            uint8_t metaType = data[pos++];
            uint32_t metaLen = readVariableLength(data, trackEnd, pos);
            if (pos + metaLen > trackEnd) break;

            if (metaType == 0x03) { // Track name
                track.name = std::string((const char*)data + pos, metaLen);
            } else if (metaType == 0x51 && metaLen == 3) { // Tempo
                uint32_t microsPerQuarter = (data[pos] << 16) | (data[pos + 1] << 8) | data[pos + 2];
                // Store tempo in first track (we'll extract it later)
            }
            pos += metaLen;
            continue;
        }

        // SysEx
        if (status == 0xF0 || status == 0xF7) {
            pos++;
            uint32_t sysexLen = readVariableLength(data, trackEnd, pos);
            if (pos + sysexLen > trackEnd) break;
            MidiEvent ev;
            ev.tick = absoluteTick;
            ev.status = status;
            ev.sysex.assign(data + pos, data + pos + sysexLen);
            track.events.push_back(ev);
            pos += sysexLen;
            continue;
        }

        // Channel event
        if (status & 0x80) {
            runningStatus = status;
            pos++;
        } else {
            status = runningStatus;
        }

        uint8_t data1 = 0, data2 = 0;
        if (pos < trackEnd) data1 = data[pos++];

        int channelEvent = status & 0xF0;
        if (channelEvent == 0xC0 || channelEvent == 0xD0) {
            // Program change or channel pressure: 1 data byte
        } else {
            if (pos < trackEnd) data2 = data[pos++];
        }

        MidiEvent ev;
        ev.tick = absoluteTick;
        ev.status = status;
        ev.data1 = data1;
        ev.data2 = data2;
        track.events.push_back(ev);
    }

    pos = trackEnd;
    return true;
}

// ── MidiFileWriter ────────────────────────────────────────────────────────────

void MidiFileWriter::writeU16(std::vector<uint8_t>& out, uint16_t v) {
    out.push_back((v >> 8) & 0xFF);
    out.push_back(v & 0xFF);
}

void MidiFileWriter::writeU32(std::vector<uint8_t>& out, uint32_t v) {
    out.push_back((v >> 24) & 0xFF);
    out.push_back((v >> 16) & 0xFF);
    out.push_back((v >> 8) & 0xFF);
    out.push_back(v & 0xFF);
}

void MidiFileWriter::writeVariableLength(std::vector<uint8_t>& out, uint32_t value) {
    uint8_t buf[4];
    int count = 0;
    buf[count++] = value & 0x7F;
    while (value >>= 7) {
        buf[count++] = (value & 0x7F) | 0x80;
    }
    for (int i = count - 1; i >= 0; --i) {
        out.push_back(buf[i]);
    }
}

bool MidiFileWriter::write(const char* path, const MidiFile& midi) {
    std::vector<uint8_t> data;
    if (!write(midi, data)) return false;
    FILE* f = std::fopen(path, "wb");
    if (!f) return false;
    std::fwrite(data.data(), 1, data.size(), f);
    std::fclose(f);
    return true;
}

bool MidiFileWriter::write(const MidiFile& midi, std::vector<uint8_t>& out) {
    out.clear();
    writeHeader(out, midi);
    for (const auto& track : midi.tracks) {
        writeTrack(out, track, midi.ticksPerQuarter);
    }
    return true;
}

void MidiFileWriter::writeHeader(std::vector<uint8_t>& out, const MidiFile& midi) {
    out.insert(out.end(), {'M', 'T', 'h', 'd'});
    writeU32(out, 6); // Header length
    writeU16(out, midi.format);
    writeU16(out, (uint16_t)midi.tracks.size());
    writeU16(out, (uint16_t)midi.ticksPerQuarter);
}

void MidiFileWriter::writeTrack(std::vector<uint8_t>& out, const MidiTrack& track, int ticksPerQuarter) {
    std::vector<uint8_t> trackData;

    // Track name meta event
    if (!track.name.empty()) {
        trackData.push_back(0x00); // delta
        trackData.push_back(0xFF);
        trackData.push_back(0x03);
        writeVariableLength(trackData, (uint32_t)track.name.size());
        trackData.insert(trackData.end(), track.name.begin(), track.name.end());
    }

    // Write events
    uint32_t lastTick = 0;
    for (const auto& ev : track.events) {
        uint32_t delta = ev.tick - lastTick;
        lastTick = ev.tick;
        writeVariableLength(trackData, delta);

        if (!ev.sysex.empty()) {
            trackData.push_back(ev.status);
            writeVariableLength(trackData, (uint32_t)ev.sysex.size());
            trackData.insert(trackData.end(), ev.sysex.begin(), ev.sysex.end());
        } else {
            trackData.push_back(ev.status);
            trackData.push_back(ev.data1);
            int channelEvent = ev.status & 0xF0;
            if (channelEvent != 0xC0 && channelEvent != 0xD0) {
                trackData.push_back(ev.data2);
            }
        }
    }

    // End of track meta event
    trackData.push_back(0x00);
    trackData.push_back(0xFF);
    trackData.push_back(0x2F);
    trackData.push_back(0x00);

    out.insert(out.end(), {'M', 'T', 'r', 'k'});
    writeU32(out, (uint32_t)trackData.size());
    out.insert(out.end(), trackData.begin(), trackData.end());
}

// ── Event iteration ───────────────────────────────────────────────────────────

void iterateMidiEvents(const MidiFile& midi, MidiEventCallback callback) {
    // Flatten all events from all tracks
    std::vector<std::pair<uint32_t, const MidiEvent*>> allEvents;
    for (const auto& track : midi.tracks) {
        for (const auto& ev : track.events) {
            allEvents.push_back({ev.tick, &ev});
        }
    }
    std::sort(allEvents.begin(), allEvents.end(),
        [](const auto& a, const auto& b) { return a.first < b.first; });

    float secondsPerTick = 60.0f / (midi.tempoBpm * midi.ticksPerQuarter);
    for (const auto& pair : allEvents) {
        float seconds = pair.first * secondsPerTick;
        callback(*pair.second, seconds);
    }
}

} // namespace opensynth
