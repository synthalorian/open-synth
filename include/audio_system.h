#pragma once
#include <cstdint>
#include <vector>
#include <string>
#include <mutex>
#include <portaudio.h>

namespace opensynth {

/// Cached info about a single audio output device.
struct DeviceInfo {
    int index;
    std::string name;
    int maxOutputChannels;
    double defaultSampleRate;
    bool isDefault;
};

/// Singleton that owns the PortAudio lifecycle.
///
/// Rules:
///   - Pa_Initialize() called once in init()
///   - Pa_Terminate() called once in shutdown()
///   - Device list is cached after init(); enumeration never calls Pa_Init/Term
///   - AudioStream instances may be created/destroyed freely while the system
///     is initialized, but all streams must be stopped before shutdown()
class AudioSystem {
public:
    /// Get the singleton instance.
    static AudioSystem& instance();

    /// Initialize PortAudio and cache the device list.
    /// Returns true on success. Safe to call multiple times (ref-counted).
    bool init();

    /// Shutdown PortAudio. Must be called after all AudioStreams are destroyed.
    /// Safe to call multiple times (ref-counted).
    void shutdown();

    /// Whether PortAudio is currently initialized.
    bool isInitialized() const { return initialized_; }

    /// Get cached device list. Returns empty vector if not initialized.
    const std::vector<DeviceInfo>& devices() const { return devices_; }

    /// Get the default output device index. Returns -1 if none.
    int defaultOutputDevice() const { return defaultOutputDevice_; }

    /// Get device count from cache.
    int deviceCount() const { return static_cast<int>(devices_.size()); }

    /// Get device info by index from cache. Returns nullptr if not found.
    const DeviceInfo* deviceAt(int index) const;

    // No copy, no move
    AudioSystem(const AudioSystem&) = delete;
    AudioSystem& operator=(const AudioSystem&) = delete;

private:
    AudioSystem();
    ~AudioSystem();

    void cacheDevices();

    bool initialized_ = false;
    int initCount_ = 0;
    int defaultOutputDevice_ = -1;
    std::vector<DeviceInfo> devices_;
    mutable std::mutex mutex_;
};

} // namespace opensynth
