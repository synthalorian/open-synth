#include "plugin_editor.h"
#include "plugin_processor.h"

namespace openamp {

// ── SynthKnob ───────────────────────────────────────────────────────────────

SynthKnob::SynthKnob(const juce::String& name, juce::Colour accent)
    : juce::Slider(juce::Slider::RotaryHorizontalVerticalDrag, juce::Slider::NoTextBox),
      name_(name), accent_(accent)
{
    setRange(0.0, 1.0, 0.01);
    setPopupDisplayEnabled(true, true, nullptr);
}

void SynthKnob::paint(juce::Graphics& g)
{
    auto bounds = getLocalBounds().toFloat();
    float size = juce::jmin(bounds.getWidth(), bounds.getHeight()) - 8.0f;
    float cx = bounds.getCentreX();
    float cy = bounds.getCentreY();
    float radius = size * 0.5f;

    // Background ring
    g.setColour(SynthColors::surface());
    g.fillEllipse(cx - radius, cy - radius, size, size);

    // Accent ring (value arc)
    float value = (float)getValue();
    float startAngle = 2.356f; // 135 degrees
    float endAngle = startAngle + value * 4.712f; // 270 degree sweep

    juce::Path arc;
    arc.addCentredArc(cx, cy, radius - 2, radius - 2, 0.0f,
                      startAngle, endAngle, true);
    g.setColour(accent_);
    g.strokePath(arc, juce::PathStrokeType(3.0f));

    // Remaining arc (dim)
    juce::Path arcDim;
    arcDim.addCentredArc(cx, cy, radius - 2, radius - 2, 0.0f,
                         endAngle, startAngle + 4.712f, true);
    g.setColour(SynthColors::gridLine());
    g.strokePath(arcDim, juce::PathStrokeType(2.0f));

    // Label
    g.setColour(SynthColors::textDim());
    g.setFont(10.0f);
    g.drawText(name_, cx - radius, cy + radius + 2, size, 14, juce::Justification::centred);
}

void SynthKnob::resized()
{
    // Let parent handle sizing
}

// ── OscPanel ────────────────────────────────────────────────────────────────

OscPanel::OscPanel(juce::AudioProcessorValueTreeState& apvts, int oscIndex)
    : apvts_(apvts), oscIndex_(oscIndex),
      waveformKnob_("Wave", SynthColors::neonPurple()),
      octaveKnob_("Octave", SynthColors::neonPurple()),
      detuneKnob_("Detune", SynthColors::hotPink()),
      volumeKnob_("Volume", SynthColors::neonYellow())
{
    addAndMakeVisible(waveformKnob_);
    addAndMakeVisible(octaveKnob_);
    addAndMakeVisible(detuneKnob_);
    addAndMakeVisible(volumeKnob_);

    // Waveform selector
    waveformSelector_.addItemList({"Sine", "Triangle", "Saw", "Square", "Pulse",
        "Noise", "Sub", "FM", "Wavetable", "Physical Model"}, 1);
    addAndMakeVisible(waveformSelector_);

    juce::String prefix = oscIndex == 1 ? "osc1" : "osc2";
    waveformAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::ComboBoxAttachment>(
        apvts_, prefix + "Waveform", waveformSelector_);
    octaveAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, prefix + "Octave", octaveKnob_);
    detuneAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, prefix + "Detune", detuneKnob_);
    volumeAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, prefix + "Volume", volumeKnob_);
}

void OscPanel::paint(juce::Graphics& g)
{
    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(getLocalBounds().toFloat(), 8.0f);

    g.setColour(SynthColors::neonPurple());
    g.setFont(14.0f);
    juce::String title = oscIndex_ == 1 ? "OSCILLATOR 1" : "OSCILLATOR 2";
    g.drawText(title, 12, 8, 120, 20, juce::Justification::left);

    g.setColour(SynthColors::gridLine());
    g.drawHorizontalLine(32, 8, getWidth() - 8);
}

void OscPanel::resized()
{
    auto b = getLocalBounds().reduced(8, 36);
    int knobSize = 56;
    int gap = 8;

    waveformSelector_.setBounds(12, 36, 100, 24);

    int x = 12;
    int y = 68;
    waveformKnob_.setBounds(x, y, knobSize, knobSize + 16);
    x += knobSize + gap;
    octaveKnob_.setBounds(x, y, knobSize, knobSize + 16);
    x += knobSize + gap;
    detuneKnob_.setBounds(x, y, knobSize, knobSize + 16);
    x += knobSize + gap;
    volumeKnob_.setBounds(x, y, knobSize, knobSize + 16);
}

// ── FilterPanel ─────────────────────────────────────────────────────────────

FilterPanel::FilterPanel(juce::AudioProcessorValueTreeState& apvts)
    : apvts_(apvts),
      cutoffKnob_("Cutoff", SynthColors::cyan()),
      resonanceKnob_("Resonance", SynthColors::cyan()),
      envAmtKnob_("Env Amt", SynthColors::hotPink()),
      driveKnob_("Drive", SynthColors::neonYellow())
{
    addAndMakeVisible(cutoffKnob_);
    addAndMakeVisible(resonanceKnob_);
    addAndMakeVisible(envAmtKnob_);
    addAndMakeVisible(driveKnob_);

    cutoffAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, "filterCutoff", cutoffKnob_);
    resonanceAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, "filterResonance", resonanceKnob_);
    envAmtAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, "filterEnvAmt", envAmtKnob_);
    driveAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, "filterDrive", driveKnob_);
}

void FilterPanel::paint(juce::Graphics& g)
{
    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(getLocalBounds().toFloat(), 8.0f);

    g.setColour(SynthColors::cyan());
    g.setFont(14.0f);
    g.drawText("FILTER", 12, 8, 100, 20, juce::Justification::left);

    g.setColour(SynthColors::gridLine());
    g.drawHorizontalLine(32, 8, getWidth() - 8);
}

void FilterPanel::resized()
{
    auto b = getLocalBounds().reduced(8, 36);
    int knobSize = 56;
    int gap = 8;
    int x = 12;
    int y = 68;

    cutoffKnob_.setBounds(x, y, knobSize, knobSize + 16);
    x += knobSize + gap;
    resonanceKnob_.setBounds(x, y, knobSize, knobSize + 16);
    x += knobSize + gap;
    envAmtKnob_.setBounds(x, y, knobSize, knobSize + 16);
    x += knobSize + gap;
    driveKnob_.setBounds(x, y, knobSize, knobSize + 16);
}

// ── EnvelopePanel ───────────────────────────────────────────────────────────

EnvelopePanel::EnvelopePanel(juce::AudioProcessorValueTreeState& apvts, const juce::String& name)
    : apvts_(apvts), name_(name),
      attackKnob_("Attack", SynthColors::neonYellow()),
      decayKnob_("Decay", SynthColors::neonYellow()),
      sustainKnob_("Sustain", SynthColors::neonYellow()),
      releaseKnob_("Release", SynthColors::neonYellow())
{
    addAndMakeVisible(attackKnob_);
    addAndMakeVisible(decayKnob_);
    addAndMakeVisible(sustainKnob_);
    addAndMakeVisible(releaseKnob_);

    juce::String prefix = name == "AMP" ? "amp" : "filter";
    attackAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, prefix + "Attack", attackKnob_);
    decayAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, prefix + "Decay", decayKnob_);
    sustainAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, prefix + "Sustain", sustainKnob_);
    releaseAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, prefix + "Release", releaseKnob_);
}

void EnvelopePanel::paint(juce::Graphics& g)
{
    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(getLocalBounds().toFloat(), 8.0f);

    g.setColour(SynthColors::neonYellow());
    g.setFont(14.0f);
    g.drawText(name_ + " ENVELOPE", 12, 8, 200, 20, juce::Justification::left);

    g.setColour(SynthColors::gridLine());
    g.drawHorizontalLine(32, 8, getWidth() - 8);
}

void EnvelopePanel::resized()
{
    auto b = getLocalBounds().reduced(8, 36);
    int knobSize = 56;
    int gap = 8;
    int x = 12;
    int y = 68;

    attackKnob_.setBounds(x, y, knobSize, knobSize + 16);
    x += knobSize + gap;
    decayKnob_.setBounds(x, y, knobSize, knobSize + 16);
    x += knobSize + gap;
    sustainKnob_.setBounds(x, y, knobSize, knobSize + 16);
    x += knobSize + gap;
    releaseKnob_.setBounds(x, y, knobSize, knobSize + 16);
}

// ── PianoKeyboard ───────────────────────────────────────────────────────────

PianoKeyboard::PianoKeyboard(juce::MidiKeyboardState& state)
    : state_(state)
{
    state_.addListener(this);
}

PianoKeyboard::~PianoKeyboard()
{
    state_.removeListener(this);
}

void PianoKeyboard::paint(juce::Graphics& g)
{
    auto b = getLocalBounds().toFloat();

    // Background
    g.setColour(SynthColors::surface());
    g.fillRect(b);

    // Draw white keys
    for (int note = 21; note <= 108; ++note)
    {
        if (!isBlackKey(note))
        {
            auto keyRect = getWhiteKeyRect(note);
            bool pressed = pressedNote_ == note;
            bool hovered = hoveredNote_ == note;

            g.setColour(pressed ? SynthColors::neonPurple() :
                        hovered ? SynthColors::card() : juce::Colours::white);
            g.fillRect(keyRect);

            g.setColour(SynthColors::surface());
            g.drawRect(keyRect, 1.0f);
        }
    }

    // Draw black keys on top
    for (int note = 21; note <= 108; ++note)
    {
        if (isBlackKey(note))
        {
            auto keyRect = getBlackKeyRect(note);
            bool pressed = pressedNote_ == note;
            bool hovered = hoveredNote_ == note;

            g.setColour(pressed ? SynthColors::hotPink() :
                        hovered ? SynthColors::neonPurple() : juce::Colours::black);
            g.fillRect(keyRect);
        }
    }
}

void PianoKeyboard::resized()
{
    // Keys auto-size based on bounds
}

void PianoKeyboard::mouseDown(const juce::MouseEvent& e)
{
    int note = getNoteAtPosition(e.getPosition());
    if (note >= 0)
    {
        pressedNote_ = note;
        state_.noteOn(1, note, 0.8f);
        repaint();
    }
}

void PianoKeyboard::mouseUp(const juce::MouseEvent& e)
{
    if (pressedNote_ >= 0)
    {
        state_.noteOff(1, pressedNote_, 0.0f);
        pressedNote_ = -1;
        repaint();
    }
}

void PianoKeyboard::mouseDrag(const juce::MouseEvent& e)
{
    int note = getNoteAtPosition(e.getPosition());
    if (note >= 0 && note != pressedNote_)
    {
        if (pressedNote_ >= 0)
            state_.noteOff(1, pressedNote_, 0.0f);
        pressedNote_ = note;
        state_.noteOn(1, note, 0.8f);
        repaint();
    }
}

void PianoKeyboard::handleNoteOn(juce::MidiKeyboardState*, int, int note, float)
{
    pressedNote_ = note;
    repaint();
}

void PianoKeyboard::handleNoteOff(juce::MidiKeyboardState*, int, int note, float)
{
    if (pressedNote_ == note)
        pressedNote_ = -1;
    repaint();
}

bool PianoKeyboard::isBlackKey(int note) const
{
    int n = note % 12;
    return n == 1 || n == 3 || n == 6 || n == 8 || n == 10;
}

juce::Rectangle<float> PianoKeyboard::getWhiteKeyRect(int note) const
{
    auto b = getLocalBounds().toFloat();
    int whiteKeyIndex = 0;
    for (int n = 21; n < note; ++n)
        if (!isBlackKey(n))
            whiteKeyIndex++;

    int totalWhiteKeys = 0;
    for (int n = 21; n <= 108; ++n)
        if (!isBlackKey(n))
            totalWhiteKeys++;

    float keyWidth = b.getWidth() / totalWhiteKeys;
    return { b.getX() + whiteKeyIndex * keyWidth, b.getY(), keyWidth - 1, b.getHeight() };
}

juce::Rectangle<float> PianoKeyboard::getBlackKeyRect(int note) const
{
    auto whiteRect = getWhiteKeyRect(note - 1);
    float blackWidth = whiteRect.getWidth() * 0.6f;
    float blackHeight = getHeight() * 0.6f;
    return { whiteRect.getRight() - blackWidth * 0.5f, getY(), blackWidth, blackHeight };
}

int PianoKeyboard::getNoteAtPosition(juce::Point<int> pos) const
{
    // Check black keys first (they're on top)
    for (int note = 108; note >= 21; --note)
    {
        if (isBlackKey(note))
        {
            if (getBlackKeyRect(note).toNearestInt().contains(pos))
                return note;
        }
    }
    for (int note = 21; note <= 108; ++note)
    {
        if (!isBlackKey(note))
        {
            if (getWhiteKeyRect(note).toNearestInt().contains(pos))
                return note;
        }
    }
    return -1;
}

// ── FxPanel (stub - full implementation later) ──────────────────────────────

FxPanel::FxPanel(juce::AudioProcessorValueTreeState& apvts)
    : apvts_(apvts), tabs_(juce::TabbedButtonBar::TabsAtTop)
{
    addAndMakeVisible(tabs_);
    tabs_.addTab("FX 1", SynthColors::neonPurple(), new juce::Component(), true);
    tabs_.addTab("FX 2", SynthColors::hotPink(), new juce::Component(), true);
    tabs_.addTab("FX 3", SynthColors::cyan(), new juce::Component(), true);
}

void FxPanel::paint(juce::Graphics& g)
{
    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(getLocalBounds().toFloat(), 8.0f);
}

void FxPanel::resized()
{
    tabs_.setBounds(getLocalBounds().reduced(8));
}

// ── OpenSynthEditor ─────────────────────────────────────────────────────────

OpenSynthEditor::OpenSynthEditor(OpenSynthProcessor& processor)
    : AudioProcessorEditor(&processor), processor_(processor),
      osc1Panel_(processor.getParameters(), 1),
      osc2Panel_(processor.getParameters(), 2),
      filterPanel_(processor.getParameters()),
      ampEnvPanel_(processor.getParameters(), "AMP"),
      filterEnvPanel_(processor.getParameters(), "FILTER"),
      fxPanel_(processor.getParameters()),
      keyboard_(keyboardState_)
{
    setSize(1200, 800);
    setResizable(true, true);
    setResizeLimits(900, 600, 1920, 1200);

    // Title
    titleLabel_.setText("OpenSynth", juce::dontSendNotification);
    titleLabel_.setFont(juce::Font(28.0f, juce::Font::bold));
    titleLabel_.setColour(juce::Label::textColourId, SynthColors::neonPurple());
    addAndMakeVisible(titleLabel_);

    // Preset button
    presetButton_.setButtonText("Presets");
    presetButton_.setColour(juce::TextButton::buttonColourId, SynthColors::card());
    presetButton_.setColour(juce::TextButton::textColourOffId, SynthColors::hotPink());
    addAndMakeVisible(presetButton_);

    // Panels
    addAndMakeVisible(osc1Panel_);
    addAndMakeVisible(osc2Panel_);
    addAndMakeVisible(filterPanel_);
    addAndMakeVisible(ampEnvPanel_);
    addAndMakeVisible(filterEnvPanel_);
    addAndMakeVisible(fxPanel_);
    addAndMakeVisible(keyboard_);

    // Meters
    voiceCountLabel_.setText("Voices: 0", juce::dontSendNotification);
    voiceCountLabel_.setColour(juce::Label::textColourId, SynthColors::textDim());
    addAndMakeVisible(voiceCountLabel_);

    cpuLabel_.setText("CPU: 0%", juce::dontSendNotification);
    cpuLabel_.setColour(juce::Label::textColourId, SynthColors::textDim());
    addAndMakeVisible(cpuLabel_);

    // Start meter timer
    startTimerHz(10);
}

void OpenSynthEditor::timerCallback()
{
    int voices = processor_.getSynth().getActiveVoiceCount();
    float cpu = processor_.getSynth().getCpuLoad() * 100.0f;

    voiceCountLabel_.setText("Voices: " + juce::String(voices), juce::dontSendNotification);
    cpuLabel_.setText("CPU: " + juce::String(cpu, 1) + "%", juce::dontSendNotification);
}

void OpenSynthEditor::paint(juce::Graphics& g)
{
    // Deep purple background with subtle grid
    g.fillAll(SynthColors::background());

    // Grid lines
    g.setColour(SynthColors::gridLine());
    for (int x = 0; x < getWidth(); x += 40)
        g.drawVerticalLine(x, 0, getHeight());
    for (int y = 0; y < getHeight(); y += 40)
        g.drawHorizontalLine(y, 0, getWidth());
}

void OpenSynthEditor::resized()
{
    auto b = getLocalBounds().reduced(12);

    // Header
    titleLabel_.setBounds(b.removeFromTop(40).removeFromLeft(200));
    presetButton_.setBounds(b.getX() + b.getWidth() - 100, b.getY() - 40, 90, 32);

    b.removeFromTop(8);

    // Top row: Oscillators + Filter
    auto topRow = b.removeFromTop(200);
    osc1Panel_.setBounds(topRow.removeFromLeft(280));
    topRow.removeFromLeft(8);
    osc2Panel_.setBounds(topRow.removeFromLeft(280));
    topRow.removeFromLeft(8);
    filterPanel_.setBounds(topRow);

    b.removeFromTop(8);

    // Middle row: Envelopes + FX
    auto midRow = b.removeFromTop(200);
    ampEnvPanel_.setBounds(midRow.removeFromLeft(280));
    midRow.removeFromLeft(8);
    filterEnvPanel_.setBounds(midRow.removeFromLeft(280));
    midRow.removeFromLeft(8);
    fxPanel_.setBounds(midRow);

    b.removeFromTop(8);

    // Bottom: Keyboard + meters
    auto bottomRow = b;
    voiceCountLabel_.setBounds(bottomRow.removeFromBottom(24).removeFromLeft(120));
    cpuLabel_.setBounds(bottomRow.removeFromBottom(24).removeFromLeft(120));
    keyboard_.setBounds(bottomRow);
}

} // namespace openamp
