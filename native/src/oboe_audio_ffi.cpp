#include "audio_stream_ffi.h"
#include "oboe_audio_stream.h"
#include "synth_engine.h"
#include "synth_mixer.h"

// ── Audio system lifecycle (Oboe stubs — no global init needed) ────────────

int32_t audio_system_init() {
    // Oboe doesn't require global initialization.
    return 1;
}

void audio_system_shutdown() {
    // No-op on Android.
}

int32_t audio_system_is_initialized() {
    return 1;
}

// ── Audio stream lifecycle ────────────────────────────────────────────────

void* audio_stream_create_for_synth(void* synthHandle, double sampleRate,
                                     uint32_t blockSize, int32_t deviceIndex) {
    (void)deviceIndex; // Android always uses the default output device.

    auto* engine = static_cast<openamp::SynthEngine*>(synthHandle);
    if (engine == nullptr) return nullptr;

    auto* stream = new openamp::OboeAudioStream(
        engine,
        [](void* ctx, openamp::AudioBuffer& buf) {
            static_cast<openamp::SynthEngine*>(ctx)->process(buf);
        },
        sampleRate, blockSize);
    return static_cast<void*>(stream);
}

void* audio_stream_create_for_pair(void* pairHandle, double sampleRate,
                                    uint32_t blockSize, int32_t deviceIndex) {
    (void)deviceIndex; // Android always uses the default output device.

    auto* pair = static_cast<openamp::SynthEnginePair*>(pairHandle);
    if (pair == nullptr) return nullptr;

    auto* stream = new openamp::OboeAudioStream(
        pair,
        [](void* ctx, openamp::AudioBuffer& buf) {
            static_cast<openamp::SynthEnginePair*>(ctx)->process(buf);
        },
        sampleRate, blockSize);
    return static_cast<void*>(stream);
}

void audio_stream_destroy(void* stream) {
    delete static_cast<openamp::OboeAudioStream*>(stream);
}

int32_t audio_stream_start(void* stream) {
    auto* s = static_cast<openamp::OboeAudioStream*>(stream);
    return s ? (s->start() ? 1 : 0) : 0;
}

void audio_stream_stop(void* stream) {
    auto* s = static_cast<openamp::OboeAudioStream*>(stream);
    if (s) s->stop();
}

int32_t audio_stream_is_running(void* stream) {
    auto* s = static_cast<openamp::OboeAudioStream*>(stream);
    return s ? (s->isRunning() ? 1 : 0) : 0;
}

uint64_t audio_stream_callback_count(void* stream) {
    auto* s = static_cast<openamp::OboeAudioStream*>(stream);
    return s ? s->callbackCount() : 0;
}

const char* audio_stream_last_error(void* stream) {
    auto* s = static_cast<openamp::OboeAudioStream*>(stream);
    return s ? s->lastError() : "null stream";
}

// ── Device enumeration (Android stubs — single "Default" device) ──────────

static thread_local char sDeviceNameBuf[256] = {};

int32_t audio_get_device_count() {
    return 1;
}

const char* audio_get_device_name(int32_t index) {
    if (index == 0) {
        std::strncpy(sDeviceNameBuf, "Default", sizeof(sDeviceNameBuf) - 1);
        sDeviceNameBuf[sizeof(sDeviceNameBuf) - 1] = '\0';
        return sDeviceNameBuf;
    }
    sDeviceNameBuf[0] = '\0';
    return sDeviceNameBuf;
}

int32_t audio_get_default_output_device() {
    return 0;
}

int32_t audio_get_device_max_output_channels(int32_t index) {
    return (index == 0) ? 2 : 0;
}

double audio_get_device_default_sample_rate(int32_t index) {
    return (index == 0) ? 48000.0 : 0.0;
}
