#pragma once
#include <juce_core/juce_core.h>
#include <array>

namespace openamp {

// ── Setlist State ─────────────────────────────────────────────────────────
struct SetlistState {
    static constexpr int kNumSlots = 16;
    std::array<juce::String, kNumSlots> slotPresetNames;

    SetlistState();
    juce::var toJSON() const;
    static SetlistState fromJSON(const juce::var& json);
};

// ── Favorites State ───────────────────────────────────────────────────────
struct FavoritesState {
    static constexpr int kNumSlots = 8;
    std::array<int, kNumSlots> presetIndices; // -1 = empty

    FavoritesState();
    juce::var toJSON() const;
    static FavoritesState fromJSON(const juce::var& json);
};

// ── App State Manager ─────────────────────────────────────────────────────
// Persists setlist slots, favorites, and last-used preset to disk.
class AppStateManager {
public:
    AppStateManager();

    // Setlist
    SetlistState loadSetlist() const;
    void saveSetlist(const SetlistState& state);

    // Favorites
    FavoritesState loadFavorites() const;
    void saveFavorites(const FavoritesState& state);

    // Last preset
    juce::String loadLastPresetID() const;
    void saveLastPresetID(const juce::String& id);

    // Directory
    static juce::File getStateDirectory();

private:
    juce::File getSetlistFile() const;
    juce::File getFavoritesFile() const;
    juce::File getLastPresetFile() const;
};

} // namespace openamp
