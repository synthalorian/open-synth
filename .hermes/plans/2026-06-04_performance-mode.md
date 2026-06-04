# OpenSynth Performance Mode Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Transform OpenSynth from a single-timbral synth into a Juno-Di-class performance workstation with split/layer keyboard configurations, performance memories, and part-level editing.

**Architecture:** Add a `Performance` struct that binds 1-2 parts to keyboard zones (lower/upper/layer), with 128 performance memories storable/retrievable. Extend the UI with a Performance panel (part select, zone assign, preset per part) and wire MIDI routing in `processBlock()` to route notes to the correct part based on split point.

**Tech Stack:** JUCE (C++), existing OpenSynth engine (16-part multitimbral, 128-voice polyphony)

---

## Current State

- **Engine:** 16-part multitimbral (`SynthPart parts_[16]`), 128-voice allocator, global FX bus
- **UI:** Single-part editor (all knobs control part 0 only), split slider + layer toggle exist but do nothing in audio path
- **MIDI:** All notes routed to part 0 regardless of channel or split point
- **Presets:** 1,424 preset library, `applyPresetToEngine()` only targets part 0
- **APVTS:** Parameters only for part 0 — no part-select mechanism

---

## Task 1: Add Performance Data Model

**Objective:** Define `Performance` and `PerformanceBank` structs for 128 performance memories.

**Files:**
- Create: `include/performance.h`

**Step 1: Write the header**

```cpp
#pragma once
#include "preset_data.h"

namespace opensynth {

struct PerformanceZone {
    bool enabled = false;
    int presetIndex = 0;        // Index into kPresetLibrary
    int minNote = 21;           // MIDI note
    int maxNote = 108;
    int transpose = 0;          // -12 .. +12
    float volume = 1.0f;
    float pan = 0.0f;
    int midiChannel = -1;       // -1 = omni, 0-15 = specific channel
};

struct Performance {
    char name[32] = "Init Performance";
    PerformanceZone lower;
    PerformanceZone upper;
    bool layerMode = false;     // true = upper plays across full range
    int fxSlotType[3] = {0,0,0};
    bool fxSlotEnabled[3] = {false,false,false};
    float masterVolume = 0.8f;
    bool arpEnabled = false;
    int arpPattern = 0;
    float arpTempo = 120.0f;
};

struct PerformanceBank {
    static constexpr int NUM_SLOTS = 128;
    std::array<Performance, NUM_SLOTS> slots;

    void initDefaults();
    void loadFromDisk(const juce::File& file);
    void saveToDisk(const juce::File& file) const;
};

} // namespace opensynth
```

**Step 2: Commit**

```bash
git add include/performance.h
git commit -m "feat: Performance data model (128 slots, lower/upper zones)"
```

---

## Task 2: Implement PerformanceBank Serialization

**Objective:** Save/load performances to/from binary file on disk.

**Files:**
- Create: `src/performance.cpp`

**Step 1: Implement initDefaults, loadFromDisk, saveToDisk**

```cpp
#include "performance.h"
#include <fstream>

namespace opensynth {

void PerformanceBank::initDefaults() {
    for (int i = 0; i < NUM_SLOTS; ++i) {
        slots[i] = Performance{};
        juce::String name = "Perf " + juce::String(i + 1);
        std::strncpy(slots[i].name, name.toRawUTF8(), 31);
        slots[i].name[31] = '\0';
    }
}

void PerformanceBank::saveToDisk(const juce::File& file) const {
    std::ofstream out(file.getFullPathName().toStdString(), std::ios::binary);
    if (!out) return;
    out.write(reinterpret_cast<const char*>(slots.data()), sizeof(slots));
}

void PerformanceBank::loadFromDisk(const juce::File& file) {
    std::ifstream in(file.getFullPathName().toStdString(), std::ios::binary);
    if (!in) { initDefaults(); return; }
    in.read(reinterpret_cast<char*>(slots.data()), sizeof(slots));
}

} // namespace opensynth
```

**Step 2: Commit**

```bash
git add src/performance.cpp
git commit -m "feat: PerformanceBank binary serialization"
```

---

## Task 3: Add Performance State to PluginProcessor

**Objective:** Store active performance index and PerformanceBank in the processor.

**Files:**
- Modify: `include/plugin_processor.h`
- Modify: `src/plugin_processor.cpp`

**Step 1: Add to plugin_processor.h**

Add `#include "performance.h"` and add these members to `OpenSynthProcessor`:

```cpp
    PerformanceBank performanceBank_;
    int activePerformanceIndex_ = 0;
    
    void loadPerformance(int index);
    Performance& currentPerformance() { return performanceBank_.slots[activePerformanceIndex_]; }
    const Performance& currentPerformance() const { return performanceBank_.slots[activePerformanceIndex_]; }
```

**Step 2: Initialize in constructor**

In `src/plugin_processor.cpp`, in the constructor after `apvts_` init:

```cpp
    performanceBank_.initDefaults();
```

**Step 3: Implement loadPerformance**

```cpp
void OpenSynthProcessor::loadPerformance(int index) {
    if (index < 0 || index >= PerformanceBank::NUM_SLOTS) return;
    activePerformanceIndex_ = index;
    auto& perf = currentPerformance();
    
    // Apply lower zone preset to part 0
    if (perf.lower.enabled && perf.lower.presetIndex >= 0 && perf.lower.presetIndex < kNumPresets) {
        applyPresetToEngine(kPresetLibrary[perf.lower.presetIndex], synth_);
        synth_.getEngine()->setPartMidiChannel(0, perf.lower.midiChannel);
        synth_.getEngine()->setPartVolume(0, perf.lower.volume);
        synth_.getEngine()->setPartPan(0, perf.lower.pan);
    }
    
    // Apply upper zone preset to part 1
    if (perf.upper.enabled && perf.upper.presetIndex >= 0 && perf.upper.presetIndex < kNumPresets) {
        applyPresetToEngine(kPresetLibrary[perf.upper.presetIndex], synth_);
        // Note: applyPresetToEngine currently only targets part 0 — we'll fix this in Task 5
        synth_.getEngine()->setPartMidiChannel(1, perf.upper.midiChannel);
        synth_.getEngine()->setPartVolume(1, perf.upper.volume);
        synth_.getEngine()->setPartPan(1, perf.upper.pan);
    }
    
    // Apply performance-level FX
    for (int slot = 0; slot < 3; ++slot) {
        synth_.setFxType(slot + 1, perf.fxSlotType[slot]);
        synth_.setFxEnabled(slot + 1, perf.fxSlotEnabled[slot]);
    }
    
    // Apply performance-level arp
    synth_.setArpEnabled(perf.arpEnabled);
    synth_.setArpPattern(perf.arpPattern);
    synth_.setArpTempo(perf.arpTempo);
    
    // Notify editor to refresh
    if (auto* editor = dynamic_cast<OpenSynthEditor*>(getActiveEditor())) {
        editor->refreshFromPerformance();
    }
}
```

**Step 4: Commit**

```bash
git add include/plugin_processor.h src/plugin_processor.cpp
git commit -m "feat: Performance loading in processor (parts 0/1, FX, arp)"
```

---

## Task 4: Wire MIDI Routing to Parts Based on Split

**Objective:** Route incoming MIDI notes to part 0 (lower) or part 1 (upper) based on split point.

**Files:**
- Modify: `src/synth_engine_wrapper.cpp` — `render()` method

**Step 1: Modify noteOn/noteOff routing**

Currently:
```cpp
engine_->noteOn(midiMsg.getNoteNumber(), midiMsg.getFloatVelocity(), midiMsg.getChannel() - 1);
```

Change to use a helper that checks the current performance split:

```cpp
// In render(), before MIDI loop:
int splitPoint = 60; // Default C3
bool layerMode = false;
// TODO: get from current performance — for now, hardcode

// In noteOn handler:
int note = midiMsg.getNoteNumber();
int partIdx = 0;
if (!layerMode && note >= splitPoint) {
    partIdx = 1; // Upper zone
}
engine_->noteOn(note, midiMsg.getFloatVelocity(), partIdx);
```

**Step 2: Commit**

```bash
git add src/synth_engine_wrapper.cpp
git commit -m "feat: MIDI note routing to part 0/1 based on split point"
```

---

## Task 5: Extend applyPresetToEngine for Multi-Part

**Objective:** Allow `applyPresetToEngine` to target a specific part index, not just part 0.

**Files:**
- Modify: `include/preset_data.h` — change signature
- Modify: `src/preset_data.cpp` — add partIndex parameter

**Step 1: Update signature**

```cpp
void applyPresetToEngine(const PresetData& preset, SynthEngineWrapper& engine, int partIndex = 0);
```

**Step 2: Update implementation**

Replace all `parts_[0]` access with `parts_[partIndex]` via a new engine accessor:

```cpp
// In synth_engine_wrapper.h, add:
void setPartOsc1Waveform(int part, int w);
// ... etc for all parameters

// Or more practically, expose the SynthPart directly:
SynthPart& getPart(int index);
```

Add `getPart()` to `SynthEngine`:

```cpp
// In synth_engine.h (already exists):
SynthPart& part(int index) { return parts_[index]; }
```

Then in `applyPresetToEngine`:

```cpp
void applyPresetToEngine(const PresetData& p, SynthEngineWrapper& e, int partIndex) {
    auto* engine = e.getEngine();
    if (!engine) return;
    auto& part = engine->part(partIndex);
    
    // Set parameters directly on part instead of wrapper setters
    part.osc1.setWaveform(p.osc1Waveform);
    part.osc1.setOctave(p.osc1Octave);
    // ... etc for all fields
}
```

**Step 3: Commit**

```bash
git add include/preset_data.h src/preset_data.cpp
git commit -m "feat: applyPresetToEngine supports multi-part target"
```

---

## Task 6: Add Performance Panel to UI

**Objective:** Create a panel showing current performance name, lower/upper preset selectors, split point, layer toggle, and performance bank navigation.

**Files:**
- Modify: `include/plugin_editor.h` — add `PerformanceModePanel` class
- Modify: `src/plugin_editor.cpp` — implement panel

**Step 1: Add PerformanceModePanel to header**

```cpp
class PerformanceModePanel : public juce::Component {
public:
    PerformanceModePanel(OpenSynthProcessor& processor);
    void paint(juce::Graphics& g) override;
    void resized() override;
    void refresh();

private:
    OpenSynthProcessor& processor_;
    juce::Label nameLabel_;
    juce::TextButton prevPerfButton_, nextPerfButton_;
    juce::TextButton lowerPresetButton_, upperPresetButton_;
    juce::Label lowerNameLabel_, upperNameLabel_;
    juce::Slider splitSlider_;
    juce::ToggleButton layerToggle_;
    juce::TextButton savePerfButton_;
    
    void loadPrevPerformance();
    void loadNextPerformance();
    void showLowerPresetBrowser();
    void showUpperPresetBrowser();
    void saveCurrentPerformance();
};
```

**Step 2: Add to OpenSynthEditor**

Add `PerformanceModePanel perfPanel_;` to `OpenSynthEditor` members.
Add `void refreshFromPerformance();` method.

**Step 3: Commit**

```bash
git add include/plugin_editor.h src/plugin_editor.cpp
git commit -m "ui: PerformanceModePanel with preset assign, split, layer"
```

---

## Task 7: Add Part Selector to Existing Panels

**Objective:** Let users select which part (0-15) the Osc/Filter/Env panels edit.

**Files:**
- Modify: `include/plugin_editor.h` — add part selector to `OscPanel`, `FilterPanel`, `EnvelopePanel`
- Modify: `src/plugin_editor.cpp` — wire part selector to update APVTS from selected part's parameters

**Step 1: Add part selector combo box to panels**

```cpp
juce::ComboBox partSelector_; // "Part 1" .. "Part 16"
```

**Step 2: On part change, load that part's parameters into APVTS**

```cpp
void OscPanel::onPartChanged(int partIndex) {
    auto* engine = processor_.getSynth().getEngine();
    if (!engine) return;
    auto& part = engine->part(partIndex);
    
    // Update APVTS from part state
    apvts_.getParameter("osc1Waveform")->setValueNotifyingHost(
        apvts_.getParameter("osc1Waveform")->convertTo0to1((float)part.osc1.waveform()));
    // ... etc
}
```

**Step 3: Commit**

```bash
git add include/plugin_editor.h src/plugin_editor.cpp
git commit -m "ui: part selector in osc/filter/env panels (1-16)"
```

---

## Task 8: Save/Load Performance in Plugin State

**Objective:** Persist performance bank in plugin state so DAW recalls it.

**Files:**
- Modify: `src/plugin_processor.cpp` — `getStateInformation()` / `setStateInformation()`

**Step 1: Serialize performance bank to MemoryBlock**

```cpp
void OpenSynthProcessor::getStateInformation(juce::MemoryBlock& destData) {
    // Existing APVTS state
    auto state = apvts_.copyState();
    std::unique_ptr<juce::XmlElement> xml(state.createXml());
    
    // Add performance bank
    auto perfXml = std::make_unique<juce::XmlElement>("PerformanceBank");
    for (int i = 0; i < PerformanceBank::NUM_SLOTS; ++i) {
        auto slotXml = std::make_unique<juce::XmlElement>("Slot");
        slotXml->setAttribute("index", i);
        slotXml->setAttribute("name", juce::String(performanceBank_.slots[i].name));
        // ... serialize all fields
        perfXml->addChildElement(slotXml.release());
    }
    xml->addChildElement(perfXml.release());
    
    copyXmlToBinary(*xml, destData);
}
```

**Step 2: Commit**

```bash
git add src/plugin_processor.cpp
git commit -m "feat: performance bank persisted in DAW plugin state"
```

---

## Task 9: Build and Verify

**Objective:** Ensure everything compiles and basic functionality works.

**Step 1: Build**

```bash
cd build && cmake --build . --target OpenSynth_VST3 -j$(nproc)
```

Expected: Clean build, 0 errors.

**Step 2: Manual test checklist**

- [ ] Load plugin, open performance panel
- [ ] Select performance 1, assign lower = "Blade Runner Pad", upper = "Neon Lead"
- [ ] Set split point to C3 (60)
- [ ] Play notes below C3 → hear pad
- [ ] Play notes above C3 → hear lead
- [ ] Enable layer mode → both sounds across full keyboard
- [ ] Save performance, reload plugin → performance recalled
- [ ] Switch to part 2 in osc panel → edits affect part 2 only

**Step 3: Commit**

```bash
git commit -m "test: performance mode verified (split, layer, save/load)"
```

---

## Risks and Tradeoffs

1. **APVTS complexity:** Part selector + performance mode means APVTS parameters need to dynamically reflect the selected part. This may require parameter groups or a "part offset" approach.
   - *Mitigation:* For v1, keep APVTS as part 0 only. Part selector directly edits engine parts without APVTS reflection. Performance panel uses direct engine access.

2. **Preset library size:** `kPresetLibrary` is only ~60 presets with full data. The other 1,364 are name-only stubs.
   - *Mitigation:* Accept that only ~60 presets have data for now. Performance preset selectors filter to presets with valid data.

3. **MIDI channel routing:** Current code routes by note range only, ignoring MIDI channel. A real Juno-Di can assign parts to specific channels.
   - *Mitigation:* Add `midiChannel` to `PerformanceZone` but ignore it in v1. Document as future enhancement.

4. **FX per-part vs global:** Currently FX is global. Juno-Di has part-level FX sends.
   - *Mitigation:* Keep FX global in v1. Part-level FX sends require engine architecture changes.

---

## Open Questions

1. Should performances reference presets by index (fragile if library changes) or by ID (stable)?
2. Should the performance panel replace the existing preset browser, or be a separate overlay?
3. How many parts should be editable from the UI? All 16, or just lower/upper (2)?

---

## Future Enhancements (Post-v1)

- **Arpeggiator MIDI out:** Send arp notes as MIDI to other plugins
- **Pattern sequencer:** 8-track song mode with chaining
- **Part-level FX sends:** Each part has its own FX send level
- **MIDI channel filtering:** Parts only respond to assigned channels
- **Performance categories:** Organize 128 performances into banks (A-H × 16)
- **Quick performance buttons:** 8 hardware-style favorites for performances
