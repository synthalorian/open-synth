#include "synth_engine.h"
#include "legacy_fx.h"
#include "fx_eq.h"
#include "fx_limiter.h"
#include "fx_rotary.h"
#include "fx_tremolo.h"
#include "fx_autowah.h"
#include "fx_bitcrusher.h"
#include "fx_ringmod.h"
#include "fx_pitchshift.h"
#include "fx_multitap_delay.h"
#include "fx_pingpong_delay.h"
#include "fx_spring_reverb.h"
#include "fx_gated_reverb.h"
#include "fx_amp_sim.h"
#include "fx_stereo_widener.h"
#include "fx_vocoder.h"
#include "sample_player.h"
#include <cmath>
#include <cstring>
#include <algorithm>
#include <fstream>
#include <sstream>
#include <iostream>
#include <chrono>

namespace opensynth {

// ── Helpers ───────────────────────────────────────────────────────────────────

static float midiNoteToFreq(int note) {
    return 440.0f * std::pow(2.0f, (note - 69) / 12.0f);
}

// ── Construction / destruction ────────────────────────────────────────────────

SynthEngine::SynthEngine(double sampleRate, uint32_t blockSize)
    : sampleRate_(sampleRate), blockSize_(blockSize), drumKit_(sampleRate) {
    // Initialize parts: part 0 = MIDI ch 1, parts 1-15 = off by default
    for (int i = 0; i < MAX_PARTS; ++i) {
        parts_[i].midiChannel = (i == 0) ? 0 : -1;
        parts_[i].lfo1.prepare(sampleRate_);
        parts_[i].lfo2.prepare(sampleRate_);
    }

    initLegacyFxSlot();
}

SynthEngine::~SynthEngine() = default;

// ── Reset ─────────────────────────────────────────────────────────────────────

void SynthEngine::reset() {
    allocator_.allNotesOff();
    drumKit_.allNotesOff();
    for (int i = 0; i < MAX_PARTS; ++i) {
        parts_[i].osc1.reset();
        parts_[i].osc2.reset();
        parts_[i].filter.reset();
        parts_[i].lfo1.reset();
        parts_[i].lfo2.reset();
    }
    fxEngine_.reset();
    sympatheticResonator_.reset();
    for (int v = 0; v < VoiceAllocator::MAX_VOICES; v++) {
        Voice* voice = allocator_.voice(v);
        if (voice) {
            voice->filterState.lp = 0.0f;
            voice->filterState.bp = 0.0f;
            voice->filterState.hp = 0.0f;
            voice->noteAge = 0.0f;
        }
    }
}

// ── MIDI ──────────────────────────────────────────────────────────────────────

void SynthEngine::noteOn(int midiNote, float velocity, int channel) {
    int partIdx = channelToPart(channel);
    if (partIdx < 0) return;

    // MPE: if MPE is enabled and this is a member channel, route per-note
    int mpeChannel = -1;
    if (mpeController_.enabled() && mpeController_.isMemberChannel(channel)) {
        mpeChannel = channel;
    }

    arpeggiator_.noteOn(midiNote, velocity);
    if (!arpeggiator_.enabled()) {
        Voice* voice = allocator_.noteOn(midiNote, velocity, partIdx, mpeChannel);
        if (voice) {
            SynthPart& part = parts_[partIdx];
            int wf1 = part.osc1.waveform();
            if (wf1 >= 18 && wf1 <= 23) {
                voice->physicalModel.setType(static_cast<PhysicalModelType>(wf1 - 17));
                voice->physicalModel.noteOn(voice->baseFreq, voice->velocity);
            }
            int wf2 = part.osc2.waveform();
            if (wf2 >= 18 && wf2 <= 23) {
                voice->physicalModel.setType(static_cast<PhysicalModelType>(wf2 - 17));
                voice->physicalModel.noteOn(voice->baseFreq, voice->velocity);
            }
            voice->realism.bodyType = part.realismBodyType;
            voice->realism.bodyMix = part.realismBodyMix;
            voice->realism.clickMix = part.realismClickMix;
            voice->realism.sympatheticMix = part.realismSympatheticMix;
            voice->realism.attackCurve = part.realismAttackCurve;
            voice->realism.brightnessSens = part.realismBrightnessSens;
            if (part.realismSympatheticMix > 0.0f) {
                sympatheticResonator_.noteOn(voice->baseFreq, voice->velocity);
            }
        }
        if (samplePlayer_ && samplePlayer_->getMixLevel() > 0.0f) {
            samplePlayer_->noteOn(midiNote, velocity);
        }
    }
}

void SynthEngine::noteOff(int midiNote, int channel) {
    int partIdx = channelToPart(channel);
    if (partIdx < 0) return;

    // MPE: if MPE is enabled and this is a member channel, route per-note
    int mpeChannel = -1;
    if (mpeController_.enabled() && mpeController_.isMemberChannel(channel)) {
        mpeChannel = channel;
    }

    arpeggiator_.noteOff(midiNote);
    if (!arpeggiator_.enabled()) {
        allocator_.noteOff(midiNote, partIdx, mpeChannel);
        for (int v = 0; v < VoiceAllocator::MAX_VOICES; ++v) {
            Voice* voice = allocator_.voice(v);
            if (voice->active && voice->midiNote == midiNote && voice->partIndex == partIdx) {
                voice->physicalModel.noteOff();
                sympatheticResonator_.noteOff(voice->baseFreq);
            }
        }
        if (samplePlayer_) {
            samplePlayer_->noteOff(midiNote);
        }
    }
}

void SynthEngine::allNotesOff(int channel) {
    int partIdx = channelToPart(channel);
    arpeggiator_.allNotesOff();
    allocator_.allNotesOff(partIdx);
}

// ── Process ───────────────────────────────────────────────────────────────────

void SynthEngine::process(AudioBuffer& output) {
    using Clock = std::chrono::high_resolution_clock;
    auto blockStart = Clock::now();

    const uint32_t numFrames = output.numFrames;
    const bool stereo = output.numChannels >= 2;

    // Drain the parameter queue at block boundaries (thread-safe).
    drainQueue();

    // Let the arpeggiator generate note events (if enabled).
    arpeggiator_.process(numFrames, sampleRate_, allocator_);

    // Advance rhythm pattern player (triggers drum hits on step boundaries).
    rhythmPlayer_.process(drumKit_, numFrames, sampleRate_);

    // Update per-block LFO (using part 0's LFOs for global modulation)
    float lfo1Val = parts_[0].lfo1.process();
    float lfo2Val = parts_[0].lfo2.process();

    // Pre-compute piano flag once per block for part 0 (legacy compat)
    bool isPiano = (parts_[0].osc1.waveform() == 6) || (parts_[0].osc2.waveform() == 6);

    for (uint32_t frame = 0; frame < numFrames; frame++) {
        float leftOut = 0.0f;
        float rightOut = 0.0f;

        // Process each active voice
        for (int v = 0; v < VoiceAllocator::MAX_VOICES; v++) {
            Voice* voice = allocator_.voice(v);
            if (!voice->active) continue;

            // Look up the part for this voice
            int partIdx = voice->partIndex;
            if (partIdx < 0 || partIdx >= MAX_PARTS) partIdx = 0;
            SynthPart& part = parts_[partIdx];

            // Skip if part is muted or another part is soloed
            if (part.mute) continue;
            if (anySolo_ && !part.solo) continue;

            // Process envelopes
            float ampEnv = voice->ampEnv.process(sampleRate_);
            float filterEnv = voice->filterEnv.process(sampleRate_);
            float pitchEnv = voice->pitchEnv.process(sampleRate_);

            // Check if voice is done
            if (voice->ampEnv.state() == Envelope::IDLE) {
                voice->active = false;
                continue;
            }

            // Apply pitch modulation (LFO + pitch envelope)
            float pitchMod = 0.0f;
            if (part.lfoPerVoice) {
                if (part.lfo1.target() == LFO::Target::PITCH) {
                    voice->lfo1Phase += part.lfo1.rate() / sampleRate_;
                    if (voice->lfo1Phase >= 1.0) voice->lfo1Phase -= 1.0;
                    pitchMod += std::sin(2.0 * M_PI * voice->lfo1Phase) * part.lfo1.depth();
                }
                if (part.lfo2.target() == LFO::Target::PITCH) {
                    voice->lfo2Phase += part.lfo2.rate() / sampleRate_;
                    if (voice->lfo2Phase >= 1.0) voice->lfo2Phase -= 1.0;
                    pitchMod += std::sin(2.0 * M_PI * voice->lfo2Phase) * part.lfo2.depth();
                }
            } else {
                if (part.lfo1.target() == LFO::Target::PITCH) pitchMod += lfo1Val;
                if (part.lfo2.target() == LFO::Target::PITCH) pitchMod += lfo2Val;
            }
            pitchMod += pitchEnv * part.pitchEnvAmount;
            pitchMod += part.pitchBend * 2.0f; // +/- 2 semitones
            // MPE per-note pitch bend (adds to global pitch bend)
            if (voice->mpe.mpeEnabled) {
                pitchMod += voice->mpe.perNotePitchBend;
            }
            float modFreq = voice->baseFreq * std::pow(2.0f, pitchMod / 12.0f);

            // Get unison configs from the voice's part
            const UnisonConfig& u1 = part.osc1.unison();
            const UnisonConfig& u2 = part.osc2.unison();
            int maxVoices = std::max(u1.voiceCount, u2.voiceCount);
            if (maxVoices < 1) maxVoices = 1;

            float voiceLeft = 0.0f;
            float voiceRight = 0.0f;

            // Render each unison voice
            for (int uv = 0; uv < maxVoices; uv++) {
                bool osc1Active = uv < u1.voiceCount;
                bool osc2Active = uv < u2.voiceCount;

                float sample = 0.0f;

                // Check for physical model waveforms on oscillator 1
                int wf1 = part.osc1.waveform();
                bool isPm1 = (wf1 >= 18 && wf1 <= 23);
                int wf2 = part.osc2.waveform();
                bool isPm2 = (wf2 >= 18 && wf2 <= 23);

                // Oscillator 1
                if (osc1Active) {
                    if (isPm1 && uv == 0) {
                        sample += voice->physicalModel.process() * part.osc1.volume();
                    } else if (!isPm1) {
                        float inc = part.osc1.phaseIncrement(modFreq, uv);
                        voice->osc1Phase[uv] += inc;
                        if (voice->osc1Phase[uv] >= 1.0f) voice->osc1Phase[uv] -= 1.0f;
                        sample += part.osc1.process(voice->osc1Phase[uv], uv, modFreq, sampleRate_);
                    }
                }

                // Oscillator 2
                if (osc2Active) {
                    if (isPm2 && uv == 0) {
                        sample += voice->physicalModel.process() * part.osc2.volume();
                    } else if (!isPm2) {
                        float inc = part.osc2.phaseIncrement(modFreq, uv);
                        voice->osc2Phase[uv] += inc;
                        if (voice->osc2Phase[uv] >= 1.0f) voice->osc2Phase[uv] -= 1.0f;
                        sample += part.osc2.process(voice->osc2Phase[uv], uv, modFreq, sampleRate_);
                    }
                }

                // Apply oscillator mix
                sample *= part.oscMix;

                // Apply unison stereo panning
                float pan;
                if (uv == 0) {
                    pan = 0.0f;
                } else {
                    pan = (u1.stereoSpread * 0.5f) * (uv % 2 == 0 ? -1.0f : 1.0f);
                }
                float panL = std::cos((pan + 1.0f) * M_PI / 4.0f);
                float panR = std::sin((pan + 1.0f) * M_PI / 4.0f);
                voiceLeft += sample * panL;
                voiceRight += sample * panR;
            }

            // Apply amp envelope with velocity
            float ampGain = ampEnv * voice->velocity;
            ampGain *= (1.0f + part.aftertouch * 0.5f); // aftertouch adds up to 50% gain
            // MPE per-note pressure adds up to 50% gain (independent per note)
            if (voice->mpe.mpeEnabled) {
                ampGain *= (1.0f + voice->mpe.perNotePressure * 0.5f);
            }

            // Apply filter
            float filterMod = 0.0f;
            if (part.lfo1.target() == LFO::Target::FILTER) filterMod += lfo1Val;
            if (part.lfo2.target() == LFO::Target::FILTER) filterMod += lfo2Val;
            filterMod += part.modWheel; // map mod wheel to filter cutoff

            float monoMix = (voiceLeft + voiceRight) * 0.5f;
            float filtered = part.filter.process(monoMix, filterEnv + filterMod, sampleRate_, voice->midiNote, voice->filterState);

            // Instrument realism processing (body resonance, key click)
            filtered = voice->realism.process(filtered, voice->velocity, sampleRate_, voice->noteAge);

            // Apply part volume/pan
            float partPanL = std::cos((part.pan + 1.0f) * M_PI / 4.0f);
            float partPanR = std::sin((part.pan + 1.0f) * M_PI / 4.0f);
            voiceLeft = filtered * ampGain * partPanL * part.volume;
            voiceRight = filtered * ampGain * partPanR * part.volume;

            leftOut += voiceLeft;
            rightOut += voiceRight;

            voice->noteAge += 1.0f / static_cast<float>(sampleRate_);
        }

        // Apply LFO amplitude modulation (using part 0 LFOs for global amp mod)
        float ampMod = 0.0f;
        if (parts_[0].lfo1.target() == LFO::Target::AMPLITUDE) ampMod += lfo1Val;
        if (parts_[0].lfo2.target() == LFO::Target::AMPLITUDE) ampMod += lfo2Val;
        ampMod = 1.0f - std::abs(ampMod) * 0.5f;

        leftOut *= ampMod;
        rightOut *= ampMod;

        // Global sympathetic resonance (mixed from all held notes)
        float sympatheticMix = parts_[0].realismSympatheticMix;
        if (sympatheticMix > 0.0f) {
            float sym = sympatheticResonator_.process(sampleRate_);
            leftOut += sym * sympatheticMix;
            rightOut += sym * sympatheticMix;
        }

            // Apply FX engine (multi-FX slots processed in series)
        // Slot 0 is the LegacyFxProcessor, slots 1-3 are user-assignable types
        fxEngine_.process(leftOut, rightOut, sampleRate_);

        // Master volume
        leftOut *= masterVolume_;
        rightOut *= masterVolume_;

        // Sample player mix-in
        if (samplePlayer_ && samplePlayer_->getMixLevel() > 0.0f) {
            float sampleLeft = 0.0f, sampleRight = 0.0f;
            samplePlayer_->process(sampleLeft, sampleRight, 1);
            leftOut += sampleLeft;
            rightOut += sampleRight;
        }

        // NaN/inf guard — if anything went sideways, zero it out
        if (!std::isfinite(leftOut)) leftOut = 0.0f;
        if (!std::isfinite(rightOut)) rightOut = 0.0f;

        // Soft clipper (tanh) — smooth limiting that doesn't produce DC flatlines
        leftOut = std::tanh(leftOut);
        rightOut = std::tanh(rightOut);

        // Write to output buffer
        if (stereo) {
            output.data[frame * 2] = leftOut;
            output.data[frame * 2 + 1] = rightOut;
        } else {
            output.data[frame] = (leftOut + rightOut) * 0.5f;
        }
    }

    // ── Recording ── capture mixed output before drums
    if (recorder_.state() == TransportState::RECORDING) {
        // We need to capture the final mix. Since we wrote per-frame above,
        // extract from output buffer (before drums are mixed in).
        // For simplicity, record the synth voices only (no drums) — drums can be recorded separately.
        static constexpr uint32_t kRecBufMax = 2048;
        float recLeft[kRecBufMax];
        float recRight[kRecBufMax];
        uint32_t recFrames = numFrames < kRecBufMax ? numFrames : kRecBufMax;
        for (uint32_t i = 0; i < recFrames; ++i) {
            if (stereo) {
                recLeft[i] = output.data[i * 2];
                recRight[i] = output.data[i * 2 + 1];
            } else {
                recLeft[i] = output.data[i];
                recRight[i] = output.data[i];
            }
        }
        recorder_.process(recLeft, recRight, recFrames);
    }

    // CPU profiling — measure block time vs. real-time budget
    auto blockEnd = Clock::now();
    double elapsedUs = std::chrono::duration<double, std::micro>(blockEnd - blockStart).count();
    double budgetUs = (numFrames / sampleRate_) * 1e6;
    float instantLoad = static_cast<float>(elapsedUs / budgetUs);
    // Exponential moving average with ~1s time constant at 48k/256 (~187 blocks/sec)
    float alpha = 0.005f;
    cpuLoad_ = cpuLoad_ * (1.0f - alpha) + instantLoad * alpha;

    // ── Drum Kit ── process block of drum audio and mix into output
    static constexpr uint32_t kDrumBufMax = 2048;
    float drumLeft[kDrumBufMax] = {};
    float drumRight[kDrumBufMax] = {};
    uint32_t nf = numFrames < kDrumBufMax ? numFrames : kDrumBufMax;
    drumKit_.process(drumLeft, drumRight, nf);
    for (uint32_t frame = 0; frame < nf; frame++) {
        float dl = drumLeft[frame];
        float dr = drumRight[frame];
        if (!std::isfinite(dl)) dl = 0.0f;
        if (!std::isfinite(dr)) dr = 0.0f;
        if (stereo) {
            output.data[frame * 2] = std::tanh(output.data[frame * 2] + dl);
            output.data[frame * 2 + 1] = std::tanh(output.data[frame * 2 + 1] + dr);
        } else {
            output.data[frame] = std::tanh(output.data[frame] + (dl + dr) * 0.5f);
        }
    }
}

// ── Parameter Queue ──────────────────────────────────────────────────────────

void SynthEngine::drainQueue() {
    paramQueue_.drainAll([this](const ParamQueue::Entry& e) {
        applyParam(e);
    });
}

void SynthEngine::applyParam(const ParamQueue::Entry& e) {
    using P = ParamQueue::ParamId;
    auto id = static_cast<P>(e.paramId);

    switch (id) {
    // MIDI
    case P::NOTE_ON:
        {
            Voice* voice = allocator_.noteOn(e.intData, e.floatData);
            if (voice) {
                SynthPart& voicePart = parts_[voice->partIndex];
                int wf1 = voicePart.osc1.waveform();
                if (wf1 >= 18 && wf1 <= 23) {
                    voice->physicalModel.setType(static_cast<PhysicalModelType>(wf1 - 17));
                    voice->physicalModel.noteOn(voice->baseFreq, voice->velocity);
                }
                int wf2 = voicePart.osc2.waveform();
                if (wf2 >= 18 && wf2 <= 23) {
                    voice->physicalModel.setType(static_cast<PhysicalModelType>(wf2 - 17));
                    voice->physicalModel.noteOn(voice->baseFreq, voice->velocity);
                }
            }
        }
        break;
    case P::NOTE_OFF:
        allocator_.noteOff(e.intData);
        break;
    case P::ALL_NOTES_OFF:
        allocator_.allNotesOff();
        break;
    case P::RESET:
        reset();
        break;

    // ── Drum Kit ──
    case P::DRUM_KIT_PRESET:
        drumKit_.setKitPreset(static_cast<int>(e.floatData));
        break;
    case P::DRUM_LEVEL:
        drumKit_.setLevel(e.floatData);
        break;
    case P::DRUM_NOTE_ON: {
        // floatData encoding: midiNote in upper 16 bits, velocity in lower
        int midiNote = static_cast<int>(e.floatData);
        float velocity = e.floatData - static_cast<float>(midiNote);
        if (velocity <= 0.0f) velocity = 0.8f;
        drumKit_.noteOn(midiNote, velocity);
        break;
    }
    case P::DRUM_NOTE_OFF:
        drumKit_.noteOff(static_cast<int>(e.floatData));
        break;

    // Rhythm Pattern Player
    case P::RHYTHM_PATTERN:
        rhythmPlayer_.setPattern(static_cast<int>(e.floatData));
        break;
    case P::RHYTHM_PLAY:
        rhythmPlayer_.play();
        break;
    case P::RHYTHM_STOP:
        rhythmPlayer_.stop();
        break;
    case P::RHYTHM_TEMPO:
        rhythmPlayer_.setTempo(e.floatData);
        break;
    case P::RHYTHM_VOLUME:
        // Rhythm volume applied as drum kit master level scaling
        drumKit_.setLevel(e.floatData);
        break;
    case P::RHYTHM_VARIATION:
        rhythmPlayer_.setVariation(static_cast<PatternVariation>(static_cast<int>(e.floatData)));
        break;
    case P::RHYTHM_SONG_MODE:
        rhythmPlayer_.setSongMode(e.intData != 0);
        break;

    // Osc 1
    case P::OSC1_WAVEFORM: parts_[0].osc1.setWaveform(e.intData); break;
    case P::OSC1_OCTAVE:   parts_[0].osc1.setOctave(e.intData); break;
    case P::OSC1_DETUNE:   parts_[0].osc1.setDetune(e.floatData); break;
    case P::OSC1_PULSE_WIDTH: parts_[0].osc1.setPulseWidth(e.floatData); break;
    case P::OSC1_VOLUME:   parts_[0].osc1.setVolume(e.floatData); break;
    case P::OSC1_NOISE_TYPE: parts_[0].osc1.setNoiseType(e.intData); break;
    case P::OSC1_SUB_OSC_MODE: parts_[0].osc1.setSubOscMode(e.intData); break;
    case P::OSC1_SUB_OSC_VOLUME: parts_[0].osc1.setSubOscVolume(e.floatData); break;
    case P::OSC1_FM_ENABLED: parts_[0].osc1.setFmEnabled(e.intData != 0); break;
    case P::OSC1_FM_AMOUNT: parts_[0].osc1.setFmAmount(e.floatData); break;

    // Osc 2
    case P::OSC2_WAVEFORM: parts_[0].osc2.setWaveform(e.intData); break;
    case P::OSC2_OCTAVE:   parts_[0].osc2.setOctave(e.intData); break;
    case P::OSC2_DETUNE:   parts_[0].osc2.setDetune(e.floatData); break;
    case P::OSC2_PULSE_WIDTH: parts_[0].osc2.setPulseWidth(e.floatData); break;
    case P::OSC2_VOLUME:   parts_[0].osc2.setVolume(e.floatData); break;
    case P::OSC2_NOISE_TYPE: parts_[0].osc2.setNoiseType(e.intData); break;
    case P::OSC2_SUB_OSC_MODE: parts_[0].osc2.setSubOscMode(e.intData); break;
    case P::OSC2_SUB_OSC_VOLUME: parts_[0].osc2.setSubOscVolume(e.floatData); break;
    case P::OSC2_FM_ENABLED: parts_[0].osc2.setFmEnabled(e.intData != 0); break;
    case P::OSC2_FM_AMOUNT: parts_[0].osc2.setFmAmount(e.floatData); break;
    case P::OSC_MIX:       parts_[0].oscMix = e.floatData; break;

    // Filter
    case P::FILTER_TYPE:     parts_[0].filter.setType(e.intData); break;
    case P::FILTER_CUTOFF:   parts_[0].filter.setCutoff(e.floatData); break;
    case P::FILTER_RESONANCE: parts_[0].filter.setResonance(e.floatData); break;
    case P::FILTER_ENV_AMOUNT: parts_[0].filter.setEnvAmount(e.floatData); break;
    case P::FILTER_KEY_TRACKING: parts_[0].filter.setKeyTracking(e.floatData); break;
    case P::FILTER_DRIVE: parts_[0].filter.setDrive(e.floatData); break;

    // Amp envelope
    case P::AMP_ATTACK:  parts_[0].ampAttack = e.floatData; break;
    case P::AMP_DECAY:   parts_[0].ampDecay = e.floatData; break;
    case P::AMP_SUSTAIN: parts_[0].ampSustain = e.floatData; break;
    case P::AMP_RELEASE: parts_[0].ampRelease = e.floatData; break;
    case P::AMP_DELAY:   parts_[0].ampDelay = e.floatData; break;
    case P::AMP_HOLD:    parts_[0].ampHold = e.floatData; break;
    case P::AMP_ATTACK_CURVE:  parts_[0].ampAttackCurve = e.intData; break;
    case P::AMP_DECAY_CURVE:   parts_[0].ampDecayCurve = e.intData; break;
    case P::AMP_RELEASE_CURVE:
        parts_[0].ampReleaseCurve = e.intData;
        // Apply to all active voices
        for (int v = 0; v < VoiceAllocator::MAX_VOICES; v++) {
            Voice* voice = allocator_.voice(v);
            if (!voice->active) continue;
            voice->ampEnv.setDelay(parts_[0].ampDelay);
            voice->ampEnv.setHold(parts_[0].ampHold);
            voice->ampEnv.setAttack(parts_[0].ampAttack);
            voice->ampEnv.setDecay(parts_[0].ampDecay);
            voice->ampEnv.setSustain(parts_[0].ampSustain);
            voice->ampEnv.setRelease(parts_[0].ampRelease);
        }
        break;

    // Filter envelope
    case P::FILTER_ATTACK:  parts_[0].filterAttack = e.floatData; break;
    case P::FILTER_DECAY:   parts_[0].filterDecay = e.floatData; break;
    case P::FILTER_SUSTAIN: parts_[0].filterSustain = e.floatData; break;
    case P::FILTER_RELEASE: parts_[0].filterRelease = e.floatData; break;
    case P::FILTER_DELAY:   parts_[0].filterDelay = e.floatData; break;
    case P::FILTER_HOLD:    parts_[0].filterHold = e.floatData; break;
    case P::FILTER_ATTACK_CURVE:  parts_[0].filterAttackCurve = e.intData; break;
    case P::FILTER_DECAY_CURVE:   parts_[0].filterDecayCurve = e.intData; break;
    case P::FILTER_RELEASE_CURVE:
        parts_[0].filterReleaseCurve = e.intData;
        // Apply to all active voices
        for (int v = 0; v < VoiceAllocator::MAX_VOICES; v++) {
            Voice* voice = allocator_.voice(v);
            if (!voice->active) continue;
            voice->filterEnv.setDelay(parts_[0].filterDelay);
            voice->filterEnv.setHold(parts_[0].filterHold);
            voice->filterEnv.setAttack(parts_[0].filterAttack);
            voice->filterEnv.setDecay(parts_[0].filterDecay);
            voice->filterEnv.setSustain(parts_[0].filterSustain);
            voice->filterEnv.setRelease(parts_[0].filterRelease);
        }
        break;

    // LFO 1
    case P::LFO1_WAVEFORM: parts_[0].lfo1.setWaveform(e.intData); break;
    case P::LFO1_RATE:     parts_[0].lfo1.setRate(e.floatData); break;
    case P::LFO1_DEPTH:    parts_[0].lfo1.setDepth(e.floatData); break;
    case P::LFO1_TARGET:   parts_[0].lfo1.setTarget(e.intData); break;
    case P::LFO1_FADE_IN:  parts_[0].lfo1.setFadeIn(e.floatData); break;
    case P::LFO1_TEMPO_SYNC: parts_[0].lfo1.setTempoSync(e.intData != 0); break;
    case P::LFO1_TEMPO_DIVISION: parts_[0].lfo1.setTempoNoteDivision(e.intData); break;

    // LFO 2
    case P::LFO2_WAVEFORM: parts_[0].lfo2.setWaveform(e.intData); break;
    case P::LFO2_RATE:     parts_[0].lfo2.setRate(e.floatData); break;
    case P::LFO2_DEPTH:    parts_[0].lfo2.setDepth(e.floatData); break;
    case P::LFO2_TARGET:   parts_[0].lfo2.setTarget(e.intData); break;
    case P::LFO2_FADE_IN:  parts_[0].lfo2.setFadeIn(e.floatData); break;
    case P::LFO2_TEMPO_SYNC: parts_[0].lfo2.setTempoSync(e.intData != 0); break;
    case P::LFO2_TEMPO_DIVISION: parts_[0].lfo2.setTempoNoteDivision(e.intData); break;

    // FX: Chorus (routed to LegacyFxProcessor slot 0)
    case P::CHORUS_ENABLED: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setChorusEnabled(e.intData != 0);
        break;
    }
    case P::CHORUS_RATE: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setChorusRate(e.floatData);
        break;
    }
    case P::CHORUS_DEPTH: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setChorusDepth(e.floatData);
        break;
    }
    case P::CHORUS_MIX: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setChorusMix(e.floatData);
        break;
    }

    // FX: Delay
    case P::DELAY_ENABLED: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setDelayEnabled(e.intData != 0);
        break;
    }
    case P::DELAY_TIME: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setDelayTime(e.floatData);
        break;
    }
    case P::DELAY_FEEDBACK: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setDelayFeedback(e.floatData);
        break;
    }
    case P::DELAY_MIX: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setDelayMix(e.floatData);
        break;
    }

    // FX: Reverb
    case P::REVERB_ENABLED: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setReverbEnabled(e.intData != 0);
        break;
    }
    case P::REVERB_SIZE: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setReverbSize(e.floatData);
        break;
    }
    case P::REVERB_DAMPING: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setReverbDamping(e.floatData);
        break;
    }
    case P::REVERB_MIX: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setReverbMix(e.floatData);
        break;
    }

    // FX: Phaser
    case P::PHASER_ENABLED: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setPhaserEnabled(e.intData != 0);
        break;
    }
    case P::PHASER_RATE: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setPhaserRate(e.floatData);
        break;
    }
    case P::PHASER_DEPTH: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setPhaserDepth(e.floatData);
        break;
    }
    case P::PHASER_FEEDBACK: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setPhaserFeedback(e.floatData);
        break;
    }
    case P::PHASER_MIX: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setPhaserMix(e.floatData);
        break;
    }

    // FX: Drive
    case P::DRIVE_ENABLED: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setDriveEnabled(e.intData != 0);
        break;
    }
    case P::DRIVE_AMOUNT: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setDriveAmount(e.floatData);
        break;
    }
    case P::DRIVE_TYPE: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setDriveType(e.intData);
        break;
    }

    // FX: Flanger
    case P::FLANGER_ENABLED: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setFlangerEnabled(e.intData != 0);
        break;
    }
    case P::FLANGER_RATE: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setFlangerRate(e.floatData);
        break;
    }
    case P::FLANGER_DEPTH: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setFlangerDepth(e.floatData);
        break;
    }
    case P::FLANGER_FEEDBACK: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setFlangerFeedback(e.floatData);
        break;
    }
    case P::FLANGER_MIX: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setFlangerMix(e.floatData);
        break;
    }

    // FX: Compressor
    case P::COMPRESSOR_ENABLED: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setCompressorEnabled(e.intData != 0);
        break;
    }
    case P::COMPRESSOR_THRESHOLD: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setCompressorThreshold(e.floatData);
        break;
    }
    case P::COMPRESSOR_RATIO: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setCompressorRatio(e.floatData);
        break;
    }
    case P::COMPRESSOR_ATTACK: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setCompressorAttack(e.floatData);
        break;
    }
    case P::COMPRESSOR_RELEASE: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setCompressorRelease(e.floatData);
        break;
    }
    case P::COMPRESSOR_MAKEUP_GAIN: {
        auto* legacy = getLegacyFx();
        if (legacy) legacy->setCompressorMakeupGain(e.floatData);
        break;
    }        // New FX: EQ (slot 1)
    case P::FX_SLOT1_TYPE: fxEngine_.setSlotProcessor(1, createFxProcessor(e.intData)); break;
    case P::FX_SLOT1_ENABLED: fxEngine_.setSlotEnabled(1, e.intData != 0); break;
    case P::FX_SLOT1_PARAM0: fxEngine_.setSlotParam(1, 0, e.floatData); break;
    case P::FX_SLOT1_PARAM1: fxEngine_.setSlotParam(1, 1, e.floatData); break;
    case P::FX_SLOT1_PARAM2: fxEngine_.setSlotParam(1, 2, e.floatData); break;
    case P::FX_SLOT1_PARAM3: fxEngine_.setSlotParam(1, 3, e.floatData); break;
    case P::FX_SLOT1_PARAM4: fxEngine_.setSlotParam(1, 4, e.floatData); break;
    case P::FX_SLOT1_PARAM5: fxEngine_.setSlotParam(1, 5, e.floatData); break;
    case P::FX_SLOT1_PARAM6: fxEngine_.setSlotParam(1, 6, e.floatData); break;
    case P::FX_SLOT1_PARAM7: fxEngine_.setSlotParam(1, 7, e.floatData); break;

        // New FX: Limiter (slot 2)
    case P::FX_SLOT2_TYPE: fxEngine_.setSlotProcessor(2, createFxProcessor(e.intData)); break;
    case P::FX_SLOT2_ENABLED: fxEngine_.setSlotEnabled(2, e.intData != 0); break;
    case P::FX_SLOT2_PARAM0: fxEngine_.setSlotParam(2, 0, e.floatData); break;
    case P::FX_SLOT2_PARAM1: fxEngine_.setSlotParam(2, 1, e.floatData); break;
    case P::FX_SLOT2_PARAM2: fxEngine_.setSlotParam(2, 2, e.floatData); break;
    case P::FX_SLOT2_PARAM3: fxEngine_.setSlotParam(2, 3, e.floatData); break;
    case P::FX_SLOT2_PARAM4: fxEngine_.setSlotParam(2, 4, e.floatData); break;

        // New FX: Rotary (slot 3)
    case P::FX_SLOT3_TYPE: fxEngine_.setSlotProcessor(3, createFxProcessor(e.intData)); break;
    case P::FX_SLOT3_ENABLED: fxEngine_.setSlotEnabled(3, e.intData != 0); break;
    case P::FX_SLOT3_PARAM0: fxEngine_.setSlotParam(3, 0, e.floatData); break;
    case P::FX_SLOT3_PARAM1: fxEngine_.setSlotParam(3, 1, e.floatData); break;
    case P::FX_SLOT3_PARAM2: fxEngine_.setSlotParam(3, 2, e.floatData); break;
    case P::FX_SLOT3_PARAM3: fxEngine_.setSlotParam(3, 3, e.floatData); break;
    case P::FX_SLOT3_PARAM4: fxEngine_.setSlotParam(3, 4, e.floatData); break;
    case P::FX_SLOT3_PARAM5: fxEngine_.setSlotParam(3, 5, e.floatData); break;

        // FX Engine master control
    case P::FX_MASTER_ENABLED: fxEngine_.setMasterEnabled(e.intData != 0); break;
    case P::FX_MASTER_MIX: fxEngine_.setMasterMix(e.floatData); break;

    // Master
    case P::MASTER_VOLUME: masterVolume_ = e.floatData; break;

    // Unison 1
    case P::OSC1_UNISON_VOICE_COUNT:    parts_[0].osc1.setUnisonVoiceCount(e.intData); break;
    case P::OSC1_UNISON_DETUNE_SPREAD:  parts_[0].osc1.setUnisonDetuneSpread(e.floatData); break;
    case P::OSC1_UNISON_STEREO_SPREAD:  parts_[0].osc1.setUnisonStereoSpread(e.floatData); break;
    case P::OSC1_UNISON_MIX:            parts_[0].osc1.setUnisonMix(e.floatData); break;

    // Unison 2
    case P::OSC2_UNISON_VOICE_COUNT:    parts_[0].osc2.setUnisonVoiceCount(e.intData); break;
    case P::OSC2_UNISON_DETUNE_SPREAD:  parts_[0].osc2.setUnisonDetuneSpread(e.floatData); break;
    case P::OSC2_UNISON_STEREO_SPREAD:  parts_[0].osc2.setUnisonStereoSpread(e.floatData); break;
    case P::OSC2_UNISON_MIX:            parts_[0].osc2.setUnisonMix(e.floatData); break;

    // Arpeggiator
    case P::ARP_ENABLED:       arpeggiator_.setEnabled(e.intData != 0); break;
    case P::ARP_TEMPO:         arpeggiator_.setTempo(e.floatData); break;
    case P::ARP_PATTERN:       arpeggiator_.setPattern(e.intData); break;
    case P::ARP_OCTAVE_RANGE:  arpeggiator_.setOctaveRange(e.intData); break;
    case P::ARP_GATE:          arpeggiator_.setGate(e.floatData); break;
    case P::ARP_RESOLUTION:    arpeggiator_.setResolution(e.intData); break;
    case P::ARP_SWING:         arpeggiator_.setSwing(e.floatData); break;
    case P::ARP_HOLD:          arpeggiator_.setHold(e.intData != 0); break;

    // Voice priority
    case P::VOICE_PRIORITY_MODE: allocator_.setPriorityMode(static_cast<VoicePriorityMode>(e.intData)); break;

    default: break; // Unknown param — ignore
    }
}

// ── Legacy FX slot initialization ───────────────────────────────────────────

void SynthEngine::initLegacyFxSlot() {
    auto* legacy = new LegacyFxProcessor();
    fxEngine_.setSlotProcessor(0, legacy);
    fxEngine_.setSlotEnabled(0, true);
}

LegacyFxProcessor* SynthEngine::getLegacyFx() const {
    // Slot 0 always holds the LegacyFxProcessor (type None)
    if (fxEngine_.slot(0).processor &&
        fxEngine_.slotType(0) == FxType::None) {
        return static_cast<LegacyFxProcessor*>(fxEngine_.slot(0).processor);
    }
    return nullptr;
}

FxProcessor* SynthEngine::createFxProcessor(int fxTypeId) {
    FxProcessor* proc = nullptr;
    switch (fxTypeId) {
    case 8:  proc = new EqProcessor();       break; // Equalizer
    case 9:  proc = new LimiterProcessor();  break; // Limiter
    case 10: proc = new RotaryProcessor();   break; // Rotary speaker
    case 11: proc = new TremoloProcessor();  break; // Tremolo
    // Phase 5: MFX Expansion
    case 12: proc = new AutoWahProcessor();       break; // Auto-wah
    case 13: proc = new BitcrusherProcessor();    break; // Bitcrusher
    case 14: proc = new RingModProcessor();       break; // Ring modulator
    case 15: proc = new PitchShiftProcessor();    break; // Pitch shifter
    case 16: proc = new MultitapDelayProcessor(); break; // Multi-tap delay
    case 17: proc = new PingPongDelayProcessor(); break; // Ping-pong delay
    case 18: proc = new SpringReverbProcessor();  break; // Spring reverb
    case 19: proc = new GatedReverbProcessor();   break; // Gated reverb
    case 20: proc = new AmpSimulatorProcessor();  break; // Amp simulator
    case 21: proc = new StereoWidenerProcessor(); break; // Stereo widener
    case 22: proc = new VocoderProcessor();      break; // Vocoder
    default: return nullptr;
    }
    // Forward the actual sample rate so processors can pre-compute
    // sample-rate-dependent coefficients before the first process() call.
    if (proc) {
        proc->setSampleRate(sampleRate_);
    }
    return proc;
}

// ── Legacy FX setters ────────────────────────────────────────────────────────

void SynthEngine::setChorusEnabled(bool e) {
    if (auto* legacy = getLegacyFx()) legacy->setChorusEnabled(e);
}
void SynthEngine::setChorusRate(float hz) {
    if (auto* legacy = getLegacyFx()) legacy->setChorusRate(hz);
}
void SynthEngine::setChorusDepth(float d) {
    if (auto* legacy = getLegacyFx()) legacy->setChorusDepth(d);
}
void SynthEngine::setChorusMix(float m) {
    if (auto* legacy = getLegacyFx()) legacy->setChorusMix(m);
}

void SynthEngine::setDelayEnabled(bool e) {
    if (auto* legacy = getLegacyFx()) legacy->setDelayEnabled(e);
}
void SynthEngine::setDelayTime(float ms) {
    if (auto* legacy = getLegacyFx()) legacy->setDelayTime(ms);
}
void SynthEngine::setDelayFeedback(float fb) {
    if (auto* legacy = getLegacyFx()) legacy->setDelayFeedback(fb);
}
void SynthEngine::setDelayMix(float m) {
    if (auto* legacy = getLegacyFx()) legacy->setDelayMix(m);
}

void SynthEngine::setReverbEnabled(bool e) {
    if (auto* legacy = getLegacyFx()) legacy->setReverbEnabled(e);
}
void SynthEngine::setReverbSize(float s) {
    if (auto* legacy = getLegacyFx()) legacy->setReverbSize(s);
}
void SynthEngine::setReverbDamping(float d) {
    if (auto* legacy = getLegacyFx()) legacy->setReverbDamping(d);
}
void SynthEngine::setReverbMix(float m) {
    if (auto* legacy = getLegacyFx()) legacy->setReverbMix(m);
}

void SynthEngine::setPhaserEnabled(bool e) {
    if (auto* legacy = getLegacyFx()) legacy->setPhaserEnabled(e);
}
void SynthEngine::setPhaserRate(float hz) {
    if (auto* legacy = getLegacyFx()) legacy->setPhaserRate(hz);
}
void SynthEngine::setPhaserDepth(float d) {
    if (auto* legacy = getLegacyFx()) legacy->setPhaserDepth(d);
}
void SynthEngine::setPhaserFeedback(float fb) {
    if (auto* legacy = getLegacyFx()) legacy->setPhaserFeedback(fb);
}
void SynthEngine::setPhaserMix(float m) {
    if (auto* legacy = getLegacyFx()) legacy->setPhaserMix(m);
}

void SynthEngine::setDriveEnabled(bool e) {
    if (auto* legacy = getLegacyFx()) legacy->setDriveEnabled(e);
}
void SynthEngine::setDriveAmount(float a) {
    if (auto* legacy = getLegacyFx()) legacy->setDriveAmount(a);
}
void SynthEngine::setDriveType(int t) {
    if (auto* legacy = getLegacyFx()) legacy->setDriveType(t);
}

void SynthEngine::setFlangerEnabled(bool e) {
    if (auto* legacy = getLegacyFx()) legacy->setFlangerEnabled(e);
}
void SynthEngine::setFlangerRate(float hz) {
    if (auto* legacy = getLegacyFx()) legacy->setFlangerRate(hz);
}
void SynthEngine::setFlangerDepth(float d) {
    if (auto* legacy = getLegacyFx()) legacy->setFlangerDepth(d);
}
void SynthEngine::setFlangerFeedback(float fb) {
    if (auto* legacy = getLegacyFx()) legacy->setFlangerFeedback(fb);
}
void SynthEngine::setFlangerMix(float m) {
    if (auto* legacy = getLegacyFx()) legacy->setFlangerMix(m);
}

void SynthEngine::setCompressorEnabled(bool e) {
    if (auto* legacy = getLegacyFx()) legacy->setCompressorEnabled(e);
}
void SynthEngine::setCompressorThreshold(float t) {
    if (auto* legacy = getLegacyFx()) legacy->setCompressorThreshold(t);
}
void SynthEngine::setCompressorRatio(float r) {
    if (auto* legacy = getLegacyFx()) legacy->setCompressorRatio(r);
}
void SynthEngine::setCompressorAttack(float a) {
    if (auto* legacy = getLegacyFx()) legacy->setCompressorAttack(a);
}
void SynthEngine::setCompressorRelease(float r) {
    if (auto* legacy = getLegacyFx()) legacy->setCompressorRelease(r);
}
void SynthEngine::setCompressorMakeupGain(float g) {
    if (auto* legacy = getLegacyFx()) legacy->setCompressorMakeupGain(g);
}

// ── Preset ────────────────────────────────────────────────────────────────────

int SynthEngine::loadPreset(const char* path) {
    std::ifstream file(path);
    if (!file.is_open()) return -1;
    // Simple preset loading — parse key=value pairs
    std::string line;
    while (std::getline(file, line)) {
        // Preset format: param_name=value
        auto eq = line.find('=');
        if (eq == std::string::npos) continue;
        std::string key = line.substr(0, eq);
        std::string val = line.substr(eq + 1);
        // Parse known params
        try {
            if (key == "osc1_waveform") setOsc1Waveform(std::stoi(val));
            else if (key == "osc1_octave") setOsc1Octave(std::stoi(val));
            else if (key == "osc1_detune") setOsc1Detune(std::stof(val));
            else if (key == "osc1_pulse_width") setOsc1PulseWidth(std::stof(val));
            else if (key == "osc1_volume") setOsc1Volume(std::stof(val));
            else if (key == "osc2_waveform") setOsc2Waveform(std::stoi(val));
            else if (key == "osc2_octave") setOsc2Octave(std::stoi(val));
            else if (key == "osc2_detune") setOsc2Detune(std::stof(val));
            else if (key == "osc2_pulse_width") setOsc2PulseWidth(std::stof(val));
            else if (key == "osc2_volume") setOsc2Volume(std::stof(val));
            else if (key == "osc_mix") setOscMix(std::stof(val));
            else if (key == "filter_type") setFilterType(std::stoi(val));
            else if (key == "filter_cutoff") setFilterCutoff(std::stof(val));
            else if (key == "filter_resonance") setFilterResonance(std::stof(val));
            else if (key == "filter_env_amount") setFilterEnvAmount(std::stof(val));
            else if (key == "amp_attack") setAmpAttack(std::stof(val));
            else if (key == "amp_decay") setAmpDecay(std::stof(val));
            else if (key == "amp_sustain") setAmpSustain(std::stof(val));
            else if (key == "amp_release") setAmpRelease(std::stof(val));
            else if (key == "filter_attack") setFilterAttack(std::stof(val));
            else if (key == "filter_decay") setFilterDecay(std::stof(val));
            else if (key == "filter_sustain") setFilterSustain(std::stof(val));
            else if (key == "filter_release") setFilterRelease(std::stof(val));
            else if (key == "master_volume") setMasterVolume(std::stof(val));
            else if (key == "osc1_unison_voice_count") setOsc1UnisonVoiceCount(std::stoi(val));
            else if (key == "osc1_unison_detune_spread") setOsc1UnisonDetuneSpread(std::stof(val));
            else if (key == "osc1_unison_stereo_spread") setOsc1UnisonStereoSpread(std::stof(val));
            else if (key == "osc1_unison_mix") setOsc1UnisonMix(std::stof(val));
            else if (key == "osc2_unison_voice_count") setOsc2UnisonVoiceCount(std::stoi(val));
            else if (key == "osc2_unison_detune_spread") setOsc2UnisonDetuneSpread(std::stof(val));
            else if (key == "osc2_unison_stereo_spread") setOsc2UnisonStereoSpread(std::stof(val));
            else if (key == "osc2_unison_mix") setOsc2UnisonMix(std::stof(val));
        } catch (...) {
            // skip invalid lines
        }
    }
    return 0;
}

int SynthEngine::savePreset(const char* path) const {
    std::ofstream file(path);
    if (!file.is_open()) return -1;

    // Oscillator 1
    file << "osc1_waveform=" << parts_[0].osc1.waveform() << "\n";
    file << "osc1_octave=" << parts_[0].osc1.octave() << "\n";
    file << "osc1_detune=" << parts_[0].osc1.detune() << "\n";
    file << "osc1_pulse_width=" << parts_[0].osc1.pulseWidth() << "\n";
    file << "osc1_volume=" << parts_[0].osc1.volume() << "\n";

    // Oscillator 2
    file << "osc2_waveform=" << parts_[0].osc2.waveform() << "\n";
    file << "osc2_octave=" << parts_[0].osc2.octave() << "\n";
    file << "osc2_detune=" << parts_[0].osc2.detune() << "\n";
    file << "osc2_pulse_width=" << parts_[0].osc2.pulseWidth() << "\n";
    file << "osc2_volume=" << parts_[0].osc2.volume() << "\n";

    file << "osc_mix=" << parts_[0].oscMix << "\n";

    // Unison 1
    file << "osc1_unison_voice_count=" << parts_[0].osc1.unison().voiceCount << "\n";
    file << "osc1_unison_detune_spread=" << parts_[0].osc1.unison().detuneSpread << "\n";
    file << "osc1_unison_stereo_spread=" << parts_[0].osc1.unison().stereoSpread << "\n";
    file << "osc1_unison_mix=" << parts_[0].osc1.unison().mix << "\n";

    // Unison 2
    file << "osc2_unison_voice_count=" << parts_[0].osc2.unison().voiceCount << "\n";
    file << "osc2_unison_detune_spread=" << parts_[0].osc2.unison().detuneSpread << "\n";
    file << "osc2_unison_stereo_spread=" << parts_[0].osc2.unison().stereoSpread << "\n";
    file << "osc2_unison_mix=" << parts_[0].osc2.unison().mix << "\n";

    // Filter
    file << "filter_type=" << parts_[0].filter.type() << "\n";
    file << "filter_cutoff=" << parts_[0].filter.cutoff() << "\n";
    file << "filter_resonance=" << parts_[0].filter.resonance() << "\n";
    file << "filter_env_amount=" << parts_[0].filter.envAmount() << "\n";

    // Amplifier envelope
    file << "amp_attack=" << parts_[0].ampAttack << "\n";
    file << "amp_decay=" << parts_[0].ampDecay << "\n";
    file << "amp_sustain=" << parts_[0].ampSustain << "\n";
    file << "amp_release=" << parts_[0].ampRelease << "\n";

    // Filter envelope
    file << "filter_attack=" << parts_[0].filterAttack << "\n";
    file << "filter_decay=" << parts_[0].filterDecay << "\n";
    file << "filter_sustain=" << parts_[0].filterSustain << "\n";
    file << "filter_release=" << parts_[0].filterRelease << "\n";

    // LFO 1
    file << "lfo1_waveform=" << parts_[0].lfo1.waveform() << "\n";
    file << "lfo1_rate=" << parts_[0].lfo1.rate() << "\n";
    file << "lfo1_depth=" << parts_[0].lfo1.depth() << "\n";
    file << "lfo1_target=" << static_cast<int>(parts_[0].lfo1.target()) << "\n";

    // LFO 2
    file << "lfo2_waveform=" << parts_[0].lfo2.waveform() << "\n";
    file << "lfo2_rate=" << parts_[0].lfo2.rate() << "\n";
    file << "lfo2_depth=" << parts_[0].lfo2.depth() << "\n";
    file << "lfo2_target=" << static_cast<int>(parts_[0].lfo2.target()) << "\n";

    // Master volume
    file << "master_volume=" << masterVolume_ << "\n";

    return 0;
}

// ── Multitimbral part management ──────────────────────────────────────────────

int SynthEngine::channelToPart(int channel) const {
    if (channel < 0 || channel > 15) return 0; // Default to part 0
    for (int i = 0; i < MAX_PARTS; ++i) {
        if (parts_[i].midiChannel == channel || parts_[i].omni) {
            return i;
        }
    }
    return 0; // Fallback to part 0
}

void SynthEngine::setPartMidiChannel(int partIndex, int channel) {
    if (partIndex < 0 || partIndex >= MAX_PARTS) return;
    parts_[partIndex].midiChannel = channel;
}

void SynthEngine::setPartVolume(int partIndex, float vol) {
    if (partIndex < 0 || partIndex >= MAX_PARTS) return;
    parts_[partIndex].volume = clamp(vol, 0.0f, 1.0f);
}

void SynthEngine::setPartPan(int partIndex, float pan) {
    if (partIndex < 0 || partIndex >= MAX_PARTS) return;
    parts_[partIndex].pan = clamp(pan, -1.0f, 1.0f);
}

void SynthEngine::setPartMute(int partIndex, bool mute) {
    if (partIndex < 0 || partIndex >= MAX_PARTS) return;
    parts_[partIndex].mute = mute;
    updateSoloState();
}

void SynthEngine::setPartSolo(int partIndex, bool solo) {
    if (partIndex < 0 || partIndex >= MAX_PARTS) return;
    parts_[partIndex].solo = solo;
    updateSoloState();
}

void SynthEngine::updateSoloState() {
    anySolo_ = false;
    for (int i = 0; i < MAX_PARTS; ++i) {
        if (parts_[i].solo) {
            anySolo_ = true;
            break;
        }
    }
}

} // namespace opensynth
