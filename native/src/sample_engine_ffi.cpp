#include "sample_engine.h"
#include "audio_buffer.h"
#include <cstring>

using openamp::SampleEngine;

extern "C" {

// ── SampleEngine lifecycle ───────────────────────────────────────────────────

void* sample_engine_create() {
    return new SampleEngine();
}

void sample_engine_destroy(void* engine) {
    delete static_cast<SampleEngine*>(engine);
}

// ── SFZ loading ──────────────────────────────────────────────────────────────

int sample_engine_load_file(void* engine, const char* path) {
    auto* e = static_cast<SampleEngine*>(engine);
    if (!e) return 0;
    return e->loadSfzFile(path) ? 1 : 0;
}

int sample_engine_load_string(void* engine, const char* virtual_path, const char* text) {
    auto* e = static_cast<SampleEngine*>(engine);
    if (!e) return 0;
    return e->loadSfzString(virtual_path ? virtual_path : "", text ? text : "") ? 1 : 0;
}

// ── Configuration ────────────────────────────────────────────────────────────

void sample_engine_set_sample_rate(void* engine, float sample_rate) {
    auto* e = static_cast<SampleEngine*>(engine);
    if (e) e->setSampleRate(sample_rate);
}

void sample_engine_set_block_size(void* engine, int block_size) {
    auto* e = static_cast<SampleEngine*>(engine);
    if (e) e->setBlockSize(block_size);
}

void sample_engine_set_volume(void* engine, float volume_db) {
    auto* e = static_cast<SampleEngine*>(engine);
    if (e) e->setVolume(volume_db);
}

float sample_engine_get_volume(void* engine) {
    auto* e = static_cast<SampleEngine*>(engine);
    return e ? e->getVolume() : 0.0f;
}

// ── MIDI events ──────────────────────────────────────────────────────────────

void sample_engine_note_on(void* engine, int delay, int note_number, int velocity) {
    auto* e = static_cast<SampleEngine*>(engine);
    if (e) e->noteOn(delay, note_number, velocity);
}

void sample_engine_note_off(void* engine, int delay, int note_number, int velocity) {
    auto* e = static_cast<SampleEngine*>(engine);
    if (e) e->noteOff(delay, note_number, velocity);
}

void sample_engine_cc(void* engine, int delay, int cc_number, int cc_value) {
    auto* e = static_cast<SampleEngine*>(engine);
    if (e) e->cc(delay, cc_number, cc_value);
}

void sample_engine_pitch_wheel(void* engine, int delay, int pitch) {
    auto* e = static_cast<SampleEngine*>(engine);
    if (e) e->pitchWheel(delay, pitch);
}

void sample_engine_aftertouch(void* engine, int delay, int aftertouch) {
    auto* e = static_cast<SampleEngine*>(engine);
    if (e) e->aftertouch(delay, aftertouch);
}

// ── Audio rendering ──────────────────────────────────────────────────────────

void sample_engine_render(void* engine, float* output, int num_frames) {
    auto* e = static_cast<SampleEngine*>(engine);
    if (e) {
        e->render(output, num_frames);
    } else {
        std::memset(output, 0, num_frames * 2 * sizeof(float));
    }
}

// ── State queries ────────────────────────────────────────────────────────────

int sample_engine_get_num_active_voices(void* engine) {
    auto* e = static_cast<SampleEngine*>(engine);
    return e ? e->getNumActiveVoices() : 0;
}

int sample_engine_get_num_voices(void* engine) {
    auto* e = static_cast<SampleEngine*>(engine);
    return e ? e->getNumVoices() : 0;
}

void sample_engine_set_num_voices(void* engine, int num_voices) {
    auto* e = static_cast<SampleEngine*>(engine);
    if (e) e->setNumVoices(num_voices);
}

int sample_engine_get_num_regions(void* engine) {
    auto* e = static_cast<SampleEngine*>(engine);
    return e ? e->getNumRegions() : 0;
}

int sample_engine_get_num_preloaded_samples(void* engine) {
    auto* e = static_cast<SampleEngine*>(engine);
    return e ? static_cast<int>(e->getNumPreloadedSamples()) : 0;
}

int sample_engine_is_loaded(void* engine) {
    auto* e = static_cast<SampleEngine*>(engine);
    return e && e->isLoaded() ? 1 : 0;
}

void sample_engine_all_sound_off(void* engine) {
    auto* e = static_cast<SampleEngine*>(engine);
    if (e) e->allSoundOff();
}

} // extern "C"
