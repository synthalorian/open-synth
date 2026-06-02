#pragma once
#include <atomic>
#include <cstdint>
#include <memory>
#include <oboe/Oboe.h>
#include "audio_buffer.h"

namespace openamp {

// Same AudioProcessor callback type as audio_stream.h
using AudioProcessor = void(*)(void* context, AudioBuffer& output);

class OboeAudioStream : public oboe::AudioStreamDataCallback {
public:
    OboeAudioStream(void* processorContext, AudioProcessor processorFn,
                    double sampleRate, uint32_t blockSize);
    ~OboeAudioStream();

    // No copy
    OboeAudioStream(const OboeAudioStream&) = delete;
    OboeAudioStream& operator=(const OboeAudioStream&) = delete;

    bool start();
    void stop();
    bool isRunning() const;
    uint64_t callbackCount() const { return callbackCount_; }
    const char* lastError() const { return errorBuf_; }

    // oboe::AudioStreamDataCallback
    oboe::DataCallbackResult onAudioReady(
        oboe::AudioStream* stream,
        void* audioData,
        int32_t numFrames) override;

private:
    void* processorContext_;
    AudioProcessor processorFn_;
    std::shared_ptr<oboe::AudioStream> stream_;
    double sampleRate_;
    uint32_t blockSize_;
    uint64_t callbackCount_ = 0;
    std::atomic<bool> running_{false};
    char errorBuf_[512] = {};
};

} // namespace openamp
