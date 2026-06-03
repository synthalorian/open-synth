#pragma once
#include <juce_audio_basics/juce_audio_basics.h>
#include <juce_audio_formats/juce_audio_formats.h>
#include <vector>
#include <memory>
#include <atomic>
#include <string>
#include <cstdint>

namespace opensynth {

// ── StreamMetrics ────────────────────────────────────────────────────────────
// Lightweight atomic counters for cache hit rate and underruns.
struct StreamMetrics {
    std::atomic<uint64_t> preloadHits{0};
    std::atomic<uint64_t> ringHits{0};
    std::atomic<uint64_t> misses{0};
    std::atomic<uint64_t> underruns{0};
    std::atomic<uint64_t> totalRequests{0};

    void reset() {
        preloadHits.store(0);
        ringHits.store(0);
        misses.store(0);
        underruns.store(0);
        totalRequests.store(0);
    }

    double cacheHitRate() const {
        uint64_t total = totalRequests.load();
        if (total == 0) return 0.0;
        uint64_t hits = preloadHits.load() + ringHits.load();
        return static_cast<double>(hits) / static_cast<double>(total);
    }
};

// ── SampleStream ─────────────────────────────────────────────────────────────
//
// Disk streaming for large sample libraries using JUCE MemoryMappedAudioFormatReader.
//
// Features:
//   - Memory-mapped file access for efficient random seeking
//   - Preload cache: first 100ms kept in RAM for instant attack
//   - Configurable stream buffer size (default 4096 samples)
//   - Prefetch ring-buffer for non-mapped fallback with read-ahead
//   - Loop point support
//   - Stream metrics (cache hits, underruns)
//
// The stream is real-time safe for reading once opened.

class SampleStream {
public:
    static constexpr int DEFAULT_BUFFER_SIZE = 4096;
    static constexpr int PREFETCH_BUFFER_SIZE = 32768; // ~0.7s at 48kHz
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

    // Prefetch / read-ahead: ensure the ring buffer covers [position, position + prefetchSize)
    void prefetch(int64_t position);

    // Set/get stream buffer size (must be set before open)
    void setStreamBufferSize(int size) { streamBufferSize_ = size; }
    int getStreamBufferSize() const { return streamBufferSize_; }

    // Preload cache info
    int getPreloadSamples() const { return preloadSamples_; }

    // Loop points read from file metadata (e.g. WAV smpl chunk)
    bool hasLoopPoints() const { return hasLoopPoints_; }
    int getLoopStart() const { return loopStart_; }
    int getLoopEnd() const { return loopEnd_; }

    // Metrics
    const StreamMetrics& getMetrics() const { return metrics_; }
    void resetMetrics() { metrics_.reset(); }

    // True if using memory-mapped I/O
    bool isMemoryMapped() const { return useMapping_; }

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

    // Prefetch ring-buffer state (non-mapped path)
    mutable std::vector<float> ringBuffer_[2];
    mutable std::atomic<int64_t> ringBufferStart_{0};
    mutable std::atomic<int64_t> ringBufferEnd_{0};
    int ringBufferSize_ = 0;

    mutable StreamMetrics metrics_;

    bool initMappedReader(const std::string& path);
    bool initFallbackReader(const std::string& path);
    void fillPreloadCache();
    void refillRingBuffer(int64_t startPos) const;
    bool verifyMappingWorks();
};

} // namespace opensynth
