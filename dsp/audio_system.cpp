#include "audio_system.h"
#include <algorithm>

namespace opensynth {

AudioSystem& AudioSystem::instance() {
    static AudioSystem inst;
    return inst;
}

AudioSystem::AudioSystem() = default;

AudioSystem::~AudioSystem() {
    // Safety: shut down if someone forgot
    if (initialized_) {
        shutdown();
    }
}

bool AudioSystem::init() {
    std::lock_guard<std::mutex> lock(mutex_);

    if (initialized_) {
        initCount_++;
        return true;
    }

    PaError err = Pa_Initialize();
    if (err != paNoError) {
        return false;
    }

    initialized_ = true;
    initCount_ = 1;
    cacheDevices();
    return true;
}

void AudioSystem::shutdown() {
    std::lock_guard<std::mutex> lock(mutex_);

    if (!initialized_) return;

    initCount_--;
    if (initCount_ > 0) return;  // Still referenced

    Pa_Terminate();
    initialized_ = false;
    devices_.clear();
    defaultOutputDevice_ = -1;
}

void AudioSystem::cacheDevices() {
    devices_.clear();
    defaultOutputDevice_ = Pa_GetDefaultOutputDevice();

    int count = Pa_GetDeviceCount();
    if (count < 0) return;

    for (int i = 0; i < count; i++) {
        const PaDeviceInfo* info = Pa_GetDeviceInfo(i);
        if (info == nullptr) continue;
        if (info->maxOutputChannels <= 0) continue;  // Skip input-only

        devices_.push_back(DeviceInfo{
            .index = i,
            .name = info->name ? info->name : "Unknown Device",
            .maxOutputChannels = info->maxOutputChannels,
            .defaultSampleRate = info->defaultSampleRate,
            .isDefault = (i == defaultOutputDevice_),
        });
    }
}

const DeviceInfo* AudioSystem::deviceAt(int index) const {
    for (const auto& d : devices_) {
        if (d.index == index) return &d;
    }
    return nullptr;
}

} // namespace opensynth
