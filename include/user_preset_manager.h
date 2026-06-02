#pragma once
#include <juce_core/juce_core.h>
#include <juce_audio_processors/juce_audio_processors.h>

namespace openamp {

struct UserPreset {
    juce::String name;
    juce::String category;
    juce::StringArray tags;
    juce::var parameterValues; // JSON object with paramID -> value
    juce::Time creationTime;

    juce::var toJSON() const;
    static std::optional<UserPreset> fromJSON(const juce::var& json);
};

class UserPresetManager {
public:
    UserPresetManager();

    // Save current APVTS state as a user preset
    bool savePreset(const juce::String& name, const juce::String& category,
                    const juce::StringArray& tags,
                    juce::AudioProcessorValueTreeState& apvts);

    // Load a user preset into APVTS
    bool loadPreset(const UserPreset& preset, juce::AudioProcessorValueTreeState& apvts);

    // Delete a user preset by name
    bool deletePreset(const juce::String& name);

    // Get all user presets
    std::vector<UserPreset> getUserPresets() const;

    // Get user presets directory
    static juce::File getPresetsDirectory();

private:
    juce::File getPresetsFile() const;
    void writePresetsToDisk(const std::vector<UserPreset>& presets) const;
};

} // namespace openamp
