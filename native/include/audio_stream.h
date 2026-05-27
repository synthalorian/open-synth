#pragma once
#include <cstdint>
#include <portaudio.h>
#include "synth_engine.h"

namespace openamp {

class AudioStream {
public:
    AudioStream(openamp::SynthEngine* engine, double sampleRate, uint32_t blockSize, int deviceIndex = -1);
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

    openamp::SynthEngine* engine_;
    PaStream* stream_;
    double sampleRate_;
    uint32_t blockSize_;
    int deviceIndex_;
    uint64_t callbackCount_;
    char errorBuf_[512];
    // Does NOT own the PortAudio session — AudioSystem singleton does
};

} // namespace openamp
