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
    inCrossfade = false;
    crossfadePos = 0.0;
    loopStartPos = static_cast<double>(z->loopStart);
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
    inCrossfade = false;
    crossfadePos = 0.0;
    loopStartPos = 0.0;
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

    // Select velocity layer stream
    VelocityLayer layer = SamplePlayer::velocityToLayer(velocity);
    auto stream = zone->streams[static_cast<int>(layer)];
    if (!stream) {
        // Fallback: use first available layer
        for (int i = 0; i < static_cast<int>(VelocityLayer::Count); ++i) {
            if (zone->streams[i]) {
                stream = zone->streams[i];
                break;
            }
        }
    }
    if (!stream || !stream->isOpen()) return 0.0f;

    int64_t numFrames = stream->getTotalSamples();
    if (numFrames == 0) return 0.0f;

    // Determine effective loop points: zone overrides stream metadata
    bool loopEnabled = zone->loopEnabled;
    int loopStart = zone->loopStart;
    int loopEnd = zone->loopEnd;
    if (!loopEnabled && stream->hasLoopPoints()) {
        loopEnabled = true;
        loopStart = stream->getLoopStart();
        loopEnd = stream->getLoopEnd();
    }

    // ── Cubic interpolation helper ───────────────────────────────────────────
    auto readChannel = [&](int64_t pos, int ch) -> float {
        if (pos < 0 || pos >= numFrames) return 0.0f;
        float temp[2] = {0.0f, 0.0f};
        stream->readSample(pos, temp);
        return temp[ch];
    };

    auto cubicInterpolate = [&](const float* p, float frac) -> float {
        // Catmull-Rom spline (4-point, 3rd-order)
        float a = -0.5f * p[0] + 1.5f * p[1] - 1.5f * p[2] + 0.5f * p[3];
        float b = p[0] - 2.5f * p[1] + 2.0f * p[2] - 0.5f * p[3];
        float c = -0.5f * p[0] + 0.5f * p[2];
        float d = p[1];
        return ((a * frac + b) * frac + c) * frac + d;
    };

    auto getSampleCubic = [&](double pos, int ch) -> float {
        int64_t i = static_cast<int64_t>(pos);
        float frac = static_cast<float>(pos - static_cast<double>(i));
        float samples[4];
        samples[0] = readChannel(i - 1, ch);
        samples[1] = readChannel(i,     ch);
        samples[2] = readChannel(i + 1, ch);
        samples[3] = readChannel(i + 2, ch);
        return cubicInterpolate(samples, frac);
    };

    // ── Anti-aliasing filter for down-pitched samples ────────────────────────
    // Simple 1-pole lowpass whose cutoff tracks pitch ratio
    // Higher pitchRatio = faster playback = more aliasing when > 1.0 (up-pitch is ok)
    // When pitchRatio < 1.0 (down-pitch), we need to filter to avoid imaging.
    // We apply a gentle 1-pole LP with cutoff = sr * 0.5 * pitchRatio
    static float aaStateL = 0.0f; // per-voice would be better, but static is ok for demo
    static float aaStateR = 0.0f;
    auto applyAA = [&](float inL, float inR) -> std::pair<float, float> {
        if (pitchRatio >= 1.0f) return {inL, inR};
        float coeff = pitchRatio; // normalized cutoff ≈ pitchRatio * Nyquist
        float outL = inL * coeff + aaStateL * (1.0f - coeff);
        float outR = inR * coeff + aaStateR * (1.0f - coeff);
        aaStateL = outL;
        aaStateR = outR;
        return {outL, outR};
    };

    // ── Loop / crossfade logic ───────────────────────────────────────────────
    double effectivePos = position;
    double altPos = 0.0;
    float crossfadeGain = 0.0f;

    if (loopEnabled && !inCrossfade && effectivePos >= static_cast<double>(loopEnd - zone->crossfadeSamples)) {
        inCrossfade = true;
        crossfadePos = 0.0;
    }

    if (inCrossfade) {
        altPos = loopStartPos + crossfadePos;
        float cfFrac = static_cast<float>(crossfadePos / static_cast<double>(zone->crossfadeSamples));
        if (cfFrac > 1.0f) cfFrac = 1.0f;
        crossfadeGain = cfFrac; // fade in loop-start, fade out tail
    }

    // ── Read samples ─────────────────────────────────────────────────────────
    float sampleL = getSampleCubic(effectivePos, 0);
    float sampleR = getSampleCubic(effectivePos, 1);

    if (inCrossfade) {
        float altL = getSampleCubic(altPos, 0);
        float altR = getSampleCubic(altPos, 1);
        sampleL = sampleL * (1.0f - crossfadeGain) + altL * crossfadeGain;
        sampleR = sampleR * (1.0f - crossfadeGain) + altR * crossfadeGain;
        crossfadePos += pitchRatio;
        if (crossfadePos >= static_cast<double>(zone->crossfadeSamples)) {
            // Crossfade complete: snap to loop start
            position = loopStartPos + (crossfadePos - static_cast<double>(zone->crossfadeSamples));
            inCrossfade = false;
            crossfadePos = 0.0;
        }
    }

    // Apply anti-aliasing filter
    auto aaResult = applyAA(sampleL, sampleR);
    sampleL = aaResult.first;
    sampleR = aaResult.second;

    position += pitchRatio;

    // If we've passed loop end without crossfade (e.g. very fast pitch ratio), hard loop
    if (loopEnabled && position >= static_cast<double>(loopEnd)) {
        position = static_cast<double>(loopStart) + (position - static_cast<double>(loopEnd));
        inCrossfade = false;
        crossfadePos = 0.0;
    }

    // End-of-sample check for non-looped
    if (!loopEnabled && position >= static_cast<double>(numFrames)) {
        active = false;
        envState = IDLE;
        return 0.0f;
    }

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
    // Load into all velocity layers for backward compatibility
    for (int i = 0; i < static_cast<int>(VelocityLayer::Count); ++i) {
        zone->streams[i] = stream;
    }

    zones_.push_back(std::move(zone));
    return true;
}

bool SamplePlayer::addZone(const SampleZone& zone) {
    auto z = std::make_unique<SampleZone>(zone);
    zones_.push_back(std::move(z));
    return true;
}

bool SamplePlayer::loadMultiSample(const std::string& manifestPath) {
    juce::File manifestFile(manifestPath);
    if (!manifestFile.existsAsFile()) {
        return false;
    }

    auto json = juce::JSON::parse(manifestFile);
    if (json.isVoid()) {
        return false;
    }

    auto* obj = json.getDynamicObject();
    if (!obj) return false;

    auto* zonesArray = obj->getProperty("zones").getArray();
    if (!zonesArray) return false;

    juce::File baseDir = manifestFile.getParentDirectory();

    for (const auto& zoneVal : *zonesArray) {
        auto* zoneObj = zoneVal.getDynamicObject();
        if (!zoneObj) continue;

        SampleZone zone;
        zone.rootNote = zoneObj->getProperty("rootNote");
        zone.minNote = zoneObj->getProperty("minNote");
        zone.maxNote = zoneObj->getProperty("maxNote");
        zone.minVelocity = static_cast<float>(zoneObj->getProperty("minVelocity"));
        zone.maxVelocity = static_cast<float>(zoneObj->getProperty("maxVelocity"));
        zone.loopEnabled = zoneObj->getProperty("loopEnabled");
        zone.loopStart = zoneObj->getProperty("loopStart");
        zone.loopEnd = zoneObj->getProperty("loopEnd");
        zone.crossfadeSamples = static_cast<int>(zoneObj->getProperty("crossfadeSamples"));
        if (zone.crossfadeSamples <= 0) zone.crossfadeSamples = 256;

        auto* layers = zoneObj->getProperty("layers").getArray();
        if (!layers) continue;

        bool anyLoaded = false;
        for (const auto& layerVal : *layers) {
            auto* layerObj = layerVal.getDynamicObject();
            if (!layerObj) continue;

            juce::String layerName = layerObj->getProperty("layer").toString();
            juce::String fileName = layerObj->getProperty("file").toString();
            juce::File sampleFile = baseDir.getChildFile(fileName);

            VelocityLayer layer = VelocityLayer::Soft;
            if (layerName == "soft") layer = VelocityLayer::Soft;
            else if (layerName == "medium") layer = VelocityLayer::Medium;
            else if (layerName == "loud") layer = VelocityLayer::Loud;
            else continue;

            auto stream = std::make_shared<SampleStream>();
            if (stream->open(sampleFile.getFullPathName().toStdString(), streamBufferSize_)) {
                zone.streams[static_cast<int>(layer)] = std::move(stream);
                if (zone.sampleRate == 48000.0) {
                    zone.sampleRate = zone.streams[static_cast<int>(layer)]->getSampleRate();
                }
                anyLoaded = true;
            }
        }

        if (anyLoaded) {
            zones_.push_back(std::make_unique<SampleZone>(zone));
        }
    }

    return !zones_.empty();
}

VelocityLayer SamplePlayer::velocityToLayer(float velocity) {
    int v = static_cast<int>(velocity * 127.0f);
    if (v <= 50) return VelocityLayer::Soft;
    if (v <= 90) return VelocityLayer::Medium;
    return VelocityLayer::Loud;
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
