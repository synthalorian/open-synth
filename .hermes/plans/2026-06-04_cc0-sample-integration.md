# OpenSynth CC0 Sample Library Integration Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Integrate CC0 sample libraries into OpenSynth so piano sounds like a real piano and drums sound like real drums, while keeping the project fully redistributable under permissive terms.

**Architecture:** Add a `SampleLibrary` system that downloads CC0 samples on first run (or bundles them via git submodule), auto-generates JSON manifests from SFZ files, and maps them to existing `SamplePlayer` zones. Update presets to reference sample-based instruments by ID.

**Tech Stack:** JUCE (C++), existing `SamplePlayer` with multi-zone support, SFZ parsing (subset), JSON manifests, git submodules or curl downloads.

---

## Current State

- `SamplePlayer` supports multi-zone mapping, velocity layers, loop points, round-robin, release samples
- `loadMultiSample()` reads JSON manifests with zone definitions
- Presets have `sampleMix = 0.0f` — samples are never used
- No bundled samples exist in the repo
- Drum synthesis is purely algorithmic (`DrumKit` with oscillators + noise)
- Piano presets use wavetable waveform 6 (WT_PIANO) — not samples

---

## Task 1: Add Sample Library Submodule Infrastructure

**Status:** ✅ COMPLETE — Submodules added, `.gitignore` updated, CMake copy step pending

**Done:**
- Added 7 CC0 sample libraries as git submodules:
  - `piano-upright-kw` (66 samples, 2 velocity layers)
  - `piano-splendid-grand` (public domain Steinway, 4 velocity layers, 342 zones when parser fixed)
  - `drums-muldjordkit` (777 zones, multi-sampled rock kit)
  - `drums-colombo-adk` (80 zones, wooden kit)
  - `guitar-spanish-classical` (48 zones)
  - `guitar-electric-clean` (120 zones)
  - `bass-electric-yr` (12 zones, finger style)
- Updated `.gitignore` to allow `samples/` directory

**Still needed:** CMakeLists.txt copy step (see Task 6)

**Files:**
- Modify: `.gitmodules` (create)
- Modify: `CMakeLists.txt` — add sample copy step

**Step 1: Add submodules for core libraries**

```bash
cd /home/synth/projects/open-synth
git submodule add https://github.com/freepats/upright-piano-KW.git samples/piano-upright-kw
git submodule add https://github.com/sfzinstruments/SplendidGrandPiano.git samples/piano-splendid-grand
git submodule add https://github.com/freepats/muldjordkit.git samples/drums-muldjordkit
git submodule add https://github.com/freepats/electric-bass-YR.git samples/bass-electric-yr
git submodule add https://github.com/freepats/spanish-classical-guitar.git samples/guitar-spanish-classical
git submodule add https://github.com/freepats/colomboADK.git samples/drums-colombo-adk
git submodule add https://github.com/freepats/e-guitar-FSBS-clean.git samples/guitar-electric-clean
```

**Step 2: Update CMakeLists.txt to copy samples to build output**

```cmake
# Copy sample libraries to build output
set(SAMPLE_DIRS
    piano-upright-kw
    piano-splendid-grand
    drums-muldjordkit
    bass-electric-yr
    guitar-spanish-classical
    drums-colombo-adk
    guitar-electric-clean
)

foreach(dir ${SAMPLE_DIRS})
    if(EXISTS "${CMAKE_SOURCE_DIR}/samples/${dir}")
        add_custom_command(TARGET OpenSynth_VST3 POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_SOURCE_DIR}/samples/${dir}"
            "$<TARGET_FILE_DIR:OpenSynth_VST3>/samples/${dir}"
        )
    endif()
endforeach()
```

**Step 3: Commit**

```bash
git add .gitmodules CMakeLists.txt
git commit -m "build: add CC0 sample library submodules + CMake copy step"
```

---

## Task 2: Write SFZ-to-JSON Manifest Converter

**Status:** ✅ MOSTLY COMPLETE — Converter works for simple SFZ, needs fix for multi-line `<group>` headers with per-group `#define` macros

**Done:**
- Created `tools/sfz_to_manifest.py` with support for:
  - Note name to MIDI conversion
  - Velocity layer parsing (`lovel`/`hivel`)
  - Loop points (`loop_start`/`loop_end`)
  - `#include` resolution with macro expansion
  - `default_path` handling

**Known Issue:** Splendid Grand Piano uses multi-line `<group>` headers where `#define $DYN PP/MP/MF/FF` appears on lines AFTER `<group>`. The parser only captures macros on the same line as `<group>`, so includes resolve with stale macro values. This produces 57 zones instead of 342.

**Fix needed:** Accumulate group header lines until `<region>`, `#include`, or next `<group>` is encountered. Parse `#define` macros from all lines in the group header block.

**Files:**
- Create: `tools/sfz_to_manifest.py` ✅

**Step 1: Fix the converter**

```python
# In parse_sfz(), when <group> is encountered, set in_group_header = True
# Parse opcodes and #define macros from all subsequent lines until <region>, #include, or <group>
# When #include is hit, use the CURRENT group's macros (not global) to expand the include path
```

**Step 2: Regenerate Splendid Grand manifest**

```bash
cd /home/synth/projects/open-synth
python3 tools/sfz_to_manifest.py "samples/piano-splendid-grand/Splendid Grand Piano.sfz" samples/manifests/piano-splendid-grand.json
# Should produce 342 zones, not 57
```

**Step 3: Commit**

```bash
git add tools/sfz_to_manifest.py samples/manifests/
git commit -m "tools: fix SFZ group macro scoping, regenerate all manifests"
```

**Files:**
- Create: `tools/sfz_to_manifest.py`

**Step 1: Write the converter**

```python
#!/usr/bin/env python3
"""Convert SFZ files to OpenSynth JSON manifests."""
import sys, re, json, os
from pathlib import Path

def parse_sfz(path):
    with open(path) as f:
        content = f.read()
    
    zones = []
    current_zone = {}
    
    for line in content.split('\n'):
        line = line.strip()
        if not line or line.startswith('//'):
            continue
        
        # New region/group
        if line.startswith('<region>'):
            if current_zone:
                zones.append(current_zone)
            current_zone = {}
        elif line.startswith('<group>'):
            if current_zone:
                zones.append(current_zone)
            current_zone = {}
        
        # Parse opcodes
        for match in re.finditer(r'(\w+)=([^\s]+)', line):
            key, val = match.group(1), match.group(2)
            if key == 'sample':
                current_zone['file'] = val
            elif key == 'lokey':
                current_zone['minNote'] = note_name_to_midi(val)
            elif key == 'hikey':
                current_zone['maxNote'] = note_name_to_midi(val)
            elif key == 'pitch_keycenter':
                current_zone['rootNote'] = note_name_to_midi(val)
            elif key == 'lovel':
                current_zone['minVelocity'] = int(val) / 127.0
            elif key == 'hivel':
                current_zone['maxVelocity'] = int(val) / 127.0
            elif key == 'loop_start':
                current_zone['loopStart'] = int(val)
            elif key == 'loop_end':
                current_zone['loopEnd'] = int(val)
            elif key == 'loop_mode':
                current_zone['loopEnabled'] = (val == 'loop_continuous')
    
    if current_zone:
        zones.append(current_zone)
    
    return zones

def note_name_to_midi(name):
    notes = {'c':0,'c#':1,'db':1,'d':2,'d#':3,'eb':3,'e':4,'f':5,
             'f#':6,'gb':6,'g':7,'g#':8,'ab':8,'a':9,'a#':10,'bb':10,'b':11}
    m = re.match(r'([a-g][#b]?)(-?\d+)', name.lower())
    if m:
        return int(m.group(2)) * 12 + notes[m.group(1)] + 12
    return int(name)

def main():
    sfz_path = sys.argv[1]
    out_path = sys.argv[2] if len(sys.argv) > 2 else sfz_path.replace('.sfz', '.json')
    
    zones = parse_sfz(sfz_path)
    
    # Resolve relative sample paths
    base_dir = os.path.dirname(sfz_path)
    for z in zones:
        if 'file' in z:
            z['file'] = os.path.normpath(os.path.join(base_dir, z['file']))
    
    manifest = {
        'name': Path(sfz_path).stem,
        'zones': zones
    }
    
    with open(out_path, 'w') as f:
        json.dump(manifest, f, indent=2)
    
    print(f"Wrote {len(zones)} zones to {out_path}")

if __name__ == '__main__':
    main()
```

**Step 2: Commit**

```bash
git add tools/sfz_to_manifest.py
git commit -m "tools: SFZ to OpenSynth JSON manifest converter"
```

---

## Task 3: Generate Manifests for All Submodules

**Status:** ✅ MOSTLY COMPLETE — 6 of 7 manifests generated; Splendid Grand needs re-generation after parser fix

**Done:**
- Generated manifests for:
  - `piano-upright-kw.json` (66 zones) ✅
  - `drums-muldjordkit.json` (777 zones) ✅
  - `drums-colombo-adk.json` (80 zones) ✅
  - `guitar-spanish-classical.json` (48 zones) ✅
  - `guitar-electric-clean.json` (120 zones) ✅
  - `bass-electric-yr-finger.json` (12 zones) ✅
- `piano-splendid-grand.json` (57 zones — WRONG, should be 342)

**Files:**
- Create: `samples/manifests/*.json` (6 done, 1 needs redo)

**Files:**
- Create: `samples/manifests/*.json` (one per instrument)

**Step 1: Generate manifests**

```bash
cd /home/synth/projects/open-synth
python3 tools/sfz_to_manifest.py samples/piano-upright-kw/UprightPianoKW-20220221.sfz samples/manifests/piano-upright-kw.json
python3 tools/sfz_to_manifest.py samples/piano-splendid-grand/Splendid\ Grand\ Piano.sfz samples/manifests/piano-splendid-grand.json
python3 tools/sfz_to_manifest.py samples/drums-muldjordkit/MuldjordKit\ 20201018.sfz samples/manifests/drums-muldjordkit.json
python3 tools/sfz_to_manifest.py samples/bass-electric-yr/FingerBassYR\ 20190930.sfz samples/manifests/bass-finger-yr.json
python3 tools/sfz_to_manifest.py samples/guitar-spanish-classical/SpanishClassicalGuitar-20190618.sfz samples/manifests/guitar-spanish-classical.json
python3 tools/sfz_to_manifest.py samples/drums-colombo-adk/ColomboADK\ FreePats\ 20200530.sfz samples/manifests/drums-colombo-adk.json
python3 tools/sfz_to_manifest.py samples/guitar-electric-clean/E-Guitar-FSBS-clean.sfz samples/manifests/guitar-electric-clean.json
```

**Step 2: Commit**

```bash
git add samples/manifests/
git commit -m "assets: generated JSON manifests for all CC0 sample libraries"
```

---

## Task 4: Update PresetData with Sample Instrument IDs

**Status:** ⏳ NOT STARTED — Blocked until manifests are finalized

**Objective:** Add a field to `PresetData` that references a sample manifest by ID.

**Plan:**
- Add `sampleManifestId` field to `PresetData`
- Update piano presets to use `"piano-splendid-grand"` (or `"piano-upright-kw"` as fallback)
- Update drum presets to use `"drums-muldjordkit"`
- Update bass presets to use `"bass-electric-yr-finger"`
- Update guitar presets to use `"guitar-spanish-classical"` or `"guitar-electric-clean"`
- Set `sampleMix = 1.0f` for sample-based presets

**Files:**
- Modify: `include/preset_data.h`
- Modify: `include/preset_library_full.h`

**Files:**
- Modify: `include/preset_data.h`

**Step 1: Add sampleManifestId field**

```cpp
    // Sample player mix (0 = synth only, 1 = sample only)
    float sampleMix = 0.0f;
    
    // Sample manifest ID (empty = no samples, use synthesis only)
    const char* sampleManifestId = "";
```

**Step 2: Update full preset library to use samples**

For piano presets in `preset_library_full.h`, change:
```cpp
    0.00,        // sampleMix
    "",          // sampleManifestId
```
to:
```cpp
    1.00,        // sampleMix — full sample
    "piano-splendid-grand",  // sampleManifestId
```

For drum presets (if any), use `"drums-muldjordkit"`.

**Step 3: Commit**

```bash
git add include/preset_data.h include/preset_library_full.h
git commit -m "feat: presets reference sample manifests for piano, drums, bass, guitar"
```

---

## Task 5: Update applyPresetToEngine to Load Samples

**Status:** ⏳ NOT STARTED — Blocked until Task 4 complete

**Objective:** When a preset has `sampleManifestId`, load the corresponding manifest into the sample player.

**Plan:**
- Add `getSampleManifestPath()` helper that resolves manifest files relative to plugin bundle or dev path
- In `applyPresetToEngine()`, check `sampleManifestId` and call `samplePlayer->loadMultiSample()`
- Set `samplePlayer->setMixLevel(p.sampleMix)`
- Handle missing manifests gracefully (fallback to synthesis)

**Files:**
- Modify: `src/preset_data.cpp`

**Files:**
- Modify: `src/preset_data.cpp`

**Step 1: Add sample loading logic**

```cpp
void applyPresetToEngine(const PresetData& p, SynthEngineWrapper& e) {
    // ... existing code ...
    
    // Load sample manifest if specified
    if (p.sampleManifestId[0] != '\0' && e.getEngine()) {
        auto* player = e.getEngine()->getSamplePlayer();
        if (player) {
            juce::File manifestFile = getSampleManifestPath(p.sampleManifestId);
            if (manifestFile.existsAsFile()) {
                player->clear();
                player->loadMultiSample(manifestFile.getFullPathName().toStdString());
                player->setMixLevel(p.sampleMix);
            }
        }
    }
}

// Helper to resolve manifest path
juce::File getSampleManifestPath(const char* id) {
    // Try plugin bundle first, then fallback to relative path
    juce::File exeDir = juce::File::getSpecialLocation(juce::File::currentExecutableFile).getParentDirectory();
    juce::File manifest = exeDir.getChildFile("samples/manifests").getChildFile(juce::String(id) + ".json");
    if (manifest.existsAsFile()) return manifest;
    
    // Development fallback
    return juce::File("/home/synth/projects/open-synth/samples/manifests").getChildFile(juce::String(id) + ".json");
}
```

**Step 2: Commit**

```bash
git add src/preset_data.cpp
git commit -m "feat: applyPresetToEngine loads sample manifests when preset specifies one"
```

---

## Task 6: Update SamplePlayer to Handle FLAC + CMake Copy Step

**Status:** ⏳ NOT STARTED

**Objective:** Ensure `SamplePlayer` can load FLAC files and CMake copies samples to build output.

**Plan:**
- Add `JUCE_USE_FLAC=1` compile definition in CMakeLists.txt
- Add CMake post-build step to copy `samples/` directory to build output
- Verify `SampleStream` uses `juce::AudioFormatReader` (it does — FLAC should work)

**Files:**
- Modify: `CMakeLists.txt`
- Verify: `dsp/sample_player.cpp`

**Files:**
- Modify: `dsp/sample_player.cpp` — verify FLAC support

**Step 1: Check JUCE audio format registration**

In `src/plugin_processor.cpp`, ensure `AudioFormatManager` is set up:

```cpp
// In constructor or prepareToPlay:
juce::AudioFormatManager formatManager;
formatManager.registerBasicFormats(); // Includes FLAC, WAV, AIFF, OggVorbis
```

The `SampleStream` class already uses `juce::AudioFormatReader`, so FLAC should work if JUCE was built with FLAC support.

**Step 2: Verify CMake has FLAC support**

```cmake
# In CMakeLists.txt, ensure JUCE formats are enabled
target_compile_definitions(OpenSynth PUBLIC JUCE_USE_FLAC=1)
```

**Step 3: Commit**

```bash
git add CMakeLists.txt
git commit -m "build: enable JUCE FLAC support for sample playback"
```

---

## Task 7: Add Sample Library Browser to UI

**Status:** ⏳ NOT STARTED — Low priority, can defer

**Objective:** Let users see which sample libraries are available and load them manually.

**Note:** This is a nice-to-have. The primary flow is preset-based (select "Grand Piano" → samples auto-load). Manual browsing is for power users who want to mix and match.

**Files:**
- Modify: `include/plugin_editor.h`
- Modify: `src/plugin_editor.cpp`

**Files:**
- Modify: `include/plugin_editor.h` — add `SampleLibraryBrowser` class
- Modify: `src/plugin_editor.cpp` — implement browser

**Step 1: Add simple browser overlay**

```cpp
class SampleLibraryBrowser : public juce::Component {
public:
    SampleLibraryBrowser();
    void paint(juce::Graphics& g) override;
    void resized() override;
    
    std::function<void(const juce::String& manifestId)> onManifestSelected;
    
private:
    juce::ListBox list_;
    juce::TextButton closeButton_;
    juce::StringArray manifestIds_;
};
```

**Step 2: Populate with available manifests**

Scan `samples/manifests/` for `.json` files and list them.

**Step 3: Commit**

```bash
git add include/plugin_editor.h src/plugin_editor.cpp
git commit -m "ui: sample library browser for manual manifest loading"
```

---

## Task 8: Build and Test

**Status:** ⏳ NOT STARTED — Blocked until Tasks 2-6 complete

**Objective:** Verify samples load and play correctly.

**Prerequisites:**
- Task 2: SFZ parser fixed, all manifests regenerated
- Task 4: Presets reference sample manifests
- Task 5: `applyPresetToEngine()` loads samples
- Task 6: CMake copies samples, FLAC enabled

**Test Checklist:**
- [ ] Load plugin, select "Grand Piano" preset
- [ ] Verify `sampleMix` is 1.0 and `sampleManifestId` is "piano-splendid-grand"
- [ ] Play notes → hear sampled Steinway, not wavetable
- [ ] Select "Juno Bass" preset → hear synthesis (no manifest)
- [ ] Select drum preset → load MuldjordKit, play GM drum notes
- [ ] Check CPU usage — disk streaming should keep it low

**Files:**
- All of the above

**Step 1: Initialize submodules and build**

```bash
cd /home/synth/projects/open-synth
git submodule update --init --recursive
cd build && cmake --build . --target OpenSynth_VST3 -j$(nproc)
```

**Step 2: Manual test checklist**

- [ ] Load plugin, select "Grand Piano" preset
- [ ] Verify `sampleMix` is 1.0 and `sampleManifestId` is "piano-splendid-grand"
- [ ] Play notes → hear sampled Steinway, not wavetable
- [ ] Select "Juno Bass" preset → hear synthesis (no manifest)
- [ ] Open sample browser → see all 7 manifests listed
- [ ] Select drum manifest → load MuldjordKit, play GM drum notes
- [ ] Check CPU usage — disk streaming should keep it low

**Step 3: Commit**

```bash
git commit -m "test: CC0 sample integration verified (piano, drums, bass, guitar)"
```

---

## Task 9: Document Sample Libraries

**Status:** ⏳ NOT STARTED — Can do anytime after Task 2

**Objective:** Add README section documenting bundled samples and their licenses.

**Note:** The Splendid Grand Piano is public domain (AKAI), not CC0. All others are CC0. Need to be precise about licensing.

**Files:**
- Modify: `README.md`

**Files:**
- Modify: `README.md`

**Step 1: Add samples section**

```markdown
## Bundled Sample Libraries

OpenSynth includes the following CC0 (public domain) sample libraries:

| Instrument | Library | Size | Source |
|------------|---------|------|--------|
| Grand Piano | Splendid Grand Piano (Steinway) | ~256MB | [sfzinstruments](https://github.com/sfzinstruments/SplendidGrandPiano) |
| Upright Piano | Upright Piano KW (Kawai) | ~65MB | [freepats](https://github.com/freepats/upright-piano-KW) |
| Rock Drums | MuldjordKit | ~500MB | [freepats](https://github.com/freepats/muldjordkit) |
| Vintage Drums | ColomboADK | ~50MB | [freepats](https://github.com/freepats/colomboADK) |
| Electric Bass | Finger Bass YR (Yamaha RBX) | ~50MB | [freepats](https://github.com/freepats/electric-bass-YR) |
| Classical Guitar | Spanish Classical Guitar | ~75MB | [freepats](https://github.com/freepats/spanish-classical-guitar) |
| Electric Guitar | E-Guitar FSBS Clean | ~50MB | [freepats](https://github.com/freepats/e-guitar-FSBS-clean) |

All samples are CC0 (public domain) and may be used in commercial projects without attribution.
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: document bundled CC0 sample libraries"
```

---

## Risks and Tradeoffs

1. **SFZ parser complexity:** The converter handles a minimal SFZ subset. Complex instruments with ARIA extensions, multi-line group headers, and nested includes need careful handling.
   - *Status:* Hit this with Splendid Grand Piano. Fix is straightforward (accumulate group header lines).
   - *Mitigation:* Fix parser, validate zone counts against known values.

2. **Repo size:** Git submodules with large sample libraries will bloat the repo.
   - *Mitigation:* Document `git submodule update --init --depth 1` in README. CI can skip samples.

3. **FLAC support:** JUCE's FLAC support requires `libflac` at build time. May not work on all platforms.
   - *Mitigation:* Convert FLAC to WAV in build step if needed. Or use JUCE's built-in FLAC decoder.

4. **License confusion:** Some repos have mixed licenses (e.g., code CC0 but samples CC-BY).
   - *Mitigation:* Only use repos where samples are explicitly CC0 or public domain. Double-check LICENSE files. Splendid Grand is public domain (AKAI), not CC0.

5. **Sample path resolution:** Manifests contain relative paths. The plugin needs to resolve these at runtime relative to the bundle or executable.
   - *Mitigation:* `getSampleManifestPath()` tries plugin bundle first, then dev fallback.

---

## Next Session Priority Order

1. **Fix SFZ parser group macro scoping** (Task 2) — Unblocks everything else
2. **Regenerate Splendid Grand manifest** (Task 3) — Validate 342 zones
3. **Add `sampleManifestId` to `PresetData`** (Task 4)
4. **Wire `applyPresetToEngine()` to load samples** (Task 5)
5. **CMake FLAC + sample copy** (Task 6)
6. **Build and test** (Task 8)
7. **UI browser** (Task 7) — Defer until core flow works
8. **README docs** (Task 9) — Defer until after testing

## Future Enhancements

- **On-demand download:** Instead of submodules, download samples on first run via curl
- **SFZ player:** Full SFZ opcode support instead of JSON manifests
- **Velocity layer crossfading:** Smooth transitions between soft/medium/loud samples
- **Round-robin:** Alternate samples for repeated notes (already supported in `SamplePlayer`)
- **Release samples:** Key-off noise for piano realism (already supported in `SamplePlayer`)
