#pragma once
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

// Forward declare sfizz C++ class
namespace sfz { class Sfizz; }

namespace openamp {

/// Wrapper around sfizz SFZ sample engine.
///
/// This class provides a simplified interface to sfizz tailored for
/// OpenSynth's architecture. It handles SFZ loading, note events,
/// and audio rendering. All file loading is done on the control thread;
/// only noteOn/noteOff/render are called on the audio thread.
class SampleEngine {
public:
    SampleEngine();
    ~SampleEngine();

    // No copy
    SampleEngine(const SampleEngine&) = delete;
    SampleEngine& operator=(const SampleEngine&) = delete;

    // Move
    SampleEngine(SampleEngine&& other) noexcept;
    SampleEngine& operator=(SampleEngine&& other) noexcept;

    /// Load an SFZ file from disk.
    /// @return true on success, false on failure.
    /// @note Must be called from the control thread, NOT the audio thread.
    bool loadSfzFile(const std::string& path);

    /// Load an SFZ from a string (for embedded presets).
    /// @param virtualPath A virtual path used to resolve relative sample paths.
    /// @param sfzText The SFZ file content.
    /// @return true on success, false on failure.
    /// @note Must be called from the control thread, NOT the audio thread.
    bool loadSfzString(const std::string& virtualPath, const std::string& sfzText);

    /// Set the sample rate.
    /// @note Must be called from the control thread, NOT the audio thread.
    void setSampleRate(float sampleRate);

    /// Set the maximum block size for rendering.
    /// @note Must be called from the control thread, NOT the audio thread.
    void setBlockSize(int blockSize);

    /// Set the volume in dB.
    void setVolume(float volumeDb);

    /// Get the current volume in dB.
    float getVolume() const;

    /// Send a note-on event.
    /// @param delay Sample delay within the current block (0 for immediate).
    /// @param noteNumber MIDI note number (0-127).
    /// @param velocity MIDI velocity (0-127).
    /// @note Must be called from the audio thread.
    void noteOn(int delay, int noteNumber, int velocity);

    /// Send a note-off event.
    /// @param delay Sample delay within the current block.
    /// @param noteNumber MIDI note number (0-127).
    /// @param velocity MIDI velocity (0-127).
    /// @note Must be called from the audio thread.
    void noteOff(int delay, int noteNumber, int velocity);

    /// Send a CC event.
    void cc(int delay, int ccNumber, int ccValue);

    /// Send a pitch wheel event.
    void pitchWheel(int delay, int pitch);

    /// Send an aftertouch event.
    void aftertouch(int delay, int aftertouch);

    /// Render audio into the provided buffer.
    /// @param output Stereo interleaved float buffer (output).
    /// @param numFrames Number of frames to render.
    /// @note Must be called from the audio thread.
    void render(float* output, int numFrames);

    /// Get the number of active voices.
    int getNumActiveVoices() const;

    /// Get the total polyphony.
    int getNumVoices() const;

    /// Set the polyphony.
    void setNumVoices(int numVoices);

    /// Get the number of regions in the loaded SFZ.
    int getNumRegions() const;

    /// Get the number of preloaded samples.
    size_t getNumPreloadedSamples() const;

    /// Get the instrument name from the SFZ (if set via `name` opcode).
    std::string getInstrumentName() const;

    /// Check if an SFZ file is currently loaded.
    bool isLoaded() const { return loaded_; }

    /// Reset the engine (all notes off, clear buffers).
    void allSoundOff();

private:
    std::unique_ptr<sfz::Sfizz> synth_;
    bool loaded_ = false;
    float sampleRate_ = 48000.0f;
    int blockSize_ = 256;

    // Temporary render buffer (avoids allocation on audio thread)
    std::vector<float> tempBuffer_;
};

} // namespace openamp
