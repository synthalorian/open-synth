#include "audio_stream.h"
#include "audio_system.h"
#include <cstdio>
#include <cstring>
#include <algorithm>

namespace opensynth {

AudioStream::AudioStream(void* processorContext, AudioProcessor processorFn,
                         double sampleRate, uint32_t blockSize, int deviceIndex)
    : processorContext_(processorContext)
    , processorFn_(processorFn)
    , stream_(nullptr)
    , sampleRate_(sampleRate)
    , blockSize_(blockSize)
    , deviceIndex_(-1)
    , callbackCount_(0)
{
    errorBuf_[0] = '\0';

    if (processorContext_ == nullptr || processorFn_ == nullptr) {
        std::strcpy(errorBuf_, "AudioStream: null processor context or function");
        return;
    }

    // Ensure PortAudio is initialized via the singleton.
    // The singleton owns Pa_Initialize/Pa_Terminate — we never call them.
    if (!AudioSystem::instance().init()) {
        std::strcpy(errorBuf_, "AudioStream: AudioSystem::init() failed");
        return;
    }

    // Resolve default device from cached data
    if (deviceIndex < 0) {
        deviceIndex_ = AudioSystem::instance().defaultOutputDevice();
    } else {
        deviceIndex_ = deviceIndex;
    }

    if (deviceIndex_ < 0) {
        std::strcpy(errorBuf_, "AudioStream: no output device found");
        return;
    }

    // Get device info from the PortAudio API (PA is already initialized)
    const PaDeviceInfo* devInfo = Pa_GetDeviceInfo(deviceIndex_);
    if (devInfo == nullptr) {
        std::snprintf(errorBuf_, sizeof(errorBuf_),
                      "Pa_GetDeviceInfo(%d) returned null", deviceIndex_);
        return;
    }

    PaStreamParameters outputParams;
    std::memset(&outputParams, 0, sizeof(outputParams));
    outputParams.device = deviceIndex_;
    outputParams.channelCount = 2; // stereo
    outputParams.sampleFormat = paFloat32;
    outputParams.suggestedLatency = devInfo->defaultLowOutputLatency;
    outputParams.hostApiSpecificStreamInfo = nullptr;

    PaError err = Pa_OpenStream(
        &stream_,
        nullptr, // no input
        &outputParams,
        sampleRate_,
        blockSize_,
        paClipOff | paPrimeOutputBuffersUsingStreamCallback,
        paCallback,
        this);

    if (err != paNoError) {
        std::snprintf(errorBuf_, sizeof(errorBuf_),
                      "Pa_OpenStream failed: %s", Pa_GetErrorText(err));
        stream_ = nullptr;
    }
}

AudioStream::~AudioStream() {
    stop();
    if (stream_) {
        Pa_CloseStream(stream_);
        stream_ = nullptr;
    }
    // Do NOT call Pa_Terminate here — AudioSystem owns that.
}

bool AudioStream::start() {
    if (stream_ == nullptr) {
        if (errorBuf_[0] == '\0') {
            std::strcpy(errorBuf_, "AudioStream: no stream (create failed)");
        }
        return false;
    }

    running_ = true;
    PaError err = Pa_StartStream(stream_);
    if (err != paNoError) {
        std::snprintf(errorBuf_, sizeof(errorBuf_),
                      "Pa_StartStream failed: %s", Pa_GetErrorText(err));
        return false;
    }
    return true;
}

void AudioStream::stop() {
    // Signal the callback to bail out immediately on next invocation.
    // This ensures Pa_StopStream() won't deadlock if a callback is stuck
    // processing, and makes the destructor safe against race conditions.
    running_ = false;
    if (stream_ && Pa_IsStreamActive(stream_) == 1) {
        Pa_StopStream(stream_);
    }
}

bool AudioStream::isRunning() const {
    if (stream_ == nullptr) return false;
    return Pa_IsStreamActive(stream_) == 1;
}

int AudioStream::paCallback(const void* input, void* output,
                             unsigned long frameCount,
                             const PaStreamCallbackTimeInfo* timeInfo,
                             PaStreamCallbackFlags statusFlags,
                             void* userData) {
    (void)input;
    (void)timeInfo;
    (void)statusFlags;

    auto* self = static_cast<AudioStream*>(userData);
    auto* out = static_cast<float*>(output);

    // Zero the output buffer first (silence if we bail early)
    std::memset(out, 0, frameCount * 2 * sizeof(float));

    // Check the running_ flag before touching the processor.
    // This is the shutdown safety guard: once stop() sets running_=false,
    // the callback returns silence immediately, preventing use-after-free
    // when the processor or its context is destroyed concurrently.
    if (!self->running_.load(std::memory_order_acquire)) {
        return paContinue;
    }

    const uint32_t frames = static_cast<uint32_t>(frameCount);
    if (self->processorContext_ && self->processorFn_) {
        AudioBuffer buf(out, frames, 2);
        self->processorFn_(self->processorContext_, buf);
    }

    self->callbackCount_++;
    return paContinue;
}

} // namespace opensynth
