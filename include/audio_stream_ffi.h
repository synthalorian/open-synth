#pragma once
#include <cstdint>

#ifdef __cplusplus
extern "C" {
#endif

// ── Audio system lifecycle ──────────────────────────────────────────────────
// Call audio_system_init() at app startup. Call audio_system_shutdown() at
// app exit. These are ref-counted and safe to call multiple times.
// Device enumeration functions read from cached data — they never call
// Pa_Initialize/Pa_Terminate.

int32_t audio_system_init();
void    audio_system_shutdown();
int32_t audio_system_is_initialized();

// ── Audio stream lifecycle ──────────────────────────────────────────────────

void*  audio_stream_create_for_synth(void* synthHandle, double sampleRate, uint32_t blockSize, int32_t deviceIndex);
void*  audio_stream_create_for_pair(void* pairHandle, double sampleRate, uint32_t blockSize, int32_t deviceIndex);
void   audio_stream_destroy(void* stream);
int32_t audio_stream_start(void* stream);
void   audio_stream_stop(void* stream);
int32_t audio_stream_is_running(void* stream);
uint64_t audio_stream_callback_count(void* stream);
const char* audio_stream_last_error(void* stream);

// ── Device enumeration (reads from cache, no Pa_Init/Term) ──────────────────

int32_t audio_get_device_count();
const char* audio_get_device_name(int32_t index);
int32_t audio_get_default_output_device();
int32_t audio_get_device_max_output_channels(int32_t index);
double  audio_get_device_default_sample_rate(int32_t index);

#ifdef __cplusplus
}
#endif
