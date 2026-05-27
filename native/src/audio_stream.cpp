#include "audio_stream.h"
#include "audio_system.h"
#include <cstdio>
#include <cstring>
#include <algorithm>

namespace openamp {

AudioStream::AudioStream(openamp::SynthEngine* engine, double sampleRate,
                         uint32_t blockSize, int deviceIndex)
    : engine_(engine)
    , stream_(nullptr)
    , sampleRate_(sampleRate)
    , blockSize_(blockSize)
    , deviceIndex_(-1)
    , callbackCount_(0)
{
    errorBuf_[0] = '\0';

    if (engine_ == nullptr) {
        std::strcpy(errorBuf_, "AudioStream: null engine pointer");
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

    PaError err = Pa_StartStream(stream_);
    if (err != paNoError) {
        std::snprintf(errorBuf_, sizeof(errorBuf_),
                      "Pa_StartStream failed: %s", Pa_GetErrorText(err));
        return false;
    }
    return true;
}

void AudioStream::stop() {
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

    // Zero the output buffer first
    std::memset(out, 0, frameCount * 2 * sizeof(float));

    const uint32_t frames = static_cast<uint32_t>(frameCount);
    if (self->engine_) {
        AudioBuffer buf(out, frames, 2);
        self->engine_->process(buf);
    }

    self->callbackCount_++;
    return paContinue;
}

} // namespace openamp
