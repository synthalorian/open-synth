cmake_minimum_required(VERSION 3.22)
project(OpenSynth VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add JUCE
add_subdirectory(/home/synth/projects/juce JUCE_BUILD)

# Add CLAP JUCE extensions
add_subdirectory(libs/clap-juce-extensions EXCLUDE_FROM_ALL)

# ── iOS / Android detection ──────────────────────────────────────────────────
set(IS_IOS FALSE)
set(IS_ANDROID FALSE)
if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    set(IS_IOS TRUE)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Android")
    set(IS_ANDROID TRUE)
endif()

# ── Determine formats ────────────────────────────────────────────────────────
# On iOS/Android we build only Standalone (AUv3 is also possible on iOS via Xcode).
# On desktop we build Standalone + VST3 + CLAP.
if(IS_IOS OR IS_ANDROID)
    set(OPEN_SYNTH_FORMATS Standalone)
else()
    set(OPEN_SYNTH_FORMATS Standalone VST3)
endif()

# ── Open Synth Plugin + Standalone ───────────────────────────────────────────
juce_add_plugin(OpenSynth
    COMPANY_NAME "SynthShark Audio"
    PLUGIN_MANUFACTURER_CODE "SynS"
    PLUGIN_CODE "OpSy"
    FORMATS ${OPEN_SYNTH_FORMATS}
    PRODUCT_NAME "Open Synth"
    BUNDLE_ID "com.synthshark.opensynth"
    MICROPHONE_PERMISSION_ENABLED TRUE
    MICROPHONE_PERMISSION_TEXT "Open Synth needs microphone access for audio recording."
    # iOS specific
    BACKGROUND_AUDIO_ENABLED TRUE
    STATUS_BAR_HIDDEN TRUE
    REQUIRES_FULL_SCREEN FALSE
    IPHONE_SCREEN_ORIENTATIONS UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
    IPAD_SCREEN_ORIENTATIONS UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
    TARGETED_DEVICE_FAMILY "1,2"
    ICON_BIG "${CMAKE_CURRENT_SOURCE_DIR}/assets/icon_1024.png"
    ICON_SMALL "${CMAKE_CURRENT_SOURCE_DIR}/assets/icon_512.png"
    # Android specific (no-op on other platforms)
    NEEDS_CURL FALSE
    NEEDS_WEB_BROWSER FALSE
)

# Add CLAP target (desktop only)
if(NOT IS_IOS AND NOT IS_ANDROID)
    clap_juce_extensions_plugin(TARGET OpenSynth
        CLAP_ID "audio.synthshark.opensynth"
        CLAP_FEATURES instrument synthesizer
    )
endif()

# Source files
set(OPENSYNTH_SOURCES
    src/plugin_processor.cpp
    src/plugin_editor.cpp
    src/synth_engine_wrapper.cpp
    src/preset_data.cpp
    src/instrument_realism.cpp
    src/user_preset_manager.cpp
    src/app_state_manager.cpp
)

# DSP engine sources (ported from Flutter FFI)
set(DSP_SOURCES
    dsp/voice.cpp
    dsp/voice_allocator.cpp
    dsp/oscillator.cpp
    dsp/envelope.cpp
    dsp/filter.cpp
    dsp/lfo.cpp
    dsp/arpeggiator.cpp
    dsp/drum_synth.cpp
    dsp/drum_kit_mapping.cpp
    dsp/rhythm_pattern_player.cpp
    dsp/wavetable_oscillator.cpp
    dsp/wavetable_data.cpp
    dsp/wavetable_bank.cpp
    dsp/physical_model.cpp
    dsp/synth_engine.cpp
    dsp/synth_preset.cpp
    dsp/synth_ffi.cpp
    dsp/synth_mixer.cpp
    dsp/recorder.cpp
    dsp/midi_file.cpp
    dsp/sample_player.cpp
    dsp/sample_stream.cpp
    dsp/fx_engine.cpp
    dsp/legacy_fx.cpp
    dsp/fx_eq.cpp
    dsp/fx_limiter.cpp
    dsp/fx_rotary.cpp
    dsp/fx_tremolo.cpp
    dsp/fx_autowah.cpp
    dsp/fx_bitcrusher.cpp
    dsp/fx_ringmod.cpp
    dsp/fx_pitchshift.cpp
    dsp/fx_multitap_delay.cpp
    dsp/fx_pingpong_delay.cpp
    dsp/fx_spring_reverb.cpp
    dsp/fx_gated_reverb.cpp
    dsp/fx_amp_sim.cpp
    dsp/fx_stereo_widener.cpp
    dsp/fx_vocoder.cpp
)

target_sources(OpenSynth PRIVATE 
    ${OPENSYNTH_SOURCES}
    ${DSP_SOURCES}
)

target_include_directories(OpenSynth PRIVATE 
    src
    dsp
    include
)

# JUCE modules
# juce_audio_devices is required for mobile audio I/O (CoreAudio on iOS, Oboe/AAudio on Android)
target_link_libraries(OpenSynth PRIVATE
    juce::juce_audio_utils
    juce::juce_audio_processors
    juce::juce_audio_devices
    juce::juce_dsp
    juce::juce_gui_extra
    juce::juce_opengl
)

# Compile definitions
# JUCE_USE_ANDROID_OBOE ensures AAudio/Oboe path on Android when available.
target_compile_definitions(OpenSynth PRIVATE
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0
    JUCE_VST3_CAN_REPLACE_VST2=0
    JUCE_DISPLAY_SPLASH_SCREEN=0
    JUCE_USE_ANDROID_OBOE=1
)

# Linux specific
if(UNIX AND NOT APPLE AND NOT IS_ANDROID)
    target_link_libraries(OpenSynth PRIVATE pthread dl)
endif()

# iOS / Android specific linker/framework tweaks
if(IS_IOS)
    # Ensure we link the required iOS frameworks for audio
    target_link_libraries(OpenSynth PRIVATE
        "-framework AudioToolbox"
        "-framework AVFoundation"
        "-framework CoreAudio"
        "-framework CoreMIDI"
        "-framework Accelerate"
    )
elseif(IS_ANDROID)
    # Android NDK already provides OpenSL ES / AAudio via juce_audio_devices,
    # but we explicitly ensure log linking.
    target_link_libraries(OpenSynth PRIVATE log)
endif()
