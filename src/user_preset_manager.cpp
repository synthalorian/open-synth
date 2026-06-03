#include "user_preset_manager.h"

namespace opensynth {

juce::var UserPreset::toJSON() const
{
    juce::DynamicObject::Ptr obj = new juce::DynamicObject();
    obj->setProperty("name", name);
    obj->setProperty("category", category);

    juce::Array<juce::var> tagArray;
    for (const auto& tag : tags)
        tagArray.add(tag);
    obj->setProperty("tags", tagArray);

    obj->setProperty("parameters", parameterValues);
    obj->setProperty("creationTime", creationTime.toMilliseconds());

    return juce::var(obj);
}

std::optional<UserPreset> UserPreset::fromJSON(const juce::var& json)
{
    if (!json.isObject())
        return std::nullopt;

    UserPreset preset;
    preset.name = json.getProperty("name", "").toString();
    preset.category = json.getProperty("category", "").toString();

    if (auto* tagArray = json.getProperty("tags", {}).getArray())
    {
        for (const auto& tag : *tagArray)
            preset.tags.add(tag.toString());
    }

    preset.parameterValues = json.getProperty("parameters", {});
    preset.creationTime = juce::Time(json.getProperty("creationTime", juce::int64(0)));

    return preset;
}

UserPresetManager::UserPresetManager()
{
    getPresetsDirectory().createDirectory();
}

juce::File UserPresetManager::getPresetsDirectory()
{
    return juce::File::getSpecialLocation(juce::File::userApplicationDataDirectory)
        .getChildFile("open-synth-juced")
        .getChildFile("presets");
}

juce::File UserPresetManager::getPresetsFile() const
{
    return getPresetsDirectory().getChildFile("user_presets.json");
}

std::vector<UserPreset> UserPresetManager::getUserPresets() const
{
    std::vector<UserPreset> presets;

    auto file = getPresetsFile();
    if (!file.existsAsFile())
        return presets;

    auto json = juce::JSON::parse(file);
    if (auto* array = json.getArray())
    {
        for (const auto& item : *array)
        {
            if (auto preset = UserPreset::fromJSON(item))
                presets.push_back(*preset);
        }
    }

    return presets;
}

void UserPresetManager::writePresetsToDisk(const std::vector<UserPreset>& presets) const
{
    juce::Array<juce::var> array;
    for (const auto& p : presets)
        array.add(p.toJSON());

    auto file = getPresetsFile();
    auto jsonString = juce::JSON::toString(juce::var(array), true);
    file.replaceWithText(jsonString);
}

bool UserPresetManager::savePreset(const juce::String& name, const juce::String& category,
                                   const juce::StringArray& tags,
                                   juce::AudioProcessorValueTreeState& apvts)
{
    if (name.trim().isEmpty())
        return false;

    UserPreset preset;
    preset.name = name.trim();
    preset.category = category.isEmpty() ? "Custom" : category;
    preset.tags = tags;
    preset.creationTime = juce::Time::getCurrentTime();

    // Capture all parameter values
    juce::DynamicObject::Ptr paramsObj = new juce::DynamicObject();
    for (auto* param : apvts.processor.getParameters())
    {
        if (param != nullptr)
        {
            paramsObj->setProperty(param->getName(50), param->getValue());
        }
    }
    preset.parameterValues = juce::var(paramsObj);

    auto presets = getUserPresets();

    // Replace existing preset with same name
    bool replaced = false;
    for (auto& existing : presets)
    {
        if (existing.name == preset.name)
        {
            existing = preset;
            replaced = true;
            break;
        }
    }

    if (!replaced)
        presets.push_back(preset);

    writePresetsToDisk(presets);
    return true;
}

bool UserPresetManager::loadPreset(const UserPreset& preset, juce::AudioProcessorValueTreeState& apvts)
{
    if (!preset.parameterValues.isObject())
        return false;

    auto* paramsObj = preset.parameterValues.getDynamicObject();
    if (paramsObj == nullptr)
        return false;

    for (auto* param : apvts.processor.getParameters())
    {
        if (param != nullptr)
        {
            juce::String paramName = param->getName(50);
            if (paramsObj->hasProperty(paramName))
            {
                float value = static_cast<float>(paramsObj->getProperty(paramName));
                param->setValueNotifyingHost(value);
            }
        }
    }

    return true;
}

bool UserPresetManager::deletePreset(const juce::String& name)
{
    auto presets = getUserPresets();
    auto it = std::remove_if(presets.begin(), presets.end(),
                             [&name](const UserPreset& p) { return p.name == name; });

    if (it == presets.end())
        return false;

    presets.erase(it, presets.end());
    writePresetsToDisk(presets);
    return true;
}

} // namespace opensynth
