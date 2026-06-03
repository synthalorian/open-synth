#include "app_state_manager.h"

namespace openamp {

// ── SetlistState ──────────────────────────────────────────────────────────

SetlistState::SetlistState()
{
    slotPresetNames.fill("Empty");
}

juce::var SetlistState::toJSON() const
{
    juce::DynamicObject::Ptr obj = new juce::DynamicObject();
    juce::Array<juce::var> arr;
    for (const auto& name : slotPresetNames)
        arr.add(name);
    obj->setProperty("slots", arr);
    return juce::var(obj);
}

SetlistState SetlistState::fromJSON(const juce::var& json)
{
    SetlistState state;
    if (!json.isObject())
        return state;

    if (auto* arr = json.getProperty("slots", {}).getArray())
    {
        for (int i = 0; i < kNumSlots && i < arr->size(); ++i)
            state.slotPresetNames[i] = (*arr)[i].toString();
    }
    return state;
}

// ── FavoritesState ────────────────────────────────────────────────────────

FavoritesState::FavoritesState()
{
    presetIndices.fill(-1);
}

juce::var FavoritesState::toJSON() const
{
    juce::DynamicObject::Ptr obj = new juce::DynamicObject();
    juce::Array<juce::var> arr;
    for (int idx : presetIndices)
        arr.add(idx);
    obj->setProperty("indices", arr);
    return juce::var(obj);
}

FavoritesState FavoritesState::fromJSON(const juce::var& json)
{
    FavoritesState state;
    if (!json.isObject())
        return state;

    if (auto* arr = json.getProperty("indices", {}).getArray())
    {
        for (int i = 0; i < kNumSlots && i < arr->size(); ++i)
            state.presetIndices[i] = static_cast<int>((*arr)[i]);
    }
    return state;
}

// ── AppStateManager ───────────────────────────────────────────────────────

AppStateManager::AppStateManager()
{
    getStateDirectory().createDirectory();
}

juce::File AppStateManager::getStateDirectory()
{
    return juce::File::getSpecialLocation(juce::File::userApplicationDataDirectory)
        .getChildFile("open-synth-juced");
}

juce::File AppStateManager::getSetlistFile() const
{
    return getStateDirectory().getChildFile("setlist.json");
}

juce::File AppStateManager::getFavoritesFile() const
{
    return getStateDirectory().getChildFile("favorites.json");
}

juce::File AppStateManager::getLastPresetFile() const
{
    return getStateDirectory().getChildFile("last_preset.txt");
}

SetlistState AppStateManager::loadSetlist() const
{
    auto file = getSetlistFile();
    if (!file.existsAsFile())
        return SetlistState{};

    auto json = juce::JSON::parse(file);
    return SetlistState::fromJSON(json);
}

void AppStateManager::saveSetlist(const SetlistState& state)
{
    auto file = getSetlistFile();
    file.replaceWithText(juce::JSON::toString(state.toJSON(), true));
}

FavoritesState AppStateManager::loadFavorites() const
{
    auto file = getFavoritesFile();
    if (!file.existsAsFile())
        return FavoritesState{};

    auto json = juce::JSON::parse(file);
    return FavoritesState::fromJSON(json);
}

void AppStateManager::saveFavorites(const FavoritesState& state)
{
    auto file = getFavoritesFile();
    file.replaceWithText(juce::JSON::toString(state.toJSON(), true));
}

juce::String AppStateManager::loadLastPresetID() const
{
    auto file = getLastPresetFile();
    if (!file.existsAsFile())
        return {};
    return file.loadFileAsString().trim();
}

void AppStateManager::saveLastPresetID(const juce::String& id)
{
    auto file = getLastPresetFile();
    file.replaceWithText(id);
}

} // namespace openamp
