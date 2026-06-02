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

    g.setColour(SynthColors::surface());
    g.fillEllipse(cx - radius, cy - radius, size, size);

    float value = (float)getValue();
    float startAngle = 2.356f;
    float endAngle = startAngle + value * 4.712f;

    juce::Path arc;
    arc.addCentredArc(cx, cy, radius - 2, radius - 2, 0.0f, startAngle, endAngle, true);
    g.setColour(accent_);
    g.strokePath(arc, juce::PathStrokeType(3.0f));

    juce::Path arcDim;
    arcDim.addCentredArc(cx, cy, radius - 2, radius - 2, 0.0f, endAngle, startAngle + 4.712f, true);
    g.setColour(SynthColors::gridLine());
    g.strokePath(arcDim, juce::PathStrokeType(2.0f));

    g.setColour(SynthColors::textDim());
    g.setFont(juce::Font(juce::FontOptions(10.0f)));
    g.drawText(name_, cx - radius, cy + radius + 2, size, 14, juce::Justification::centred);
}

void SynthKnob::resized() {}

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
    g.setFont(juce::Font(juce::FontOptions(14.0f)));
    juce::String title = oscIndex_ == 1 ? "OSCILLATOR 1" : "OSCILLATOR 2";
    g.drawText(title, 12, 8, 120, 20, juce::Justification::left);
    g.setColour(SynthColors::gridLine());
    g.drawHorizontalLine(32, 8, getWidth() - 8);
}

void OscPanel::resized()
{
    int knobSize = 56, gap = 8;
    waveformSelector_.setBounds(12, 36, 100, 24);
    int x = 12, y = 68;
    waveformKnob_.setBounds(x, y, knobSize, knobSize + 16); x += knobSize + gap;
    octaveKnob_.setBounds(x, y, knobSize, knobSize + 16); x += knobSize + gap;
    detuneKnob_.setBounds(x, y, knobSize, knobSize + 16); x += knobSize + gap;
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
    g.setFont(juce::Font(juce::FontOptions(14.0f)));
    g.drawText("FILTER", 12, 8, 100, 20, juce::Justification::left);
    g.setColour(SynthColors::gridLine());
    g.drawHorizontalLine(32, 8, getWidth() - 8);
}

void FilterPanel::resized()
{
    int knobSize = 56, gap = 8, x = 12, y = 68;
    cutoffKnob_.setBounds(x, y, knobSize, knobSize + 16); x += knobSize + gap;
    resonanceKnob_.setBounds(x, y, knobSize, knobSize + 16); x += knobSize + gap;
    envAmtKnob_.setBounds(x, y, knobSize, knobSize + 16); x += knobSize + gap;
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
    g.setFont(juce::Font(juce::FontOptions(14.0f)));
    g.drawText(name_ + " ENVELOPE", 12, 8, 200, 20, juce::Justification::left);
    g.setColour(SynthColors::gridLine());
    g.drawHorizontalLine(32, 8, getWidth() - 8);
}

void EnvelopePanel::resized()
{
    int knobSize = 56, gap = 8, x = 12, y = 68;
    attackKnob_.setBounds(x, y, knobSize, knobSize + 16); x += knobSize + gap;
    decayKnob_.setBounds(x, y, knobSize, knobSize + 16); x += knobSize + gap;
    sustainKnob_.setBounds(x, y, knobSize, knobSize + 16); x += knobSize + gap;
    releaseKnob_.setBounds(x, y, knobSize, knobSize + 16);
}

// ── FxSlotPanel ─────────────────────────────────────────────────────────────

FxSlotPanel::FxSlotPanel(juce::AudioProcessorValueTreeState& apvts, int slotIndex)
    : apvts_(apvts), slotIndex_(slotIndex),
      paramKnobs_{{"P1", SynthColors::neonPurple()}, {"P2", SynthColors::hotPink()},
                   {"P3", SynthColors::cyan()}, {"P4", SynthColors::neonYellow()}}
{
    enabledButton_.setButtonText("ON");
    enabledButton_.setColour(juce::ToggleButton::tickColourId, SynthColors::neonPurple());
    addAndMakeVisible(enabledButton_);

    populateFxTypes();
    addAndMakeVisible(typeSelector_);

    for (auto& knob : paramKnobs_)
        addAndMakeVisible(knob);

    juce::String prefix = "fx" + juce::String(slotIndex);
    enabledAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::ButtonAttachment>(
        apvts_, prefix + "Enabled", enabledButton_);
    typeAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::ComboBoxAttachment>(
        apvts_, prefix + "Type", typeSelector_);

    for (int i = 0; i < 4; ++i)
    {
        paramAttaches_[i] = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
            apvts_, prefix + "Param" + juce::String(i), paramKnobs_[i]);
    }
}

void FxSlotPanel::populateFxTypes()
{
    typeSelector_.addItem("None", 1);
    typeSelector_.addItem("Chorus", 2);
    typeSelector_.addItem("Delay", 3);
    typeSelector_.addItem("Reverb", 4);
    typeSelector_.addItem("Phaser", 5);
    typeSelector_.addItem("Flanger", 6);
    typeSelector_.addItem("Compressor", 7);
    typeSelector_.addItem("Drive", 8);
    typeSelector_.addItem("EQ", 9);
    typeSelector_.addItem("Limiter", 10);
    typeSelector_.addItem("Rotary", 11);
    typeSelector_.addItem("Tremolo", 12);
    typeSelector_.addItem("Auto-Wah", 13);
    typeSelector_.addItem("Bitcrusher", 14);
    typeSelector_.addItem("Ring Mod", 15);
    typeSelector_.addItem("Pitch Shift", 16);
    typeSelector_.addItem("Multi-tap Delay", 17);
    typeSelector_.addItem("Ping-Pong Delay", 18);
    typeSelector_.addItem("Spring Reverb", 19);
    typeSelector_.addItem("Gated Reverb", 20);
    typeSelector_.addItem("Amp Sim", 21);
    typeSelector_.addItem("Stereo Widener", 22);
}

void FxSlotPanel::paint(juce::Graphics& g)
{
    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(getLocalBounds().toFloat(), 8.0f);

    juce::Colour accent = slotIndex_ == 1 ? SynthColors::neonPurple()
                         : slotIndex_ == 2 ? SynthColors::hotPink()
                         : SynthColors::cyan();
    g.setColour(accent);
    g.setFont(juce::Font(juce::FontOptions(14.0f)));
    g.drawText("FX SLOT " + juce::String(slotIndex_), 12, 8, 120, 20, juce::Justification::left);
    g.setColour(SynthColors::gridLine());
    g.drawHorizontalLine(32, 8, getWidth() - 8);
}

void FxSlotPanel::resized()
{
    enabledButton_.setBounds(12, 36, 50, 24);
    typeSelector_.setBounds(68, 36, 120, 24);

    int knobSize = 48, gap = 6, x = 12, y = 68;
    for (auto& knob : paramKnobs_)
    {
        knob.setBounds(x, y, knobSize, knobSize + 14);
        x += knobSize + gap;
    }
}

// ── ArpPanel ────────────────────────────────────────────────────────────────

ArpPanel::ArpPanel(juce::AudioProcessorValueTreeState& apvts)
    : apvts_(apvts),
      tempoKnob_("Tempo", SynthColors::neonPurple()),
      gateKnob_("Gate", SynthColors::hotPink()),
      swingKnob_("Swing", SynthColors::cyan()),
      octaveKnob_("Octave", SynthColors::neonYellow())
{
    enabledButton_.setButtonText("ARP ON");
    enabledButton_.setColour(juce::ToggleButton::tickColourId, SynthColors::neonPurple());
    addAndMakeVisible(enabledButton_);

    patternSelector_.addItemList({"Up", "Down", "Up/Down", "Random", "Chord"}, 1);
    addAndMakeVisible(patternSelector_);

    addAndMakeVisible(tempoKnob_);
    addAndMakeVisible(gateKnob_);
    addAndMakeVisible(swingKnob_);
    addAndMakeVisible(octaveKnob_);

    enabledAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::ButtonAttachment>(
        apvts_, "arpEnabled", enabledButton_);
    patternAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::ComboBoxAttachment>(
        apvts_, "arpPattern", patternSelector_);
    tempoAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, "arpTempo", tempoKnob_);
    gateAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, "arpGate", gateKnob_);
    swingAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, "arpSwing", swingKnob_);
    octaveAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, "arpOctave", octaveKnob_);
}

void ArpPanel::paint(juce::Graphics& g)
{
    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(getLocalBounds().toFloat(), 8.0f);
    g.setColour(SynthColors::magenta());
    g.setFont(juce::Font(juce::FontOptions(14.0f)));
    g.drawText("ARPEGGIATOR", 12, 8, 120, 20, juce::Justification::left);
    g.setColour(SynthColors::gridLine());
    g.drawHorizontalLine(32, 8, getWidth() - 8);
}

void ArpPanel::resized()
{
    enabledButton_.setBounds(12, 36, 70, 24);
    patternSelector_.setBounds(88, 36, 100, 24);

    int knobSize = 48, gap = 6, x = 12, y = 68;
    tempoKnob_.setBounds(x, y, knobSize, knobSize + 14); x += knobSize + gap;
    gateKnob_.setBounds(x, y, knobSize, knobSize + 14); x += knobSize + gap;
    swingKnob_.setBounds(x, y, knobSize, knobSize + 14); x += knobSize + gap;
    octaveKnob_.setBounds(x, y, knobSize, knobSize + 14);
}

// ── PerformanceMeter ────────────────────────────────────────────────────────

PerformanceMeter::PerformanceMeter()
{
    startTimerHz(10);
}

void PerformanceMeter::setVoiceCount(int count) { voiceCount_ = count; }
void PerformanceMeter::setCpuLoad(float load) { cpuLoad_ = load; }

void PerformanceMeter::timerCallback() { repaint(); }

void PerformanceMeter::paint(juce::Graphics& g)
{
    auto b = getLocalBounds().toFloat();

    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(b, 6.0f);

    // CPU bar
    float cpuNorm = juce::jlimit(0.0f, 1.0f, cpuLoad_ / 100.0f);
    juce::Colour cpuColor = cpuNorm < 0.5f ? SynthColors::neonPurple()
                          : cpuNorm < 0.8f ? SynthColors::neonYellow()
                          : SynthColors::danger();

    g.setColour(cpuColor.withAlpha(0.3f));
    g.fillRoundedRectangle(b.reduced(4), 4.0f);

    g.setColour(cpuColor);
    float barWidth = (b.getWidth() - 8) * cpuNorm;
    g.fillRoundedRectangle(b.getX() + 4, b.getY() + 4, barWidth, b.getHeight() - 8, 4.0f);

    // Text
    g.setColour(SynthColors::text());
    g.setFont(juce::Font(juce::FontOptions(10.0f)));
    g.drawText("CPU: " + juce::String(cpuLoad_, 1) + "% | Voices: " + juce::String(voiceCount_),
               b.toNearestInt(), juce::Justification::centred, false);
}

void PerformanceMeter::resized() {}

// ── PresetBrowser ───────────────────────────────────────────────────────────

PresetBrowser::PresetBrowser()
{
    setOpaque(true);

    titleLabel_.setText("PRESET BROWSER", juce::dontSendNotification);
    titleLabel_.setFont(juce::Font(juce::FontOptions(20.0f, juce::Font::bold)));
    titleLabel_.setColour(juce::Label::textColourId, SynthColors::neonPurple());
    addAndMakeVisible(titleLabel_);

    searchBox_.setTextToShowWhenEmpty("Search presets...", SynthColors::textDim());
    searchBox_.setColour(juce::TextEditor::backgroundColourId, SynthColors::surface());
    searchBox_.setColour(juce::TextEditor::textColourId, SynthColors::text());
    searchBox_.addListener(this);
    addAndMakeVisible(searchBox_);

    closeButton_.setButtonText("X");
    closeButton_.setColour(juce::TextButton::buttonColourId, SynthColors::danger());
    closeButton_.onClick = [this]() { setVisible(false); };
    addAndMakeVisible(closeButton_);

    // Category filter
    categoryFilter_.addItem("All Categories", 1);
    categoryFilter_.addItemList({"Pads", "Leads", "Bass", "Keys", "Arps", "FX",
        "Synthwave", "Organ", "Strings", "Brass", "Piano", "Guitar", "Choir",
        "Percussion", "Electric Guitar", "Drums", "Ethnic", "Mallets",
        "Electric Piano", "Acoustic Guitar", "Bass Guitar", "Woodwinds",
        "Custom", "Clavinet"}, 2);
    categoryFilter_.onChange = [this]() {
        int idx = categoryFilter_.getSelectedItemIndex();
        currentCategory_ = (idx <= 0) ? "" : categoryFilter_.getItemText(idx);
        rebuildFilter();
    };
    addAndMakeVisible(categoryFilter_);

    presetList_.setModel(this);
    presetList_.setColour(juce::ListBox::backgroundColourId, SynthColors::surface());
    addAndMakeVisible(presetList_);

    rebuildFilter();
}

void PresetBrowser::rebuildFilter()
{
    filteredPresets_.clear();
    currentSearch_ = searchBox_.getText().toLowerCase();

    for (int i = 0; i < kNumPresets; ++i) {
        const auto& preset = kPresets[i];
        bool matchesSearch = currentSearch_.isEmpty() ||
                             preset.name.toLowerCase().contains(currentSearch_) ||
                             preset.id.toLowerCase().contains(currentSearch_);
        bool matchesCategory = currentCategory_.isEmpty() ||
                               preset.category.equalsIgnoreCase(currentCategory_);
        if (matchesSearch && matchesCategory)
            filteredPresets_.push_back(&preset);
    }

    presetList_.updateContent();
    presetList_.repaint();
}

void PresetBrowser::paintListBoxItem(int rowNumber, juce::Graphics& g, int width, int height, bool rowIsSelected)
{
    if (rowNumber < 0 || rowNumber >= (int)filteredPresets_.size()) return;

    auto* preset = filteredPresets_[rowNumber];
    auto b = juce::Rectangle<int>(0, 0, width, height);

    if (rowIsSelected) {
        g.setColour(SynthColors::neonPurple().withAlpha(0.4f));
        g.fillRect(b);
    } else if (rowNumber % 2 == 0) {
        g.setColour(SynthColors::card().withAlpha(0.3f));
        g.fillRect(b);
    }

    g.setColour(SynthColors::text());
    g.setFont(juce::Font(juce::FontOptions(13.0f)));
    g.drawText(preset->name, b.reduced(8, 2), juce::Justification::centredLeft, true);

    g.setColour(SynthColors::textDim());
    g.setFont(juce::Font(juce::FontOptions(10.0f)));
    g.drawText(preset->category, b.reduced(8, 2), juce::Justification::centredRight, true);
}

void PresetBrowser::selectedRowsChanged(int lastRowSelected)
{
    if (lastRowSelected >= 0 && lastRowSelected < (int)filteredPresets_.size()) {
        if (onPresetSelected)
            onPresetSelected(filteredPresets_[lastRowSelected]);
    }
}

void PresetBrowser::paint(juce::Graphics& g)
{
    g.fillAll(SynthColors::background().withAlpha(0.95f));

    g.setColour(SynthColors::gridLine());
    for (int x = 0; x < getWidth(); x += 40)
        g.drawVerticalLine(x, 0, getHeight());
    for (int y = 0; y < getHeight(); y += 40)
        g.drawHorizontalLine(y, 0, getWidth());
}

void PresetBrowser::resized()
{
    auto b = getLocalBounds().reduced(20);
    titleLabel_.setBounds(b.removeFromTop(30));
    closeButton_.setBounds(getWidth() - 50, 20, 30, 30);

    auto filterRow = b.removeFromTop(30);
    categoryFilter_.setBounds(filterRow.removeFromLeft(180));
    filterRow.removeFromLeft(8);
    searchBox_.setBounds(filterRow);

    b.removeFromTop(8);
    presetList_.setBounds(b);
}

void PresetBrowser::setVisible(bool shouldBeVisible)
{
    juce::Component::setVisible(shouldBeVisible);
    if (shouldBeVisible) {
        searchBox_.grabKeyboardFocus();
        rebuildFilter();
    }
}

// ── FavoritesBar ────────────────────────────────────────────────────────────

FavoritesBar::FavoritesBar()
{
    for (int i = 0; i < 8; ++i)
    {
        favButtons_[i].setButtonText(juce::String(i + 1));
        favButtons_[i].setColour(juce::TextButton::buttonColourId, SynthColors::card());
        favButtons_[i].setColour(juce::TextButton::textColourOffId, SynthColors::neonYellow());
        favButtons_[i].onClick = [this, i]() { buttonClicked(i); };
        addAndMakeVisible(favButtons_[i]);
    }
}

void FavoritesBar::paint(juce::Graphics& g)
{
    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(getLocalBounds().toFloat(), 6.0f);
}

void FavoritesBar::resized()
{
    auto b = getLocalBounds().reduced(4);
    int btnWidth = b.getWidth() / 8 - 4;
    for (int i = 0; i < 8; ++i)
    {
        favButtons_[i].setBounds(b.getX() + i * (btnWidth + 4), b.getY(), btnWidth, b.getHeight());
    }
}

void FavoritesBar::buttonClicked(int index)
{
    if (onPresetSelected)
        onPresetSelected(index);
}

// ── SplitKeyboardOverlay ────────────────────────────────────────────────────

SplitKeyboardOverlay::SplitKeyboardOverlay()
{
    setInterceptsMouseClicks(true, false);
}

void SplitKeyboardOverlay::paint(juce::Graphics& g)
{
    if (!isVisible()) return;

    auto b = getLocalBounds().toFloat();
    float splitX = b.getX() + (splitPoint_ - 21) * b.getWidth() / (108 - 21);

    // Split line
    g.setColour(SynthColors::neonYellow());
    g.drawVerticalLine((int)splitX, b.getY(), b.getBottom());

    // Zone labels
    g.setFont(juce::Font(juce::FontOptions(12.0f, juce::Font::bold)));
    g.setColour(SynthColors::hotPink());
    g.drawText("LOWER", (int)b.getX() + 4, (int)b.getY() + 4, 60, 20, juce::Justification::left);
    g.setColour(SynthColors::cyan());
    g.drawText("UPPER", (int)splitX + 4, (int)b.getY() + 4, 60, 20, juce::Justification::left);

    // Note name at split
    static const char* noteNames[] = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"};
    int note = splitPoint_ % 12;
    int octave = splitPoint_ / 12 - 1;
    g.setColour(SynthColors::neonYellow());
    g.drawText(noteNames[note] + juce::String(octave), (int)splitX - 20, (int)b.getBottom() - 24, 40, 20, juce::Justification::centred);
}

void SplitKeyboardOverlay::resized() {}

void SplitKeyboardOverlay::setSplitPoint(int note)
{
    splitPoint_ = juce::jlimit(21, 108, note);
    repaint();
}

void SplitKeyboardOverlay::mouseDown(const juce::MouseEvent& e)
{
    dragging_ = true;
    setSplitPoint(noteAtX(e.getPosition().getX()));
    if (onSplitChanged)
        onSplitChanged(splitPoint_);
}

void SplitKeyboardOverlay::mouseDrag(const juce::MouseEvent& e)
{
    if (dragging_)
    {
        setSplitPoint(noteAtX(e.getPosition().getX()));
        if (onSplitChanged)
            onSplitChanged(splitPoint_);
    }
}

void SplitKeyboardOverlay::mouseUp(const juce::MouseEvent&)
{
    dragging_ = false;
}

int SplitKeyboardOverlay::noteAtX(int x) const
{
    auto b = getLocalBounds().toFloat();
    float norm = juce::jlimit(0.0f, 1.0f, (float)(x - b.getX()) / b.getWidth());
    return 21 + (int)(norm * (108 - 21));
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
    g.setColour(SynthColors::surface());
    g.fillRect(b);

    // White keys
    for (int note = 21; note <= 108; ++note)
    {
        if (!isBlackKey(note))
        {
            auto keyRect = getWhiteKeyRect(note);
            bool pressed = pressedNote_ == note;
            bool isSplit = showSplit_ && note >= splitPoint_;

            g.setColour(pressed ? SynthColors::neonPurple() :
                        isSplit ? SynthColors::cyan().withAlpha(0.3f) :
                        juce::Colours::white);
            g.fillRect(keyRect);
            g.setColour(SynthColors::surface());
            g.drawRect(keyRect, 1.0f);
        }
    }

    // Black keys
    for (int note = 21; note <= 108; ++note)
    {
        if (isBlackKey(note))
        {
            auto keyRect = getBlackKeyRect(note);
            bool pressed = pressedNote_ == note;
            bool isSplit = showSplit_ && note >= splitPoint_;

            g.setColour(pressed ? SynthColors::hotPink() :
                        isSplit ? SynthColors::cyan().withAlpha(0.5f) :
                        juce::Colours::black);
            g.fillRect(keyRect);
        }
    }

    // Split indicator line
    if (showSplit_)
    {
        auto splitRect = getWhiteKeyRect(splitPoint_);
        g.setColour(SynthColors::neonYellow());
        g.drawVerticalLine((int)splitRect.getX(), b.getY(), b.getBottom());
    }
}

void PianoKeyboard::resized() {}

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

void PianoKeyboard::mouseUp(const juce::MouseEvent&)
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

void PianoKeyboard::setSplitPoint(int note)
{
    splitPoint_ = juce::jlimit(21, 108, note);
    repaint();
}

void PianoKeyboard::setShowSplit(bool show)
{
    showSplit_ = show;
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
    return { whiteRect.getRight() - blackWidth * 0.5f, (float)getY(), blackWidth, blackHeight };
}

int PianoKeyboard::getNoteAtPosition(juce::Point<int> pos) const
{
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

} // namespace openamp

// ── MidiLearnManager ────────────────────────────────────────────────────────

namespace openamp {

void MidiLearnManager::startLearning(const juce::String& paramID)
{
    learningParam_ = paramID;
}

void MidiLearnManager::cancelLearning()
{
    learningParam_.clear();
}

bool MidiLearnManager::handleMidiCC(int ccNumber, float value, juce::AudioProcessorValueTreeState& apvts)
{
    if (learningParam_.isNotEmpty()) {
        auto it = ccToParam_.find(ccNumber);
        if (it != ccToParam_.end()) {
            paramToCC_.erase(it->second);
        }
        auto it2 = paramToCC_.find(learningParam_);
        if (it2 != paramToCC_.end()) {
            ccToParam_.erase(it2->second);
        }
        paramToCC_[learningParam_] = ccNumber;
        ccToParam_[ccNumber] = learningParam_;
        learningParam_.clear();
        return true;
    }

    auto it = ccToParam_.find(ccNumber);
    if (it != ccToParam_.end()) {
        auto* param = apvts.getParameter(it->second);
        if (param != nullptr) {
            param->setValueNotifyingHost(value / 127.0f);
        }
        return true;
    }
    return false;
}

std::vector<MidiLearnManager::Mapping> MidiLearnManager::getMappings() const
{
    std::vector<Mapping> result;
    result.reserve(paramToCC_.size());
    for (const auto& kv : paramToCC_) {
        result.push_back({kv.first, kv.second});
    }
    return result;
}

void MidiLearnManager::setMappings(const std::vector<Mapping>& mappings)
{
    paramToCC_.clear();
    ccToParam_.clear();
    for (const auto& m : mappings) {
        if (m.ccNumber >= 0 && m.ccNumber <= 127) {
            paramToCC_[m.paramID] = m.ccNumber;
            ccToParam_[m.ccNumber] = m.paramID;
        }
    }
}

int MidiLearnManager::getCCForParam(const juce::String& paramID) const
{
    auto it = paramToCC_.find(paramID);
    return (it != paramToCC_.end()) ? it->second : -1;
}

// ── MidiLearnableKnob ───────────────────────────────────────────────────────

MidiLearnableKnob::MidiLearnableKnob(const juce::String& name, juce::Colour accent,
                                     juce::AudioProcessorValueTreeState& apvts,
                                     const juce::String& paramID,
                                     MidiLearnManager& midiLearn)
    : SynthKnob(name, accent), apvts_(apvts), paramID_(paramID), midiLearn_(midiLearn)
{
}

void MidiLearnableKnob::mouseDown(const juce::MouseEvent& e)
{
    if (e.mods.isRightButtonDown()) {
        showContextMenu();
        return;
    }
    SynthKnob::mouseDown(e);
}

void MidiLearnableKnob::showContextMenu()
{
    juce::PopupMenu menu;
    int currentCC = midiLearn_.getCCForParam(paramID_);

    if (currentCC >= 0) {
        menu.addItem(juce::PopupMenu::Item("Mapped to CC " + juce::String(currentCC)).setEnabled(false));
        menu.addSeparator();
        menu.addItem("Unmap MIDI", [this]() {
            midiLearn_.setMappings({});
            repaint();
        });
    } else {
        menu.addItem("Learn MIDI CC", [this]() {
            midiLearn_.startLearning(paramID_);
            repaint();
        });
    }
    menu.showMenuAsync(juce::PopupMenu::Options().withTargetComponent(this));
}

void MidiLearnableKnob::paint(juce::Graphics& g)
{
    SynthKnob::paint(g);

    auto bounds = getLocalBounds().toFloat();
    float size = juce::jmin(bounds.getWidth(), bounds.getHeight()) - 8.0f;
    float cx = bounds.getCentreX();
    float cy = bounds.getCentreY();
    float radius = size * 0.5f;

    if (midiLearn_.isLearning() && midiLearn_.getLearningParam() == paramID_) {
        float pulse = 0.5f + 0.5f * std::sin(juce::Time::getMillisecondCounter() / 200.0f);
        g.setColour(SynthColors::neonYellow().withAlpha(pulse));
        g.drawEllipse(cx - radius - 3, cy - radius - 3, size + 6, size + 6, 2.0f);
    } else if (midiLearn_.getCCForParam(paramID_) >= 0) {
        g.setColour(SynthColors::neonYellow());
        g.fillEllipse(cx + radius - 6, cy - radius - 2, 8, 8);
    }
}

} // namespace openamp

// ── OpenSynthEditor ─────────────────────────────────────────────────────────

namespace openamp {

OpenSynthEditor::OpenSynthEditor(OpenSynthProcessor& processor)
    : AudioProcessorEditor(&processor), processor_(processor),
      osc1Panel_(processor.getParameters(), 1),
      osc2Panel_(processor.getParameters(), 2),
      filterPanel_(processor.getParameters()),
      ampEnvPanel_(processor.getParameters(), "AMP"),
      filterEnvPanel_(processor.getParameters(), "FILTER"),
      fx1Panel_(processor.getParameters(), 1),
      fx2Panel_(processor.getParameters(), 2),
      fx3Panel_(processor.getParameters(), 3),
      arpPanel_(processor.getParameters()),
      keyboard_(keyboardState_)
{
    setSize(1400, 900);
    setResizable(true, true);
    setResizeLimits(1000, 700, 1920, 1200);

    // Title
    titleLabel_.setText("OpenSynth", juce::dontSendNotification);
    titleLabel_.setFont(juce::Font(juce::FontOptions(28.0f, juce::Font::bold)));
    titleLabel_.setColour(juce::Label::textColourId, SynthColors::neonPurple());
    addAndMakeVisible(titleLabel_);

    // Header buttons
    presetButton_.setButtonText("Presets");
    presetButton_.setColour(juce::TextButton::buttonColourId, SynthColors::card());
    presetButton_.setColour(juce::TextButton::textColourOffId, SynthColors::hotPink());
    presetButton_.onClick = [this]() { showPresetBrowser(); };
    addAndMakeVisible(presetButton_);

    setlistButton_.setButtonText("Setlist");
    setlistButton_.setColour(juce::TextButton::buttonColourId, SynthColors::card());
    setlistButton_.setColour(juce::TextButton::textColourOffId, SynthColors::cyan());
    addAndMakeVisible(setlistButton_);

    // Favorites bar
    favorites_.onPresetSelected = [this](int idx) {
        if (idx >= 0 && idx < kNumPresets)
            loadPresetByIndex(idx);
    };
    addAndMakeVisible(favorites_);

    // Preset browser callback
    presetBrowser_.onPresetSelected = [this](const PresetInfo* preset) {
        if (preset != nullptr) {
            loadPresetByID(preset->id);
            presetBrowser_.setVisible(false);
        }
    };

    // Meters
    addAndMakeVisible(meters_);

    // Panels
    addAndMakeVisible(osc1Panel_);
    addAndMakeVisible(osc2Panel_);
    addAndMakeVisible(filterPanel_);
    addAndMakeVisible(ampEnvPanel_);
    addAndMakeVisible(filterEnvPanel_);
    addAndMakeVisible(fx1Panel_);
    addAndMakeVisible(fx2Panel_);
    addAndMakeVisible(fx3Panel_);
    addAndMakeVisible(arpPanel_);
    addAndMakeVisible(keyboard_);

    // Overlays (initially hidden)
    addChildComponent(presetBrowser_);
    addChildComponent(splitOverlay_);

    splitOverlay_.onSplitChanged = [this](int note)
    {
        keyboard_.setSplitPoint(note);
    };

    // Start meter timer
    startTimerHz(10);
}

void OpenSynthEditor::handleMidiCC(int ccNumber, float value)
{
    midiLearnManager_.handleMidiCC(ccNumber, value, processor_.getParameters());
}

void OpenSynthEditor::timerCallback()
{
    int voices = processor_.getSynth().getActiveVoiceCount();
    float cpu = processor_.getSynth().getCpuLoad() * 100.0f;
    meters_.setVoiceCount(voices);
    meters_.setCpuLoad(cpu);
}

void OpenSynthEditor::showPresetBrowser()
{
    presetBrowser_.setVisible(true);
    presetBrowser_.setBounds(getLocalBounds());
    presetBrowser_.toFront(true);
}

void OpenSynthEditor::showSetlistMode()
{
    // TODO: Implement setlist overlay
}

void OpenSynthEditor::loadFavoritePreset(int index)
{
    juce::ignoreUnused(index);
}

void OpenSynthEditor::loadPresetByIndex(int index)
{
    if (index >= 0 && index < kNumPresets)
        loadPresetByID(kPresets[index].id);
}

void OpenSynthEditor::loadPresetByID(const juce::String& id)
{
    // Find preset in library
    for (int i = 0; i < kNumPresets; ++i) {
        if (kPresets[i].id == id) {
            // Update title
            titleLabel_.setText(kPresets[i].name, juce::dontSendNotification);
            // TODO: Load full parameter set into APVTS when preset data includes parameters
            break;
        }
    }
}

void OpenSynthEditor::paint(juce::Graphics& g)
{
    g.fillAll(SynthColors::background());
    g.setColour(SynthColors::gridLine());
    for (int x = 0; x < getWidth(); x += 40)
        g.drawVerticalLine(x, 0, getHeight());
    for (int y = 0; y < getHeight(); y += 40)
        g.drawHorizontalLine(y, 0, getWidth());
}

void OpenSynthEditor::resized()
{
    auto b = getLocalBounds().reduced(12);

    // Header row
    auto header = b.removeFromTop(40);
    titleLabel_.setBounds(header.removeFromLeft(200));
    favorites_.setBounds(header.removeFromLeft(320));
    meters_.setBounds(header.removeFromLeft(200));
    presetButton_.setBounds(header.removeFromRight(90));
    setlistButton_.setBounds(header.removeFromRight(90));

    b.removeFromTop(8);

    // Top row: Oscillators + Filter + Arp
    auto topRow = b.removeFromTop(200);
    osc1Panel_.setBounds(topRow.removeFromLeft(260));
    topRow.removeFromLeft(8);
    osc2Panel_.setBounds(topRow.removeFromLeft(260));
    topRow.removeFromLeft(8);
    filterPanel_.setBounds(topRow.removeFromLeft(260));
    topRow.removeFromLeft(8);
    arpPanel_.setBounds(topRow);

    b.removeFromTop(8);

    // Middle row: Envelopes + FX slots
    auto midRow = b.removeFromTop(200);
    ampEnvPanel_.setBounds(midRow.removeFromLeft(200));
    midRow.removeFromLeft(8);
    filterEnvPanel_.setBounds(midRow.removeFromLeft(200));
    midRow.removeFromLeft(8);
    fx1Panel_.setBounds(midRow.removeFromLeft(200));
    midRow.removeFromLeft(8);
    fx2Panel_.setBounds(midRow.removeFromLeft(200));
    midRow.removeFromLeft(8);
    fx3Panel_.setBounds(midRow);

    b.removeFromTop(8);

    // Bottom: Keyboard
    keyboard_.setBounds(b);

    // Overlays fill entire editor
    presetBrowser_.setBounds(getLocalBounds());
    splitOverlay_.setBounds(keyboard_.getBounds());
}

} // namespace openamp
