cmake_minimum_required(VERSION 3.22)
project(OpenSynth VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add JUCE
add_subdirectory(/home/synth/projects/juce JUCE_BUILD)

# Add CLAP JUCE extensions
add_subdirectory(libs/clap-juce-extensions EXCLUDE_FROM_ALL)

# Open Synth Plugin + Standalone
juce_add_plugin(OpenSynth
    COMPANY_NAME "SynthShark Audio"
    PLUGIN_MANUFACTURER_CODE "SynS"
    PLUGIN_CODE "OpSy"
    FORMATS Standalone VST3
    PRODUCT_NAME "Open Synth"
    MICROPHONE_PERMISSION_ENABLED TRUE
)

# Add CLAP target
clap_juce_extensions_plugin(TARGET OpenSynth
    CLAP_ID "audio.synthshark.opensynth"
    CLAP_FEATURES instrument synthesizer
)

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
target_link_libraries(OpenSynth PRIVATE
    juce::juce_audio_utils
    juce::juce_audio_processors
    juce::juce_audio_devices
    juce::juce_dsp
    juce::juce_gui_extra
    juce::juce_opengl
)

# Compile definitions
target_compile_definitions(OpenSynth PRIVATE
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0
    JUCE_VST3_CAN_REPLACE_VST2=0
    JUCE_DISPLAY_SPLASH_SCREEN=0
)

# Linux specific
if(UNIX AND NOT APPLE)
    target_link_libraries(OpenSynth PRIVATE pthread dl)
endif()
