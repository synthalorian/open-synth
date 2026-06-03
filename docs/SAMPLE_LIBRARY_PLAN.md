# Open Synth — Sample Library Integration Plan

## Goal
Add real instrument samples to Open Synth so acoustic presets (piano, organ, guitar, strings, brass, woodwind, ethnic, percussion, chromatic, orchestral) blend synthesized wavetables with actual recordings for Juno-Di-level realism.

## Current State (as of commit ef87a91)
- `PresetData` has `sampleMix` field (0.0 = synth only, 1.0 = sample only)
- 236 presets generated with category-appropriate `sampleMix` values:
  - Acoustic categories: 0.5–0.7 sampleMix
  - Synth categories: 0.0 sampleMix
- `SamplePlayer` + `SampleStream` (disk streaming) already implemented
- `OpenSynthEditor::configureSamplePlayerForPreset()` auto-creates sample player when `sampleMix > 0`
- `OpenSynthEditor::loadSampleForPreset()` looks for `samples/<category>/<name>.wav` relative to executable
- Build targets all pass: Standalone, VST3, CLAP

## Sample Directory Layout

```
OpenSynth_artefacts/Release/Standalone/
└── samples/
    ├── piano/
    │   ├── Grand_Piano.wav
    │   ├── Bright_Piano.wav
    │   └── ...
    ├── organ/
    │   ├── Hammond_Organ.wav
    │   └── ...
    ├── guitar/
    ├── strings/
    ├── brass/
    ├── woodwind/
    ├── ethnic/
    ├── percussion/
    ├── chromatic/
    └── orchestral/
```

**Naming rule:** preset name with spaces replaced by underscores + `.wav`
Example: "Grand Piano" → `samples/piano/Grand_Piano.wav`

## Recommended Free Sample Sources

### Primary: FluidR3_GM SoundFont
- **File:** `FluidR3_GM.sf2` (~141 MB)
- **Source:** https://github.com/FluidSynth/fluidsynth/wiki/SoundFont (or `fluid-soundfont-gm` package on Arch)
- **Quality:** Full General MIDI set, decent quality, CC0/public domain
- **Extraction tool:** `sf2split`, `swami`, or Python with `sf2utils`

### Alternative: GeneralUser GS
- **File:** `GeneralUser_GS.sf2` (~31 MB)
- **Source:** http://www.schristiancollins.com/generaluser.php
- **Quality:** Better than FluidR3, free for any use

### Alternative: Freepiano / Versilian Studios
- **Source:** https://versilian-studios.com/ncsd/
- **Quality:** Individual instrument recordings, higher quality per instrument

## Extraction Workflow

1. **Install tools:**
   ```bash
   # Arch Linux
   sudo pacman -S fluidsynth python-pip
   pip install sf2utils
   ```

2. **Extract samples from SoundFont:**
   ```bash
   # Using fluidsynth
   fluidsynth -ni FluidR3_GM.sf2 -r 48000 -o audio.file.name=output.wav
   
   # Or use Python script (to be written) to extract per-instrument WAVs
   ```

3. **Organize into category folders** matching preset names

4. **Test:** Build and run Standalone, load an acoustic preset, verify sample playback

## Next Session Tasks

- [ ] Download and verify a free GM SoundFont
- [ ] Write Python extraction script to pull individual instrument WAVs from SF2
- [ ] Map SF2 instruments to Open Synth preset categories
- [ ] Generate sample directory structure
- [ ] Test sample loading with Standalone build
- [ ] Adjust sampleMix values per preset based on listening
- [ ] Document any missing instruments that need custom recording/synthesis

## Technical Notes

- `SampleStream` uses JUCE `MemoryMappedAudioFormatReader` for efficient disk streaming
- Preload cache: first 100ms kept in RAM for instant attack
- SamplePlayer supports multi-zone mapping but current implementation uses single stretch (root=60, range=0-127)
- For realistic results, consider multi-sampling (separate samples per octave/velocity) in future
- Current sample player is 16-voice polyphonic with ADSR envelope

## Files Modified in This Track

- `include/preset_data.h` — added `sampleMix` field
- `include/preset_library_full.h` — regenerated 236 presets with sampleMix
- `include/synth_engine.h` — added `getSampleRate()`, `getSamplePlayer()`, `setSamplePlayer()`
- `include/synth_engine_wrapper.h` — added `getEngine()` accessor
- `include/plugin_editor.h` — added `configureSamplePlayerForPreset()`, `loadSampleForPreset()`
- `src/plugin_editor.cpp` — implemented sample player auto-configuration
