#include "synth_ffi.h"
#include "synth_engine.h"
#include "synth_mixer.h"
#include "audio_buffer.h"
#include <cstring>
#include <string>

using namespace openamp;

// ── Lifecycle ─────────────────────────────────────────────────────────────────

void* synth_engine_create(double sampleRate, uint32_t blockSize) {
    auto* engine = new SynthEngine(sampleRate, blockSize);
    return static_cast<void*>(engine);
}

void synth_engine_destroy(void* engine) {
    delete static_cast<SynthEngine*>(engine);
}

void synth_engine_process(void* engine, float* output, uint32_t numFrames) {
    auto* e = static_cast<SynthEngine*>(engine);
    AudioBuffer buf(output, numFrames, 1); // mono — matches existing Dart API
    e->process(buf);
}

void synth_engine_reset(void* engine) {
    static_cast<SynthEngine*>(engine)->reset();
}

// ── MIDI ──────────────────────────────────────────────────────────────────────

void synth_engine_note_on(void* engine, int32_t midiNote, float velocity) {
    static_cast<SynthEngine*>(engine)->noteOn(midiNote, velocity);
}

void synth_engine_note_off(void* engine, int32_t midiNote) {
    static_cast<SynthEngine*>(engine)->noteOff(midiNote);
}

void synth_engine_all_notes_off(void* engine) {
    static_cast<SynthEngine*>(engine)->allNotesOff();
}

// ── Osc 1 ─────────────────────────────────────────────────────────────────────

void synth_engine_set_osc1_waveform(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setOsc1Waveform(v);
}
void synth_engine_set_osc1_octave(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setOsc1Octave(v);
}
void synth_engine_set_osc1_detune(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setOsc1Detune(v);
}
void synth_engine_set_osc1_pulse_width(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setOsc1PulseWidth(v);
}
void synth_engine_set_osc1_volume(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setOsc1Volume(v);
}

// ── Osc 2 ─────────────────────────────────────────────────────────────────────

void synth_engine_set_osc2_waveform(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setOsc2Waveform(v);
}
void synth_engine_set_osc2_octave(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setOsc2Octave(v);
}
void synth_engine_set_osc2_detune(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setOsc2Detune(v);
}
void synth_engine_set_osc2_pulse_width(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setOsc2PulseWidth(v);
}
void synth_engine_set_osc2_volume(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setOsc2Volume(v);
}
void synth_engine_set_osc_mix(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setOscMix(v);
}

// ── Filter ────────────────────────────────────────────────────────────────────

void synth_engine_set_filter_type(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setFilterType(v);
}
void synth_engine_set_filter_cutoff(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setFilterCutoff(v);
}
void synth_engine_set_filter_resonance(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setFilterResonance(v);
}
void synth_engine_set_filter_env_amount(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setFilterEnvAmount(v);
}

// ── Amp envelope ──────────────────────────────────────────────────────────────

void synth_engine_set_amp_attack(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setAmpAttack(v);
}
void synth_engine_set_amp_decay(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setAmpDecay(v);
}
void synth_engine_set_amp_sustain(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setAmpSustain(v);
}
void synth_engine_set_amp_release(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setAmpRelease(v);
}

// ── Filter envelope ───────────────────────────────────────────────────────────

void synth_engine_set_filter_attack(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setFilterAttack(v);
}
void synth_engine_set_filter_decay(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setFilterDecay(v);
}
void synth_engine_set_filter_sustain(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setFilterSustain(v);
}
void synth_engine_set_filter_release(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setFilterRelease(v);
}

// ── LFO 1 ─────────────────────────────────────────────────────────────────────

void synth_engine_set_lfo1_waveform(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setLfo1Waveform(v);
}
void synth_engine_set_lfo1_rate(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setLfo1Rate(v);
}
void synth_engine_set_lfo1_depth(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setLfo1Depth(v);
}
void synth_engine_set_lfo1_target(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setLfo1Target(v);
}

// ── LFO 2 ─────────────────────────────────────────────────────────────────────

void synth_engine_set_lfo2_waveform(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setLfo2Waveform(v);
}
void synth_engine_set_lfo2_rate(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setLfo2Rate(v);
}
void synth_engine_set_lfo2_depth(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setLfo2Depth(v);
}
void synth_engine_set_lfo2_target(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setLfo2Target(v);
}

// ── FX: Chorus ────────────────────────────────────────────────────────────────

void synth_engine_set_chorus_enabled(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setChorusEnabled(v != 0);
}
void synth_engine_set_chorus_rate(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setChorusRate(v);
}
void synth_engine_set_chorus_depth(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setChorusDepth(v);
}
void synth_engine_set_chorus_mix(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setChorusMix(v);
}

// ── FX: Delay ─────────────────────────────────────────────────────────────────

void synth_engine_set_delay_enabled(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setDelayEnabled(v != 0);
}
void synth_engine_set_delay_time(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setDelayTime(v);
}
void synth_engine_set_delay_feedback(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setDelayFeedback(v);
}
void synth_engine_set_delay_mix(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setDelayMix(v);
}

// ── FX: Reverb ────────────────────────────────────────────────────────────────

void synth_engine_set_reverb_enabled(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setReverbEnabled(v != 0);
}
void synth_engine_set_reverb_size(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setReverbSize(v);
}
void synth_engine_set_reverb_damping(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setReverbDamping(v);
}
void synth_engine_set_reverb_mix(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setReverbMix(v);
}

// ── FX: Phaser ────────────────────────────────────────────────────────────────

void synth_engine_set_phaser_enabled(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setPhaserEnabled(v != 0);
}
void synth_engine_set_phaser_rate(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setPhaserRate(v);
}
void synth_engine_set_phaser_depth(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setPhaserDepth(v);
}
void synth_engine_set_phaser_feedback(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setPhaserFeedback(v);
}
void synth_engine_set_phaser_mix(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setPhaserMix(v);
}

// ── FX: Drive ─────────────────────────────────────────────────────────────────

void synth_engine_set_drive_enabled(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setDriveEnabled(v != 0);
}
void synth_engine_set_drive_amount(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setDriveAmount(v);
}
void synth_engine_set_drive_type(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setDriveType(v);
}

// ── FX: Flanger ───────────────────────────────────────────────────────────────

void synth_engine_set_flanger_enabled(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setFlangerEnabled(v != 0);
}
void synth_engine_set_flanger_rate(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setFlangerRate(v);
}
void synth_engine_set_flanger_depth(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setFlangerDepth(v);
}
void synth_engine_set_flanger_feedback(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setFlangerFeedback(v);
}
void synth_engine_set_flanger_mix(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setFlangerMix(v);
}

// ── FX: Compressor ─────────────────────────────────────────────────────────────

void synth_engine_set_compressor_enabled(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setCompressorEnabled(v != 0);
}
void synth_engine_set_compressor_threshold(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setCompressorThreshold(v);
}
void synth_engine_set_compressor_ratio(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setCompressorRatio(v);
}
void synth_engine_set_compressor_attack(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setCompressorAttack(v);
}
void synth_engine_set_compressor_release(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setCompressorRelease(v);
}
void synth_engine_set_compressor_makeup_gain(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setCompressorMakeupGain(v);
}

// ── Master ────────────────────────────────────────────────────────────────────

void synth_engine_set_master_volume(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setMasterVolume(v);
}

int32_t synth_engine_get_active_voices(void* engine) {
    return static_cast<int32_t>(static_cast<SynthEngine*>(engine)->getActiveVoiceCount());
}

float synth_engine_get_cpu_load(void* engine) {
    return static_cast<SynthEngine*>(engine)->getCpuLoad();
}

// ── Arpeggiator state ───────────────────────────────────────────────────────

int32_t synth_engine_get_arp_current_step(void* engine) {
    return static_cast<int32_t>(static_cast<SynthEngine*>(engine)->getArpCurrentStep());
}

int32_t synth_engine_get_arp_total_steps(void* engine) {
    return static_cast<int32_t>(static_cast<SynthEngine*>(engine)->getArpTotalSteps());
}

extern "C" {

// ── Rhythm Pattern Player ────────────────────────────────────────────────────

void synth_engine_rhythm_play(void* engine) {
    static_cast<SynthEngine*>(engine)->rhythmPlayer().play();
}

void synth_engine_rhythm_stop(void* engine) {
    static_cast<SynthEngine*>(engine)->rhythmPlayer().stop();
}

void synth_engine_rhythm_set_pattern(void* engine, int32_t index) {
    static_cast<SynthEngine*>(engine)->rhythmPlayer().setPattern(index);
}

void synth_engine_rhythm_set_tempo(void* engine, float bpm) {
    static_cast<SynthEngine*>(engine)->rhythmPlayer().setTempo(bpm);
}

void synth_engine_rhythm_set_volume(void* engine, float vol) {
    static_cast<SynthEngine*>(engine)->rhythmPlayer().setTempo(vol);
}

void synth_engine_rhythm_set_variation(void* engine, int32_t variation) {
    static_cast<SynthEngine*>(engine)->rhythmPlayer().setVariation(
        static_cast<PatternVariation>(variation));
}

void synth_engine_rhythm_set_song_mode(void* engine, int32_t enabled) {
    static_cast<SynthEngine*>(engine)->rhythmPlayer().setSongMode(enabled != 0);
}

int32_t synth_engine_get_rhythm_current_step(void* engine) {
    return static_cast<int32_t>(
        static_cast<SynthEngine*>(engine)->rhythmPlayer().currentStep());
}

int32_t synth_engine_get_rhythm_total_steps(void* engine) {
    return static_cast<int32_t>(
        static_cast<SynthEngine*>(engine)->rhythmPlayer().totalSteps());
}

} // extern "C"

// ── Recording ─────────────────────────────────────────────────────────────────

void synth_engine_start_recording(void* engine, const char* path) {
    static_cast<SynthEngine*>(engine)->startRecording(path);
}

void synth_engine_stop_recording(void* engine) {
    static_cast<SynthEngine*>(engine)->stopRecording();
}

int32_t synth_engine_is_recording(void* engine) {
    return static_cast<SynthEngine*>(engine)->isRecording() ? 1 : 0;
}

double synth_engine_get_recorded_seconds(void* engine) {
    return static_cast<SynthEngine*>(engine)->recordedSeconds();
}

// ── Preset ────────────────────────────────────────────────────────────────────

int32_t synth_engine_load_preset(void* engine, const char* path) {
    return static_cast<int32_t>(static_cast<SynthEngine*>(engine)->loadPreset(path));
}

int32_t synth_engine_save_preset(void* engine, const char* path) {
    return static_cast<int32_t>(static_cast<SynthEngine*>(engine)->savePreset(path));
}

// ── UNISON ────────────────────────────────────────────────────────────────────

// Osc 1
void synth_engine_set_osc1_unison_voice_count(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setOsc1UnisonVoiceCount(v);
}
void synth_engine_set_osc1_unison_detune_spread(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setOsc1UnisonDetuneSpread(v);
}
void synth_engine_set_osc1_unison_stereo_spread(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setOsc1UnisonStereoSpread(v);
}
void synth_engine_set_osc1_unison_mix(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setOsc1UnisonMix(v);
}

// Osc 2
void synth_engine_set_osc2_unison_voice_count(void* engine, int32_t v) {
    static_cast<SynthEngine*>(engine)->setOsc2UnisonVoiceCount(v);
}
void synth_engine_set_osc2_unison_detune_spread(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setOsc2UnisonDetuneSpread(v);
}
void synth_engine_set_osc2_unison_stereo_spread(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setOsc2UnisonStereoSpread(v);
}
void synth_engine_set_osc2_unison_mix(void* engine, float v) {
    static_cast<SynthEngine*>(engine)->setOsc2UnisonMix(v);
}

// ── Thread-safe parameter queue ──────────────────────────────────────────────

void synth_engine_enqueue_float(void* engine, int32_t paramId, float value) {
    auto* e = static_cast<SynthEngine*>(engine);
    e->paramQueue().enqueue(static_cast<ParamQueue::ParamId>(paramId), value);
}

void synth_engine_enqueue_int(void* engine, int32_t paramId, int32_t value) {
    auto* e = static_cast<SynthEngine*>(engine);
    e->paramQueue().enqueueInt(static_cast<ParamQueue::ParamId>(paramId),
                               static_cast<int16_t>(value));
}

void synth_engine_enqueue_note_on(void* engine, int32_t note, float velocity) {
    auto* e = static_cast<SynthEngine*>(engine);
    e->paramQueue().enqueueNoteOn(static_cast<int16_t>(note), velocity);
}

void synth_engine_enqueue_note_off(void* engine, int32_t note) {
    auto* e = static_cast<SynthEngine*>(engine);
    e->paramQueue().enqueueNoteOff(static_cast<int16_t>(note));
}

void synth_engine_enqueue_all_notes_off(void* engine) {
    auto* e = static_cast<SynthEngine*>(engine);
    e->paramQueue().enqueueInt(ParamQueue::ALL_NOTES_OFF, 0);
}

void synth_engine_enqueue_reset(void* engine) {
    auto* e = static_cast<SynthEngine*>(engine);
    e->paramQueue().enqueueInt(ParamQueue::RESET, 0);
}

// ── FX Slot Control ──────────────────────────────────────────────────────────

void synth_engine_set_fx_slot_type(void* engine, int32_t slotIndex, int32_t fxTypeId) {
    auto* e = static_cast<SynthEngine*>(engine);
    // Delegate to SynthEngine which knows how to create FX processors
    // For now, just pass through as a param queue entry
    // The actual FX creation happens via createFxProcessor which is called
    // through the applyParam path
    if (e) {
        e->paramQueue().enqueueInt(
            static_cast<ParamQueue::ParamId>(180 + slotIndex * 10), // FX_SLOT1_TYPE = 180
            static_cast<int16_t>(fxTypeId));
    }
}

void synth_engine_set_fx_slot_enabled(void* engine, int32_t slotIndex, int32_t enabled) {
    auto* e = static_cast<SynthEngine*>(engine);
    if (e) {
        e->paramQueue().enqueueInt(
            static_cast<ParamQueue::ParamId>(181 + slotIndex * 10), // FX_SLOT1_ENABLED = 181
            static_cast<int16_t>(enabled));
    }
}

void synth_engine_set_fx_slot_param(void* engine, int32_t slotIndex, int32_t paramIdx, float value) {
    auto* e = static_cast<SynthEngine*>(engine);
    if (e) {
        e->paramQueue().enqueue(
            static_cast<ParamQueue::ParamId>(182 + slotIndex * 10 + paramIdx),
            value);
    }
}

void synth_engine_set_fx_master_enabled(void* engine, int32_t enabled) {
    auto* e = static_cast<SynthEngine*>(engine);
    if (e) {
        e->paramQueue().enqueueInt(ParamQueue::FX_MASTER_ENABLED,
                                    static_cast<int16_t>(enabled));
    }
}

void synth_engine_set_fx_master_mix(void* engine, float mix) {
    auto* e = static_cast<SynthEngine*>(engine);
    if (e) {
        e->paramQueue().enqueue(ParamQueue::FX_MASTER_MIX, mix);
    }
}

// ── SynthEnginePair (Zone A + Zone B mixer) ──────────────────────────────────

void* synth_pair_create(double sampleRate, uint32_t blockSize) {
    auto* pair = new SynthEnginePair(sampleRate, blockSize);
    return static_cast<void*>(pair);
}

void synth_pair_destroy(void* pair) {
    delete static_cast<SynthEnginePair*>(pair);
}

void synth_pair_process(void* pair, float* output, uint32_t numFrames) {
    auto* p = static_cast<SynthEnginePair*>(pair);
    AudioBuffer buf(output, numFrames, 2); // stereo
    p->process(buf);
}

void* synth_pair_engine_a(void* pair) {
    auto* p = static_cast<SynthEnginePair*>(pair);
    return static_cast<void*>(&p->engineA());
}

void* synth_pair_engine_b(void* pair) {
    auto* p = static_cast<SynthEnginePair*>(pair);
    return static_cast<void*>(&p->engineB());
}

void synth_pair_set_mix_a(void* pair, float mix) {
    auto* p = static_cast<SynthEnginePair*>(pair);
    p->setMixA(mix);
}

void synth_pair_set_mix_b(void* pair, float mix) {
    auto* p = static_cast<SynthEnginePair*>(pair);
    p->setMixB(mix);
}

void synth_pair_reset(void* pair) {
    auto* p = static_cast<SynthEnginePair*>(pair);
    p->reset();
}

int32_t synth_pair_get_active_voices(void* pair) {
    auto* p = static_cast<SynthEnginePair*>(pair);
    return static_cast<int32_t>(p->getActiveVoiceCount());
}

int32_t synth_pair_get_zone_a_voices(void* pair) {
    auto* p = static_cast<SynthEnginePair*>(pair);
    return static_cast<int32_t>(p->getZoneAVoiceCount());
}

int32_t synth_pair_get_zone_b_voices(void* pair) {
    auto* p = static_cast<SynthEnginePair*>(pair);
    return static_cast<int32_t>(p->getZoneBVoiceCount());
}

// ── MIDI File I/O ─────────────────────────────────────────────────────────────

#include "midi_file.h"

int32_t midi_file_load(const char* path, void** outHandle) {
    auto* midi = new MidiFile();
    if (MidiFileReader::read(path, *midi)) {
        *outHandle = midi;
        return 1;
    }
    delete midi;
    return 0;
}

void midi_file_free(void* handle) {
    delete static_cast<MidiFile*>(handle);
}

int32_t midi_file_get_track_count(void* handle) {
    return static_cast<int32_t>(static_cast<MidiFile*>(handle)->tracks.size());
}

int32_t midi_file_get_event_count(void* handle, int32_t trackIndex) {
    auto* midi = static_cast<MidiFile*>(handle);
    if (trackIndex < 0 || trackIndex >= (int32_t)midi->tracks.size()) return 0;
    return static_cast<int32_t>(midi->tracks[trackIndex].events.size());
}

void midi_file_get_event(void* handle, int32_t trackIndex, int32_t eventIndex,
                         uint32_t* tick, uint8_t* status, uint8_t* data1, uint8_t* data2) {
    auto* midi = static_cast<MidiFile*>(handle);
    if (trackIndex < 0 || trackIndex >= (int32_t)midi->tracks.size()) return;
    auto& track = midi->tracks[trackIndex];
    if (eventIndex < 0 || eventIndex >= (int32_t)track.events.size()) return;
    auto& ev = track.events[eventIndex];
    *tick = ev.tick;
    *status = ev.status;
    *data1 = ev.data1;
    *data2 = ev.data2;
}

int32_t midi_file_save(const char* path, int32_t format, int32_t ticksPerQuarter,
                       int32_t numTracks, int32_t numEvents, const uint32_t* ticks,
                       const uint8_t* statuses, const uint8_t* data1s, const uint8_t* data2s) {
    MidiFile midi;
    midi.format = format;
    midi.ticksPerQuarter = ticksPerQuarter;
    midi.tracks.resize(numTracks);

    int evIdx = 0;
    for (int t = 0; t < numTracks; ++t) {
        for (int e = 0; e < numEvents; ++e) {
            if (evIdx >= numEvents * numTracks) break;
            MidiEvent event;
            event.tick = ticks[evIdx];
            event.status = statuses[evIdx];
            event.data1 = data1s[evIdx];
            event.data2 = data2s[evIdx];
            midi.tracks[t].events.push_back(event);
            evIdx++;
        }
    }

    return MidiFileWriter::write(path, midi) ? 1 : 0;
}

float midi_file_get_tempo(void* handle) {
    return static_cast<MidiFile*>(handle)->tempoBpm;
}

uint32_t midi_file_get_total_ticks(void* handle) {
    return static_cast<MidiFile*>(handle)->totalTicks();
}