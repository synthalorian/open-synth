#include "oboe_audio_stream.h"
#include <cstdio>
#include <cstring>

namespace opensynth {

OboeAudioStream::OboeAudioStream(void* processorContext, AudioProcessor processorFn,
                                   double sampleRate, uint32_t blockSize)
    : processorContext_(processorContext)
    , processorFn_(processorFn)
    , sampleRate_(sampleRate)
    , blockSize_(blockSize)
{
    errorBuf_[0] = '\0';

    if (processorContext_ == nullptr || processorFn_ == nullptr) {
        std::strcpy(errorBuf_, "OboeAudioStream: null processor context or function");
        return;
    }

    oboe::AudioStreamBuilder builder;
    oboe::Result result = builder
        .setDirection(oboe::Direction::Output)
        ->setPerformanceMode(oboe::PerformanceMode::LowLatency)
        ->setSharingMode(oboe::SharingMode::Exclusive)
        ->setFormat(oboe::AudioFormat::Float)
        ->setChannelCount(2)  // stereo
        ->setSampleRate(static_cast<int32_t>(sampleRate_))
        ->setBufferCapacityInFrames(static_cast<int32_t>(blockSize_ * 2))
        ->setFramesPerDataCallback(static_cast<int32_t>(blockSize_))
        ->setDataCallback(this)
        ->openStream(stream_);

    if (result != oboe::Result::OK) {
        std::snprintf(errorBuf_, sizeof(errorBuf_),
                      "OboeAudioStream: failed to open stream: %s",
                      oboe::convertToText(result));
        stream_.reset();
    }
}

OboeAudioStream::~OboeAudioStream() {
    stop();
    if (stream_) {
        stream_->close();
        stream_.reset();
    }
}

bool OboeAudioStream::start() {
    if (!stream_) {
        if (errorBuf_[0] == '\0') {
            std::strcpy(errorBuf_, "OboeAudioStream: no stream (create failed)");
        }
        return false;
    }

    running_.store(true, std::memory_order_release);
    oboe::Result result = stream_->requestStart();
    if (result != oboe::Result::OK) {
        std::snprintf(errorBuf_, sizeof(errorBuf_),
                      "OboeAudioStream: requestStart failed: %s",
                      oboe::convertToText(result));
        running_.store(false, std::memory_order_release);
        return false;
    }
    return true;
}

void OboeAudioStream::stop() {
    running_.store(false, std::memory_order_release);
    if (stream_) {
        oboe::Result result = stream_->requestStop();
        if (result != oboe::Result::OK) {
            // Best-effort stop; log but don't overwrite a previous error
            if (errorBuf_[0] == '\0') {
                std::snprintf(errorBuf_, sizeof(errorBuf_),
                              "OboeAudioStream: requestStop returned: %s",
                              oboe::convertToText(result));
            }
        }
    }
}

bool OboeAudioStream::isRunning() const {
    if (!stream_) return false;
    return running_.load(std::memory_order_acquire) &&
           stream_->getState() == oboe::StreamState::Open;
}

oboe::DataCallbackResult OboeAudioStream::onAudioReady(
        oboe::AudioStream* /*stream*/,
        void* audioData,
        int32_t numFrames)
{
    auto* out = static_cast<float*>(audioData);

    // Zero the output buffer first (silence if we bail early)
    std::memset(out, 0, static_cast<size_t>(numFrames) * 2 * sizeof(float));

    // Check the running_ flag before touching the processor.
    // This is the shutdown safety guard: once stop() sets running_=false,
    // the callback returns silence immediately, preventing use-after-free.
    if (!running_.load(std::memory_order_acquire)) {
        return oboe::DataCallbackResult::Continue;
    }

    const uint32_t frames = static_cast<uint32_t>(numFrames);
    if (processorContext_ && processorFn_) {
        AudioBuffer buf(out, frames, 2);
        processorFn_(processorContext_, buf);
    }

    callbackCount_++;
    return oboe::DataCallbackResult::Continue;
}

} // namespace opensynth
