# Open Synth -- Master Plan

**Vision:** The world's first open-source, fully functional synthesizer keyboard app.
Feature parity with Roland Juno-Di plus modern extensions.

---

## Phase 0: STABLE AUDIO -- COMPLETE ✓

### 0.1 Fix PortAudio Lifecycle ✓
- [x] Refactor device enumeration to use a shared PortAudio session
- [x] Move `Pa_Initialize()` to app startup, `Pa_Terminate()` to app shutdown
- [x] Create a singleton `AudioSystem` that owns the PA lifecycle
- [x] Device enumeration reads from cached data (never calls Pa_Init/Term)

### 0.2 Thread Safety ✓
- [x] Add atomic parameter ring buffer between UI and audio threads
- [x] All synth parameter changes go through a lock-free SPSC queue
- [x] Audio callback drains the queue at block boundaries
- [x] No mutexes in the audio thread path

### 0.3 Provider Lifecycle Hardening ✓
- [x] `synthAudioStreamProvider` uses explicit onDispose with stop-then-destroy
- [x] Stream recreation uses stop-drain-restart pattern
- [x] Add explicit `dispose` ordering: stream.stop() -> stream.dispose() -> engine.dispose()
- [x] Never call PortAudio functions during widget build

### 0.4 DSP Bug Fixes ✓
- [x] Fix flanger stereo (use separate L/R delay buffers)
- [x] Fix compressor makeup gain (multiply, don't add)
- [x] Replace hard-limiter with tanh soft clipper (no DC flatlines)
- [x] Clamp all delay buffer reads/writes to [-2, +2] (all FX: delay, reverb, flanger, phaser)
- [x] Add NaN/inf guards in the process loop
- [x] Fix reverb delay length to be sample-rate aware
- [x] Clamp phaser tan() coeff to 10.0 to prevent explosion

### 0.5 Bugfix Sprint -- COMPLETE ✓
- [x] Fix Envelope.cpp sustain=0 bug (pluck/percussive presets silent)
- [x] Fix applyPresetToSynth stale state (audio dies on preset switch)
- [x] Fix synth_engine.cpp reset() to clear flanger/chorus/phaser/compressor state too
- [x] App icon installed globally ✓

### 1.1 Polyphony Increase (16 -> 64)
- [x] Increase `VoiceAllocator::MAX_VOICES` to 64
- [ ] Add voice priority modes (last note, lowest note, round-robin)
- [ ] CPU profiling to verify performance at full polyphony
- [ ] Dynamic voice stealing based on CPU load

### 1.2—1.5 Core Engine Upgrades (backlog)

### 4.1 Arpeggiator Engine — COMPLETE ✓
- [x] C++ Arpeggiator class with 5 patterns: Up, Down, Up/Down, Random, Chord
- [x] Adjustable tempo (20–300 BPM), octave range (1–4), gate (0–100%)
- [x] 4 resolutions: quarter, eighth, sixteenth, thirty-second
- [x] Thread-safe param queue integration (ARP_ENABLED, ARP_TEMPO, etc.)
- [x] Note routing: arp intercepts noteOn/noteOff when enabled, generates events at block boundaries
- [x] Voice allocator integration (arp feeds directly into synth engine)
- [x] Dart provider bridges config to native engine via param queue
- [x] Arpeggiator panel UI already exists (pattern toggle, rate, octave, randomization)

### 5.1 Preset Expansion (102 -> 272)
- [x] Extended from 36 factory presets to 272 across all 8 categories
- [x] Pads: Nebula Haze, Aurora Borealis, Ocean Floor, Sapphire, Twilight Halo, Cathedral, Aurora Strings, Solar Flare (+ more)
- [x] Leads: Electric Dab, Hopping, Aggro Saw, Digitalis, Blade Saw, Techno Lead, Reso Lead, Dual Saw, Tri-Saw, Sync Lead (+ more)
- [x] Bass: Analog Honk, Zaw, Dub Sub, Future Bass, Hopping Sub, Analog Sine, Drop Bass, ARP Bass, Tau, Everlong, Percussion Bass (+ more)
- [x] Keys: Bright Grand, Phase Rhodes, Digital Piano, Toy Piano, Electric Grand, FM E-Piano, Wurlitzer 200A (+ more)
- [x] Arps: Fantasia, Saw Arp, Multi Saw, Funky Arp, Lately Bass, Sync Bells, Stab, Squelch Arp (+ more)
- [x] FX: Space Drone, White Noise SFX, Swoosh, Radio, Helicopter, Explosion, Big Reverb Hit, Transform, Sci-Fi, Noise Impact (+ more)
- [x] Synthwave: 2010s, Dreamwave, Justice Bass, Night Drive, Sidechain Pad, Deep Poly, Retro Poly, Down Under (+ more)
- [x] Custom: Call Waiting, B-Movie, MP-5, Old Man, Infinite, Phased Pad, Sine Flow, Glass Pad (+ more)

---

## Phase 1: CORE ENGINE UPGRADES

### 1.1 Polyphony Increase (16 -> 64) — COMPLETE ✓
- [x] Increase `VoiceAllocator::MAX_VOICES` to 64
- [x] Add voice priority modes (newest, oldest, quietest, highest note)
- [ ] CPU profiling to verify performance at full polyphony
- [ ] Dynamic voice stealing based on CPU load

### 1.2 Expanded Waveforms — PARTIAL ✓
- [x] Add noise types: white, pink, brown
- [ ] Add wavetable support (user-loadable wavetables)
- [ ] Add sample playback (PCM patches from SF2/SFZ files)
- [ ] Add additive synthesis partials

### 1.3 Oscillator Features — PARTIAL ✓
- [x] Sub-oscillator (square/sine, 1-2 oct below)
- [x] Noise generator integrated per oscillator
- [x] FM synthesis mode (osc2 modulates osc1, per-oscillator toggle)
- [ ] PWM via LFO/envelope
- [ ] Oscillator sync (hard sync, soft sync)

### 1.4 Filter Upgrades — PARTIAL ✓
- [x] More filter types: low-shelf, high-shelf, peaking EQ
- [x] Filter key tracking
- [x] Filter drive/saturation stage
- [ ] Self-oscillation mode with resonance > 1.0

### 1.5 Envelope Upgrades — COMPLETE ✓
- [x] Pitch envelope (3rd envelope generator, per-voice)
- [x] Envelope curves (linear, exponential, logarithmic attack/decay/release)
- [x] Delay stage (pre-attack wait)
- [x] Hold stage (sustain at max for fixed time)

### 1.6 LFO Upgrades — PARTIAL ✓
- [x] S&H smoothed and random walk waveforms
- [x] LFO fade-in time
- [x] LFO tempo sync with note divisions
- [x] Per-voice LFO mode
- [ ] Add LFO 3 and LFO 4
- [ ] Custom LFO waveform drawing

---

## Phase 2: EFFECTS ENGINE OVERHAUL

### 2.1 Multi-FX Architecture
- [ ] 3 independent MFX slots (like Juno-Di)
- [ ] 79+ effect types across categories
- [ ] Per-part effects routing in multitimbral mode
- [ ] Insert vs send routing

### 2.2 Effect Types to Add
- [ ] EQ (2-band, 3-band, parametric, graphic)
- [ ] Limiter (brick wall, lookahead)
- [ ] Multiband compressor
- [ ] Overdrive / distortion (tube, tape, transistor)
- [ ] Auto-wah / envelope filter
- [ ] Rotary speaker simulator
- [ ] Tremolo / autopan
- [ ] Stereo widener / haas effect
- [ ] Bitcrusher / lo-fi
- [ ] Tape echo (with wow/flutter)
- [ ] BPM-synced delay (1/4, 1/8, 1/16, dotted, triplet)
- [ ] Multi-tap delay
- [ ] Ping-pong delay
- [ ] Pitch shifter
- [ ] Harmonizer
- [ ] Vocoder (using mic input)
- [ ] Amp simulator (guitar, bass)
- [ ] Spring reverb type
- [ ] Gated reverb (80s snare vibe)
- [ ] Granular delay

### 2.3 Reverb Upgrade
- [ ] Replace simple Schroeder with proper algorithmic reverb
- [ ] Types: Hall, Room, Plate, Stage, Chamber, Spring, Shimmer, Gated
- [ ] Early reflections + late tail separation
- [ ] Pre-delay control
- [ ] Size / decay / damping / mix controls

---

## Phase 3: PERFORMER FEATURES

### 3.1 Keyboard Split & Layer (Juno-Di Performance Mode)
- [ ] Split: 2 zones with configurable split point
- [ ] Layer: Stack 2+ presets on same key range
- [ ] Each zone: independent patch, volume, octave, pan
- [ ] Visual split point indicator on keyboard
- [ ] Crossfade at split point option

### 3.2 Multitimbral (16-part)
- [ ] 16 independent parts (like Juno-Di)
- [ ] Each part: own patch, MIDI channel, key range, volume
- [ ] Mix view for balancing parts
- [ ] MIDI channel routing per part

### 3.3 Favorites System — COMPLETE ✓
- [x] Favorite/unfavorite presets with star toggle
- [x] Reorderable favorites list (drag to rearrange)
- [x] Persistent storage via Hive (survives app restart)
- [x] Named setlists for live performance (create, rename, delete, add/remove presets)
- [x] Active setlist provider for quick recall

### 3.4 Performance Controls
- [ ] Transpose (global and per-zone)
- [ ] Octave shift (global and per-zone)
- [ ] Pitch bend range config
- [ ] Mod wheel sensitivity
- [ ] Aftertouch support (channel pressure + polyphonic)
- [ ] Sustain pedal with half-pedaling
- [ ] Expression pedal
- [ ] 5 assignable real-time knobs (like Juno-Di)

---

## Phase 4: ARPEGGIATOR & RHYTHM

### 4.1 Arpeggiator Engine
- [ ] 128+ preset arpeggio patterns
- [ ] Styles: Up, Down, Up/Down, Random, Chord, Phrase
- [ ] Note values: 1/1, 1/2, 1/4, 1/8, 1/16, 1/32, triplets, dotted
- [ ] Octave range: 1-4
- [ ] Shuffle/groove feel
- [ ] Velocity patterns (fixed, accent, random)
- [ ] Pattern editor (draw notes in grid)
- [ ] Tempo sync to master clock
- [ ] Hold function (latch arpeggiator)

### 4.2 Rhythm Patterns
- [ ] 144+ rhythm patterns (24 groups x 6 variations)
- [ ] Genres: Rock, Pop, Jazz, Funk, Latin, Dance, World, Synthwave
- [ ] Each pattern: Intro, Main A, Main B, Fill A, Fill B, Ending
- [ ] Pattern chaining for song arrangement
- [ ] Drum synthesis engine (kick, snare, hihat, etc.)
- [ ] PCM drum samples as alternative

### 4.3 Chord Memory
- [ ] 17+ chord types (major, minor, 7th, sus, dim, aug, etc.)
- [ ] Trigger chord from single key
- [ ] Chord inversion control
- [ ] Custom chord programming

### 4.4 Step Sequencer
- [ ] 16-step pattern sequencer
- [ ] Multiple lanes (note, velocity, gate, CC)
- [ ] Pattern length: 1-64 steps
- [ ] Real-time recording
- [ ] Song mode (chain patterns)

---

## Phase 5: SOUND LIBRARY

### 5.1 Preset Expansion (272 → 377) — PARTIAL ✓
- [x] Extended from 272 to 377 factory presets across all 15 categories
- [x] Piano: 15 presets (grand, upright, honky-tonk, bright, electric grand, etc.)
- [x] Organ: 15 presets (tonewheel, pipe, combo, cathedral, rock, jazz, etc.)
- [x] Guitar: 15 presets (acoustic, electric clean, distorted, nylon, bass, etc.)
- [x] Strings: 15 presets (ensemble, solo violin, cello, pizzicato, cinematic, etc.)
- [x] Brass: 15 presets (trumpet, trombone, sax, tuba, ensemble, synth brass, etc.)
- [x] Choir: 15 presets (ooh, aah, cathedral, boy choir, vocoder pad, etc.)
- [x] Percussion: 15 presets (kick, snare, hi-hat, toms, cymbals, mallet, etc.)
- [ ] Piano: add velocity-layered variations (pp, mf, ff)
- [ ] Expand to 1300+ total presets (more per category)
- [ ] PCM-based presets for realistic instruments (future with sample engine)

### 5.2 Category Expansion — COMPLETE ✓
- [x] Added categories: Piano, Organ, Guitar, Strings, Brass, Choir, Percussion
- [x] Category colors in preset browser UI
- [ ] Sub-categories within each main category
- [ ] Tag-based search across categories
- [ ] Author/creator filtering

### 5.3 Sound Design Tools
- [ ] Preset randomizer with lockable parameters
- [ ] A/B comparison (existing)
- [ ] Morph between presets (existing, enhance)
- [ ] Smart preset recommendations based on playing style
- [ ] Preset import/export (share with community)

---

## Phase 6: FILE PLAYBACK & I/O

### 6.1 Audio File Player
- [ ] WAV playback via USB/storage
- [ ] MP3 decoding
- [ ] AIFF support
- [ ] Center cancel (karaoke/vocal reduction)
- [ ] Playback controls: play, stop, FF, rewind
- [ ] Playlist management

### 6.2 MIDI File Player
- [ ] SMF Format 0 playback
- [ ] SMF Format 1 playback
- [ ] Tempo control
- [ ] Song position pointer
- [ ] Loop points

### 6.3 Recording
- [ ] Audio recording to WAV
- [ ] MIDI recording to SMF
- [ ] Multi-track recording
- [ ] Bounce to audio file

### 6.4 MIDI Enhancement
- [ ] Full MIDI CC mapping
- [ ] MIDI learn for all controls
- [ ] Program change send/receive
- [ ] SysEx support for patch transfer
- [ ] MIDI clock sync (send/receive)
- [ ] MPE (Multidimensional Polyphonic Expression) support

---

## Phase 7: ADVANCED SYNTHESIS

### 7.1 PCM Sample Engine
- [ ] SF2 (SoundFont 2) file loading
- [ ] SFZ file support
- [ ] Velocity layers and keyswitching
- [ ] Sample loop points
- [ ] Sample editor (trim, loop, crossfade)

### 7.2 Wavetable Synthesis
- [ ] Wavetable oscillator with position morphing
- [ ] Import wavetables from Serum, Vital formats
- [ ] Draw custom wavetables
- [ ] Wavetable position modulation (LFO, envelope, velocity)

### 7.3 FM Synthesis
- [ ] 4-operator FM engine
- [ ] Algorithm selection (8 algorithms like DX7)
- [ ] Operator feedback
- [ ] FM presets library

### 7.4 Physical Modeling
- [ ] Plucked string (Karplus-Strong)
- [ ] Bowed string
- [ ] Blown pipe (flute/brass)
- [ ] Drum membrane

### 7.5 Granular Synthesis
- [ ] Grain cloud engine
- [ ] Position, size, density, shape controls
- [ ] Freeze mode
- [ ] Scatter/stretch

---

## Phase 8: UI/UX POLISH

### 8.1 Keyboard UI
- [ ] Responsive piano keyboard with velocity sensitivity
- [ ] Multi-touch support (Android/iOS)
- [ ] Key labels (note names)
- [ ] Scale highlighting (major, minor, pentatonic, etc.)
- [ ] Glissando mode
- [ ] Adjustable keyboard size

### 8.2 Knob/Control UI
- [ ] High-quality knob widgets (existing, enhance)
- [ ] Value popup on adjustment
- [ ] Double-tap to reset to default
- [ ] Fine control (shift+drag)
- [ ] MIDI learn overlay

### 8.3 Preset Browser
- [ ] Category grid (like Juno-Di's 12 category buttons)
- [ ] Search with auto-complete
- [ ] Preset preview (play a chord when selecting)
- [ ] Recently used presets
- [ ] Favorites tab

### 8.4 Performance View
- [ ] Full-screen keyboard mode
- [ ] Quick access to favorites
- [ ] Real-time oscilloscope (existing)
- [ ] Spectrum analyzer (existing)
- [ ] Performance meters (CPU, voices, memory)

### 8.5 Settings
- [ ] Audio device selection with latency info
- [ ] Buffer size configuration
- [ ] Sample rate selection
- [ ] MIDI device management
- [ ] Theme customization (match synthwave palette)
- [ ] Backup/restore presets and settings

---

## Phase 9: PLATFORM & DISTRIBUTION

### 9.1 Android
- [ ] Replace PortAudio with Oboe/AAudio for low-latency Android audio
- [ ] MIDI via Android MIDI API (USB/BLE)
- [ ] Multi-touch optimization
- [ ] Battery optimization
- [ ] APK/AAB distribution

### 9.2 iOS (Future)
- [ ] Core Audio / AVAudioEngine backend
- [ ] AUv3 plugin version
- [ ] Inter-App Audio
- [ ] App Store distribution

### 9.3 Desktop (Linux/Windows/macOS)
- [ ] JACK audio support (Linux pro audio)
- [ ] ALSA direct (bypass PortAudio)
- [ ] VST/AU plugin version (future)
- [ ] Flatpak/Snap distribution (Linux)

### 9.4 Community
- [ ] Preset sharing platform
- [ ] Community patch library
- [ ] Tutorial system built into app
- [ ] Documentation wiki

---

## Implementation Priority Order

1. **Phase 0** — Audio stability (COMPLETE ✓)
2. **Phase 0.5** — Bugfix sprint: envelope fix, preset switching fix, preset audit (COMPLETE ✓)
3. **Phase 4.1** — Arpeggiator engine (COMPLETE ✓)
4. **Phase 1.1** — Polyphony increase to 64 with voice priority modes (COMPLETE ✓)
5. **Phase 1.5** — Envelope upgrades: curves, delay/hold, pitch envelope (COMPLETE ✓)
6. **Phase 1.2–1.4, 1.6** — Core engine upgrades: noise, sub-osc, FM, filter types/key-tracking/drive, LFO S&H/fade-in/tempo-sync/per-voice (PARTIAL ✓)
7. **Phase 5.1** — Preset expansion: 272 → 377 with 7 new categories (PARTIAL ✓)
8. **Phase 3.3** — Favorites system with setlists (COMPLETE ✓)
9. **Phase 2.2** — More effect types (quality of life)
10. **Phase 3.1** — Split & layer (essential keyboard feature)
11. **Phase 4.2** — Rhythm patterns (backing tracks)
12. **Phase 6.1** — Audio file playback (karaoke/practice)
13. **Phase 7.1** — PCM samples (realistic instruments)
14. Everything else in priority order

---

## Architecture Notes

### Audio Thread Safety Pattern
```
UI Thread (Dart)              Audio Thread (C++)
    |                              |
    | [Atomic Ring Buffer]         |
    | ---- param changes ---->     |
    |                              | drain queue at block start
    |                              | process block
    |                              | output to PortAudio
```

### PortAudio Lifecycle (Fixed)
```
App Start -> Pa_Initialize() once
  -> Enumerate devices (cached)
  -> Create engine
  -> Create stream (on first note or explicit)
  ...
  -> Stop stream
  -> Destroy stream
  -> Destroy engine
App Exit -> Pa_Terminate() once
```

### Multitimbral Architecture (Future)
```
Part 1 (Ch 1) --+-- Mix Bus -- FX 1/2/3 -- Master Out
Part 2 (Ch 2) --|
...             |
Part 16 (Ch 16)-+
```
