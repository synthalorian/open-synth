#pragma once
#include <cstdint>
#include <cstddef>

namespace opensynth {

struct AudioBuffer {
    float* data;
    uint32_t numFrames;
    uint32_t numChannels;

    AudioBuffer() : data(nullptr), numFrames(0), numChannels(1) {}
    AudioBuffer(float* d, uint32_t f, uint32_t c = 1)
        : data(d), numFrames(f), numChannels(c) {}
};

} // namespace opensynth
