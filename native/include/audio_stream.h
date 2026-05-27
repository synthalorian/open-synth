#pragma once
#include <atomic>
#include <cstdint>
#include <functional>
#include <portaudio.h>
#include "audio_buffer.h"

namespace openamp {

/// Process callback type — a function that fills an AudioBuffer with audio.
/// Used to abstract over SynthEngine, SynthEnginePair, or any other processor.
using AudioProcessor = void(*)(void* context, AudioBuffer& output);

class AudioStream {
public:
    /// Create an audio stream bound to a generic audio processor.
    /// The processor callback is called from the realtime audio thread.
    AudioStream(void* processorContext, AudioProcessor processorFn,
                double sampleRate, uint32_t blockSize, int deviceIndex = -1);
    ~AudioStream();

    // No copy
    AudioStream(const AudioStream&) = delete;
    AudioStream& operator=(const AudioStream&) = delete;

    bool start();
    void stop();
    bool isRunning() const;
    uint64_t callbackCount() const { return callbackCount_; }
    const char* lastError() const { return errorBuf_; }
    int deviceIndex() const { return deviceIndex_; }

private:
    static int paCallback(const void* input, void* output,
                          unsigned long frameCount,
                          const PaStreamCallbackTimeInfo* timeInfo,
                          PaStreamCallbackFlags statusFlags,
                          void* userData);

    void* processorContext_;
    AudioProcessor processorFn_;
    PaStream* stream_;
    double sampleRate_;
    uint32_t blockSize_;
    int deviceIndex_;
    uint64_t callbackCount_;
    std::atomic<bool> running_{true};
    char errorBuf_[512];
    // Does NOT own the PortAudio session — AudioSystem singleton does
};

} // namespace openamp
