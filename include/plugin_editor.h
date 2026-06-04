#pragma once
#include <juce_gui_basics/juce_gui_basics.h>
#include <juce_audio_processors/juce_audio_processors.h>
#include <juce_audio_formats/juce_audio_formats.h>
#include <juce_audio_devices/juce_audio_devices.h>
#include "plugin_processor.h"
#include "preset_library.h"
#include "preset_data.h"
#include "user_preset_manager.h"
#include "app_state_manager.h"
#include "sample_player.h"

namespace opensynth {

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
    static juce::Colour danger()      { return juce::Colour(0xFFFF3333); }
};

// ── Custom Knob Component ─────────────────────────────────────────────────
class SynthKnob : public juce::Slider {
public:
    SynthKnob(const juce::String& name, juce::Colour accent);
    void paint(juce::Graphics& g) override;
    void resized() override;

    void setName(const juce::String& name) { name_ = name; }
    juce::String getName() const { return name_; }

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

// ── FX Slot Panel (one slot with type selector + params) ──────────────────
class FxSlotPanel : public juce::Component {
public:
    FxSlotPanel(juce::AudioProcessorValueTreeState& apvts, int slotIndex);
    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    juce::AudioProcessorValueTreeState& apvts_;
    int slotIndex_;

    juce::ToggleButton enabledButton_;
    juce::ComboBox typeSelector_;
    SynthKnob paramKnobs_[4];

    std::unique_ptr<juce::AudioProcessorValueTreeState::ButtonAttachment> enabledAttach_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::ComboBoxAttachment> typeAttach_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> paramAttaches_[4];

    void populateFxTypes();
    void updateParamLabels(int fxTypeId);
};

// ── Arpeggiator Panel ─────────────────────────────────────────────────────
class ArpPanel : public juce::Component {
public:
    explicit ArpPanel(juce::AudioProcessorValueTreeState& apvts);
    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    juce::AudioProcessorValueTreeState& apvts_;
    juce::ToggleButton enabledButton_;
    juce::ComboBox patternSelector_;
    SynthKnob tempoKnob_, gateKnob_, swingKnob_, octaveKnob_;

    std::unique_ptr<juce::AudioProcessorValueTreeState::ButtonAttachment> enabledAttach_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::ComboBoxAttachment> patternAttach_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> tempoAttach_, gateAttach_, swingAttach_, octaveAttach_;
};

// ── Instrument Realism Panel ──────────────────────────────────────────────
class RealismPanel : public juce::Component {
public:
    explicit RealismPanel(juce::AudioProcessorValueTreeState& apvts);
    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    juce::AudioProcessorValueTreeState& apvts_;

    juce::ComboBox bodyTypeSelector_;
    SynthKnob bodyMixKnob_, clickMixKnob_, sympatheticKnob_, brightnessKnob_;
    juce::ComboBox attackCurveSelector_;

    std::unique_ptr<juce::AudioProcessorValueTreeState::ComboBoxAttachment> bodyTypeAttach_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> bodyMixAttach_, clickMixAttach_, sympatheticAttach_, brightnessAttach_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::ComboBoxAttachment> attackCurveAttach_;
};

// ── MPE Panel ─────────────────────────────────────────────────────────────
class MpePanel : public juce::Component {
public:
    explicit MpePanel(juce::AudioProcessorValueTreeState& apvts);
    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    juce::AudioProcessorValueTreeState& apvts_;

    juce::ToggleButton enableButton_;
    juce::ComboBox zoneSelector_;
    SynthKnob bendRangeKnob_;

    std::unique_ptr<juce::AudioProcessorValueTreeState::ButtonAttachment> enableAttach_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::ComboBoxAttachment> zoneAttach_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> bendRangeAttach_;
};

// ── D-Beam Controller (Juno-Di inspired) ──────────────────────────────────
class DBeamPanel : public juce::Component {
public:
    DBeamPanel(juce::AudioProcessorValueTreeState& apvts);
    void paint(juce::Graphics& g) override;
    void resized() override;

    std::function<void(float)> onValueChanged;

private:
    juce::AudioProcessorValueTreeState& apvts_;
    juce::ComboBox targetSelector_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::ComboBoxAttachment> targetAttach_;

    float currentValue_ = 0.0f;
    bool dragging_ = false;

    void mouseDown(const juce::MouseEvent& e) override;
    void mouseDrag(const juce::MouseEvent& e) override;
    void mouseUp(const juce::MouseEvent& e) override;
    void updateValueFromY(int y);
};

// ── Phrase Sampler / Audio Player (stub) ──────────────────────────────────
class PhraseSamplerPanel : public juce::Component,
                           private juce::Timer {
public:
    PhraseSamplerPanel();
    ~PhraseSamplerPanel() override;
    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    juce::TextButton loadButton_;
    juce::TextButton playButton_;
    juce::TextButton stopButton_;
    juce::Label fileLabel_;
    juce::Slider volumeSlider_;
    juce::AudioFormatManager formatManager_;
    juce::File currentFile_;

    std::unique_ptr<juce::FileChooser> fileChooser_;

    void timerCallback() override;
    void loadFile();
    void play();
    void stop();
};

// ── Sample Panel (Multi-zone sample player UI) ────────────────────────────
class SamplePanel : public juce::Component,
                    public juce::FileDragAndDropTarget,
                    private juce::Timer {
public:
    SamplePanel(juce::AudioProcessorValueTreeState& apvts, OpenSynthProcessor& processor);
    void paint(juce::Graphics& g) override;
    void resized() override;

    void refresh();

    // FileDragAndDropTarget
    bool isInterestedInFileDrag(const juce::StringArray& files) override;
    void filesDropped(const juce::StringArray& files, int x, int y) override;

private:
    juce::AudioProcessorValueTreeState& apvts_;
    OpenSynthProcessor& processor_;

    juce::Label titleLabel_;
    juce::Label sampleNameLabel_;
    juce::Label categoryLabel_;
    juce::Label zoneCountLabel_;
    SynthKnob mixKnob_;
    juce::TextButton browseButton_;
    juce::TextButton clearButton_;
    juce::TextButton editZonesButton_;

    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> mixAttach_;
    std::unique_ptr<juce::FileChooser> fileChooser_;

    juce::Viewport zoneViewport_;
    juce::Component zoneContainer_;
    std::vector<std::unique_ptr<juce::Label>> zoneLabels_;

    // Zone editor overlay
    std::unique_ptr<juce::Component> zoneEditor_;
    void showZoneEditor();
    void hideZoneEditor();

    void browseForSample();
    void clearSample();
    void rebuildZoneList();
    void timerCallback() override;
    void loadFile(const juce::File& file);
};

// ── Performance Controls (Juno-Di inspired) ────────────────────────────────
class PerformancePanel : public juce::Component {
public:
    PerformancePanel(juce::AudioProcessorValueTreeState& apvts);
    void paint(juce::Graphics& g) override;
    void resized() override;

    std::function<void(int)> onSplitChanged;
    std::function<void(bool)> onLayerChanged;

private:
    juce::AudioProcessorValueTreeState& apvts_;

    juce::Label splitLabel_;
    juce::Slider splitSlider_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> splitAttach_;

    juce::ToggleButton layerButton_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::ButtonAttachment> layerAttach_;

    juce::Label transposeLabel_;
    juce::Slider transposeSlider_;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> transposeAttach_;

    juce::Label titleLabel_;
};

// ── Scope Component (Oscilloscope) ────────────────────────────────────────
class ScopeComponent : public juce::Component, private juce::Timer {
public:
    ScopeComponent();
    void paint(juce::Graphics& g) override;
    void resized() override;
    void pushBuffer(const std::vector<float>& interleavedBuffer, int numChannels);

private:
    std::vector<float> displayBuffer_;
    juce::CriticalSection bufferLock_;
    void timerCallback() override;
};

// ── Performance Meters ────────────────────────────────────────────────────
class PerformanceMeter : public juce::Component, private juce::Timer {
public:
    PerformanceMeter();
    void setVoiceCount(int count);
    void setCpuLoad(float load);
    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    int voiceCount_ = 0;
    float cpuLoad_ = 0.0f;
    void timerCallback() override;
};

// ── Preset Browser (popup overlay) ────────────────────────────────────────
class PresetBrowser : public juce::Component,
                      private juce::ListBoxModel,
                      private juce::TextEditor::Listener {
public:
    PresetBrowser();
    void paint(juce::Graphics& g) override;
    void resized() override;

    void setVisible(bool shouldBeVisible) override;

    std::function<void(const PresetInfo*)> onPresetSelected;
    std::function<void()> onSavePresetRequested;
    std::function<void(const UserPreset&)> onUserPresetSelected;

    void refreshUserPresets();

private:
    juce::TextEditor searchBox_;
    juce::ListBox presetList_;
    juce::TextButton closeButton_;
    juce::TextButton savePresetButton_;
    juce::Label titleLabel_;
    juce::ComboBox categoryFilter_;
    juce::ToggleButton showUserPresetsButton_;

    std::vector<const PresetInfo*> filteredFactoryPresets_;
    std::vector<UserPreset> userPresets_;
    std::vector<juce::var> displayList_;
    bool showingUserPresets_ = false;
    juce::String currentSearch_;
    juce::String currentCategory_;

    void rebuildFilter();

    // ListBoxModel
    int getNumRows() override { return (int)displayList_.size(); }
    void paintListBoxItem(int rowNumber, juce::Graphics& g, int width, int height, bool rowIsSelected) override;
    void selectedRowsChanged(int lastRowSelected) override;

    // TextEditor::Listener
    void textEditorTextChanged(juce::TextEditor&) override { rebuildFilter(); }

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(PresetBrowser)
};

// ── Quick Favorites Bar ───────────────────────────────────────────────────
class FavoritesBar : public juce::Component {
public:
    FavoritesBar();
    void paint(juce::Graphics& g) override;
    void resized() override;

    std::function<void(int)> onPresetSelected;

    void assignPresetIndex(int slot, int presetIndex);
    int getPresetIndex(int slot) const;

private:
    juce::TextButton favButtons_[8];
    int presetIndices_[8] = {-1, -1, -1, -1, -1, -1, -1, -1};
    void buttonClicked(int index);
};

// ── Split Keyboard Overlay ────────────────────────────────────────────────
class SplitKeyboardOverlay : public juce::Component {
public:
    SplitKeyboardOverlay();
    void paint(juce::Graphics& g) override;
    void resized() override;

    void setSplitPoint(int note);
    int getSplitPoint() const { return splitPoint_; }

    std::function<void(int)> onSplitChanged;

private:
    int splitPoint_ = 60; // C3
    bool dragging_ = false;

    void mouseDown(const juce::MouseEvent& e) override;
    void mouseDrag(const juce::MouseEvent& e) override;
    void mouseUp(const juce::MouseEvent& e) override;
    int noteAtX(int x) const;
};

// ── Keyboard Component ────────────────────────────────────────────────────
class PianoKeyboard : public juce::Component {
public:
    explicit PianoKeyboard(OpenSynthProcessor& processor);

    void paint(juce::Graphics& g) override;
    void resized() override;
    void mouseDown(const juce::MouseEvent& e) override;
    void mouseUp(const juce::MouseEvent& e) override;
    void mouseDrag(const juce::MouseEvent& e) override;

    void setSplitPoint(int note);
    void setShowSplit(bool show);

    // Called from computer keyboard piano (Z-M, Q-U)
    void setKeyPressed(int note);
    void setKeyReleased(int note);

private:
    OpenSynthProcessor& processor_;
    int hoveredNote_ = -1;
    int pressedNote_ = -1;
    int splitPoint_ = 60;
    bool showSplit_ = false;

    int getNoteAtPosition(juce::Point<int> pos) const;
    bool isBlackKey(int note) const;
    juce::Rectangle<float> getWhiteKeyRect(int note) const;
    juce::Rectangle<float> getBlackKeyRect(int note) const;
};

// ── MIDI Learn Manager ────────────────────────────────────────────────────
class MidiLearnManager {
public:
    struct Mapping {
        juce::String paramID;
        int ccNumber = -1;
    };

    void startLearning(const juce::String& paramID);
    bool isLearning() const { return learningParam_.isNotEmpty(); }
    void cancelLearning();

    // Call from MIDI input handler
    bool handleMidiCC(int ccNumber, float value, juce::AudioProcessorValueTreeState& apvts);

    // Get/set all mappings
    std::vector<Mapping> getMappings() const;
    void setMappings(const std::vector<Mapping>& mappings);

    juce::String getLearningParam() const { return learningParam_; }
    int getCCForParam(const juce::String& paramID) const;

private:
    juce::String learningParam_;
    std::unordered_map<juce::String, int> paramToCC_;
    std::unordered_map<int, juce::String> ccToParam_;
};

// ── MIDI-Learnable Knob ───────────────────────────────────────────────────
class MidiLearnableKnob : public SynthKnob {
public:
    MidiLearnableKnob(const juce::String& name, juce::Colour accent,
                      juce::AudioProcessorValueTreeState& apvts,
                      const juce::String& paramID,
                      MidiLearnManager& midiLearn);

    void mouseDown(const juce::MouseEvent& e) override;
    void paint(juce::Graphics& g) override;

private:
    juce::AudioProcessorValueTreeState& apvts_;
    juce::String paramID_;
    MidiLearnManager& midiLearn_;

    void showContextMenu();
};

// ── Setlist Overlay ───────────────────────────────────────────────────────
class SetlistOverlay : public juce::Component {
public:
    SetlistOverlay();
    void paint(juce::Graphics& g) override;
    void resized() override;

    void setVisible(bool shouldBeVisible) override;

    std::function<void(int)> onSlotSelected;   // click to load
    std::function<void(int)> onSlotAssigned;   // right-click or shift-click to assign current preset

    void assignPresetToSlot(int slotIndex, const juce::String& presetName);
    juce::String getSlotPresetName(int slotIndex) const;
    void clearSlot(int slotIndex);
    void clearAll();

private:
    static constexpr int kNumSlots = 16;
    juce::TextButton slotButtons_[kNumSlots];
    juce::String slotPresetNames_[kNumSlots];
    juce::TextButton closeButton_;
    juce::Label titleLabel_;
    juce::TextButton clearButton_;

    void slotClicked(int index);
    void slotRightClicked(int index);

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(SetlistOverlay)
};

// ── Main Editor ───────────────────────────────────────────────────────────
class OpenSynthEditor : public juce::AudioProcessorEditor,
                         private juce::Timer,
                         private juce::MidiInputCallback {
public:
    explicit OpenSynthEditor(OpenSynthProcessor& processor);
    ~OpenSynthEditor() override
    {
        saveAppState();
    }

    void paint(juce::Graphics& g) override;
    void resized() override;
    bool keyPressed(const juce::KeyPress& key) override;
    bool keyStateChanged(bool isKeyDown) override;

private:
    OpenSynthProcessor& processor_;

    // Header
    juce::Label titleLabel_;
    juce::TextButton presetButton_;
    juce::TextButton setlistButton_;
    juce::TextButton undoButton_;
    juce::TextButton redoButton_;
    PerformanceMeter meters_;
    ScopeComponent scope_;
    FavoritesBar favorites_;

    // Main sections
    OscPanel osc1Panel_, osc2Panel_;
    FilterPanel filterPanel_;
    EnvelopePanel ampEnvPanel_, filterEnvPanel_;
    FxSlotPanel fx1Panel_, fx2Panel_, fx3Panel_;
    ArpPanel arpPanel_;
    RealismPanel realismPanel_;
    MpePanel mpePanel_;
    DBeamPanel dbeamPanel_;
    PhraseSamplerPanel phraseSamplerPanel_;
    SamplePanel samplePanel_;
    PerformancePanel performancePanel_;
    PianoKeyboard keyboard_;

    // Overlay components
    PresetBrowser presetBrowser_;
    SplitKeyboardOverlay splitOverlay_;
    SetlistOverlay setlistOverlay_;

    // MIDI Learn
    MidiLearnManager midiLearnManager_;

    // Keyboard tracking
    std::unordered_set<int> heldKeys_;
    static int keyToNote(int keyCode);

    // Preset navigation
    int currentPresetIndex_ = 0;

    // Undo/Redo visual feedback
    juce::Label undoFeedbackLabel_;
    int undoFeedbackCounter_ = 0;

    // User preset manager
    UserPresetManager userPresetManager_;

    void timerCallback() override;
    void handleMidiCC(int ccNumber, float value);
    void showPresetBrowser();
    void showSetlistMode();
    void loadFavoritePreset(int index);
    void loadPresetByIndex(int index);
    void loadPresetByID(const juce::String& id);
    void configureSamplePlayerForPreset(const PresetData& p);
    void loadSampleForPreset(const PresetData& p, SamplePlayer& player);
    void saveCurrentPreset();
    void showUndoFeedback(const juce::String& text);

    // App state persistence
    AppStateManager appStateManager_;
    void loadAppState();
    void saveAppState();

    // MIDI device input
    std::unique_ptr<juce::MidiInput> midiInput_;
    void handleIncomingMidiMessage(juce::MidiInput* source, const juce::MidiMessage& message) override;
    void openDefaultMidiInput();

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(OpenSynthEditor)
};

} // namespace opensynth
