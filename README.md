# Open Synth 🎹🦈

**Open Synth** is a high-performance software synthesizer built with Flutter and the **OpenAmp** DSP engine. Designed for the neon-soaked aesthetics of 1984, it features a library of rich synthwave presets, a low-latency native audio backend, and a fully customizable synthesis engine.

## Features

- **Dual Oscillators:** Subtractive synthesis with Saw, Square, Triangle, Sine, Pulse, Noise (white/pink/brown), Wavetable, and Physical Modeling waveforms.
- **Sub-Oscillator & FM:** Square/Sine sub-oscillator (1-2 octaves below) and FM synthesis mode per oscillator.
- **Physical Modeling:** Karplus-Strong (guitar, bass, bright) and Modal synthesis (mallet, vibraphone, steel) for realistic acoustic instruments.
- **Resonant Filters:** Low-pass, High-pass, Band-pass, Notch, Low-shelf, High-shelf, and Peaking EQ with key tracking, drive stage, and envelope modulation.
- **Advanced Envelopes:** ADSR + Delay/Hold stages with exponential/linear/log curve shaping for both amplitude and filter.
- **Dual LFOs:** Multiple waveforms including S&H smoothed and random walk, with fade-in, tempo sync, per-voice mode, and multiple targets (Pitch, Filter, Amplitude, Pan).
- **Arpeggiator:** 5 patterns (Up, Down, Up/Down, Random, Chord) with adjustable tempo, octave range, gate, and resolution.
- **Rhythm Pattern Player:** 24 preset drum patterns across 9 genres with variations, song mode, and swing control.
- **64-Voice Polyphony:** Voice priority modes (newest, oldest, quietest, highest note) with intelligent voice stealing.
- **Multitimbral Engine:** 16-part multitimbral with per-part MIDI channel routing, volume, pan, mute, and solo.
- **Built-in FX:** Chorus, Delay, Reverb, Phaser, Flanger, Drive, and Compressor for that authentic retro sound.
- **Preset Library:** 1,415 factory presets across 15 categories — Synthwave, Pads, Leads, Bass, Keys, Arps, FX, Piano, Organ, Guitar, Strings, Brass, Choir, Percussion, and Custom.
- **Favorites & Setlists:** Star presets, reorder them, and organize into named setlists for live performance.
- **Recording:** WAV export with 16/24/32-bit depth, stereo output.
- **MIDI File I/O:** Import and export Standard MIDI Files (SMF) with tempo control.
- **Native Audio:** Uses the OpenAmp FFI engine for low-latency audio processing via PortAudio (desktop) or Oboe (Android).

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.11+ recommended)
- [PortAudio](http://www.portaudio.com/) (Required for native audio processing)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/synthalorian/open-synth.git
   cd open-synth
   ```

2. Fetch Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Ensure the native library is present:
   The project requires `libopenamp_dart_ffi.so` (Linux) or equivalent to be located in the `native/` directory.

4. Run the application:
   ```bash
   flutter run
   ```

## Building for Production

### Linux

The Linux build is configured to bundle the native library automatically.

```bash
flutter build linux --release
```
The resulting bundle will be in `build/linux/x64/release/bundle/`.

### Android (Experimental)

To build for Android, ensure the native libraries are placed in `android/app/src/main/jniLibs/` for each architecture (e.g., `arm64-v8a`, `x86_64`).

```bash
flutter build apk --release
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

- Developed by **synth (synthalorian)**.
- Audio engine powered by **OpenAmp**.
- Special thanks to the 1984 synthesis engine for the inspiration. 🎹🦈
