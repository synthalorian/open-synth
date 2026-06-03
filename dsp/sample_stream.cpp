#include "sample_stream.h"
#include <cmath>
#include <algorithm>

namespace opensynth {

SampleStream::SampleStream() = default;

SampleStream::~SampleStream() {
    close();
}

bool SampleStream::open(const std::string& path, int streamBufferSize) {
    close();
    streamBufferSize_ = streamBufferSize;

    // Try memory-mapped reader first (WAV/AIFF)
    if (initMappedReader(path)) {
        useMapping_ = true;
    } else if (initFallbackReader(path)) {
        useMapping_ = false;
    } else {
        return false;
    }

    fillPreloadCache();

    // Setup fallback ring buffer if needed
    if (!useMapping_) {
        ringBufferSize_ = streamBufferSize_ * 2;
        ringBuffer_[0].resize(ringBufferSize_);
        ringBuffer_[1].resize(ringBufferSize_);
        ringBufferStart_.store(0);
        ringBufferEnd_.store(0);
    }

    return true;
}

void SampleStream::close() {
    mappedReader_.reset();
    fallbackReader_.reset();
    fileStream_.reset();
    file_ = juce::File();
    sampleRate_ = 48000.0;
    numChannels_ = 0;
    totalSamples_ = 0;
    preloadSamples_ = 0;
    hasLoopPoints_ = false;
    loopStart_ = 0;
    loopEnd_ = 0;
    useMapping_ = false;
    for (int ch = 0; ch < 2; ++ch) {
        preloadCache_[ch].clear();
        ringBuffer_[ch].clear();
    }
    ringBufferStart_.store(0);
    ringBufferEnd_.store(0);
    ringBufferSize_ = 0;
}

bool SampleStream::isOpen() const {
    return useMapping_ ? (mappedReader_ != nullptr) : (fallbackReader_ != nullptr);
}

int SampleStream::getNumChannels() const {
    return numChannels_;
}

int64_t SampleStream::getTotalSamples() const {
    return totalSamples_;
}

double SampleStream::getSampleRate() const {
    return sampleRate_;
}

bool SampleStream::readSample(int64_t position, float* dest) const {
    if (!isOpen() || position < 0 || position >= totalSamples_ || dest == nullptr)
        return false;

    // Preload cache: first 100ms in RAM
    if (position < preloadSamples_) {
        for (int ch = 0; ch < numChannels_; ++ch) {
            int cacheCh = (ch < 2) ? ch : 0;
            dest[ch] = preloadCache_[cacheCh][static_cast<size_t>(position)];
        }
        // Zero remaining channels if < 2
        for (int ch = numChannels_; ch < 2; ++ch)
            dest[ch] = 0.0f;
        return true;
    }

    if (useMapping_ && mappedReader_) {
        auto mappedSection = mappedReader_->getMappedSection();
        if (position >= mappedSection.getStart() && position < mappedSection.getEnd()) {
            mappedReader_->getSample(position, dest);
            // Zero remaining channels if reader has 1 channel but caller expects 2
            for (int ch = numChannels_; ch < 2; ++ch)
                dest[ch] = 0.0f;
            return true;
        }
        return false;
    }

    // Fallback: read from ring buffer
    if (!fallbackReader_)
        return false;

    int64_t bufStart = ringBufferStart_.load();
    int64_t bufEnd = ringBufferEnd_.load();

    if (position < bufStart || position >= bufEnd) {
        // Refill ring buffer around requested position
        const_cast<SampleStream*>(this)->refillRingBuffer(position);
        bufStart = ringBufferStart_.load();
        bufEnd = ringBufferEnd_.load();
    }

    if (position < bufStart || position >= bufEnd)
        return false;

    int idx = static_cast<int>((position - bufStart) % ringBufferSize_);
    for (int ch = 0; ch < numChannels_; ++ch) {
        int cacheCh = (ch < 2) ? ch : 0;
        dest[ch] = ringBuffer_[cacheCh][idx];
    }
    for (int ch = numChannels_; ch < 2; ++ch)
        dest[ch] = 0.0f;
    return true;
}

int SampleStream::readBlock(juce::AudioBuffer<float>& buffer,
                            int startSample, int numSamples,
                            int64_t filePosition) {
    if (!isOpen() || numSamples <= 0)
        return 0;

    int framesToRead = std::min(numSamples, static_cast<int>(totalSamples_ - filePosition));
    framesToRead = std::max(0, framesToRead);
    if (framesToRead <= 0)
        return 0;

    int chans = std::min(buffer.getNumChannels(), numChannels_);

    if (useMapping_ && mappedReader_) {
        // Fast path: read directly into buffer using AudioFormatReader::read
        // MemoryMappedAudioFormatReader inherits read()
        mappedReader_.get()
            ->read(buffer.getArrayOfWritePointers(), chans, filePosition, framesToRead);

        // Duplicate mono to stereo if needed
        if (numChannels_ == 1 && buffer.getNumChannels() > 1) {
            buffer.copyFrom(1, startSample, buffer.getReadPointer(0), framesToRead);
        }
        return framesToRead;
    }

    // Fallback: sample-by-sample via ring buffer
    float temp[2];
    for (int i = 0; i < framesToRead; ++i) {
        if (readSample(filePosition + i, temp)) {
            for (int ch = 0; ch < buffer.getNumChannels(); ++ch) {
                int srcCh = (ch < numChannels_) ? ch : 0;
                buffer.setSample(ch, startSample + i, temp[srcCh]);
            }
        } else {
            for (int ch = 0; ch < buffer.getNumChannels(); ++ch)
                buffer.setSample(ch, startSample + i, 0.0f);
        }
    }
    return framesToRead;
}

bool SampleStream::initMappedReader(const std::string& path) {
    juce::AudioFormatManager formatManager;
    formatManager.registerBasicFormats();

    file_ = juce::File(juce::String(path));

    juce::AudioFormatReader* createdReader = nullptr;
    int numFormats = formatManager.getNumKnownFormats();
    for (int i = 0; i < numFormats; ++i) {
        auto* fmt = formatManager.getKnownFormat(i);
        if (!fmt) continue;
        mappedReader_.reset(fmt->createMemoryMappedReader(file_));
        if (mappedReader_) {
            createdReader = fmt->createReaderFor(file_.createInputStream().release(), true);
            break;
        }
    }

    if (!mappedReader_)
        return false;

    if (!mappedReader_->mapEntireFile()) {
        mappedReader_.reset();
        return false;
    }

    sampleRate_ = mappedReader_->sampleRate;
    numChannels_ = static_cast<int>(mappedReader_->numChannels);
    totalSamples_ = static_cast<int64_t>(mappedReader_->lengthInSamples);

    // Read loop points from JUCE AudioFormatReader metadata (e.g. WAV smpl chunk)
    if (mappedReader_->metadataValues.containsKey("Loop0Start")) {
        hasLoopPoints_ = true;
        loopStart_ = mappedReader_->metadataValues["Loop0Start"].getIntValue();
        loopEnd_ = mappedReader_->metadataValues["Loop0End"].getIntValue();
    }

    delete createdReader;
    return true;
}

bool SampleStream::initFallbackReader(const std::string& path) {
    juce::AudioFormatManager formatManager;
    formatManager.registerBasicFormats();

    file_ = juce::File(juce::String(path));
    fallbackReader_.reset(formatManager.createReaderFor(file_));

    if (!fallbackReader_)
        return false;

    sampleRate_ = fallbackReader_->sampleRate;
    numChannels_ = static_cast<int>(fallbackReader_->numChannels);
    totalSamples_ = static_cast<int64_t>(fallbackReader_->lengthInSamples);

    if (fallbackReader_->metadataValues.containsKey("Loop0Start")) {
        hasLoopPoints_ = true;
        loopStart_ = fallbackReader_->metadataValues["Loop0Start"].getIntValue();
        loopEnd_ = fallbackReader_->metadataValues["Loop0End"].getIntValue();
    }

    return true;
}

void SampleStream::fillPreloadCache() {
    preloadSamples_ = static_cast<int>(std::ceil(sampleRate_ * PRELOAD_DURATION_SEC));
    if (preloadSamples_ > totalSamples_)
        preloadSamples_ = static_cast<int>(totalSamples_);
    if (preloadSamples_ <= 0)
        return;

    for (int ch = 0; ch < 2; ++ch)
        preloadCache_[ch].resize(preloadSamples_, 0.0f);

    if (useMapping_ && mappedReader_) {
        juce::AudioBuffer<float> tmp(numChannels_, preloadSamples_);
        mappedReader_->read(tmp.getArrayOfWritePointers(), numChannels_, 0, preloadSamples_);
        for (int ch = 0; ch < 2; ++ch) {
            int srcCh = (ch < numChannels_) ? ch : 0;
            std::memcpy(preloadCache_[ch].data(), tmp.getReadPointer(srcCh),
                        preloadSamples_ * sizeof(float));
        }
    } else if (fallbackReader_) {
        juce::AudioBuffer<float> tmp(numChannels_, preloadSamples_);
        fallbackReader_->read(tmp.getArrayOfWritePointers(), numChannels_, 0, preloadSamples_);
        for (int ch = 0; ch < 2; ++ch) {
            int srcCh = (ch < numChannels_) ? ch : 0;
            std::memcpy(preloadCache_[ch].data(), tmp.getReadPointer(srcCh),
                        preloadSamples_ * sizeof(float));
        }
    }
}

void SampleStream::refillRingBuffer(int64_t startPos) const {
    if (!fallbackReader_ || ringBufferSize_ <= 0)
        return;

    int64_t readStart = std::max(int64_t{0}, startPos);
    int64_t readEnd = std::min(readStart + ringBufferSize_, totalSamples_);
    int frames = static_cast<int>(readEnd - readStart);
    if (frames <= 0)
        return;

    juce::AudioBuffer<float> tmp(numChannels_, frames);
    fallbackReader_->read(tmp.getArrayOfWritePointers(), numChannels_, readStart, frames);

    for (int ch = 0; ch < 2; ++ch) {
        int srcCh = (ch < numChannels_) ? ch : 0;
        std::memcpy(ringBuffer_[ch].data(), tmp.getReadPointer(srcCh), frames * sizeof(float));
    }

    ringBufferStart_.store(readStart);
    ringBufferEnd_.store(readStart + frames);
}

} // namespace opensynth
