// Preset browser UI logic tests: category switching, keyboard navigation,
// loaded-instrument state. Runs headless (no desktop peers created).
#include <juce_gui_basics/juce_gui_basics.h>
#include "plugin_editor.h"
#include "preset_library_full.h"

using namespace opensynth;

static int g_failures = 0;

#define CHECK(cond)                                                     \
    do {                                                                \
        if (!(cond)) {                                                  \
            std::printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, #cond); \
            ++g_failures;                                               \
        }                                                               \
    } while (0)

// Mirrors the browser's rule: snake_case library categories normalize to
// words, filters match exactly or as whole words ("pad" covers "synth pad").
static bool categoryMatches(const char* presetCategory, const juce::String& filter)
{
    if (filter.isEmpty()) return true;
    juce::String cat = juce::String(presetCategory).replaceCharacter('_', ' ').toLowerCase();
    if (cat == filter.toLowerCase()) return true;
    return (" " + cat + " ").contains(" " + filter.toLowerCase() + " ");
}

static int countFactoryPresetsInCategory(const juce::String& filter)
{
    int count = 0;
    for (int i = 0; i < kNumFullPresets; ++i)
        if (categoryMatches(kFullPresets[i].category, filter))
            ++count;
    return count;
}

int main()
{
    juce::ScopedJuceInitialiser_GUI init;

    // ── Full list by default ─────────────────────────────────────────
    {
        PresetBrowser browser;
        browser.setSize(1200, 800);
        CHECK(browser.getNumDisplayedPresets() == kNumFullPresets);
    }

    // ── Fast category switching (Piano/Organ/Drums/Bass/Pads) ────────
    {
        PresetBrowser browser;
        browser.setSize(1200, 800);

        for (const char* cat : {"piano", "organ", "drums", "bass", "pad"})
        {
            browser.setCategoryFilter(cat);
            int expected = countFactoryPresetsInCategory(cat);
            CHECK(expected > 0);
            CHECK(browser.getNumDisplayedPresets() == expected);
        }

        // Exact library categories work too
        browser.setCategoryFilter("Synth Pad");
        CHECK(browser.getNumDisplayedPresets() == countFactoryPresetsInCategory("synth pad"));

        browser.setCategoryFilter("");
        CHECK(browser.getNumDisplayedPresets() == kNumFullPresets);
    }

    // ── Keyboard navigation auditions presets ────────────────────────
    {
        PresetBrowser browser;
        browser.setSize(1200, 800);

        int auditioned = -1;
        browser.onPresetSelected = [&auditioned](int idx) { auditioned = idx; };

        browser.setCategoryFilter("piano");

        // Down selects and auditions the first row
        CHECK(browser.handleKey(juce::KeyPress(juce::KeyPress::downKey)));
        CHECK(browser.getSelectedRow() == 0);
        CHECK(auditioned >= 0 && auditioned < kNumFullPresets);
        int firstPiano = auditioned;
        CHECK(categoryMatches(kFullPresets[firstPiano].category, "piano"));

        // Down again moves to the next preset
        CHECK(browser.handleKey(juce::KeyPress(juce::KeyPress::downKey)));
        CHECK(browser.getSelectedRow() == 1);
        CHECK(auditioned != firstPiano);

        // Up wraps back
        CHECK(browser.handleKey(juce::KeyPress(juce::KeyPress::upKey)));
        CHECK(browser.getSelectedRow() == 0);
        CHECK(auditioned == firstPiano);

        // Up from the first row wraps to the last
        CHECK(browser.handleKey(juce::KeyPress(juce::KeyPress::upKey)));
        CHECK(browser.getSelectedRow() == browser.getNumDisplayedPresets() - 1);
    }

    // ── Enter loads and closes; Escape closes ────────────────────────
    {
        PresetBrowser browser;
        browser.setSize(1200, 800);

        int loaded = -1;
        browser.onPresetSelected = [&loaded](int idx) { loaded = idx; };

        browser.setVisible(true);
        CHECK(browser.isVisible());
        CHECK(browser.handleKey(juce::KeyPress(juce::KeyPress::returnKey)));
        CHECK(!browser.isVisible());
        CHECK(loaded >= 0);  // nothing selected -> first row loads

        browser.setVisible(true);
        CHECK(browser.isVisible());
        CHECK(browser.handleKey(juce::KeyPress(juce::KeyPress::escapeKey)));
        CHECK(!browser.isVisible());
    }

    // ── Left/right cycles the category filter ────────────────────────
    {
        PresetBrowser browser;
        browser.setSize(1200, 800);

        // From "All Categories", right moves to the first library category
        CHECK(browser.handleKey(juce::KeyPress(juce::KeyPress::rightKey)));
        int cycled = browser.getNumDisplayedPresets();
        CHECK(cycled > 0 && cycled < kNumFullPresets);

        // Left wraps back to all
        CHECK(browser.handleKey(juce::KeyPress(juce::KeyPress::leftKey)));
        CHECK(browser.getNumDisplayedPresets() == kNumFullPresets);

        // Left from "all" wraps to the last combo item (Custom: no factory presets)
        CHECK(browser.handleKey(juce::KeyPress(juce::KeyPress::leftKey)));
        CHECK(browser.getNumDisplayedPresets() == 0);
    }

    // ── Currently loaded instrument is preselected on open ───────────
    {
        PresetBrowser browser;
        browser.setSize(1200, 800);

        browser.setCategoryFilter("piano");

        // Find the 3rd piano-group preset in the factory library
        int target = -1;
        int seen = 0;
        for (int i = 0; i < kNumFullPresets; ++i)
        {
            if (categoryMatches(kFullPresets[i].category, "piano") && seen++ == 2)
            {
                target = i;
                break;
            }
        }
        CHECK(target >= 0);

        browser.setCurrentPreset(target, kFullPresets[target].name);
        browser.setVisible(true);
        CHECK(browser.getSelectedRow() == 2);
    }

    if (g_failures == 0)
        std::printf("All preset browser tests passed.\n");
    else
        std::printf("%d preset browser test(s) FAILED.\n", g_failures);

    return g_failures == 0 ? 0 : 1;
}
