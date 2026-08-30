#pragma once
#include <juce_gui_basics/juce_gui_basics.h>

namespace opensynth {

// ── Blackshield Colour Palette (default) ──────────────────────────────────
// Blood + steel + bone. Source of truth: KDE scheme "Blackshield"
// (blackshield-mercenary-v1). See ~/.local/share/color-schemes/Blackshield.colors
struct BlackshieldColours {
    static juce::Colour blood()       { return juce::Colour(0xFFC1121F); }  // accent / highlight
    static juce::Colour bloodBright() { return juce::Colour(0xFFFF6B72); }  // fg on selection only
    static juce::Colour bone()        { return juce::Colour(0xFFD8D3C8); }  // primary text
    static juce::Colour boneBright()  { return juce::Colour(0xFFF5F1E8); }  // text on blood
    static juce::Colour voidBlack()   { return juce::Colour(0xFF0D0D11); }  // deepest bg
    static juce::Colour iron()        { return juce::Colour(0xFF101014); }  // window bg
    static juce::Colour steel()       { return juce::Colour(0xFF16161C); }  // widget/card bg
    static juce::Colour steelLight()  { return juce::Colour(0xFF1A1A20); }  // raised surfaces
    static juce::Colour ash()         { return juce::Colour(0xFF8A8F98); }  // muted fg / borders
    static juce::Colour steelBlue()   { return juce::Colour(0xFF5B7FA6); }  // links / info
    static juce::Colour steelBlueBright() { return juce::Colour(0xFF7B9DC4); }
    static juce::Colour warGold()     { return juce::Colour(0xFFC9A227); }  // warning
    static juce::Colour fieldGreen()  { return juce::Colour(0xFF6A994E); }  // success
};

// ── Synthwave '84 Palette (legacy brand, kept for reference) ──────────────
struct Synthwave84Colours {
    static juce::Colour background()  { return juce::Colour(0xFF240037); }
    static juce::Colour surface()     { return juce::Colour(0xFF1A0029); }
    static juce::Colour card()        { return juce::Colour(0xFF2D0047); }
    static juce::Colour neonPurple()  { return juce::Colour(0xFF8F00FF); }
    static juce::Colour hotPink()     { return juce::Colour(0xFFFF7EDB); }
    static juce::Colour magenta()     { return juce::Colour(0xFFFF00FF); }
    static juce::Colour neonYellow()  { return juce::Colour(0xFFF3E70F); }
    static juce::Colour cyan()        { return juce::Colour(0xFF00F0FF); }
};

} // namespace opensynth
