#pragma once
#include <juce_audio_basics/juce_audio_basics.h>
#include <juce_audio_formats/juce_audio_formats.h>
#include <vector>
#include <memory>
#include <atomic>
#include <string>

namespace opensynth {

// ── SampleStream ─────────────────────────────────────────────────────────────
//
// Disk streaming for large sample libraries using JUCE MemoryMappedAudioFormatReader.
//
// Features:
//   - Memory-mapped file access for efficient random seeking
//   - Preload cache: first 100ms kept in RAM for instant attack
//   - Configurable stream buffer size (default 4096 samples)
//   - Double-buffered read-ahead for non-mapped fallback
//   - Loop point support
//
// The stream is real-time safe for reading once opened.

class SampleStream {
public:
    static constexpr int DEFAULT_BUFFER_SIZE = 4096;
    static constexpr double PRELOAD_DURATION_SEC = 0.1; // 100ms

    SampleStream();
    ~SampleStream();

    // Open a file. Returns false on failure.
    bool open(const std::string& path, int streamBufferSize = DEFAULT_BUFFER_SIZE);

    // Close and release resources
    void close();

    // Returns true if the file is open and readable
    bool isOpen() const;

    // Number of channels
    int getNumChannels() const;

    // Total samples in the file
    int64_t getTotalSamples() const;

    // Sample rate of the file
    double getSampleRate() const;

    // Read one interleaved frame (one sample per channel) at 'position'.
    // 'dest' must hold at least getNumChannels() floats.
    // Returns true if sample was available.
    bool readSample(int64_t position, float* dest) const;

    // Read a block of samples into a JUCE AudioBuffer, starting at 'startPosition'.
    // Returns number of frames actually read.
    int readBlock(juce::AudioBuffer<float>& buffer, int startSample, int numSamples, int64_t filePosition);

    // Set/get stream buffer size (must be set before open)
    void setStreamBufferSize(int size) { streamBufferSize_ = size; }
    int getStreamBufferSize() const { return streamBufferSize_; }

    // Preload cache info
    int getPreloadSamples() const { return preloadSamples_; }

    // Loop points read from file metadata (e.g. WAV smpl chunk)
    bool hasLoopPoints() const { return hasLoopPoints_; }
    int getLoopStart() const { return loopStart_; }
    int getLoopEnd() const { return loopEnd_; }

private:
    std::unique_ptr<juce::MemoryMappedAudioFormatReader> mappedReader_;
    std::unique_ptr<juce::AudioFormatReader> fallbackReader_;
    std::unique_ptr<juce::FileInputStream> fileStream_;

    juce::File file_;
    double sampleRate_ = 48000.0;
    int numChannels_ = 0;
    int64_t totalSamples_ = 0;
    int streamBufferSize_ = DEFAULT_BUFFER_SIZE;

    // Loop points read from file metadata
    bool hasLoopPoints_ = false;
    int loopStart_ = 0;
    int loopEnd_ = 0;

    // Preload cache: first N samples kept in RAM for instant attack
    std::vector<float> preloadCache_[2]; // planar: L, R
    int preloadSamples_ = 0;
    bool useMapping_ = false;

    // Fallback ring-buffer state (non-mapped path)
    mutable std::vector<float> ringBuffer_[2];
    mutable std::atomic<int64_t> ringBufferStart_{0};
    mutable std::atomic<int64_t> ringBufferEnd_{0};
    mutable int ringBufferSize_ = 0;

    bool initMappedReader(const std::string& path);
    bool initFallbackReader(const std::string& path);
    void fillPreloadCache();
    void refillRingBuffer(int64_t startPos) const;
};

} // namespace opensynth
