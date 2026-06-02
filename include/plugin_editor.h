#pragma once
#include <juce_gui_basics/juce_gui_basics.h>
#include <juce_audio_processors/juce_audio_processors.h>
#include "plugin_processor.h"

namespace openamp {

// ── Synthwave Color Palette ───────────────────────────────────────────────
struct SynthColors {
    static juce::Colour background()  { return juce::Colour(0xFF240037); }
    static juce::Colour surface()     { return juce::Colour(0xFF1A0029); }
    static juce::Colour card()        { return juce::Colour(0xFF2D0047); }
    static juce::Colour neonPurple()  { return juce::Colour(0xFF8F00FF); }
    static juce::Colour hotPink()     { return juce::Colour(0xFFFF7EDB); }
    static juce::Colour magenta()     { return juce::Colour(0xFFFF00FF); }
    static juce::Colour neonYellow()  { return juce::Colour(0xFFF3E70F); }
    static juce::Colour cyan()        { return juce::Colour(0xFF00F0FF); }
    static juce::Colour text()        { return juce::Colour(0xFFFFFFFF); }
    static juce::Colour textDim()     { return juce::Colour(0x80FFFFFF); }
    static juce::Colour gridLine()    { return juce::Colour(0x208F00FF); }
};

// ── Custom Knob Component ─────────────────────────────────────────────────
class SynthKnob : public juce::Slider {
public:
    SynthKnob(const juce::String& name, juce::Colour accent);
    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    juce::String name_;
    juce::Colour accent_;
};

// ── Oscillator Panel ──────────────────────────────────────────────────────
class OscPanel : public juce::Component {
public:
    OscPanel(juce::AudioProcessorValueTreeState& apvts, int oscIndex);
    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    juce::AudioProcessorValueTreeState& apvts_;
    int oscIndex_;

    SynthKnob waveformKnob_, octaveKnob_, detuneKnob_, volumeKnob_;
    juce::ComboBox waveformSelector_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::ComboBoxAttachment> waveformAttach_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> octaveAttach_, detuneAttach_, volumeAttach_;
};

// ── Filter Panel ──────────────────────────────────────────────────────────
class FilterPanel : public juce::Component {
public:
    explicit FilterPanel(juce::AudioProcessorValueTreeState& apvts);
    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    juce::AudioProcessorValueTreeState& apvts_;
    SynthKnob cutoffKnob_, resonanceKnob_, envAmtKnob_, driveKnob_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> cutoffAttach_, resonanceAttach_, envAmtAttach_, driveAttach_;
};

// ── Envelope Panel ────────────────────────────────────────────────────────
class EnvelopePanel : public juce::Component {
public:
    EnvelopePanel(juce::AudioProcessorValueTreeState& apvts, const juce::String& name);
    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    juce::AudioProcessorValueTreeState& apvts_;
    juce::String name_;
    SynthKnob attackKnob_, decayKnob_, sustainKnob_, releaseKnob_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> attackAttach_, decayAttach_, sustainAttach_, releaseAttach_;
};

// ── FX Panel ──────────────────────────────────────────────────────────────
class FxPanel : public juce::Component {
public:
    explicit FxPanel(juce::AudioProcessorValueTreeState& apvts);
    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    juce::AudioProcessorValueTreeState& apvts_;
    juce::TabbedComponent tabs_;
};

// ── Keyboard Component ────────────────────────────────────────────────────
class PianoKeyboard : public juce::Component, public juce::MidiKeyboardState::Listener {
public:
    explicit PianoKeyboard(juce::MidiKeyboardState& state);
    ~PianoKeyboard() override;

    void paint(juce::Graphics& g) override;
    void resized() override;
    void mouseDown(const juce::MouseEvent& e) override;
    void mouseUp(const juce::MouseEvent& e) override;
    void mouseDrag(const juce::MouseEvent& e) override;

    void handleNoteOn(juce::MidiKeyboardState*, int midiChannel, int midiNoteNumber, float velocity) override;
    void handleNoteOff(juce::MidiKeyboardState*, int midiChannel, int midiNoteNumber, float velocity) override;

private:
    juce::MidiKeyboardState& state_;
    int hoveredNote_ = -1;
    int pressedNote_ = -1;

    int getNoteAtPosition(juce::Point<int> pos) const;
    bool isBlackKey(int note) const;
    juce::Rectangle<float> getWhiteKeyRect(int note) const;
    juce::Rectangle<float> getBlackKeyRect(int note) const;
};

// ── Main Editor ───────────────────────────────────────────────────────────
class OpenSynthEditor : public juce::AudioProcessorEditor,
                         private juce::Timer {
public:
    explicit OpenSynthEditor(OpenSynthProcessor& processor);
    ~OpenSynthEditor() override = default;

    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    OpenSynthProcessor& processor_;
    juce::MidiKeyboardState keyboardState_;

    // Header
    juce::Label titleLabel_;
    juce::TextButton presetButton_;

    // Main sections
    OscPanel osc1Panel_, osc2Panel_;
    FilterPanel filterPanel_;
    EnvelopePanel ampEnvPanel_, filterEnvPanel_;
    FxPanel fxPanel_;
    PianoKeyboard keyboard_;

    // Performance meters
    juce::Label voiceCountLabel_, cpuLabel_;

    void timerCallback() override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(OpenSynthEditor)
};

} // namespace openamp
