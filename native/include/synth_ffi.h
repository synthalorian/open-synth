#pragma once
#include <cstdint>

#ifdef __cplusplus
extern "C" {
#endif

void* synth_engine_create(double sampleRate, uint32_t blockSize);
void  synth_engine_destroy(void* engine);
void  synth_engine_process(void* engine, float* output, uint32_t numFrames);
void  synth_engine_reset(void* engine);

void  synth_engine_note_on(void* engine, int32_t midiNote, float velocity);
void  synth_engine_note_off(void* engine, int32_t midiNote);
void  synth_engine_all_notes_off(void* engine);

// Osc 1
void synth_engine_set_osc1_waveform(void* engine, int32_t v);
void synth_engine_set_osc1_octave(void* engine, int32_t v);
void synth_engine_set_osc1_detune(void* engine, float v);
void synth_engine_set_osc1_pulse_width(void* engine, float v);
void synth_engine_set_osc1_volume(void* engine, float v);

// Osc 2
void synth_engine_set_osc2_waveform(void* engine, int32_t v);
void synth_engine_set_osc2_octave(void* engine, int32_t v);
void synth_engine_set_osc2_detune(void* engine, float v);
void synth_engine_set_osc2_pulse_width(void* engine, float v);
void synth_engine_set_osc2_volume(void* engine, float v);
void synth_engine_set_osc_mix(void* engine, float v);

// Filter
void synth_engine_set_filter_type(void* engine, int32_t v);
void synth_engine_set_filter_cutoff(void* engine, float v);
void synth_engine_set_filter_resonance(void* engine, float v);
void synth_engine_set_filter_env_amount(void* engine, float v);

// Amp envelope
void synth_engine_set_amp_attack(void* engine, float v);
void synth_engine_set_amp_decay(void* engine, float v);
void synth_engine_set_amp_sustain(void* engine, float v);
void synth_engine_set_amp_release(void* engine, float v);

// Filter envelope
void synth_engine_set_filter_attack(void* engine, float v);
void synth_engine_set_filter_decay(void* engine, float v);
void synth_engine_set_filter_sustain(void* engine, float v);
void synth_engine_set_filter_release(void* engine, float v);

// LFO 1
void synth_engine_set_lfo1_waveform(void* engine, int32_t v);
void synth_engine_set_lfo1_rate(void* engine, float v);
void synth_engine_set_lfo1_depth(void* engine, float v);
void synth_engine_set_lfo1_target(void* engine, int32_t v);

// LFO 2
void synth_engine_set_lfo2_waveform(void* engine, int32_t v);
void synth_engine_set_lfo2_rate(void* engine, float v);
void synth_engine_set_lfo2_depth(void* engine, float v);
void synth_engine_set_lfo2_target(void* engine, int32_t v);

// FX: Chorus
void synth_engine_set_chorus_enabled(void* engine, int32_t v);
void synth_engine_set_chorus_rate(void* engine, float v);
void synth_engine_set_chorus_depth(void* engine, float v);
void synth_engine_set_chorus_mix(void* engine, float v);

// FX: Delay
void synth_engine_set_delay_enabled(void* engine, int32_t v);
void synth_engine_set_delay_time(void* engine, float v);
void synth_engine_set_delay_feedback(void* engine, float v);
void synth_engine_set_delay_mix(void* engine, float v);

// FX: Reverb
void synth_engine_set_reverb_enabled(void* engine, int32_t v);
void synth_engine_set_reverb_size(void* engine, float v);
void synth_engine_set_reverb_damping(void* engine, float v);
void synth_engine_set_reverb_mix(void* engine, float v);

// FX: Phaser
void synth_engine_set_phaser_enabled(void* engine, int32_t v);
void synth_engine_set_phaser_rate(void* engine, float v);
void synth_engine_set_phaser_depth(void* engine, float v);
void synth_engine_set_phaser_feedback(void* engine, float v);
void synth_engine_set_phaser_mix(void* engine, float v);

// FX: Drive
void synth_engine_set_drive_enabled(void* engine, int32_t v);
void synth_engine_set_drive_amount(void* engine, float v);
void synth_engine_set_drive_type(void* engine, int32_t v);

// FX: Flanger
void synth_engine_set_flanger_enabled(void* engine, int32_t v);
void synth_engine_set_flanger_rate(void* engine, float v);
void synth_engine_set_flanger_depth(void* engine, float v);
void synth_engine_set_flanger_feedback(void* engine, float v);
void synth_engine_set_flanger_mix(void* engine, float v);

// FX: Compressor
void synth_engine_set_compressor_enabled(void* engine, int32_t v);
void synth_engine_set_compressor_threshold(void* engine, float v);
void synth_engine_set_compressor_ratio(void* engine, float v);
void synth_engine_set_compressor_attack(void* engine, float v);
void synth_engine_set_compressor_release(void* engine, float v);
void synth_engine_set_compressor_makeup_gain(void* engine, float v);

// Master
void synth_engine_set_master_volume(void* engine, float v);
int32_t synth_engine_get_active_voices(void* engine);

// ── Thread-safe parameter queue ─────────────────────────────────────────────
// These enqueue parameters into the lock-free SPSC ring buffer.
// The audio thread drains the queue at the start of each process block.
// Use these instead of the direct setters above when audio is running.

void    synth_engine_enqueue_float(void* engine, int32_t paramId, float value);
void    synth_engine_enqueue_int(void* engine, int32_t paramId, int32_t value);
void    synth_engine_enqueue_note_on(void* engine, int32_t note, float velocity);
void    synth_engine_enqueue_note_off(void* engine, int32_t note);
void    synth_engine_enqueue_all_notes_off(void* engine);
void    synth_engine_enqueue_reset(void* engine);

// Preset
int32_t synth_engine_load_preset(void* engine, const char* path);
int32_t synth_engine_save_preset(void* engine, const char* path);

// ── Unison ────────────────────────────────────────────────────────────────────

// Osc 1
void synth_engine_set_osc1_unison_voice_count(void* engine, int32_t v);
void synth_engine_set_osc1_unison_detune_spread(void* engine, float v);
void synth_engine_set_osc1_unison_stereo_spread(void* engine, float v);
void synth_engine_set_osc1_unison_mix(void* engine, float v);

// Osc 2
void synth_engine_set_osc2_unison_voice_count(void* engine, int32_t v);
void synth_engine_set_osc2_unison_detune_spread(void* engine, float v);
void synth_engine_set_osc2_unison_stereo_spread(void* engine, float v);
void synth_engine_set_osc2_unison_mix(void* engine, float v);

#ifdef __cplusplus
}
#endif
