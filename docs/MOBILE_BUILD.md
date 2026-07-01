# Mobile Build Instructions — iOS & Android

This document covers building Open Synth standalone apps for iOS and Android.

## Prerequisites

- Same repo setup as desktop: `git clone --recurse-submodules`
- JUCE submodule at `/home/synth/projects/juce` (or adjust `CMakeLists.txt`)

---

## iOS (Xcode)

### 1. Generate Xcode project

```bash
cd /home/synth/projects/open-synth
mkdir build-ios && cd build-ios
cmake .. -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
```

- `-G Xcode` is **required** — JUCE only enables AUv3 wrappers with the Xcode generator.
- `CMAKE_OSX_ARCHITECTURES` can be `arm64` only for device-only builds.

### 2. Build

```bash
cmake --build . --config Release --target OpenSynth_Standalone
```

Or open `OpenSynth.xcodeproj` in Xcode and build the **OpenSynth_Standalone** scheme.

### 3. Run / Archive

- For simulator: select any iOS Simulator destination.
- For device: connect an iPhone/iPad, select it, and build.
- For App Store: use **Product → Archive**.

### iOS-specific CMake options already set in `CMakeLists.txt`

| Option | Value | Purpose |
|--------|-------|---------|
| `BUNDLE_ID` | `com.synthclaw.opensynth` | App Store / signing identifier |
| `MICROPHONE_PERMISSION_ENABLED` | `TRUE` | Adds `NSMicrophoneUsageDescription` to `Info.plist` |
| `BACKGROUND_AUDIO_ENABLED` | `TRUE` | Allows audio in background |
| `STATUS_BAR_HIDDEN` | `TRUE` | Immersive full-screen UI |
| `REQUIRES_FULL_SCREEN` | `FALSE` | Supports split-screen / Slide Over |
| `IPHONE_SCREEN_ORIENTATIONS` | Portrait + Landscape | Flexible orientation |
| `IPAD_SCREEN_ORIENTATIONS` | Portrait + Landscape | Flexible orientation |
| `TARGETED_DEVICE_FAMILY` | `"1,2"` | iPhone + iPad |
| `ICON_BIG` / `ICON_SMALL` | `assets/icon_1024.png` / `512.png` | App icon sources |

---

## Android (Gradle / CMake)

### 1. Install Android SDK & NDK

Ensure you have:
- Android SDK (API 33+ recommended)
- Android NDK r25c or newer
- CMake 3.22+ inside SDK or system

### 2. Build with Gradle (recommended)

JUCE ships with an Android exporter that generates a Gradle project. The simplest path is:

```bash
cd /home/synth/projects/open-synth
mkdir build-android && cd build-android

# Configure for Android
cmake .. \
  -DCMAKE_SYSTEM_NAME=Android \
  -DCMAKE_ANDROID_NDK=$ANDROID_NDK_HOME \
  -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a \
  -DCMAKE_ANDROID_API=33 \
  -DCMAKE_BUILD_TYPE=Release

# Build standalone APK wrapper libraries
cmake --build . --target OpenSynth_Standalone --config Release
```

JUCE’s CMake support for Android will emit a Gradle-compatible project structure under the build directory. You can then:

```bash
cd OpenSynth_artefacts/Release/Standalone   # or the generated android folder
cp -r ...  # follow JUCE Android build output instructions
```

For a fully integrated Gradle build, consider using **Projucer** to export an Android Studio project, or use the **JUCE Android CMake** experimental path with `android_gradle_build`.

### Android-specific CMake options already set in `CMakeLists.txt`

| Option | Value | Purpose |
|--------|-------|---------|
| `JUCE_USE_ANDROID_OBOE` | `1` | Prefer AAudio/Oboe audio backend |
| `NEEDS_CURL` / `NEEDS_WEB_BROWSER` | `FALSE` | Avoid heavy dependencies |
| `log` linked | — | Android logging (`__android_log_print`) |

---

## Mobile UI Considerations

The current desktop-oriented editor (`plugin_editor.cpp`) uses small rotary knobs and dense layouts. For a great mobile experience, consider these adaptations **in a future PR**:

1. **Touch targets**: Increase minimum hit area to 44 × 44 pt (iOS HIG) / 48 dp (Android).
2. **Zoom / scroll**: Wrap the editor in a `juce::Viewport` or use a tabbed layout.
3. **Virtual keyboard**: On iOS/Android there is no physical MIDI keyboard by default. Add an on-screen piano component (`juce::MidiKeyboardComponent`) scaled for touch.
4. **Orientation**: The CMake config already allows both portrait and landscape. Test layout in both.
5. **File access**: Mobile sandboxes restrict file I/O. Use `juce::File::getSpecialLocation()` for documents/presets.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `AUv3` target missing on iOS | Ensure `-G Xcode` is used; AUv3 is disabled for other generators. |
| Microphone permission denied | Verify `MICROPHONE_PERMISSION_TEXT` is set (non-empty). |
| Android link errors about `oboe` | Ensure NDK is r25c+ and `JUCE_USE_ANDROID_OBOE=1` is defined. |
| App icon not showing | Check `assets/icon_1024.png` and `icon_512.png` exist; regenerate build. |

---

## Related Files

- `/home/synth/projects/open-synth/CMakeLists.txt` — main build configuration
- `/home/synth/projects/open-synth/assets/icon.png` — source icon (resized to 512/1024 automatically)
