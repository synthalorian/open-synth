#include "sample_player.h"
#include <juce_audio_formats/juce_audio_formats.h>
#include <cmath>
#include <cstring>
#include <algorithm>

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
    aaStateL = 0.0f;
    aaStateR = 0.0f;
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
    aaStateL = 0.0f;
    aaStateR = 0.0f;
}

// Inline linear interpolation read — no lambdas, minimal branching
static inline float readChannelLinear(const SampleStream* stream, double pos, int ch, int64_t numFrames) {
    int64_t i = static_cast<int64_t>(pos);
    float frac = static_cast<float>(pos - static_cast<double>(i));
    if (i < 0) i = 0;
    if (i >= numFrames - 1) i = numFrames - 2;
    if (numFrames <= 1) return 0.0f;

    float s0[2] = {0.0f, 0.0f};
    float s1[2] = {0.0f, 0.0f};
    stream->readSample(i, s0);
    stream->readSample(i + 1, s1);
    return s0[ch] + frac * (s1[ch] - s0[ch]);
}

// Inline anti-aliasing 1-pole LP (per-channel state passed by reference)
static inline float applyAA(float in, float coeff, float& state) {
    if (coeff >= 1.0f) return in;
    float out = in * coeff + state * (1.0f - coeff);
    state = out;
    return out;
}

float SampleVoice::process(double /*sampleRate*/) {
    if (!active || !zone || envState == IDLE) return 0.0f;

    // Advance envelope — reduced branching via switch still present but body is tight
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

    if (!active) return 0.0f;

    // Select velocity layer stream
    VelocityLayer layer = SamplePlayer::velocityToLayer(velocity);
    auto stream = zone->streams[static_cast<int>(layer)];
    if (!stream) {
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
        crossfadeGain = cfFrac;
    }

    // ── Read samples with linear interpolation ───────────────────────────────
    float sampleL = readChannelLinear(stream.get(), effectivePos, 0, numFrames);
    float sampleR = readChannelLinear(stream.get(), effectivePos, 1, numFrames);

    if (inCrossfade) {
        float altL = readChannelLinear(stream.get(), altPos, 0, numFrames);
        float altR = readChannelLinear(stream.get(), altPos, 1, numFrames);
        float invGain = 1.0f - crossfadeGain;
        sampleL = sampleL * invGain + altL * crossfadeGain;
        sampleR = sampleR * invGain + altR * crossfadeGain;
        crossfadePos += pitchRatio;
        if (crossfadePos >= static_cast<double>(zone->crossfadeSamples)) {
            position = loopStartPos + (crossfadePos - static_cast<double>(zone->crossfadeSamples));
            inCrossfade = false;
            crossfadePos = 0.0;
        }
    }

    // Apply anti-aliasing filter (per-voice state)
    float aaCoeff = (pitchRatio >= 1.0f) ? 1.0f : static_cast<float>(pitchRatio);
    sampleL = applyAA(sampleL, aaCoeff, aaStateL);
    sampleR = applyAA(sampleR, aaCoeff, aaStateR);

    position += pitchRatio;

    // Hard loop for very fast pitch ratios
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

    // Mix to mono for return (stereo handled in SamplePlayer::processBlock)
    float sample = (sampleL + sampleR) * 0.5f;
    return sample * ampEnv * velocity;
}

// ── Block-based voice process ────────────────────────────────────────────────
// Processes up to 'numFrames' samples into outL/outR. Returns frames written.
int SampleVoice::processBlock(float* outL, float* outR, int numFrames, double /*sampleRate*/) {
    if (!active || !zone || envState == IDLE || numFrames <= 0) return 0;

    // Select stream
    VelocityLayer layer = SamplePlayer::velocityToLayer(velocity);
    auto stream = zone->streams[static_cast<int>(layer)];
    if (!stream) {
        for (int i = 0; i < static_cast<int>(VelocityLayer::Count); ++i) {
            if (zone->streams[i]) {
                stream = zone->streams[i];
                break;
            }
        }
    }
    if (!stream || !stream->isOpen()) {
        active = false;
        envState = IDLE;
        return 0;
    }

    int64_t totalFrames = stream->getTotalSamples();
    if (totalFrames == 0) {
        active = false;
        envState = IDLE;
        return 0;
    }

    bool loopEnabled = zone->loopEnabled;
    int loopStart = zone->loopStart;
    int loopEnd = zone->loopEnd;
    if (!loopEnabled && stream->hasLoopPoints()) {
        loopEnabled = true;
        loopStart = stream->getLoopStart();
        loopEnd = stream->getLoopEnd();
    }

    float aaCoeff = (pitchRatio >= 1.0f) ? 1.0f : static_cast<float>(pitchRatio);
    int framesWritten = 0;

    for (int n = 0; n < numFrames; ++n) {
        // Envelope
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

        if (!active) {
            outL[n] = 0.0f;
            outR[n] = 0.0f;
            framesWritten = n + 1;
            continue;
        }

        // Crossfade logic
        double effectivePos = position;
        double altPos = 0.0;
        float crossfadeGain = 0.0f;
        bool doCrossfade = false;

        if (loopEnabled && !inCrossfade && effectivePos >= static_cast<double>(loopEnd - zone->crossfadeSamples)) {
            inCrossfade = true;
            crossfadePos = 0.0;
        }

        if (inCrossfade) {
            altPos = loopStartPos + crossfadePos;
            float cfFrac = static_cast<float>(crossfadePos / static_cast<double>(zone->crossfadeSamples));
            if (cfFrac > 1.0f) cfFrac = 1.0f;
            crossfadeGain = cfFrac;
            doCrossfade = true;
        }

        // Linear interpolation read
        float sampleL = readChannelLinear(stream.get(), effectivePos, 0, totalFrames);
        float sampleR = readChannelLinear(stream.get(), effectivePos, 1, totalFrames);

        if (doCrossfade) {
            float altL = readChannelLinear(stream.get(), altPos, 0, totalFrames);
            float altR = readChannelLinear(stream.get(), altPos, 1, totalFrames);
            float invGain = 1.0f - crossfadeGain;
            sampleL = sampleL * invGain + altL * crossfadeGain;
            sampleR = sampleR * invGain + altR * crossfadeGain;
            crossfadePos += pitchRatio;
            if (crossfadePos >= static_cast<double>(zone->crossfadeSamples)) {
                position = loopStartPos + (crossfadePos - static_cast<double>(zone->crossfadeSamples));
                inCrossfade = false;
                crossfadePos = 0.0;
            }
        }

        // Anti-aliasing
        sampleL = applyAA(sampleL, aaCoeff, aaStateL);
        sampleR = applyAA(sampleR, aaCoeff, aaStateR);

        position += pitchRatio;

        if (loopEnabled && position >= static_cast<double>(loopEnd)) {
            position = static_cast<double>(loopStart) + (position - static_cast<double>(loopEnd));
            inCrossfade = false;
            crossfadePos = 0.0;
        }

        if (!loopEnabled && position >= static_cast<double>(totalFrames)) {
            active = false;
            envState = IDLE;
            outL[n] = 0.0f;
            outR[n] = 0.0f;
            framesWritten = n + 1;
            continue;
        }

        float envVel = ampEnv * velocity;
        outL[n] = sampleL * envVel;
        outR[n] = sampleR * envVel;
        framesWritten = n + 1;
    }

    return framesWritten;
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

// Legacy per-sample process (inefficient, kept for compat)
void SamplePlayer::process(float& left, float& right, int numFrames) {
    if (mixLevel_ <= 0.0f || zones_.empty()) return;

    for (int f = 0; f < numFrames; ++f) {
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
}

// Block-based process: render each voice into a temp buffer and accumulate.
void SamplePlayer::processBlock(float* outL, float* outR, int numFrames) {
    if (mixLevel_ <= 0.0f || zones_.empty() || numFrames <= 0) return;

    // Temporary stereo buffers per voice on the stack (max 512 typical)
    alignas(16) float voiceL[512];
    alignas(16) float voiceR[512];

    int frames = std::min(numFrames, 512);

    for (auto& voice : voices_) {
        if (!voice.active) continue;

        std::memset(voiceL, 0, frames * sizeof(float));
        std::memset(voiceR, 0, frames * sizeof(float));

        int written = voice.processBlock(voiceL, voiceR, frames, sampleRate_);
        if (written > 0) {
            // SIMD-friendly accumulation loop
            for (int i = 0; i < written; ++i) {
                outL[i] += voiceL[i] * mixLevel_;
                outR[i] += voiceR[i] * mixLevel_;
            }
        }
    }
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

// ── Async preload ────────────────────────────────────────────────────────────

void SamplePlayer::preloadAsync() {
    std::lock_guard<std::mutex> lock(preloadMutex_);
    preloadFutures_.clear();
    preloadComplete_ = false;

    for (const auto& zone : zones_) {
        for (int i = 0; i < static_cast<int>(VelocityLayer::Count); ++i) {
            auto stream = zone->streams[i];
            if (!stream) continue;
            // Launch a task that just touches the preload cache and prefetches
            preloadFutures_.push_back(std::async(std::launch::async, [stream]() {
                if (stream->isOpen()) {
                    stream->prefetch(stream->getPreloadSamples());
                }
            }));
        }
    }
}

void SamplePlayer::waitForPreload() {
    std::lock_guard<std::mutex> lock(preloadMutex_);
    for (auto& f : preloadFutures_) {
        if (f.valid()) f.wait();
    }
    preloadFutures_.clear();
    preloadComplete_ = true;
}

bool SamplePlayer::isPreloadComplete() const {
    std::lock_guard<std::mutex> lock(preloadMutex_);
    if (preloadComplete_) return true;
    for (const auto& f : preloadFutures_) {
        if (f.valid() && f.wait_for(std::chrono::seconds(0)) != std::future_status::ready)
            return false;
    }
    preloadComplete_ = true;
    return true;
}

// ── Metrics ──────────────────────────────────────────────────────────────────

SamplePlayer::AggregateMetrics SamplePlayer::getMetrics() const {
    AggregateMetrics agg;
    uint64_t hits = 0;
    uint64_t total = 0;
    for (const auto& zone : zones_) {
        for (int i = 0; i < static_cast<int>(VelocityLayer::Count); ++i) {
            auto stream = zone->streams[i];
            if (!stream) continue;
            const auto& m = stream->getMetrics();
            hits += m.preloadHits.load() + m.ringHits.load();
            total += m.totalRequests.load();
            agg.underruns += m.underruns.load();
        }
    }
    agg.totalRequests = total;
    agg.cacheHitRate = (total > 0) ? static_cast<double>(hits) / static_cast<double>(total) : 0.0;
    return agg;
}

void SamplePlayer::resetMetrics() {
    for (const auto& zone : zones_) {
        for (int i = 0; i < static_cast<int>(VelocityLayer::Count); ++i) {
            auto stream = zone->streams[i];
            if (stream) stream->resetMetrics();
        }
    }
}

} // namespace opensynth
