#include "sample_engine.h"
#include "sfizz.hpp"
#include "sfizz_message.h"
#include <cmath>
#include <cstring>
#include <string>

namespace openamp {

SampleEngine::SampleEngine()
    : synth_(std::make_unique<sfz::Sfizz>())
{
    synth_->setSamplesPerBlock(blockSize_);
    synth_->setSampleRate(sampleRate_);
}

SampleEngine::~SampleEngine() = default;

SampleEngine::SampleEngine(SampleEngine&& other) noexcept
    : synth_(std::move(other.synth_))
    , loaded_(other.loaded_)
    , sampleRate_(other.sampleRate_)
    , blockSize_(other.blockSize_)
    , tempBuffer_(std::move(other.tempBuffer_))
{
    other.loaded_ = false;
}

SampleEngine& SampleEngine::operator=(SampleEngine&& other) noexcept {
    if (this != &other) {
        synth_ = std::move(other.synth_);
        loaded_ = other.loaded_;
        sampleRate_ = other.sampleRate_;
        blockSize_ = other.blockSize_;
        tempBuffer_ = std::move(other.tempBuffer_);
        other.loaded_ = false;
    }
    return *this;
}

bool SampleEngine::loadSfzFile(const std::string& path) {
    if (!synth_) return false;
    loaded_ = synth_->loadSfzFile(path);
    return loaded_;
}

bool SampleEngine::loadSfzString(const std::string& virtualPath, const std::string& sfzText) {
    if (!synth_) return false;
    loaded_ = synth_->loadSfzString(virtualPath, sfzText);
    return loaded_;
}

void SampleEngine::setSampleRate(float sampleRate) {
    sampleRate_ = sampleRate;
    if (synth_) {
        synth_->setSampleRate(sampleRate);
    }
}

void SampleEngine::setBlockSize(int blockSize) {
    blockSize_ = blockSize;
    if (synth_) {
        synth_->setSamplesPerBlock(blockSize);
    }
}

void SampleEngine::setVolume(float volumeDb) {
    if (synth_) {
        synth_->setVolume(volumeDb);
    }
}

float SampleEngine::getVolume() const {
    if (!synth_) return 0.0f;
    return synth_->getVolume();
}

void SampleEngine::noteOn(int delay, int noteNumber, int velocity) {
    if (!synth_ || !loaded_) return;
    synth_->noteOn(delay, noteNumber, velocity);
}

void SampleEngine::noteOff(int delay, int noteNumber, int velocity) {
    if (!synth_ || !loaded_) return;
    synth_->noteOff(delay, noteNumber, velocity);
}

void SampleEngine::cc(int delay, int ccNumber, int ccValue) {
    if (!synth_ || !loaded_) return;
    synth_->cc(delay, ccNumber, ccValue);
}

void SampleEngine::pitchWheel(int delay, int pitch) {
    if (!synth_ || !loaded_) return;
    synth_->pitchWheel(delay, pitch);
}

void SampleEngine::aftertouch(int delay, int aftertouch) {
    if (!synth_ || !loaded_) return;
    synth_->channelAftertouch(delay, aftertouch);
}

void SampleEngine::render(float* output, int numFrames) {
    if (!synth_ || !loaded_) {
        // Silence if not loaded
        std::memset(output, 0, numFrames * 2 * sizeof(float));
        return;
    }

    // sfizz::renderBlock expects float** with channels separated.
    // We use a temp buffer and then interleave into output.
    tempBuffer_.resize(numFrames * 2);
    float* channels[2] = { tempBuffer_.data(), tempBuffer_.data() + numFrames };
    
    synth_->renderBlock(channels, numFrames, 1);

    // Interleave L/R into output buffer
    for (int i = 0; i < numFrames; ++i) {
        output[i * 2] = channels[0][i];
        output[i * 2 + 1] = channels[1][i];
    }
}

int SampleEngine::getNumActiveVoices() const {
    if (!synth_) return 0;
    return synth_->getNumActiveVoices();
}

int SampleEngine::getNumVoices() const {
    if (!synth_) return 0;
    return synth_->getNumVoices();
}

void SampleEngine::setNumVoices(int numVoices) {
    if (synth_) {
        synth_->setNumVoices(numVoices);
    }
}

int SampleEngine::getNumRegions() const {
    if (!synth_) return 0;
    return synth_->getNumRegions();
}

size_t SampleEngine::getNumPreloadedSamples() const {
    if (!synth_) return 0;
    return synth_->getNumPreloadedSamples();
}

std::string SampleEngine::getInstrumentName() const {
    // sfizz doesn't have a direct getInstrumentName, but we can check key labels
    // or return empty string for now
    return "";
}

void SampleEngine::allSoundOff() {
    if (synth_) {
        synth_->allSoundOff();
    }
    loaded_ = false;
}

} // namespace openamp
