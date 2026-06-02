#include "synth_mixer.h"
#include <cstring>
#include <algorithm>

namespace openamp {

SynthEnginePair::SynthEnginePair(double sampleRate, uint32_t blockSize)
    : engineA_(sampleRate, blockSize)
    , engineB_(sampleRate, blockSize)
{
    // Allocate a temporary stereo buffer for engine B's output.
    // Using std::vector for RAII — no manual free needed in destructor.
    tempStorage_.resize(blockSize * 2, 0.0f);
    tempBuffer_ = AudioBuffer(tempStorage_.data(), blockSize, 2);
    tempBufferAllocated_ = true;
}

SynthEnginePair::~SynthEnginePair() = default;

void SynthEnginePair::process(AudioBuffer& output) {
    if (!tempBufferAllocated_) {
        // Fallback: just process engine A if temp buffer allocation failed
        engineA_.process(output);
        return;
    }

    const uint32_t frames = output.numFrames;
    const bool stereoOut = output.numChannels >= 2;

    // Ensure temp buffer matches output frame count
    if (tempBuffer_.numFrames != frames) {
        tempBuffer_.numFrames = frames;
        tempBuffer_.numChannels = 2;
    }

    // Clear output buffer
    std::memset(output.data, 0, frames * (stereoOut ? 2 : 1) * sizeof(float));

    // Process engine A directly into output
    engineA_.process(output);

    // Process engine B into temp buffer
    std::memset(tempBuffer_.data, 0, frames * 2 * sizeof(float));
    engineB_.process(tempBuffer_);

    // Mix engine B into output with zone volumes
    if (stereoOut) {
        for (uint32_t i = 0; i < frames; i++) {
            output.data[i * 2]     += tempBuffer_.data[i * 2]     * mixB_;
            output.data[i * 2 + 1] += tempBuffer_.data[i * 2 + 1] * mixB_;
        }
        // Apply engine A mix
        for (uint32_t i = 0; i < frames * 2; i++) {
            output.data[i] *= mixA_;
        }
    } else {
        for (uint32_t i = 0; i < frames; i++) {
            const float monoB = (tempBuffer_.data[i * 2] + tempBuffer_.data[i * 2 + 1]) * 0.5f;
            output.data[i] = output.data[i] * mixA_ + monoB * mixB_;
        }
    }
}

void SynthEnginePair::reset() {
    engineA_.reset();
    engineB_.reset();
    if (tempBufferAllocated_) {
        std::memset(tempBuffer_.data, 0, tempBuffer_.numFrames * 2 * sizeof(float));
    }
}

} // namespace openamp
