# OpenSynth Instrument Realism Roadmap
## Closing the Gap to Roland Juno-Di Sound Quality

---

## The Fundamental Problem

The Roland Juno-Di uses **PCM samples** (1000+ recorded waveforms) + analog modeling.
OpenSynth uses **pure synthesis** (wavetables, physical modeling, subtractive).

A 2048-sample single-cycle wavetable cannot capture:
- Hammer strike transients (piano)
- Tine behavior (electric piano)
- Bow noise (strings)
- Breath noise (brass/woodwind)
- Body resonance (guitar)
- Room ambience (drums)

**This is not a bug — it's an architectural limitation.** Without a PCM sample engine, we will never sound exactly like a Juno-Di. But we can get MUCH closer with better synthesis techniques.

---

## Current State Assessment

| Category | Presets | Waveform Used | Realism (1-10) | Main Issue |
|----------|---------|---------------|----------------|------------|
| **Piano** | 16 | wtPiano | 3 | No hammer transient, no string resonance, sounds organ-like |
| **Electric Piano** | 8 | wtPiano / triangle | 3 | No tine strike, no pickup noise |
| **Organ** | 16 | wtOrgan / subtractive | 4 | No drawbar mixing, no rotary speaker on presets |
| **Guitar** | 12 | wtGuitar / pmKarplus | 5 | KS is decent but no body resonance |
| **Strings** | 12 | wtStrings / saw | 4 | No bow noise, no ensemble spread |
| **Brass** | 10 | wtBrass / saw | 4 | Too clean, no breath noise |
| **Choir** | 8 | wtChoir | 3 | No formant filtering, sounds like cheap organ |
| **Drums** | 10 kits | Drum synthesis | 6 | Good for electronic, not acoustic |
| **Synth Pads** | 50+ | saw/square/triangle | 7 | This is our strength |
| **Synth Leads** | 50+ | saw/square | 7 | This is our strength |
| **Bass** | 40+ | saw/sine/square | 7 | This is our strength |

---

## Phase 1: Quick Wins (No New C++ Engine Code)

### 1.1 Better Preset Design

**Piano presets need:**
- FM-enabled osc2 for bell-like attack transient
- Noise burst on note-on (use noise waveform with fast envelope)
- Longer release with decay curve
- Key tracking on filter
- Velocity-sensitive filter opening

**Electric Piano (Rhodes) presets need:**
- Triangle + sine mix (not wtPiano)
- Filter envelope for "bark" character
- Chorus for stereo shimmer
- Short attack, medium decay, low sustain

**Organ presets need:**
- Multiple sine oscillators at harmonic ratios (drawbar emulation)
- Rotary effect (already implemented — wire it!)
- Percussive attack option (fast attack, immediate decay)

**Choir presets need:**
- Formant filter emulation (peaks at 500Hz, 1500Hz, 2500Hz)
- Multiple detuned voices (unison)
- Breath noise (subtle filtered noise)

### 1.2 Wavetable Improvements

Current wavetables use only 8 harmonics. Increase to 16-32 for richer timbres:

```cpp
// Current (8 harmonics)
float pianoHarmonics[] = {1.0, 0.5, 0.33, 0.2, 0.15, 0.1, 0.07, 0.05};

// Improved (16 harmonics with inharmonicity)
float pianoHarmonics[] = {
    1.00, 0.55, 0.35, 0.22, 0.15, 0.10, 0.08, 0.06,
    0.05, 0.04, 0.035, 0.03, 0.025, 0.02, 0.015, 0.01
};
// Add slight inharmonicity: freq * n * sqrt(1 + B*n^2) where B = 0.0004
```

### 1.3 Velocity Layer Enhancement

Current velocity layers only vary harmonic content. Add:
- Attack time variation (harder = faster attack)
- Filter cutoff variation (harder = brighter)
- Noise component variation (harder = more transient noise)

---

## Phase 2: New Synthesis Modes (C++ Engine Work)

### 2.1 FM Synthesis for EPiano/Bells

Add a proper FM operator pair:
- Carrier: sine wave
- Modulator: sine wave at harmonic ratio
- Modulation index envelope (fast decay for bell attack)
- Self-feedback for richer harmonics

**Use case:** Rhodes tine simulation, FM piano, bells, mallets.

### 2.2 Drawbar Organ Engine

Add a dedicated organ oscillator:
- 9 sine waves at drawbar frequencies (16', 5 1/3', 8', 4', 2 2/3', 2', 1 3/5', 1 1/3', 1')
- Individual level per drawbar
- Percussive envelope (fast attack, exponential decay)
- Leakage noise (subtle crosstalk between tones)

**Use case:** All organ presets, jazz organ, church organ.

### 2.3 Formant Filter for Choir/Voice

Add a vowel formant filter:
- 3-5 resonant peaks at vowel-specific frequencies
- Morphable between vowels (A, E, I, O, U)
- Excited by rich source (saw, pulse, or noise)

**Use case:** Choir, vocal pads, talk box effects.

### 2.4 Body Resonance for Guitar/Plucked

Extend Karplus-Strong with:
- Parallel resonant filters simulating guitar body
- Formant frequencies: ~100Hz (air), ~300Hz (wood), ~800Hz (bridge)
- Pick position simulation (filtering based on pluck point)

**Use case:** Acoustic guitar, harp, plucked strings.

### 2.5 Bow Noise for Strings

Add filtered noise to string presets:
- Pink noise, bandpass filtered
- Amplitude follows a slow envelope
- Stereo spread for ensemble effect

**Use case:** Violin, cello, string ensemble.

### 2.6 Breath Noise for Brass/Woodwind

Add breath simulation:
- Filtered noise (bandpass, 2-5kHz)
- Amplitude linked to note velocity
- Random modulation for realism

**Use case:** Trumpet, saxophone, flute.

---

## Phase 3: PCM Sample Engine (Major Architecture)

This is the ONLY way to truly match Juno-Di realism. Requires:

### 3.1 Sample Loader
- SFZ or SoundFont format support
- Multi-sample mapping (velocity layers, key ranges)
- Loop points for sustained sounds
- Release samples

### 3.2 Sample Playback Engine
- Pitch-shifted playback (resampling)
- ADSR envelope on samples
- Filter per voice
- Effects send

### 3.3 Sample Library
- Piano: Steinway/Rhodes/Wurlitzer samples (~100MB)
- Drums: Acoustic drum kit samples (~50MB)
- Orchestra: Strings/brass/woodwind sections (~200MB)
- Guitar: Acoustic/electric samples (~50MB)

**Trade-off:** This turns OpenSynth from a ~10MB synthesizer into a ~500MB sample player. It changes the project's character.

---

## Phase 4: Hybrid Approach (Recommended)

Keep synthesis for synth sounds, add lightweight sampling for acoustic instruments:

### 4.1 Short Sample Mode
- Only load attack transients (~0.1s per sample)
- Crossfade to synthesis for sustain/decay
- Dramatically reduces memory vs full samples

**Example:** Piano = real hammer strike sample (0.05s) → crossfade to wavetable sustain

### 4.2 Granular Synthesis
- Chop samples into 10-50ms grains
- Reassemble with randomization
- Creates organic variation without huge memory

### 4.3 Convolution Reverb
- Record impulse responses of real spaces
- Apply to synthesized sounds
- Makes synth piano sound like it's in a concert hall

---

## Immediate Action Items (Priority Order)

1. **Fix split keyboard bug** ✅ DONE
2. **Rewrite piano presets** — Add FM transient, noise burst, better envelopes
3. **Rewrite organ presets** — Use multiple sines, add rotary FX
4. **Rewrite choir presets** — Add formant filtering concept (even if simulated)
5. **Improve wavetable harmonic content** — 16+ harmonics, inharmonicity
6. **Add velocity-sensitive parameters** — Filter, attack, noise level
7. **Implement FM synthesis mode** — For EPiano, bells, mallets
8. **Implement drawbar organ** — 9-sine oscillator
9. **Add body resonance to KS** — For guitar realism
10. **Evaluate PCM sample engine** — Decide if/when to add sampling

---

## What the Juno-Di Actually Sounds Like

### Piano
- Bright, slightly compressed attack
- Short sustain (it's a stage piano, not a concert grand)
- Modest reverb tail
- Velocity layers: soft = mellow, hard = bright with more hammer noise

### Electric Piano
- Rhodes: bell-like attack, "bark" on hard strikes, tine chorus
- Wurlitzer: reedier, more midrange, less bell
- Both: mechanical key noise, stereo tremolo

### Organ
- Drawbar: 9 sliders controlling harmonic content
- Rotary: doppler + tremolo effect
- Percussion: short bright attack on top of sustained tone
- Key click: subtle mechanical noise

### Guitar
- Acoustic: pluck transient, body resonance, string decay
- Electric: pickup character, amp distortion option
- Both: position-dependent tone (bridge vs neck)

### Strings
- Section sound: multiple players, slight detune
- Bow noise: subtle scratch on attack
- Vibrato: delayed onset, natural variation
- Portamento: slide between notes

### Brass
- Lip buzz: rich harmonics, slightly unstable pitch
- Breath noise: subtle air sound
- Mutes: wah-wah, harmon, plunger effects
- Fall-off: pitch drop at note end

### Drums
- Kick: deep punch, short decay, felt beater
- Snare: crack + wire rattle, rimshot option
- Hats: tight closed, shimmering open
- Cymbals: crash (explosive), ride (ping + wash)
- Toms: melodic, resonant

### Choir
- "Ah" vowel: warm, formant peaks at 800Hz, 1200Hz
- "Oo" vowel: darker, lower formants
- Multiple voices: natural beat frequencies
- Breath: subtle noise between phrases

---

## Conclusion

OpenSynth's synthesis engine is actually quite capable. The drum synthesis, synth pads, leads, and bass are genuinely good. The weak spots are acoustic instrument emulation — piano, EP, organ, strings, brass, choir.

**Without a PCM sample engine, we'll never match a Juno-Di's acoustic instrument realism.** But we can get from "obviously synthetic" to "surprisingly close" with:
1. Better preset design (immediate)
2. New synthesis modes (FM, drawbar, formant — medium effort)
3. Hybrid sample+synthesis (long-term)

The split keyboard bug is now fixed. The instrument realism is the next frontier.
