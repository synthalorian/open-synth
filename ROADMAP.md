# Open Synth — Roadmap & Architecture Plan

> **Goal:** Open-source Roland Juno-Di parity. Every sound category the Juno-Di covers, we cover — with modern synthesis techniques and a synthwave soul.
>
> **Status:** Fully standalone project. No Hermes integration. OpenSynth has its own setup, config, and tooling pipeline.

---

## Current State (May 2026)

### What Works
- 64-voice polyphonic subtractive synth engine (C++ → Flutter FFI)
- Dual oscillators with saw/square/triangle/sine/noise/pulse + unison + FM
- 7 FX types: chorus, delay, reverb, phaser, flanger, drive, compressor (+ EQ, limiter, rotary, tremolo)
- Arpeggiator: 5 patterns, swing, hold/latch, live step LEDs
- 16-step sequencer with per-step note editing
- Mod matrix, macro controls, preset morphing
- Keyboard split and layer modes
- Desktop (PortAudio) + Android (Oboe) audio backends
- 1,415 factory presets across 25 categories
- Synthwave-themed UI with oscilloscope + spectrum analyzer
- Mobile UX: hamburger drawer, landscape split-view, collapsible panels
- **Standalone setup system** (`opensynth setup` wizard, `opensynth doctor`, config management)

### What's Broken / Missing
- **Wavetable synthesis** — `wt_piano`, `wt_guitar`, `wt_choir` waveform types are stubs (Dart enum exists, C++ has no implementation). Piano presets currently fall back to saw-based subtractive approximation.
- **No drum/rhythm engine** — 97 "drum" presets are single-pitch subtractive patches. No drum kit mapping, no rhythm patterns, no dedicated drum synthesis.
- **No acoustic instrument modeling** — Strings, brass, guitars, woodwinds are all "best effort" subtractive patches. They don't fool anyone.
- **No sample playback** — Pure synthesis engine. No PCM/SF2/sample support for realistic acoustic sounds.
- **No physical modeling** — No dedicated algorithms for plucked strings, blown tubes, struck membranes.
- **Android audio untested** — Oboe backend compiles and links, but hasn't been validated for latency/glitches on real hardware yet.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter UI (Riverpod)                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────┐  │
│  │  Synth   │ │  Drum    │ │  Kit &   │ │  Settings &   │  │
│  │  Screen  │ │  Pads    │ │  Pattern │ │  Preset Mgmt  │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └───────┬───────┘  │
│       │            │            │                │          │
│  ┌────┴────────────┴────────────┴────────────────┴───────┐  │
│  │              FFI Bindings (Dart ↔ C++)                 │  │
│  └────┬────────────┬────────────┬────────────────────────┘  │
└───────┼────────────┼────────────┼───────────────────────────┘
        │            │            │
┌───────┼────────────┼────────────┼───────────────────────────┐
│       ▼            ▼            ▼          C++ Engine        │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐                      │
│  │  Synth   │ │  Drum    │ │ Wavetable│                      │
│  │  Engine  │ │  Kit     │ │ Engine   │                      │
│  │(existing)│ │ (new)    │ │ (new)    │                      │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘                     │
│       │            │            │                            │
│  ┌────┴────────────┴────────────┴─────┐                     │
│  │           FX Engine (shared)        │                     │
│  └────────────────┬───────────────────┘                     │
│                   ▼                                          │
│  ┌────────────────────────────────────┐                     │
│  │   Audio Backend                    │                     │
│  │   PortAudio (desktop) / Oboe (Android) │                 │
│  └────────────────────────────────────┘                     │
└─────────────────────────────────────────────────────────────┘
```

All synthesis engines share the same `process(AudioBuffer&)` interface and get mixed before the FX chain. The audio backend is already abstracted — adding new engines is additive.

---

## OpenSynth Standalone Setup System

OpenSynth has its own setup and configuration pipeline — completely independent from Hermes Agent and OpenShark. The setup wizard runs during first install and can be re-run anytime.

### CLI Commands

```bash
opensynth setup              # Interactive setup wizard
opensynth doctor             # Check dependencies and config health
opensynth config             # View current config
opensynth config edit        # Open config in $EDITOR
opensynth config set KEY VAL # Set a config value
opensynth config path        # Print config file path
```

### Setup Flow

```
1. DETECT  → 2. INSTALL DEPS (if needed)  → 3. AUTO-CONFIGURE  → 4. TEST  → 5. DONE
```

**Step 1 — Detect:**
- Check Flutter SDK installation and version
- Check native build toolchain (CMake, C++ compiler)
- Check PortAudio (desktop) or Android NDK (mobile)
- Check for existing OpenSynth config at `~/.config/opensynth/`

**Step 2 — Install Dependencies:**
- Flutter SDK (if missing, prompt for install path)
- PortAudio development headers (`portaudio` on Arch, `libportaudio2-dev` on Debian)
- CMake 3.22+
- Android SDK + NDK (if mobile build selected)

**Step 3 — Auto-Configure:**
- Write `~/.config/opensynth/config.yaml` with defaults:
  - Audio backend preference (PortAudio/Oboe/auto)
  - Default sample rate (48000)
  - Default buffer size (256 samples)
  - UI theme (synthwave/default)
  - MIDI input device (auto-detect)
- Create `~/.local/share/opensynth/` for presets, wavetables, recordings
- Create `.desktop` entry for app launchers

**Step 4 — Test:**
- Verify native library builds successfully
- Run audio probe (detect available audio devices)
- Test MIDI device enumeration (if available)

**Step 5 — Done:**
- Print summary of configured settings
- Show quick-start commands
- Offer to launch the app

### Config File (`~/.config/opensynth/config.yaml`)

```yaml
audio:
  backend: auto              # portaudio | oboe | auto
  sample_rate: 48000
  buffer_size: 256
  device_index: null         # null = default device
  input_device_index: null   # for MIDI/audio input

ui:
  theme: synthwave           # synthwave | dark | light
  show_spectrum: true
  show_oscilloscope: true
  keyboard_size: medium      # small | medium | large
  default_octave: 4

midi:
  enabled: true
  input_device: null         # null = first available
  channel: 0                 # 0-15

presets:
  factory_path: ~/.local/share/opensynth/presets
  user_path: ~/.local/share/opensynth/user_presets
  favorites_path: ~/.local/share/opensynth/favorites.json

paths:
  recordings: ~/.local/share/opensynth/recordings
  wavetables: ~/.local/share/opensynth/wavetables
  drum_kits: ~/.local/share/opensynth/drum_kits
```

---

## Roadmap

### Phase 0: Standalone Setup System
**Goal:** OpenSynth has its own setup wizard, config management, and doctor command.
**Estimate:** 2-3 days
**Status:** NOT STARTED

#### Deliverables
- `opensynth` CLI entry point (Python or Dart)
- `opensynth setup` — interactive wizard
- `opensynth doctor` — dependency/config health check
- `opensynth config` — get/set/edit config
- Config file at `~/.config/opensynth/config.yaml`
- Data directory at `~/.local/share/opensynth/`
- `.desktop` file generation

#### Files to Create
```
scripts/setup.py              # Setup wizard (Python)
scripts/doctor.py             # Health check
scripts/config.py             # Config management
lib/utils/config.dart         # Dart config loader
lib/utils/paths.dart          # XDG path resolution
```

---

### Phase 1: Drum Synthesis Engine
**Goal:** Real drum sounds, playable from the keyboard, with at least one kit.
**Estimate:** 3-4 days
**Status:** NOT STARTED

#### C++ Drum Synthesis
Each drum sound gets a dedicated algorithm — not generic oscillators.

| Sound | Synthesis Method | Key Parameters |
|-------|-----------------|----------------|
| **Kick** | Sine + pitch envelope (200Hz→50Hz, 30ms) + noise click transient | Decay, tuning, click level |
| **Snare** | Triangle (tone layer, BPF) + noise (noise layer, HPF) + separate decay curves | Tone/noise balance, tightness, decay |
| **Closed HH** | Noise → HPF (8kHz+) → fast VCA (30ms) | Decay (fixed short), tone |
| **Open HH** | Noise → HPF → medium VCA (300ms). Choke group with closed | Decay, tone |
| **Tom (H/M/L)** | Sine + pitch envelope (higher than kick, slower sweep) + optional noise layer | Tuning, decay, pitch sweep depth |
| **Crash** | Noise → 3× parallel BPF (metallic partials at non-harmonic intervals) → long decay (2s+) | Decay, brightness, partial balance |
| **Ride** | Noise → BPF + triangle undertone → medium decay | Decay, bell tone, undertone mix |
| **Clap** | Noise → BPF → burst pattern (3 hits in 30ms, then tail decay) | Tightness, reverb amount |
| **Rimshot** | Triangle → HPF → very fast decay (20ms) | Brightness, decay |
| **Cowbell** | 2× detuned square oscillators → BPF | Tuning, decay, detune |
| **Shaker/Tamb** | Noise → HPF → short decay, low amplitude | Decay, brightness |
| **Conga/Bongo** | Sine + slight pitch envelope → BPF | Tuning, slap amount |

#### Drum Kit System
GM2-standard note mapping (C1=36 through C3=~96):

```
C1(36)=Kick  D1(38)=Snare  F#1(42)=CHH  G#1(44)=PHH
A#1(46)=OHH  C2(48)=Tom1  E2(52)=Tom2  A2(57)=Crash
C3(60)=Ride  D#1(39)=Clap  C#1(37)=Rim  G#2(56)=Cowbell
```

A kit = array of `{note → {drumType, tuning, level, decay}}`. Different kits are just different parameter sets.

**Kit presets to include:**
1. Standard
2. Room
3. Power
4. TR-808
5. TR-909
6. Electronic
7. Jazz
8. Brush
9. Orchestra
10. SFX

#### Files
```
native/include/drum_synth.h
native/src/drum_synth.cpp
native/include/drum_kit_mapping.h
native/src/drum_kit_mapping.cpp
native/src/drum_ffi.cpp
native/include/drum_ffi.h
lib/models/drum_kit_config.dart
lib/providers/drum_providers.dart
lib/widgets/drum_pad_grid.dart
```

---

### Phase 2: Rhythm Pattern Player
**Goal:** Preset drum patterns with start/stop/tempo, like the Juno-Di rhythm section.
**Estimate:** 2-3 days
**Status:** NOT STARTED

#### Pattern Engine
```cpp
struct DrumHit {
    uint8_t note;      // which drum (MIDI note number)
    uint8_t velocity;  // 0-127
    uint8_t step;      // position in pattern (0-based 16th notes)
    uint8_t gate;      // duration as fraction of step (for open hats etc.)
};

struct DrumPattern {
    DrumHit* hits;
    int hitCount;
    int steps;           // 16, 32, 64
    int beatsPerBar;     // 3, 4, 5, 6, 7
    int subdivisions;    // 4 = 16th notes, 3 = triplets
    const char* name;
    const char* style;   // "rock", "funk", "jazz", etc.
};
```

#### Pattern Categories (30-50 presets)
- **Rock:** Basic 4/4, Rock Ballad, Half-time, Driving Rock, Shuffle Rock
- **Pop:** Pop Basic, Dance Pop, Synth Pop, Dream Pop
- **Funk:** Funk 16th, James Brown, Syncopated, Meters
- **Jazz:** Swing Basic, Jazz Waltz, Bebop, Brush Pattern
- **Latin:** Bossa Nova, Samba, Mambo, Salsa, Reggaeton
- **Electronic:** Four-on-floor, House, Techno, DnB, Trap, UK Garage
- **World:** Afrobeat, Reggae, Ska, Country, Waltz

#### UI
- Pattern browser (category → pattern list)
- Transport: Start/Stop/Tempo
- Visual step indicator (like the arp LEDs)
- Volume knob for the rhythm section

#### Integration
- Plays alongside the synth engine (parallel process, mixed at output)
- Syncs with existing MIDI clock provider
- Can be triggered from the existing sequencer panel

#### Files
```
native/include/drum_pattern_player.h
native/src/drum_pattern_player.cpp
lib/models/drum_pattern_config.dart
lib/providers/drum_pattern_provider.dart
lib/widgets/rhythm_panel.dart
```

---

### Phase 3: Wavetable Engine
**Goal:** Sampled wavetables for acoustic instruments that actually sound like the real thing.
**Estimate:** 5-7 days
**Status:** NOT STARTED

This is the biggest single feature. It's what separates a "synth with presets" from something that can cover a Juno-Di's full sound palette.

#### Wavetable Format
Single-cycle waveforms captured from real instruments (or synthesized with physical modeling). Multiple tables per instrument, switchable by velocity and/or key range.

```cpp
struct Wavetable {
    float* samples;        // 2048 samples per cycle
    int sampleCount;       // 2048 (power of 2 for interpolation)
    int tableCount;        // number of velocity/morph layers
    float baseFrequency;   // original pitch of the sampled note
    const char* name;
};
```

#### Wavetable Library (priority order)

| Instrument | Tables Needed | Source |
|-----------|--------------|--------|
| **Piano** | 4-6 (pp/mf/f, soft/bright) per octave × 3 octaves | Samples from public domain pianos or synthesized via physical modeling |
| **Electric Piano (Rhodes)** | 3-4 layers × 2 octaves | FM synthesis can approximate this well — no samples needed |
| **Organ (B3/Hammond)** | 9 drawbars = 9 sine waves, no wavetables needed | Pure additive synthesis with drawbar model |
| **Strings (Ensemble)** | 3 layers × 2 octaves | Samples for attack, loop for sustain |
| **Brass (Trumpet/Trombone/Sax)** | 3-4 layers × 2 octaves | Samples or physical modeling (blown tube) |
| **Acoustic Guitar** | 4-6 layers × 3 octaves | Physical modeling (Karplus-Strong + extensions) |
| **Electric Guitar** | 3 layers × 2 octaves | Physical modeling or wavetable |
| **Bass Guitar** | 3 layers × 2 octaves | Karplus-Strong for roundwound, filtered noise for slap |
| **Flute/Clarinet/Oboe** | 2-3 layers × 2 octaves | Physical modeling (waveguide) |
| **Choir/Vox** | 3-4 layers × 1.5 octaves | Samples (looped sustained vowels) |
| **Mallets (Vibes/Marimba/Xylo)** | 3 layers × 2 octaves | Physical modeling (struck bar) |
| **Ethnic (Sitar/Erhu/Shakuhachi)** | 2-3 layers each | Samples or physical modeling |

#### Synthesis Approaches by Instrument

**Pure additive/spectral (no samples):**
- Organ (drawbar model — already partially there)
- Electric Piano (FM synthesis — engine supports FM)
- Basic strings (filtered saw with chorus — existing engine)

**Physical modeling (algorithmic, no samples):**
- Guitar/Bass (Karplus-Strong with pick position, body resonance)
- Mallets (struck bar model — modal synthesis)
- Plucked ethnic strings (sitar, koto — extended Karplus-Strong)

**Wavetable (sampled single-cycles):**
- Piano, Brass, Woodwinds, Choir
- These need real acoustic captures or high-quality synthesized equivalents

**Hybrid (wavetable + subtractive shaping):**
- Most instruments benefit from this — wavetable sets the core timbre, filter/envelope shapes it dynamically

#### Files
```
native/include/wavetable_oscillator.h
native/src/wavetable_oscillator.cpp
native/include/wavetable_bank.h     — manages loaded wavetables
native/src/wavetable_bank.cpp
native/include/physical_models.h    — Karplus-Strong, waveguide, etc.
native/src/physical_models.cpp
native/wavetables/                  — .wt binary files (compiled from source samples)
native/tools/                       — build scripts to generate .wt from WAV/FLAC
lib/models/wavetable_config.dart
lib/providers/wavetable_providers.dart
```

---

### Phase 4: Keyboard Split + Drum Zone Integration
**Goal:** Lower keyboard zone plays drums, upper zone plays synth — like a Juno-Di.
**Estimate:** 1-2 days
**Status:** NOT STARTED

The keyboard split infrastructure already exists (`SynthEnginePair`, split/layer modes). This phase wires the drum kit into the lower zone.

- When rhythm mode is active, notes below the split point route to `DrumKit::noteOn()` instead of the synth engine
- Split point configurable (default C2 = note 48)
- Layer mode: both synth and drums can sound simultaneously
- Split indicator on the keyboard widget UI

---

### Phase 5: Drum Pad UI + Mobile Layout
**Goal:** Touch-friendly drum pads and rhythm controls for phone/tablet.
**Estimate:** 2-3 days
**Status:** NOT STARTED

- 4×4 pad grid (16 pads = most common drum hits)
- Color-coded by type (red=kick, blue=snare, yellow=hats, green=toms, purple=cymbals)
- Velocity-sensitive touch (tap position or force on supported devices)
- Pattern controls at the top: start/stop, tempo, pattern selector
- Mobile landscape: pads fill the bottom half, controls on top
- Mobile portrait: scrollable pad rows with transport at top

---

### Phase 6: Sound Design Polish Pass
**Goal:** Every preset category sounds like the real instrument it's emulating.
**Estimate:** 3-5 days (ongoing as wavetable library grows)
**Status:** NOT STARTED

#### Preset Rebuild Targets (per category)

| Category | Current State | Target State |
|----------|--------------|-------------|
| **Piano (15 presets)** | Fixed: saw-based subtractive | Wavetable with proper velocity layers |
| **Electric Piano (10)** | Triangle/sine — decent for Rhodes | FM model for authentic tine tone |
| **Organ (10)** | Basic sine stacks | Drawbar model with rotary speaker |
| **Guitar (15)** | Filtered saw | Karplus-Strong physical model |
| **Bass Guitar (10)** | Filtered saw | Karplus-Strong + slap model |
| **Strings (20)** | Saw + chorus + slow attack | Wavetable ensemble with proper attack transient |
| **Brass (15)** | Bright saw + filter | Wavetable or waveguide model |
| **Woodwinds (10)** | Filtered saw | Waveguide model with breath noise |
| **Choir (10)** | Filtered saw + vowel filter | Wavetable with vowel morphing |
| **Mallets (10)** | Sine + FM | Modal synthesis (struck bar) |
| **Percussion (20)** | Single-pitch synth patches | Dedicated drum synthesis engine |
| **Drums (30)** | Single-pitch synth patches | Full drum kit with key mapping |
| **Synth Leads/Pads/Bass/Arps/FX** | ✅ Already solid | Tweak existing presets, add more variety |

---

### Phase 7: Pro Features (Future)
**Goal:** Go beyond Juno-Di parity into modern workstation territory.
**Status:** NOT STARTED

- **Effects rack expansion:** Parametric EQ, vocoder, distortion models (tube, tape, bitcrush), ring modulator, multiband compressor
- **MIDI import/export** for sequencer patterns
- **Audio recording** (bounce to WAV/FLAC)
- **Patch exchange** (share presets via JSON, import from community)
- **Plugin format** (VST3/AU wrapper — use the C++ engine as a plugin)
- **Multitimbral mode** (16-part multitimbral like a real workstation)
- **Audio input processing** (guitar in → FX chain, vocoder carrier)

---

## Build Order Summary

| Phase | Feature | Days | Dependency |
|-------|---------|------|-----------|
| **0** | Standalone Setup System | 2-3 | None |
| **1** | Drum Synthesis Engine | 3-4 | None |
| **2** | Rhythm Pattern Player | 2-3 | Phase 1 |
| **3** | Wavetable Engine | 5-7 | None (parallel with 1-2) |
| **4** | Keyboard Split + Drum Zone | 1-2 | Phase 1 |
| **5** | Drum Pad UI + Mobile | 2-3 | Phase 1 |
| **6** | Sound Design Polish | 3-5 | Phase 3 |
| **7** | Pro Features | Ongoing | All above |

**Phases 0, 1, and 3 can run in parallel.** Total for Juno-Di parity (0-5): ~18-22 days.

---

## Technical Constraints

- **No external audio libraries** for core synthesis — everything hand-rolled C++ for deterministic performance and FFI compatibility
- **Oboe (Android) and PortAudio (desktop)** are the only external audio deps
- **Flutter + Riverpod** for all UI — no native Android/iOS views
- **Single-threaded audio callback** — no allocations, no locks, no Dart calls in the hot path
- **All engines share AudioBuffer interface** for zero-copy mixing
- **Desktop must never break** — mobile code is gated behind `Platform.isAndroid/iOS` checks
- **ARM64 + x86_64** builds for Android (Pixel 8a = ARM64, emulator = x86_64)
- **No Hermes integration** — OpenSynth is fully standalone with its own setup, config, and tooling

---

## Immediate Next Steps

When we pick this back up:

1. **Start Phase 0** — build the standalone `opensynth` CLI with setup wizard, doctor, and config management
2. **Then Phase 1** — build `DrumSynth` with kick + snare + hats + toms first
3. **Get a single kit playable** — trigger from keyboard, hear real drum sounds
4. **Then expand** — more sounds, more kits, pattern player

The standalone setup system is the foundation. Everything else builds on it.
