#include "sample_player.h"
#include <juce_audio_formats/juce_audio_formats.h>
#include <cmath>
#include <cstring>

namespace opensynth {

// ── SampleVoice ──────────────────────────────────────────────────────────────

void SampleVoice::noteOn(int note, float vel, const SampleZone* z, double sr) {
    zone = z;
    midiNote = note;
    velocity = vel;
    position = 0.0;
    pitchRatio = std::pow(2.0, (note - z->rootNote) / 12.0) * (z->sampleRate / sr);
    active = true;
    envState = ATTACK;
    ampEnv = 0.0f;
}

void SampleVoice::noteOff() {
    if (active && envState != IDLE) {
        envState = RELEASE;
    }
}

void SampleVoice::reset() {
    active = false;
    zone = nullptr;
    envState = IDLE;
    ampEnv = 0.0f;
    position = 0.0;
}

float SampleVoice::process(double /*sampleRate*/) {
    if (!active || !zone || envState == IDLE) return 0.0f;

    // Advance envelope
    switch (envState) {
        case ATTACK:
            ampEnv += attackRate;
            if (ampEnv >= 1.0f) { ampEnv = 1.0f; envState = DECAY; }
            break;
        case DECAY:
            ampEnv -= decayRate;
            if (ampEnv <= sustainLevel) { ampEnv = sustainLevel; envState = SUSTAIN; }
            break;
        case SUSTAIN:
            break;
        case RELEASE:
            ampEnv -= releaseRate;
            if (ampEnv <= 0.0f) { ampEnv = 0.0f; active = false; envState = IDLE; }
            break;
        default:
            break;
    }

    // Linear interpolation sample read from stream
    int pos = static_cast<int>(position);
    float frac = static_cast<float>(position - pos);

    if (!zone->stream || !zone->stream->isOpen()) return 0.0f;

    int64_t numFrames = zone->stream->getTotalSamples();
    if (numFrames == 0) return 0.0f;

    if (pos >= numFrames - 1) {
        if (zone->loopEnabled && pos >= zone->loopEnd) {
            position = zone->loopStart + frac;
            pos = zone->loopStart;
        } else {
            active = false;
            envState = IDLE;
            return 0.0f;
        }
    }

    float s0l = 0.0f, s0r = 0.0f;
    float s1l = 0.0f, s1r = 0.0f;

    float temp0[2] = {0.0f, 0.0f};
    float temp1[2] = {0.0f, 0.0f};

    zone->stream->readSample(pos, temp0);
    s0l = temp0[0];
    s0r = temp0[1];

    if (pos + 1 < numFrames) {
        zone->stream->readSample(pos + 1, temp1);
        s1l = temp1[0];
        s1r = temp1[1];
    } else {
        s1l = s0l;
        s1r = s0r;
    }

    float sampleL = s0l + frac * (s1l - s0l);
    float sampleR = s0r + frac * (s1r - s0r);

    position += pitchRatio;

    // Mix to mono for return (stereo handled in SamplePlayer::process)
    float sample = (sampleL + sampleR) * 0.5f;
    return sample * ampEnv * velocity;
}

// ── SamplePlayer ─────────────────────────────────────────────────────────────

SamplePlayer::SamplePlayer() = default;

bool SamplePlayer::loadSample(const std::string& path, int rootNote, int minNote, int maxNote) {
    auto stream = std::make_shared<SampleStream>();
    if (!stream->open(path, streamBufferSize_)) {
        return false;
    }

    auto zone = std::make_unique<SampleZone>();
    zone->rootNote = rootNote;
    zone->minNote = minNote;
    zone->maxNote = maxNote;
    zone->sampleRate = stream->getSampleRate();
    zone->stream = std::move(stream);

    zones_.push_back(std::move(zone));
    return true;
}

void SamplePlayer::clear() {
    zones_.clear();
    allNotesOff();
}

void SamplePlayer::noteOn(int midiNote, float velocity) {
    const SampleZone* zone = findZone(midiNote, velocity);
    if (!zone) return;

    SampleVoice* voice = findFreeVoice();
    if (!voice) return;

    voice->noteOn(midiNote, velocity, zone, sampleRate_);
    voice->attackRate = 1.0f / (attackMs_ * 0.001f * static_cast<float>(sampleRate_));
    if (voice->attackRate > 1.0f) voice->attackRate = 1.0f;
    voice->decayRate = 1.0f / (decayMs_ * 0.001f * static_cast<float>(sampleRate_));
    if (voice->decayRate > 0.1f) voice->decayRate = 0.1f;
    voice->sustainLevel = sustainLevel_;
    voice->releaseRate = 1.0f / (releaseMs_ * 0.001f * static_cast<float>(sampleRate_));
    if (voice->releaseRate > 0.1f) voice->releaseRate = 0.1f;
}

void SamplePlayer::noteOff(int midiNote) {
    for (auto& voice : voices_) {
        if (voice.active && voice.midiNote == midiNote) {
            voice.noteOff();
        }
    }
}

void SamplePlayer::allNotesOff() {
    for (auto& voice : voices_) {
        voice.noteOff();
    }
}

void SamplePlayer::prepare(double sampleRate) {
    sampleRate_ = sampleRate;
}

void SamplePlayer::process(float& left, float& right, int numFrames) {
    if (mixLevel_ <= 0.0f || zones_.empty()) return;

    float l = 0.0f, r = 0.0f;
    for (auto& voice : voices_) {
        if (!voice.active) continue;
        float s = voice.process(sampleRate_);
        l += s;
        r += s;
    }
    left += l * mixLevel_;
    right += r * mixLevel_;
}

void SamplePlayer::setAttack(float ms) { attackMs_ = ms; }
void SamplePlayer::setDecay(float ms) { decayMs_ = ms; }
void SamplePlayer::setSustain(float level) { sustainLevel_ = level; }
void SamplePlayer::setRelease(float ms) { releaseMs_ = ms; }

int SamplePlayer::activeVoiceCount() const {
    int count = 0;
    for (const auto& v : voices_) if (v.active) ++count;
    return count;
}

const SampleZone* SamplePlayer::findZone(int midiNote, float velocity) const {
    for (const auto& zone : zones_) {
        if (midiNote >= zone->minNote && midiNote <= zone->maxNote &&
            velocity >= zone->minVelocity && velocity <= zone->maxVelocity) {
            return zone.get();
        }
    }
    return nullptr;
}

SampleVoice* SamplePlayer::findFreeVoice() {
    for (auto& voice : voices_) {
        if (!voice.active) return &voice;
    }
    // Steal oldest (first active)
    for (auto& voice : voices_) {
        if (voice.active) {
            voice.reset();
            return &voice;
        }
    }
    return nullptr;
}

} // namespace opensynth
