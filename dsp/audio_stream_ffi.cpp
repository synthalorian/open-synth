#include "audio_stream_ffi.h"
#include "audio_system.h"
#include "audio_stream.h"
#include "synth_engine.h"
#include "synth_mixer.h"

using opensynth::AudioSystem;

// ── Audio system lifecycle ────────────────────────────────────────────────────

int32_t audio_system_init() {
    return AudioSystem::instance().init() ? 1 : 0;
}

void audio_system_shutdown() {
    AudioSystem::instance().shutdown();
}

int32_t audio_system_is_initialized() {
    return AudioSystem::instance().isInitialized() ? 1 : 0;
}

// ── Audio stream lifecycle ────────────────────────────────────────────────────

void* audio_stream_create_for_synth(void* synthHandle, double sampleRate,
                                     uint32_t blockSize, int32_t deviceIndex) {
    auto* engine = static_cast<opensynth::SynthEngine*>(synthHandle);
    if (engine == nullptr) return nullptr;

    // Create a generic processor that calls SynthEngine::process
    auto* stream = new opensynth::AudioStream(
        engine,
        [](void* ctx, opensynth::AudioBuffer& buf) {
            static_cast<opensynth::SynthEngine*>(ctx)->process(buf);
        },
        sampleRate, blockSize,
        static_cast<int>(deviceIndex));
    return static_cast<void*>(stream);
}

void* audio_stream_create_for_pair(void* pairHandle, double sampleRate,
                                    uint32_t blockSize, int32_t deviceIndex) {
    auto* pair = static_cast<opensynth::SynthEnginePair*>(pairHandle);
    if (pair == nullptr) return nullptr;

    auto* stream = new opensynth::AudioStream(
        pair,
        [](void* ctx, opensynth::AudioBuffer& buf) {
            static_cast<opensynth::SynthEnginePair*>(ctx)->process(buf);
        },
        sampleRate, blockSize,
        static_cast<int>(deviceIndex));
    return static_cast<void*>(stream);
}

void audio_stream_destroy(void* stream) {
    delete static_cast<opensynth::AudioStream*>(stream);
}

int32_t audio_stream_start(void* stream) {
    auto* s = static_cast<opensynth::AudioStream*>(stream);
    return s ? (s->start() ? 1 : 0) : 0;
}

void audio_stream_stop(void* stream) {
    auto* s = static_cast<opensynth::AudioStream*>(stream);
    if (s) s->stop();
}

int32_t audio_stream_is_running(void* stream) {
    auto* s = static_cast<opensynth::AudioStream*>(stream);
    return s ? (s->isRunning() ? 1 : 0) : 0;
}

uint64_t audio_stream_callback_count(void* stream) {
    auto* s = static_cast<opensynth::AudioStream*>(stream);
    return s ? s->callbackCount() : 0;
}

const char* audio_stream_last_error(void* stream) {
    auto* s = static_cast<opensynth::AudioStream*>(stream);
    return s ? s->lastError() : "null stream";
}

// ── Device enumeration (cached — no Pa_Initialize/Pa_Terminate) ──────────────

// Static buffers for C-string returns (device enumeration returns pointers
// that must outlive the call).  Since devices are cached, these are stable.
static thread_local char sDeviceNameBuf[256];

int32_t audio_get_device_count() {
    return AudioSystem::instance().deviceCount();
}

const char* audio_get_device_name(int32_t index) {
    const auto* dev = AudioSystem::instance().deviceAt(static_cast<int>(index));
    if (dev == nullptr) {
        sDeviceNameBuf[0] = '\0';
        return sDeviceNameBuf;
    }
    std::strncpy(sDeviceNameBuf, dev->name.c_str(), sizeof(sDeviceNameBuf) - 1);
    sDeviceNameBuf[sizeof(sDeviceNameBuf) - 1] = '\0';
    return sDeviceNameBuf;
}

int32_t audio_get_default_output_device() {
    return static_cast<int32_t>(AudioSystem::instance().defaultOutputDevice());
}

int32_t audio_get_device_max_output_channels(int32_t index) {
    const auto* dev = AudioSystem::instance().deviceAt(static_cast<int>(index));
    return dev ? dev->maxOutputChannels : 0;
}

double audio_get_device_default_sample_rate(int32_t index) {
    const auto* dev = AudioSystem::instance().deviceAt(static_cast<int>(index));
    return dev ? dev->defaultSampleRate : 0.0;
}
