# Open Synth 🎹🦞

**Open Synth** is a high-performance software synthesizer built with Flutter and the **OpenAmp** DSP engine. Designed for the neon-soaked aesthetics of 1984, it features a library of rich synthwave presets, a low-latency native audio backend, and a fully customizable synthesis engine.

## Features

- **Dual Oscillators:** Subtractive synthesis with Saw, Square, Triangle, and Noise waveforms.
- **Resonant Filters:** Low-pass, High-pass, and Band-pass filters with envelope modulation.
- **Dynamic Envelopes:** ADSR controls for both amplitude and filter cutoff.
- **LFO Modulation:** Dual LFOs with multiple targets (Pitch, Filter, Volume).
- **Built-in FX:** Chorus, Delay, Reverb, Phaser, and Drive for that authentic retro sound.
- **Preset Library:** A curated collection of factory presets optimized for synthwave production.
- **Native Audio:** Uses the OpenAmp FFI engine for low-latency audio processing via PortAudio.

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
- Special thanks to the 1984 synthesis engine for the inspiration. 🎹🦞
