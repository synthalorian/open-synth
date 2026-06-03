#pragma once
#include <cstdint>
#include <cstdio>
#include <vector>
#include <string>
#include <atomic>
#include <mutex>

namespace opensynth {

// ── WAV file writer ──────────────────────────────────────────────────────────

enum class WavBitDepth : int {
    BITS_16 = 16,
    BITS_24 = 24,
    BITS_32 = 32,
};

class WavWriter {
public:
    WavWriter();
    ~WavWriter();

    // Open a file for writing. sampleRate = Hz, channels = 1 or 2
    bool open(const char* path, int sampleRate, int channels, WavBitDepth bits);
    void close();

    // Write interleaved float samples (-1.0 to 1.0). Returns true on success.
    bool writeInterleaved(const float* samples, uint32_t numFrames);

    bool isOpen() const { return file_ != nullptr; }
    uint32_t framesWritten() const { return framesWritten_; }

private:
    std::FILE* file_ = nullptr;
    int sampleRate_ = 48000;
    int channels_ = 2;
    WavBitDepth bitDepth_ = WavBitDepth::BITS_24;
    uint32_t framesWritten_ = 0;
    uint32_t dataChunkPos_ = 0;

    void writeHeader();
    void finalizeHeader();
};

// ── Transport state ──────────────────────────────────────────────────────────

enum class TransportState : uint8_t {
    STOPPED = 0,
    RECORDING,
    PLAYING,
};

// ── Recording engine ─────────────────────────────────────────────────────────

class Recorder {
public:
    Recorder();
    ~Recorder();

    // Configuration
    void setSampleRate(int sr) { sampleRate_ = sr; }
    void setBitDepth(WavBitDepth bits) { bitDepth_ = bits; }

    // Transport
    void startRecording(const char* path);
    void stop();
    void startPlayback(const char* path);  // Future: playback recorded file

    TransportState state() const { return state_.load(); }
    uint32_t recordedFrames() const { return recordedFrames_.load(); }
    double recordedSeconds() const { return recordedFrames_.load() / static_cast<double>(sampleRate_); }

    // Process a block of audio. Called from audio thread.
    // If recording, writes samples to WAV file.
    void process(const float* left, const float* right, uint32_t numFrames);

    // Multi-track: record individual part outputs
    void setMultiTrackEnabled(bool e) { multiTrack_ = e; }
    bool multiTrackEnabled() const { return multiTrack_; }

private:
    std::atomic<TransportState> state_{TransportState::STOPPED};
    WavWriter writer_;
    int sampleRate_ = 48000;
    WavBitDepth bitDepth_ = WavBitDepth::BITS_24;
    std::atomic<uint32_t> recordedFrames_{0};
    bool multiTrack_ = false;

    // Temp buffer for interleaving
    std::vector<float> interleaveBuf_;
    std::mutex bufMutex_;
};

} // namespace opensynth
