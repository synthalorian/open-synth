#include "plugin_editor.h"
#include "plugin_processor.h"
#include "preset_library_full.h"
#include "preset_data.h"
#include "user_preset_manager.h"
#include "fx_engine.h"

namespace opensynth {

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
    float size = juce::jmin(bounds.getWidth(), bounds.getHeight()) - 10.0f;
    float cx = bounds.getCentreX();
    float cy = bounds.getCentreY();
    float radius = size * 0.5f;

    // Glow effect behind knob
    juce::Path glow;
    glow.addCentredArc(cx, cy, radius + 6, radius + 6, 0.0f, 0.0f, 6.283f, true);
    g.setColour(accent_.withAlpha(0.08f));
    g.fillPath(glow);

    g.setColour(SynthColors::surface());
    g.fillEllipse(cx - radius, cy - radius, size, size);

    // Outer ring
    g.setColour(accent_.withAlpha(0.4f));
    g.drawEllipse(cx - radius, cy - radius, size, size, 1.5f);

    float value = (float)getValue();
    float startAngle = 2.356f;
    float endAngle = startAngle + value * 4.712f;

    juce::Path arc;
    arc.addCentredArc(cx, cy, radius - 3, radius - 3, 0.0f, startAngle, endAngle, true);
    g.setColour(accent_);
    g.strokePath(arc, juce::PathStrokeType(4.0f));

    juce::Path arcDim;
    arcDim.addCentredArc(cx, cy, radius - 3, radius - 3, 0.0f, endAngle, startAngle + 4.712f, true);
    g.setColour(SynthColors::gridLine());
    g.strokePath(arcDim, juce::PathStrokeType(2.0f));

    // Value indicator dot
    float dotAngle = endAngle;
    float dotX = cx + (radius - 8) * std::cos(dotAngle);
    float dotY = cy + (radius - 8) * std::sin(dotAngle);
    g.setColour(accent_.brighter());
    g.fillEllipse(dotX - 3, dotY - 3, 6, 6);

    g.setColour(SynthColors::textDim());
    g.setFont(juce::Font(juce::FontOptions(10.0f)));
    g.drawText(name_, cx - radius, cy + radius + 4, size, 14, juce::Justification::centred);
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
    auto b = getLocalBounds().toFloat();
    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(b, 8.0f);

    // Neon border glow
    g.setColour(SynthColors::neonPurple().withAlpha(0.3f));
    g.drawRoundedRectangle(b.reduced(1.0f), 8.0f, 1.5f);

    g.setColour(SynthColors::neonPurple());
    g.setFont(juce::Font(juce::FontOptions(14.0f, juce::Font::bold)));
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

    // Update knob labels when FX type changes
    typeSelector_.onChange = [this]() {
        updateParamLabels(typeSelector_.getSelectedItemIndex());
    };
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
    typeSelector_.addItem("Vocoder", 23);
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

void FxSlotPanel::updateParamLabels(int fxTypeId)
{
    auto desc = opensynth::FxProcessor::getDescriptor(fxTypeId);
    for (int i = 0; i < 4; ++i)
    {
        if (i < desc.numParams)
        {
            paramKnobs_[i].setName(juce::String(desc.params[i].name));
            paramKnobs_[i].setVisible(true);
        }
        else
        {
            paramKnobs_[i].setName("");
            paramKnobs_[i].setVisible(fxTypeId == 0 ? false : true);
        }
    }
    repaint();
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

// ── RealismPanel ────────────────────────────────────────────────────────────

RealismPanel::RealismPanel(juce::AudioProcessorValueTreeState& apvts)
    : apvts_(apvts),
      bodyMixKnob_("Body Mix", SynthColors::neonPurple()),
      clickMixKnob_("Click", SynthColors::hotPink()),
      sympatheticKnob_("Sympathetic", SynthColors::cyan()),
      brightnessKnob_("Brightness", SynthColors::neonYellow())
{
    bodyTypeSelector_.addItemList({"None", "Piano", "Guitar", "Violin", "Organ", "Brass", "Plucked", "Mallet"}, 1);
    addAndMakeVisible(bodyTypeSelector_);

    addAndMakeVisible(bodyMixKnob_);
    addAndMakeVisible(clickMixKnob_);
    addAndMakeVisible(sympatheticKnob_);
    addAndMakeVisible(brightnessKnob_);

    attackCurveSelector_.addItemList({"Linear", "Exponential", "Logarithmic", "Double-Exp"}, 1);
    addAndMakeVisible(attackCurveSelector_);

    bodyTypeAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::ComboBoxAttachment>(
        apvts_, "realismBodyType", bodyTypeSelector_);
    bodyMixAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, "realismBodyMix", bodyMixKnob_);
    clickMixAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, "realismClickMix", clickMixKnob_);
    sympatheticAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, "realismSympatheticMix", sympatheticKnob_);
    brightnessAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, "realismBrightnessSens", brightnessKnob_);
    attackCurveAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::ComboBoxAttachment>(
        apvts_, "realismAttackCurve", attackCurveSelector_);
}

void RealismPanel::paint(juce::Graphics& g)
{
    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(getLocalBounds().toFloat(), 8.0f);
    g.setColour(SynthColors::neonYellow());
    g.setFont(juce::Font(juce::FontOptions(14.0f)));
    g.drawText("INSTRUMENT REALISM", 12, 8, 160, 20, juce::Justification::left);
    g.setColour(SynthColors::gridLine());
    g.drawHorizontalLine(32, 8, getWidth() - 8);
}

void RealismPanel::resized()
{
    bodyTypeSelector_.setBounds(12, 36, 110, 24);
    attackCurveSelector_.setBounds(128, 36, 120, 24);

    int knobSize = 48, gap = 6, x = 12, y = 68;
    bodyMixKnob_.setBounds(x, y, knobSize, knobSize + 14); x += knobSize + gap;
    clickMixKnob_.setBounds(x, y, knobSize, knobSize + 14); x += knobSize + gap;
    sympatheticKnob_.setBounds(x, y, knobSize, knobSize + 14); x += knobSize + gap;
    brightnessKnob_.setBounds(x, y, knobSize, knobSize + 14);
}

// ── MpePanel ────────────────────────────────────────────────────────────────

MpePanel::MpePanel(juce::AudioProcessorValueTreeState& apvts)
    : apvts_(apvts)
    , bendRangeKnob_("Bend", juce::Colours::cyan)
{
    enableButton_.setButtonText("MPE");
    enableButton_.setColour(juce::TextButton::buttonOnColourId, juce::Colours::cyan);
    enableButton_.setColour(juce::TextButton::textColourOnId, juce::Colours::black);
    addAndMakeVisible(enableButton_);

    zoneSelector_.addItem("Lower (Ch 1)", 1);
    zoneSelector_.addItem("Upper (Ch 16)", 2);
    addAndMakeVisible(zoneSelector_);

    addAndMakeVisible(bendRangeKnob_);

    enableAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::ButtonAttachment>(apvts_, "mpeEnabled", enableButton_);
    zoneAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::ComboBoxAttachment>(apvts_, "mpeZone", zoneSelector_);
    bendRangeAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(apvts_, "mpeBendRange", bendRangeKnob_);
}

void MpePanel::paint(juce::Graphics& g)
{
    auto b = getLocalBounds().toFloat();
    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(b, 6.0f);

    g.setColour(juce::Colours::cyan);
    g.setFont(juce::Font(14.0f, juce::Font::bold));
    g.drawText("MPE", b.removeFromTop(28).reduced(8, 0), juce::Justification::centredLeft);
}

void MpePanel::resized()
{
    enableButton_.setBounds(12, 36, 60, 24);
    zoneSelector_.setBounds(78, 36, 110, 24);
    bendRangeKnob_.setBounds(196, 28, 48, 48 + 14);
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

// ── ScopeComponent ──────────────────────────────────────────────────────────

ScopeComponent::ScopeComponent()
{
    startTimerHz(30);
}

void ScopeComponent::pushBuffer(const std::vector<float>& interleavedBuffer, int numChannels)
{
    if (numChannels < 1 || interleavedBuffer.empty()) return;

    juce::ScopedLock lock(bufferLock_);
    size_t numFrames = interleavedBuffer.size() / numChannels;
    displayBuffer_.resize(numFrames);

    // Mix down to mono for display
    for (size_t i = 0; i < numFrames; ++i)
    {
        float sum = 0.0f;
        for (int ch = 0; ch < numChannels; ++ch)
            sum += interleavedBuffer[i * numChannels + ch];
        displayBuffer_[i] = sum / numChannels;
    }
}

void ScopeComponent::timerCallback()
{
    repaint();
}

void ScopeComponent::paint(juce::Graphics& g)
{
    auto b = getLocalBounds().toFloat();
    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(b, 6.0f);

    g.setColour(SynthColors::gridLine().withAlpha(0.3f));
    g.drawHorizontalLine(getHeight() / 2, 0, getWidth());

    juce::ScopedLock lock(bufferLock_);
    if (displayBuffer_.size() < 2) return;

    g.setColour(SynthColors::neonYellow());
    juce::Path path;
    float xStep = b.getWidth() / (float)(displayBuffer_.size() - 1);
    float centerY = b.getCentreY();
    float scale = b.getHeight() * 0.45f;

    path.startNewSubPath(b.getX(), centerY - displayBuffer_[0] * scale);
    for (size_t i = 1; i < displayBuffer_.size(); ++i)
        path.lineTo(b.getX() + i * xStep, centerY - displayBuffer_[i] * scale);

    g.strokePath(path, juce::PathStrokeType(2.0f));
}

void ScopeComponent::resized() {}

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

    savePresetButton_.setButtonText("Save Preset");
    savePresetButton_.setColour(juce::TextButton::buttonColourId, SynthColors::neonPurple());
    savePresetButton_.setColour(juce::TextButton::textColourOffId, SynthColors::text());
    savePresetButton_.onClick = [this]() {
        if (onSavePresetRequested)
            onSavePresetRequested();
    };
    addAndMakeVisible(savePresetButton_);

    showUserPresetsButton_.setButtonText("User Presets");
    showUserPresetsButton_.setColour(juce::ToggleButton::tickColourId, SynthColors::neonYellow());
    showUserPresetsButton_.setColour(juce::ToggleButton::tickDisabledColourId, SynthColors::textDim());
    showUserPresetsButton_.onClick = [this]() {
        showingUserPresets_ = showUserPresetsButton_.getToggleState();
        rebuildFilter();
    };
    addAndMakeVisible(showUserPresetsButton_);

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

void PresetBrowser::refreshUserPresets()
{
    UserPresetManager manager;
    userPresets_ = manager.getUserPresets();
    rebuildFilter();
}

void PresetBrowser::rebuildFilter()
{
    displayList_.clear();
    currentSearch_ = searchBox_.getText().toLowerCase();

    if (showingUserPresets_)
    {
        for (const auto& preset : userPresets_)
        {
            bool matchesSearch = currentSearch_.isEmpty() ||
                                 preset.name.toLowerCase().contains(currentSearch_);
            bool matchesCategory = currentCategory_.isEmpty() ||
                                   preset.category.equalsIgnoreCase(currentCategory_);
            if (matchesSearch && matchesCategory)
            {
                juce::DynamicObject::Ptr obj = new juce::DynamicObject();
                obj->setProperty("isUser", true);
                obj->setProperty("name", preset.name);
                obj->setProperty("category", preset.category);
                obj->setProperty("index", (int)(displayList_.size()));
                displayList_.emplace_back(obj);
            }
        }
    }
    else
    {
        filteredFactoryPresets_.clear();
        for (int i = 0; i < kNumPresets; ++i) {
            const auto& preset = kPresets[i];
            bool matchesSearch = currentSearch_.isEmpty() ||
                                 preset.name.toLowerCase().contains(currentSearch_) ||
                                 preset.id.toLowerCase().contains(currentSearch_);
            bool matchesCategory = currentCategory_.isEmpty() ||
                                   preset.category.equalsIgnoreCase(currentCategory_);
            if (matchesSearch && matchesCategory)
            {
                filteredFactoryPresets_.push_back(&preset);
                juce::DynamicObject::Ptr obj = new juce::DynamicObject();
                obj->setProperty("isUser", false);
                obj->setProperty("name", preset.name);
                obj->setProperty("category", preset.category);
                obj->setProperty("index", (int)(filteredFactoryPresets_.size() - 1));
                displayList_.emplace_back(obj);
            }
        }
    }

    presetList_.updateContent();
    presetList_.repaint();
}

void PresetBrowser::paintListBoxItem(int rowNumber, juce::Graphics& g, int width, int height, bool rowIsSelected)
{
    if (rowNumber < 0 || rowNumber >= (int)displayList_.size()) return;

    auto* obj = displayList_[rowNumber].getDynamicObject();
    if (obj == nullptr) return;

    juce::String name = obj->getProperty("name");
    juce::String category = obj->getProperty("category");
    bool isUser = obj->getProperty("isUser");

    auto b = juce::Rectangle<int>(0, 0, width, height);

    if (rowIsSelected) {
        g.setColour(SynthColors::neonPurple().withAlpha(0.4f));
        g.fillRect(b);
    } else if (rowNumber % 2 == 0) {
        g.setColour(SynthColors::card().withAlpha(0.3f));
        g.fillRect(b);
    }

    if (isUser)
    {
        g.setColour(SynthColors::neonYellow());
        g.setFont(juce::Font(juce::FontOptions(11.0f, juce::Font::bold)));
        g.drawText("[USER]", b.reduced(8, 2).removeFromLeft(50), juce::Justification::centredLeft, true);
    }

    g.setColour(SynthColors::text());
    g.setFont(juce::Font(juce::FontOptions(13.0f)));
    g.drawText(name, b.reduced(isUser ? 60 : 8, 2), juce::Justification::centredLeft, true);

    g.setColour(SynthColors::textDim());
    g.setFont(juce::Font(juce::FontOptions(10.0f)));
    g.drawText(category, b.reduced(8, 2), juce::Justification::centredRight, true);
}

void PresetBrowser::selectedRowsChanged(int lastRowSelected)
{
    if (lastRowSelected >= 0 && lastRowSelected < (int)displayList_.size()) {
        auto* obj = displayList_[lastRowSelected].getDynamicObject();
        if (obj == nullptr) return;

        bool isUser = obj->getProperty("isUser");
        if (isUser)
        {
            int userIndex = lastRowSelected;
            int count = 0;
            for (int i = 0; i < (int)displayList_.size(); ++i)
            {
                auto* o = displayList_[i].getDynamicObject();
                if (o && o->getProperty("isUser"))
                {
                    if (count == userIndex && onUserPresetSelected)
                    {
                        onUserPresetSelected(userPresets_[count]);
                        return;
                    }
                    count++;
                }
            }
        }
        else
        {
            int factoryIndex = (int)obj->getProperty("index");
            if (factoryIndex >= 0 && factoryIndex < (int)filteredFactoryPresets_.size()) {
                if (onPresetSelected)
                    onPresetSelected(filteredFactoryPresets_[factoryIndex]);
            }
        }
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
    savePresetButton_.setBounds(filterRow.removeFromLeft(100));
    filterRow.removeFromLeft(8);
    showUserPresetsButton_.setBounds(filterRow.removeFromLeft(110));
    filterRow.removeFromLeft(8);
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
        refreshUserPresets();
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
        onPresetSelected(presetIndices_[index]);
}

void FavoritesBar::assignPresetIndex(int slot, int presetIndex)
{
    if (slot >= 0 && slot < 8)
    {
        presetIndices_[slot] = presetIndex;
        if (presetIndex >= 0 && presetIndex < kNumFullPresets)
        {
            favButtons_[slot].setButtonText(juce::String(slot + 1) + ": " + kFullPresets[presetIndex].name);
            favButtons_[slot].setColour(juce::TextButton::textColourOffId, SynthColors::neonYellow());
        }
        else
        {
            favButtons_[slot].setButtonText(juce::String(slot + 1));
            favButtons_[slot].setColour(juce::TextButton::textColourOffId, SynthColors::textDim());
        }
    }
}

int FavoritesBar::getPresetIndex(int slot) const
{
    if (slot >= 0 && slot < 8)
        return presetIndices_[slot];
    return -1;
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

PianoKeyboard::PianoKeyboard(OpenSynthProcessor& processor)
    : processor_(processor)
{
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
        processor_.injectMidiMessage(juce::MidiMessage::noteOn(1, note, 0.8f));
        repaint();
    }
}

void PianoKeyboard::mouseUp(const juce::MouseEvent&)
{
    if (pressedNote_ >= 0)
    {
        processor_.injectMidiMessage(juce::MidiMessage::noteOff(1, pressedNote_, 0.0f));
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
            processor_.injectMidiMessage(juce::MidiMessage::noteOff(1, pressedNote_, 0.0f));
        pressedNote_ = note;
        processor_.injectMidiMessage(juce::MidiMessage::noteOn(1, note, 0.8f));
        repaint();
    }
}

void PianoKeyboard::setSplitPoint(int note)
{
    splitPoint_ = juce::jlimit(21, 108, note);
    repaint();
}

void PianoKeyboard::setKeyPressed(int note)
{
    if (note >= 21 && note <= 108)
    {
        pressedNote_ = note;
        repaint();
    }
}

void PianoKeyboard::setKeyReleased(int note)
{
    if (pressedNote_ == note)
    {
        pressedNote_ = -1;
        repaint();
    }
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

} // namespace opensynth

// ── MidiLearnManager ────────────────────────────────────────────────────────

namespace opensynth {

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

} // namespace opensynth

// ── OpenSynthEditor ────────────────────────────────────────────────────

namespace opensynth {

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
      realismPanel_(processor.getParameters()),
      mpePanel_(processor.getParameters()),
      dbeamPanel_(processor.getParameters()),
      performancePanel_(processor.getParameters()),
      keyboard_(processor)
{
    setSize(1400, 900);
    setResizable(false, false);

    // Title
    titleLabel_.setText("Open Synth", juce::dontSendNotification);
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
    setlistButton_.onClick = [this]() { showSetlistMode(); };
    addAndMakeVisible(setlistButton_);

    undoButton_.setButtonText("Undo");
    undoButton_.setColour(juce::TextButton::buttonColourId, SynthColors::card());
    undoButton_.setColour(juce::TextButton::textColourOffId, SynthColors::textDim());
    undoButton_.onClick = [this]() {
        processor_.getUndoManager().undo();
        showUndoFeedback("Undo");
    };
    addAndMakeVisible(undoButton_);

    redoButton_.setButtonText("Redo");
    redoButton_.setColour(juce::TextButton::buttonColourId, SynthColors::card());
    redoButton_.setColour(juce::TextButton::textColourOffId, SynthColors::textDim());
    redoButton_.onClick = [this]() {
        processor_.getUndoManager().redo();
        showUndoFeedback("Redo");
    };
    addAndMakeVisible(redoButton_);

    // Undo feedback label
    undoFeedbackLabel_.setText("", juce::dontSendNotification);
    undoFeedbackLabel_.setFont(juce::Font(juce::FontOptions(14.0f, juce::Font::bold)));
    undoFeedbackLabel_.setColour(juce::Label::textColourId, SynthColors::neonYellow());
    undoFeedbackLabel_.setJustificationType(juce::Justification::centred);
    addAndMakeVisible(undoFeedbackLabel_);

    // Setlist overlay
    setlistOverlay_.onSlotSelected = [this](int slotIndex) {
        juce::String name = setlistOverlay_.getSlotPresetName(slotIndex);
        if (name.isNotEmpty()) {
            // Find preset by name in full library
            for (int i = 0; i < kNumFullPresets; ++i) {
                if (juce::String(kFullPresets[i].name) == name) {
                    loadPresetByIndex(i);
                    setlistOverlay_.setVisible(false);
                    break;
                }
            }
        }
    };
    setlistOverlay_.onSlotAssigned = [this](int slotIndex) {
        juce::String currentName = titleLabel_.getText();
        setlistOverlay_.assignPresetToSlot(slotIndex, currentName);
    };
    addChildComponent(setlistOverlay_);

    // Favorites bar
    favorites_.onPresetSelected = [this](int idx) {
        if (idx >= 0 && idx < kNumFullPresets)
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
    presetBrowser_.onSavePresetRequested = [this]() {
        saveCurrentPreset();
    };
    presetBrowser_.onUserPresetSelected = [this](const UserPreset& preset) {
        userPresetManager_.loadPreset(preset, processor_.getParameters());
        titleLabel_.setText(preset.name, juce::dontSendNotification);
        presetBrowser_.setVisible(false);
    };

    // Meters + Scope
    addAndMakeVisible(meters_);
    addAndMakeVisible(scope_);

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
    addAndMakeVisible(realismPanel_);
    addAndMakeVisible(mpePanel_);
    addAndMakeVisible(dbeamPanel_);
    addAndMakeVisible(phraseSamplerPanel_);
    addAndMakeVisible(performancePanel_);
    addAndMakeVisible(keyboard_);

    // Overlays (initially hidden)
    addChildComponent(presetBrowser_);
    addChildComponent(splitOverlay_);

    splitOverlay_.onSplitChanged = [this](int note)
    {
        keyboard_.setSplitPoint(note);
        // Update performance panel slider to match
        if (auto* param = processor_.getParameters().getParameter("perfSplitPoint"))
        {
            param->beginChangeGesture();
            param->setValueNotifyingHost((note - 21) / 87.0f);
            param->endChangeGesture();
        }
    };

    performancePanel_.onSplitChanged = [this](int note)
    {
        keyboard_.setSplitPoint(note);
        splitOverlay_.setSplitPoint(note);
    };

    performancePanel_.onLayerChanged = [this](bool enabled)
    {
        juce::ignoreUnused(enabled);
        // Layer on/off could toggle osc2 volume or enable split mode
    };

    dbeamPanel_.onValueChanged = [this](float value)
    {
        if (auto* param = processor_.getParameters().getParameter("dbeamValue"))
        {
            param->beginChangeGesture();
            param->setValueNotifyingHost(value);
            param->endChangeGesture();
        }

        // Also route to target parameter based on dbeamTarget
        int target = static_cast<int>(*processor_.getParameters().getRawParameterValue("dbeamTarget"));
        switch (target)
        {
        case 0: // Filter cutoff
            if (auto* p = processor_.getParameters().getParameter("filterCutoff"))
            {
                float min = 20.0f, max = 20000.0f;
                p->beginChangeGesture();
                p->setValueNotifyingHost((min + value * (max - min) - 20.0f) / 19980.0f);
                p->endChangeGesture();
            }
            break;
        case 1: // Pitch bend
            // Pitch bend is handled per-note, store in a mod source
            break;
        case 2: // FX depth
            if (auto* p = processor_.getParameters().getParameter("fx1Param3"))
            {
                p->beginChangeGesture();
                p->setValueNotifyingHost(value);
                p->endChangeGesture();
            }
            break;
        case 3: // Master volume
            if (auto* p = processor_.getParameters().getParameter("masterVolume"))
            {
                p->beginChangeGesture();
                p->setValueNotifyingHost(value);
                p->endChangeGesture();
            }
            break;
        }
    };

    // Start meter timer
    startTimerHz(10);

    // Load persisted app state (setlist, favorites, last preset)
    loadAppState();

    // Open default MIDI input device
    openDefaultMidiInput();
}

void OpenSynthEditor::loadAppState()
{
    // Load setlist
    auto setlist = appStateManager_.loadSetlist();
    for (int i = 0; i < SetlistState::kNumSlots; ++i)
        setlistOverlay_.assignPresetToSlot(i, setlist.slotPresetNames[i]);

    // Load favorites
    auto favorites = appStateManager_.loadFavorites();
    for (int i = 0; i < FavoritesState::kNumSlots; ++i)
    {
        int idx = favorites.presetIndices[i];
        if (idx >= 0 && idx < kNumFullPresets)
            favorites_.assignPresetIndex(i, idx);
    }

    // Load last preset
    auto lastID = appStateManager_.loadLastPresetID();
    if (lastID.isNotEmpty())
        loadPresetByID(lastID);
    else
        loadPresetByIndex(0);

    // Refresh user presets in browser
    presetBrowser_.refreshUserPresets();
}

void OpenSynthEditor::saveAppState()
{
    // Save setlist
    SetlistState setlist;
    for (int i = 0; i < SetlistState::kNumSlots; ++i)
        setlist.slotPresetNames[i] = setlistOverlay_.getSlotPresetName(i);
    appStateManager_.saveSetlist(setlist);

    // Save favorites
    FavoritesState favorites;
    for (int i = 0; i < FavoritesState::kNumSlots; ++i)
        favorites.presetIndices[i] = favorites_.getPresetIndex(i);
    appStateManager_.saveFavorites(favorites);

    // Save last preset ID
    if (currentPresetIndex_ >= 0 && currentPresetIndex_ < kNumFullPresets)
        appStateManager_.saveLastPresetID(kFullPresets[currentPresetIndex_].id);
}

void OpenSynthEditor::handleMidiCC(int ccNumber, float value)
{
    midiLearnManager_.handleMidiCC(ccNumber, value, processor_.getParameters());
}

void OpenSynthEditor::openDefaultMidiInput()
{
    auto devices = juce::MidiInput::getAvailableDevices();
    if (devices.isEmpty()) return;

    // Prefer the first non-virtual device, or just the first one
    for (const auto& device : devices)
    {
        midiInput_ = juce::MidiInput::openDevice(device.identifier, this);
        if (midiInput_ != nullptr)
        {
            midiInput_->start();
            break;
        }
    }
}

void OpenSynthEditor::handleIncomingMidiMessage(juce::MidiInput* source, const juce::MidiMessage& message)
{
    juce::ignoreUnused(source);

    if (message.isNoteOn())
    {
        int note = message.getNoteNumber();
        processor_.injectMidiMessage(juce::MidiMessage::noteOn(1, note, message.getFloatVelocity()));
        keyboard_.setKeyPressed(note);
    }
    else if (message.isNoteOff())
    {
        int note = message.getNoteNumber();
        processor_.injectMidiMessage(juce::MidiMessage::noteOff(1, note, 0.0f));
        keyboard_.setKeyReleased(note);
    }
    else if (message.isController())
    {
        handleMidiCC(message.getControllerNumber(), message.getControllerValue() / 127.0f);
    }
    else if (message.isPitchWheel())
    {
        processor_.injectMidiMessage(message);
    }
    else if (message.isSustainPedalOn() || message.isSustainPedalOff())
    {
        processor_.injectMidiMessage(message);
    }
}

void OpenSynthEditor::timerCallback()
{
    int voices = processor_.getSynth().getActiveVoiceCount();
    float cpu = processor_.getSynth().getCpuLoad() * 100.0f;
    meters_.setVoiceCount(voices);
    meters_.setCpuLoad(cpu);

    // Push audio buffer to scope
    auto buffer = processor_.getSynth().getLastAudioBuffer();
    if (!buffer.empty())
        scope_.pushBuffer(buffer, 2);

    // Update undo/redo button states
    undoButton_.setEnabled(processor_.getUndoManager().canUndo());
    redoButton_.setEnabled(processor_.getUndoManager().canRedo());
    undoButton_.setColour(juce::TextButton::textColourOffId,
        processor_.getUndoManager().canUndo() ? SynthColors::text() : SynthColors::textDim());
    redoButton_.setColour(juce::TextButton::textColourOffId,
        processor_.getUndoManager().canRedo() ? SynthColors::text() : SynthColors::textDim());

    // Fade out undo feedback
    if (undoFeedbackCounter_ > 0)
    {
        undoFeedbackCounter_--;
        if (undoFeedbackCounter_ <= 0)
            undoFeedbackLabel_.setText("", juce::dontSendNotification);
    }
}

void OpenSynthEditor::showPresetBrowser()
{
    presetBrowser_.setVisible(true);
    presetBrowser_.setBounds(getLocalBounds());
    presetBrowser_.toFront(true);
}

void OpenSynthEditor::showSetlistMode()
{
    setlistOverlay_.setVisible(true);
    setlistOverlay_.setBounds(getLocalBounds());
    setlistOverlay_.toFront(true);
}

void OpenSynthEditor::loadFavoritePreset(int index)
{
    int presetIdx = favorites_.getPresetIndex(index);
    if (presetIdx >= 0 && presetIdx < kNumFullPresets)
        loadPresetByIndex(presetIdx);
}

void OpenSynthEditor::loadPresetByIndex(int index)
{
    if (index >= 0 && index < kNumFullPresets) {
        currentPresetIndex_ = index;
        loadPresetByID(kFullPresets[index].id);
    }
}

void OpenSynthEditor::loadPresetByID(const juce::String& id)
{
    // Find preset in full library
    for (int i = 0; i < kNumFullPresets; ++i) {
        if (juce::String(kFullPresets[i].id) == id) {
            const auto& p = kFullPresets[i];
            currentPresetIndex_ = i;
            // Update title
            titleLabel_.setText(p.name, juce::dontSendNotification);
            // Push to APVTS (UI updates automatically via attachments)
            applyPresetToAPVTS(p, processor_.getParameters());
            // Push to engine (immediate audio update)
            applyPresetToEngine(p, processor_.getSynth());
            break;
        }
    }
}

void OpenSynthEditor::saveCurrentPreset()
{
    auto* alert = new juce::AlertWindow("Save Preset", "Enter a name for your preset:", juce::AlertWindow::QuestionIcon, this);
    alert->addTextEditor("name", titleLabel_.getText(), "Preset Name");
    alert->addButton("Save", 1, juce::KeyPress(juce::KeyPress::returnKey));
    alert->addButton("Cancel", 0, juce::KeyPress(juce::KeyPress::escapeKey));

    alert->enterModalState(true, juce::ModalCallbackFunction::create([this, alert](int result)
    {
        if (result == 1)
        {
            juce::String name = alert->getTextEditorContents("name").trim();
            if (name.isNotEmpty())
            {
                if (userPresetManager_.savePreset(name, "Custom", {}, processor_.getParameters()))
                {
                    titleLabel_.setText(name, juce::dontSendNotification);
                    presetBrowser_.refreshUserPresets();
                    showUndoFeedback("Preset Saved");
                }
            }
        }
        delete alert;
    }), true);
}

void OpenSynthEditor::showUndoFeedback(const juce::String& text)
{
    undoFeedbackLabel_.setText(text, juce::dontSendNotification);
    undoFeedbackCounter_ = 30; // ~3 seconds at 10Hz timer
}

void OpenSynthEditor::paint(juce::Graphics& g)
{
    g.fillAll(SynthColors::background());

    // Animated grid lines with subtle pulse
    float alpha = 0.08f + 0.04f * std::sin(juce::Time::getMillisecondCounter() / 2000.0f);
    g.setColour(SynthColors::neonPurple().withAlpha(alpha));
    for (int x = 0; x < getWidth(); x += 40)
        g.drawVerticalLine(x, 0, getHeight());
    for (int y = 0; y < getHeight(); y += 40)
        g.drawHorizontalLine(y, 0, getWidth());

    // Horizon line (synthwave sunset effect)
    float horizonY = getHeight() * 0.65f;
    g.setColour(SynthColors::hotPink().withAlpha(0.05f));
    g.drawHorizontalLine((int)horizonY, 0, (float)getWidth());
    g.setColour(SynthColors::hotPink().withAlpha(0.03f));
    g.drawHorizontalLine((int)horizonY - 1, 0, (float)getWidth());
    g.drawHorizontalLine((int)horizonY + 1, 0, (float)getWidth());
}

void OpenSynthEditor::resized()
{
    auto b = getLocalBounds().reduced(12);

    // Header row
    auto header = b.removeFromTop(40);
    titleLabel_.setBounds(header.removeFromLeft(220));
    favorites_.setBounds(header.removeFromLeft(320));
    meters_.setBounds(header.removeFromLeft(180));
    scope_.setBounds(header.removeFromLeft(120));
    undoButton_.setBounds(header.removeFromRight(60));
    redoButton_.setBounds(header.removeFromRight(60));
    presetButton_.setBounds(header.removeFromRight(90));
    setlistButton_.setBounds(header.removeFromRight(90));

    // Undo feedback overlay (centered)
    undoFeedbackLabel_.setBounds(getLocalBounds().reduced(200, 300));

    b.removeFromTop(8);

    // Calculate responsive panel sizes
    int availWidth = b.getWidth();
    int availHeight = b.getHeight();
    int gap = juce::jmin(12, availWidth / 60);
    int panelWidth = (availWidth - gap * 3) / 4;
    int topHeight = juce::jmin(220, availHeight / 3);
    int midHeight = juce::jmin(220, availHeight / 3);
    int keyHeight = availHeight - topHeight - midHeight - gap * 2;

    // Top row: Oscillators + Filter + Arp
    auto topRow = b.removeFromTop(topHeight);
    osc1Panel_.setBounds(topRow.removeFromLeft(panelWidth));
    topRow.removeFromLeft(gap);
    osc2Panel_.setBounds(topRow.removeFromLeft(panelWidth));
    topRow.removeFromLeft(gap);
    filterPanel_.setBounds(topRow.removeFromLeft(panelWidth));
    topRow.removeFromLeft(gap);
    arpPanel_.setBounds(topRow.removeFromLeft(panelWidth));

    b.removeFromTop(gap);

    // Middle row: Envelopes + FX slots + Realism + MPE + D-Beam + Performance
    auto midRow = b.removeFromTop(midHeight);
    int midPanelWidth = (availWidth - gap * 7) / 8;
    ampEnvPanel_.setBounds(midRow.removeFromLeft(midPanelWidth));
    midRow.removeFromLeft(gap);
    filterEnvPanel_.setBounds(midRow.removeFromLeft(midPanelWidth));
    midRow.removeFromLeft(gap);
    fx1Panel_.setBounds(midRow.removeFromLeft(midPanelWidth));
    midRow.removeFromLeft(gap);
    fx2Panel_.setBounds(midRow.removeFromLeft(midPanelWidth));
    midRow.removeFromLeft(gap);
    fx3Panel_.setBounds(midRow.removeFromLeft(midPanelWidth));
    midRow.removeFromLeft(gap);
    realismPanel_.setBounds(midRow.removeFromLeft(midPanelWidth));
    midRow.removeFromLeft(gap);
    mpePanel_.setBounds(midRow.removeFromLeft(midPanelWidth));
    midRow.removeFromLeft(gap);
    dbeamPanel_.setBounds(midRow.removeFromLeft(midPanelWidth));
    midRow.removeFromLeft(gap);
    performancePanel_.setBounds(midRow);

    b.removeFromTop(gap);

    // Bottom: Phrase sampler + Keyboard
    int samplerHeight = juce::jmin(160, b.getHeight() / 3);
    auto samplerRow = b.removeFromTop(samplerHeight);
    phraseSamplerPanel_.setBounds(samplerRow.removeFromLeft(juce::jmin(300, availWidth / 4)));
    samplerRow.removeFromLeft(gap);
    keyboard_.setBounds(samplerRow);

    // Overlays fill entire editor
    presetBrowser_.setBounds(getLocalBounds());
    splitOverlay_.setBounds(keyboard_.getBounds());
    setlistOverlay_.setBounds(getLocalBounds());
}

// ── D-Beam Panel ────────────────────────────────────────────────────────────

DBeamPanel::DBeamPanel(juce::AudioProcessorValueTreeState& apvts)
    : apvts_(apvts)
{
    targetSelector_.addItemList({"Filter Cutoff", "Pitch Bend", "FX Depth", "Master Volume"}, 1);
    addAndMakeVisible(targetSelector_);
    targetAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::ComboBoxAttachment>(
        apvts_, "dbeamTarget", targetSelector_);
}

void DBeamPanel::paint(juce::Graphics& g)
{
    auto b = getLocalBounds().toFloat();
    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(b, 8.0f);

    g.setColour(SynthColors::neonYellow());
    g.setFont(juce::Font(juce::FontOptions(14.0f, juce::Font::bold)));
    g.drawText("D-BEAM", 12, 8, 120, 20, juce::Justification::left);
    g.setColour(SynthColors::gridLine());
    g.drawHorizontalLine(32, 8, getWidth() - 8);

    // Draw horizontal bar representing current value
    int barY = 60;
    int barHeight = 20;
    int barX = 12;
    int barWidth = getWidth() - 24;

    g.setColour(SynthColors::surface());
    g.fillRoundedRectangle((float)barX, (float)barY, (float)barWidth, (float)barHeight, 4.0f);

    // Filled portion
    int fillWidth = static_cast<int>(barWidth * currentValue_);
    juce::Colour beamColor = SynthColors::neonYellow().withAlpha(0.6f + 0.4f * currentValue_);
    g.setColour(beamColor);
    g.fillRoundedRectangle((float)barX, (float)barY, (float)fillWidth, (float)barHeight, 4.0f);

    // Glow line at the value position
    g.setColour(SynthColors::neonYellow().brighter());
    g.drawVerticalLine(barX + fillWidth, barY, barY + barHeight);

    // Value text
    g.setColour(SynthColors::text());
    g.setFont(juce::Font(juce::FontOptions(11.0f)));
    g.drawText(juce::String(static_cast<int>(currentValue_ * 100)) + "%",
               barX, barY + barHeight + 4, barWidth, 16, juce::Justification::centred);

    // Instruction
    g.setColour(SynthColors::textDim());
    g.setFont(juce::Font(juce::FontOptions(10.0f)));
    g.drawText("Click & drag vertically to control",
               barX, barY + barHeight + 20, barWidth, 16, juce::Justification::centred);
}

void DBeamPanel::resized()
{
    targetSelector_.setBounds(12, 36, getWidth() - 24, 22);
}

void DBeamPanel::mouseDown(const juce::MouseEvent& e)
{
    dragging_ = true;
    updateValueFromY(e.getPosition().getY());
}

void DBeamPanel::mouseDrag(const juce::MouseEvent& e)
{
    if (dragging_)
        updateValueFromY(e.getPosition().getY());
}

void DBeamPanel::mouseUp(const juce::MouseEvent&)
{
    dragging_ = false;
}

void DBeamPanel::updateValueFromY(int y)
{
    float norm = 1.0f - juce::jlimit(0.0f, 1.0f, (float)(y - 50) / (getHeight() - 70));
    currentValue_ = norm;
    if (onValueChanged)
        onValueChanged(currentValue_);
    repaint();
}

// ── Phrase Sampler Panel ────────────────────────────────────────────────────

PhraseSamplerPanel::PhraseSamplerPanel()
{
    setOpaque(false);

    loadButton_.setButtonText("Load WAV");
    loadButton_.setColour(juce::TextButton::buttonColourId, SynthColors::card());
    loadButton_.setColour(juce::TextButton::textColourOffId, SynthColors::neonYellow());
    loadButton_.onClick = [this]() { loadFile(); };
    addAndMakeVisible(loadButton_);

    playButton_.setButtonText("Play");
    playButton_.setColour(juce::TextButton::buttonColourId, SynthColors::card());
    playButton_.setColour(juce::TextButton::textColourOffId, SynthColors::cyan());
    playButton_.onClick = [this]() { play(); };
    addAndMakeVisible(playButton_);

    stopButton_.setButtonText("Stop");
    stopButton_.setColour(juce::TextButton::buttonColourId, SynthColors::card());
    stopButton_.setColour(juce::TextButton::textColourOffId, SynthColors::danger());
    stopButton_.onClick = [this]() { stop(); };
    addAndMakeVisible(stopButton_);

    fileLabel_.setText("No file loaded", juce::dontSendNotification);
    fileLabel_.setColour(juce::Label::textColourId, SynthColors::textDim());
    fileLabel_.setFont(juce::Font(juce::FontOptions(11.0f)));
    addAndMakeVisible(fileLabel_);

    volumeSlider_.setSliderStyle(juce::Slider::LinearHorizontal);
    volumeSlider_.setTextBoxStyle(juce::Slider::NoTextBox, false, 0, 0);
    volumeSlider_.setRange(0.0, 1.0, 0.01);
    volumeSlider_.setValue(0.8);
    addAndMakeVisible(volumeSlider_);

    formatManager_.registerBasicFormats();

    startTimerHz(10);
}

PhraseSamplerPanel::~PhraseSamplerPanel() = default;

void PhraseSamplerPanel::paint(juce::Graphics& g)
{
    auto b = getLocalBounds().toFloat();
    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(b, 8.0f);

    g.setColour(SynthColors::hotPink());
    g.setFont(juce::Font(juce::FontOptions(14.0f, juce::Font::bold)));
    g.drawText("PHRASE SAMPLER", 12, 8, 150, 20, juce::Justification::left);
    g.setColour(SynthColors::gridLine());
    g.drawHorizontalLine(32, 8, getWidth() - 8);

    // Simple waveform placeholder
    g.setColour(SynthColors::surface());
    g.fillRoundedRectangle(12.0f, 90.0f, (float)getWidth() - 24.0f, 40.0f, 4.0f);

    g.setColour(SynthColors::neonPurple().withAlpha(0.3f));
    float cx = getWidth() * 0.5f;
    float cy = 110.0f;
    for (int i = 0; i < getWidth() - 24; i += 4)
    {
        float y = cy + std::sin(i * 0.1f + juce::Time::getMillisecondCounter() / 500.0f) * 10.0f;
        g.fillEllipse((float)(12 + i), y, 2.0f, 2.0f);
    }
}

void PhraseSamplerPanel::resized()
{
    loadButton_.setBounds(12, 38, 70, 24);
    playButton_.setBounds(88, 38, 50, 24);
    stopButton_.setBounds(144, 38, 50, 24);
    fileLabel_.setBounds(12, 66, getWidth() - 24, 20);
    volumeSlider_.setBounds(12, 136, getWidth() - 24, 20);
}

void PhraseSamplerPanel::timerCallback()
{
    // Update playback position if playing
}

void PhraseSamplerPanel::loadFile()
{
    fileChooser_ = std::make_unique<juce::FileChooser>(
        "Select a WAV file...",
        juce::File::getSpecialLocation(juce::File::userMusicDirectory),
        "*.wav;*.aiff;*.flac");

    fileChooser_->launchAsync(juce::FileBrowserComponent::openMode | juce::FileBrowserComponent::canSelectFiles,
        [this](const juce::FileChooser& chooser)
    {
        auto file = chooser.getResult();
        if (file != juce::File())
        {
            auto* reader = formatManager_.createReaderFor(file);
            if (reader != nullptr)
            {
                delete reader;
                currentFile_ = file;
                fileLabel_.setText(file.getFileNameWithoutExtension(), juce::dontSendNotification);
                fileLabel_.setColour(juce::Label::textColourId, SynthColors::text());
            }
            else
            {
                fileLabel_.setText("Failed to load file", juce::dontSendNotification);
                fileLabel_.setColour(juce::Label::textColourId, SynthColors::danger());
            }
        }
    });
}

void PhraseSamplerPanel::play()
{
    if (currentFile_.existsAsFile())
    {
        fileLabel_.setText(currentFile_.getFileNameWithoutExtension() + " (playing)", juce::dontSendNotification);
    }
}

void PhraseSamplerPanel::stop()
{
    // Stub: would stop transport
}

// ── Performance Panel ───────────────────────────────────────────────────────

PerformancePanel::PerformancePanel(juce::AudioProcessorValueTreeState& apvts)
    : apvts_(apvts)
{
    titleLabel_.setText("PERFORMANCE", juce::dontSendNotification);
    titleLabel_.setFont(juce::Font(juce::FontOptions(14.0f, juce::Font::bold)));
    titleLabel_.setColour(juce::Label::textColourId, SynthColors::cyan());
    addAndMakeVisible(titleLabel_);

    splitLabel_.setText("Split", juce::dontSendNotification);
    splitLabel_.setColour(juce::Label::textColourId, SynthColors::textDim());
    splitLabel_.setFont(juce::Font(juce::FontOptions(11.0f)));
    addAndMakeVisible(splitLabel_);

    splitSlider_.setSliderStyle(juce::Slider::LinearHorizontal);
    splitSlider_.setTextBoxStyle(juce::Slider::TextBoxLeft, false, 40, 20);
    splitSlider_.setRange(21, 108, 1);
    splitSlider_.setValue(60);
    addAndMakeVisible(splitSlider_);
    splitAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, "perfSplitPoint", splitSlider_);

    layerButton_.setButtonText("Layer");
    layerButton_.setColour(juce::ToggleButton::tickColourId, SynthColors::hotPink());
    addAndMakeVisible(layerButton_);
    layerAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::ButtonAttachment>(
        apvts_, "perfLayerEnabled", layerButton_);

    transposeLabel_.setText("Transpose", juce::dontSendNotification);
    transposeLabel_.setColour(juce::Label::textColourId, SynthColors::textDim());
    transposeLabel_.setFont(juce::Font(juce::FontOptions(11.0f)));
    addAndMakeVisible(transposeLabel_);

    transposeSlider_.setSliderStyle(juce::Slider::LinearHorizontal);
    transposeSlider_.setTextBoxStyle(juce::Slider::TextBoxLeft, false, 40, 20);
    transposeSlider_.setRange(-12, 12, 1);
    transposeSlider_.setValue(0);
    addAndMakeVisible(transposeSlider_);
    transposeAttach_ = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        apvts_, "perfTranspose", transposeSlider_);

    // Callbacks
    splitSlider_.onValueChange = [this]()
    {
        if (onSplitChanged)
            onSplitChanged(static_cast<int>(splitSlider_.getValue()));
    };

    layerButton_.onClick = [this]()
    {
        if (onLayerChanged)
            onLayerChanged(layerButton_.getToggleState());
    };
}

void PerformancePanel::paint(juce::Graphics& g)
{
    auto b = getLocalBounds().toFloat();
    g.setColour(SynthColors::card());
    g.fillRoundedRectangle(b, 8.0f);

    g.setColour(SynthColors::cyan());
    g.setFont(juce::Font(juce::FontOptions(14.0f, juce::Font::bold)));
    g.drawText("PERFORMANCE", 12, 8, 120, 20, juce::Justification::left);
    g.setColour(SynthColors::gridLine());
    g.drawHorizontalLine(32, 8, getWidth() - 8);
}

void PerformancePanel::resized()
{
    titleLabel_.setBounds(12, 8, 120, 20);

    int y = 38;
    splitLabel_.setBounds(12, y, 50, 20);
    splitSlider_.setBounds(64, y, getWidth() - 76, 20);
    y += 28;

    layerButton_.setBounds(12, y, 80, 22);
    y += 30;

    transposeLabel_.setBounds(12, y, 60, 20);
    transposeSlider_.setBounds(74, y, getWidth() - 86, 20);
}

bool OpenSynthEditor::keyPressed(const juce::KeyPress& key)
{
    // Undo/Redo
    auto mods = juce::ModifierKeys::getCurrentModifiers();
    if (mods.isCtrlDown() && key.getKeyCode() == 'z' && !mods.isShiftDown())
    {
        processor_.getUndoManager().undo();
        return true;
    }
    if (mods.isCtrlDown() && (key.getKeyCode() == 'y' || (key.getKeyCode() == 'z' && mods.isShiftDown())))
    {
        processor_.getUndoManager().redo();
        return true;
    }

    // Preset navigation: Up/Down arrows
    if (key == juce::KeyPress::upKey)
    {
        if (kNumFullPresets > 0) {
            currentPresetIndex_--;
            if (currentPresetIndex_ < 0)
                currentPresetIndex_ = kNumFullPresets - 1;
            loadPresetByIndex(currentPresetIndex_);
        }
        return true;
    }
    if (key == juce::KeyPress::downKey)
    {
        if (kNumFullPresets > 0) {
            currentPresetIndex_++;
            if (currentPresetIndex_ >= kNumFullPresets)
                currentPresetIndex_ = 0;
            loadPresetByIndex(currentPresetIndex_);
        }
        return true;
    }

    // Space = toggle arpeggiator
    if (key == juce::KeyPress::spaceKey)
    {
        auto* param = processor_.getParameters().getParameter("arpEnabled");
        if (param != nullptr)
        {
            bool newVal = !param->getValue();
            param->beginChangeGesture();
            param->setValueNotifyingHost(newVal ? 1.0f : 0.0f);
            param->endChangeGesture();
        }
        return true;
    }

    // Ctrl+Z = undo
    if (key == juce::KeyPress('z', juce::ModifierKeys::ctrlModifier, 0))
    {
        processor_.getUndoManager().undo();
        showUndoFeedback("Undo");
        return true;
    }

    // Ctrl+Y = redo
    if (key == juce::KeyPress('y', juce::ModifierKeys::ctrlModifier, 0))
    {
        processor_.getUndoManager().redo();
        showUndoFeedback("Redo");
        return true;
    }

    // Ctrl+Shift+Z = redo (alternative)
    if (key == juce::KeyPress('z', juce::ModifierKeys::ctrlModifier | juce::ModifierKeys::shiftModifier, 0))
    {
        processor_.getUndoManager().redo();
        showUndoFeedback("Redo");
        return true;
    }

    // 1-8 = favorite presets
    int favKey = key.getTextCharacter();
    if (favKey >= '1' && favKey <= '8')
    {
        loadFavoritePreset(favKey - '1');
        return true;
    }

    // P = open preset browser
    if (favKey == 'p' || favKey == 'P')
    {
        showPresetBrowser();
        return true;
    }

    // M = toggle master mute (set master volume to 0 / restore)
    if (favKey == 'm' || favKey == 'M')
    {
        auto* param = processor_.getParameters().getParameter("masterVolume");
        if (param != nullptr)
        {
            static float lastVolume = 0.8f;
            float current = param->getValue();
            if (current > 0.01f)
            {
                lastVolume = current;
                param->beginChangeGesture();
                param->setValueNotifyingHost(0.0f);
                param->endChangeGesture();
            }
            else
            {
                param->beginChangeGesture();
                param->setValueNotifyingHost(lastVolume);
                param->endChangeGesture();
            }
        }
        return true;
    }

    // Computer keyboard as piano
    int note = keyToNote(favKey);
    if (note >= 0)
    {
        if (heldKeys_.insert(favKey).second) // was not already held
        {
            processor_.injectMidiMessage(juce::MidiMessage::noteOn(1, note, 0.9f));
            keyboard_.setKeyPressed(note);
        }
        return true;
    }

    return false;
}

bool OpenSynthEditor::keyStateChanged(bool isKeyDown)
{
    juce::ignoreUnused(isKeyDown);

    // Check which held keys have been released
    std::vector<int> released;
    for (int keyCode : heldKeys_)
    {
        if (!juce::KeyPress::isKeyCurrentlyDown(keyCode))
        {
            int note = keyToNote(keyCode);
            if (note >= 0)
            {
                processor_.injectMidiMessage(juce::MidiMessage::noteOff(1, note, 0.0f));
                keyboard_.setKeyReleased(note);
            }
            released.push_back(keyCode);
        }
    }
    for (int keyCode : released)
        heldKeys_.erase(keyCode);
    return false; // allow other handlers
}

int OpenSynthEditor::keyToNote(int keyCode)
{
    switch (keyCode)
    {
        case 'z': return 48;
        case 's': return 49;
        case 'x': return 50;
        case 'd': return 51;
        case 'c': return 52;
        case 'v': return 53;
        case 'g': return 54;
        case 'b': return 55;
        case 'h': return 56;
        case 'n': return 57;
        case 'j': return 58;
        case 'm': return 59;
        case 'q': return 60;
        case '2': return 61;
        case 'w': return 62;
        case '3': return 63;
        case 'e': return 64;
        case 'r': return 65;
        case '5': return 66;
        case 't': return 67;
        case '6': return 68;
        case 'y': return 69;
        case '7': return 70;
        case 'u': return 71;
        default:  return -1;
    }
}

} // namespace opensynth

// ── SetlistOverlay ──────────────────────────────────────────────────────────

namespace opensynth {

SetlistOverlay::SetlistOverlay()
{
    setOpaque(true);

    titleLabel_.setText("SETLIST MODE", juce::dontSendNotification);
    titleLabel_.setFont(juce::Font(juce::FontOptions(20.0f, juce::Font::bold)));
    titleLabel_.setColour(juce::Label::textColourId, SynthColors::cyan());
    addAndMakeVisible(titleLabel_);

    closeButton_.setButtonText("X");
    closeButton_.setColour(juce::TextButton::buttonColourId, SynthColors::danger());
    closeButton_.onClick = [this]() { setVisible(false); };
    addAndMakeVisible(closeButton_);

    clearButton_.setButtonText("Clear All");
    clearButton_.setColour(juce::TextButton::buttonColourId, SynthColors::card());
    clearButton_.setColour(juce::TextButton::textColourOffId, SynthColors::textDim());
    clearButton_.onClick = [this]() { clearAll(); };
    addAndMakeVisible(clearButton_);

    for (int i = 0; i < kNumSlots; ++i)
    {
        slotPresetNames_[i] = "Empty";
        slotButtons_[i].setButtonText(juce::String(i + 1) + ": Empty");
        slotButtons_[i].setColour(juce::TextButton::buttonColourId, SynthColors::card());
        slotButtons_[i].setColour(juce::TextButton::textColourOffId, SynthColors::textDim());
        slotButtons_[i].onClick = [this, i]() { slotClicked(i); };
        addAndMakeVisible(slotButtons_[i]);
    }
}

void SetlistOverlay::paint(juce::Graphics& g)
{
    g.fillAll(SynthColors::background().withAlpha(0.95f));

    g.setColour(SynthColors::gridLine());
    for (int x = 0; x < getWidth(); x += 40)
        g.drawVerticalLine(x, 0, getHeight());
    for (int y = 0; y < getHeight(); y += 40)
        g.drawHorizontalLine(y, 0, getWidth());
}

void SetlistOverlay::resized()
{
    auto b = getLocalBounds().reduced(20);
    titleLabel_.setBounds(b.removeFromTop(30));
    closeButton_.setBounds(getWidth() - 50, 20, 30, 30);

    auto controls = b.removeFromTop(30);
    clearButton_.setBounds(controls.removeFromLeft(100));
    b.removeFromTop(12);

    int cols = 4;
    int rows = kNumSlots / cols;
    int btnWidth = (b.getWidth() - (cols - 1) * 12) / cols;
    int btnHeight = (b.getHeight() - (rows - 1) * 12) / rows;

    for (int i = 0; i < kNumSlots; ++i)
    {
        int col = i % cols;
        int row = i / cols;
        slotButtons_[i].setBounds(
            b.getX() + col * (btnWidth + 12),
            b.getY() + row * (btnHeight + 12),
            btnWidth, btnHeight);
    }
}

void SetlistOverlay::setVisible(bool shouldBeVisible)
{
    juce::Component::setVisible(shouldBeVisible);
}

void SetlistOverlay::slotClicked(int index)
{
    if (juce::ModifierKeys::getCurrentModifiers().isShiftDown())
    {
        if (onSlotAssigned)
            onSlotAssigned(index);
    }
    else
    {
        if (onSlotSelected)
            onSlotSelected(index);
    }
}

void SetlistOverlay::assignPresetToSlot(int slotIndex, const juce::String& presetName)
{
    if (slotIndex >= 0 && slotIndex < kNumSlots)
    {
        slotPresetNames_[slotIndex] = presetName.isEmpty() ? "Empty" : presetName;
        slotButtons_[slotIndex].setButtonText(juce::String(slotIndex + 1) + ": " + slotPresetNames_[slotIndex]);
        slotButtons_[slotIndex].setColour(juce::TextButton::textColourOffId,
            presetName.isEmpty() ? SynthColors::textDim() : SynthColors::neonYellow());
    }
}

juce::String SetlistOverlay::getSlotPresetName(int slotIndex) const
{
    if (slotIndex >= 0 && slotIndex < kNumSlots)
        return slotPresetNames_[slotIndex];
    return {};
}

void SetlistOverlay::clearSlot(int slotIndex)
{
    if (slotIndex >= 0 && slotIndex < kNumSlots)
        assignPresetToSlot(slotIndex, "Empty");
}

void SetlistOverlay::clearAll()
{
    for (int i = 0; i < kNumSlots; ++i)
        assignPresetToSlot(i, "Empty");
}

} // namespace opensynth
