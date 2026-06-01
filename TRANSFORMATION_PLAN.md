# OpenSynth → Ultimate Roland Juno-Di Killer
## Transformation Plan v1.0

**Goal:** Close the realism gap and elevate OpenSynth from "cool open-source synth" to "the open-source Roland Juno-Di that never existed."

**Current State:** 1,454 presets, 64-voice polyphony, full C++ engine (subtractive + drum synthesis + wavetable stubs + physical modeling stubs), 11 FX types, arpeggiator, rhythm patterns, keyboard split. Builds clean. Audio stable.

**Target State:** 800-1000 curated killer presets, wavetable + physical modeling fully wired, 30+ MFX types, drum kits polished, performance mode gig-ready, optional lightweight PCM sample engine for acoustic realism.

---

## Phase 1: Preset Audit & Cull
**Duration:** 2-3 days  
**Goal:** Quality over quantity. Every preset must earn its place.

### 1.1 Automated Audit Script
- [ ] Build `scripts/audit_presets.dart` — analyzes factory_presets.dart for:
  - Duplicate names
  - Duplicate parameter sets (near-identical sounds)
  - Empty/broken presets (missing required fields)
  - Category distribution imbalance
  - Presets using stub waveforms (wt_piano, wt_guitar, etc.)
  - Presets with identical osc1+osc2 configs (wasted voices)

### 1.2 Manual Listening Pass
- [ ] Play through each category, mark:
  - **Keeper** — sounds great, unique character
  - **Merge** — similar to another, pick the best
  - **Fix** — good idea, bad execution (needs parameter tweak)
  - **Kill** — uninspired, broken, or redundant

### 1.3 Cull & Consolidate
- [ ] Remove "Kill" presets
- [ ] Merge "Merge" presets (keep best params, kill duplicates)
- [ ] Fix "Fix" presets (tweak envelopes, filters, FX)
- [ ] Target: 800-1000 presets from 1,454

### 1.4 Category Rebalance
- [ ] Ensure every category has strong representation
- [ ] Add missing sub-categories if needed
- [ ] Verify tags are meaningful and searchable

### 1.5 Preset Quality Gates
Every surviving preset must pass:
- [ ] Has a distinct sonic identity (not "generic saw pad #47")
- [ ] Envelope makes sense for the category (pianos have fast attack, pads have slow)
- [ ] FX are tasteful (not every preset needs reverb + delay + chorus)
- [ ] Velocity response feels musical
- [ ] No clipping at max velocity

---

## Phase 2: Wavetable Integration
**Duration:** 2-3 days  
**Depends on:** Phase 1  
**Goal:** Make wavetable synthesis actually produce sound.

### 2.1 Wavetable Generation
- [ ] Generate 2048-sample single-cycle wavetables for:
  - Piano (4 velocity layers × 3 octaves)
  - Electric Piano (tine, reed)
  - Strings (ensemble, solo)
  - Brass (trumpet, trombone, sax)
  - Woodwinds (flute, clarinet, oboe)
  - Choir (ah, oo, eh)
  - Guitar (plucked, muted)
- [ ] Store as compiled binary blobs in `native/wavetables/`
- [ ] Build tool to generate .wt from WAV/FLAC source

### 2.2 Engine Wiring
- [ ] Connect `WavetableOscillator` to `SynthPart` voices
- [ ] Velocity-based wavetable switching
- [ ] Key-tracking for multi-octave tables
- [ ] Crossfade between adjacent tables

### 2.3 Preset Migration
- [ ] Update piano presets to use `wt_piano` (now real)
- [ ] Update string presets to use `wt_strings`
- [ ] Update brass presets to use `wt_brass`
- [ ] Update choir presets to use `wt_choir`

---

## Phase 3: Physical Modeling Presets
**Duration:** 2-3 days  
**Depends on:** Phase 1  
**Goal:** Karplus-Strong and modal synthesis become real instruments.

### 3.1 Karplus-Strong Polish
- [ ] Add body resonance filters (guitar body simulation)
- [ ] Pick position simulation
- [ ] String damping control
- [ ] Nylon vs steel string character

### 3.2 Modal Synthesis
- [ ] Struck bar model (marimba, xylophone, vibes)
- [ ] Tuned membrane (tabla, bongo)
- [ ] Bell/chime model

### 3.3 Preset Creation
- [ ] Acoustic Guitar (nylon + steel variants)
- [ ] Electric Bass (roundwound, flatwound, slap)
- [ ] Mallets (marimba, xylophone, vibraphone)
- [ ] Ethnic plucked (sitar, koto, balalaika)

---

## Phase 4: Drum Kit Polish
**Duration:** 1-2 days  
**Depends on:** Phase 1  
**Goal:** Drum engine goes from "tech demo" to "gig-ready."

### 4.1 Kit Preset Finalization
- [ ] Tune all 10 kit presets (Standard, Room, Power, 808, 909, Electronic, Jazz, Brush, Orchestra, SFX)
- [ ] Velocity curves feel natural
- [ ] Choke groups work (open/closed hi-hat)

### 4.2 UI Integration
- [ ] Drum pad grid on desktop (4×4 or 3×5)
- [ ] Drum pad grid on mobile (scrollable or grid)
- [ ] Kit selector dropdown
- [ ] Level + tuning per pad

### 4.3 Rhythm Pattern Integration
- [ ] Patterns trigger drum kit correctly
- [ ] Tempo sync with arpeggiator
- [ ] Pattern chaining (intro → main A → fill → main B)

---

## Phase 5: MFX Expansion (The 79 Effects)
**Duration:** 3-5 days  
**Depends on:** Phase 1-4  
**Goal:** Juno-Di parity on effects.

### 5.1 C++ FX Implementations
- [ ] Auto-wah / envelope filter
- [ ] Bitcrusher / lo-fi
- [ ] Ring modulator
- [ ] Pitch shifter
- [ ] Harmonizer
- [ ] Multi-tap delay
- [ ] Ping-pong delay
- [ ] Tape echo (with wow/flutter)
- [ ] Spring reverb
- [ ] Gated reverb
- [ ] Shimmer reverb
- [ ] Amp simulator (tube, transistor)
- [ ] Vocoder (needs audio input)
- [ ] Stereo widener / Haas effect
- [ ] Talk box / formant filter

### 5.2 FX UI Panels
- [ ] Each new FX gets a dedicated panel widget
- [ ] Consistent knob layout
- [ ] A/B comparison works across all FX
- [ ] Preset save/load includes FX state

### 5.3 FX Routing
- [ ] 3 MFX slots (insert or send)
- [ ] Per-part FX routing in multitimbral mode
- [ ] FX order matters (reorderable chain)

---

## Phase 6: Performance Mode Overhaul
**Duration:** 2-3 days  
**Depends on:** Phase 1-5  
**Goal:** Gig-ready performance features.

### 6.1 Split Screen
- [ ] Visual keyboard zone indicators
- [ ] Drag-to-set split point
- [ ] Per-zone preset, volume, octave, pan
- [ ] Crossfade at split point

### 6.2 Live Performance Features
- [ ] Quick-favorites (1-tap preset recall)
- [ ] Setlist mode with seamless switching
- [ ] Tap tempo
- [ ] Transpose on the fly

### 6.3 Meters & Monitoring
- [ ] CPU load meter (accurate)
- [ ] Voice count display
- [ ] Clip indicator
- [ ] Master output VU meter

---

## Phase 7: Lightweight PCM Sample Engine (Optional)
**Duration:** 1-2 weeks  
**Depends on:** Phase 1-6  
**Goal:** Close the acoustic realism gap if synthesis alone isn't enough.

### 7.1 Hybrid Sample Mode
- [ ] Load only attack transients (~0.1s per sample)
- [ ] Crossfade to synthesis for sustain/decay
- [ ] Dramatically less memory than full samples

### 7.2 Sample Format
- [ ] SFZ parser for mapping files
- [ ] WAV/FLAC loader
- [ ] Velocity layers and key ranges
- [ ] Loop points for sustained sounds

### 7.3 Integration
- [ ] New waveform type: `sample`
- [ ] Presets can mix synthesis + samples
- [ ] Background loading (no audio thread stalls)

---

## Build Order Summary

| Phase | Feature | Days | Dependency |
|-------|---------|------|-----------|
| **1** | Preset Audit & Cull | 2-3 | None |
| **2** | Wavetable Integration | 2-3 | Phase 1 |
| **3** | Physical Modeling Presets | 2-3 | Phase 1 |
| **4** | Drum Kit Polish | 1-2 | Phase 1 |
| **5** | MFX Expansion | 3-5 | Phase 1-4 |
| **6** | Performance Mode Overhaul | 2-3 | Phase 1-5 |
| **7** | PCM Sample Engine | 7-14 | Phase 1-6 |

**Phases 2, 3, and 4 can run in parallel after Phase 1.**  
**Total for Juno-Di parity (Phases 1-6): ~12-19 days.**  
**Total with PCM engine (all phases): ~19-33 days.**

---

## Immediate Action Items (Phase 1)

1. **Build audit script** — `scripts/audit_presets.dart`
2. **Run automated analysis** — find duplicates, stubs, broken presets
3. **Manual listening pass** — keeper/merge/fix/kill classification
4. **Execute cull** — remove dead weight, consolidate duplicates
5. **Rebalance categories** — ensure strong representation across all 25
6. **Quality gate pass** — every survivor earns its place

---

## Technical Constraints

- No external audio libraries for core synthesis — hand-rolled C++ for deterministic performance
- Oboe (Android) and PortAudio (desktop) are the only external audio deps
- Flutter + Riverpod for all UI
- Single-threaded audio callback — no allocations, no locks, no Dart calls in hot path
- All engines share AudioBuffer interface for zero-copy mixing
- Desktop must never break — mobile code is gated behind Platform checks
- ARM64 + x86_64 builds for Android

---

*This is the wave. The tape never stops rolling.* 🎹🦈
