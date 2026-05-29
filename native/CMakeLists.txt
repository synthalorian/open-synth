cmake_minimum_required(VERSION 3.20)
project(openamp_dart_ffi VERSION 2.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Sources
set(SRC_DIR ${CMAKE_CURRENT_LIST_DIR}/src)
set(INC_DIR ${CMAKE_CURRENT_LIST_DIR}/include)

# ── Common sources (shared by all platforms) ───────────────────────────────
set(COMMON_SOURCES
    ${SRC_DIR}/envelope.cpp
    ${SRC_DIR}/oscillator.cpp
    ${SRC_DIR}/voice.cpp
    ${SRC_DIR}/voice_allocator.cpp
    ${SRC_DIR}/filter.cpp
    ${SRC_DIR}/lfo.cpp
    ${SRC_DIR}/arpeggiator.cpp
    ${SRC_DIR}/synth_engine.cpp
    ${SRC_DIR}/synth_preset.cpp
    ${SRC_DIR}/synth_ffi.cpp
    ${SRC_DIR}/synth_mixer.cpp
    ${SRC_DIR}/drum_synth.cpp
    ${SRC_DIR}/drum_kit_mapping.cpp
    ${SRC_DIR}/drum_ffi.cpp
    ${SRC_DIR}/wavetable_oscillator.cpp
    ${SRC_DIR}/wavetable_data.cpp
    ${SRC_DIR}/wavetable_bank.cpp
    ${SRC_DIR}/fx_engine.cpp
    ${SRC_DIR}/fx_eq.cpp
    ${SRC_DIR}/fx_limiter.cpp
    ${SRC_DIR}/fx_rotary.cpp
    ${SRC_DIR}/fx_tremolo.cpp
    ${SRC_DIR}/legacy_fx.cpp
)

# ── Platform-specific audio backend ────────────────────────────────────────
if(ANDROID)
    # ── Android: Oboe backend (vendored) ────────────────────────────────
    set(OBOE_DIR ${CMAKE_CURRENT_LIST_DIR}/oboe)

    file(GLOB_RECURSE OBOE_SOURCES
        "${OBOE_DIR}/src/aaudio/*.cpp"
        "${OBOE_DIR}/src/common/*.cpp"
        "${OBOE_DIR}/src/fifo/*.cpp"
        "${OBOE_DIR}/src/flowgraph/*.cpp"
        "${OBOE_DIR}/src/opensles/*.cpp"
    )

    add_library(oboe STATIC ${OBOE_SOURCES})

    target_include_directories(oboe
        PUBLIC
            ${OBOE_DIR}/include
        PRIVATE
            ${OBOE_DIR}/src
    )

    set(PLATFORM_SOURCES
        ${SRC_DIR}/oboe_audio_stream.cpp
        ${SRC_DIR}/oboe_audio_ffi.cpp
    )

    add_library(openamp_dart_ffi SHARED
        ${COMMON_SOURCES}
        ${PLATFORM_SOURCES}
    )

    target_include_directories(openamp_dart_ffi
        PUBLIC
            ${INC_DIR}
        PRIVATE
            ${SRC_DIR}
    )

    target_link_libraries(openamp_dart_ffi PRIVATE oboe log OpenSLES)

else()
    # ── Desktop: PortAudio backend ────────────────────────────────────────
    set(PLATFORM_SOURCES
        ${SRC_DIR}/audio_system.cpp
        ${SRC_DIR}/audio_stream.cpp
        ${SRC_DIR}/audio_stream_ffi.cpp
    )

    add_library(openamp_dart_ffi SHARED
        ${COMMON_SOURCES}
        ${PLATFORM_SOURCES}
    )

    target_include_directories(openamp_dart_ffi
        PUBLIC
            ${INC_DIR}
        PRIVATE
            ${SRC_DIR}
    )

    # Find and link PortAudio for real-time audio output
    find_package(PkgConfig QUIET)
    if(PkgConfig_FOUND)
        pkg_check_modules(PORTAUDIO portaudio-2.0)
    endif()

    if(PORTAUDIO_FOUND)
        target_include_directories(openamp_dart_ffi PRIVATE ${PORTAUDIO_INCLUDE_DIRS})
        target_link_libraries(openamp_dart_ffi PRIVATE ${PORTAUDIO_LIBRARIES})
        message(STATUS "PortAudio found: ${PORTAUDIO_LIBRARIES}")
    else()
        # Fallback: try linking directly
        find_library(PORTAUDIO_LIB portaudio)
        if(PORTAUDIO_LIB)
            target_link_libraries(openamp_dart_ffi PRIVATE ${PORTAUDIO_LIB})
            message(STATUS "PortAudio found via find_library: ${PORTAUDIO_LIB}")
        else()
            message(WARNING "PortAudio not found — audio stream will be stubs! Install portaudio-dev or libportaudio-dev")
        endif()
    endif()

endif()

# Set output name
if(NOT ANDROID)
    set_target_properties(openamp_dart_ffi PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
        OUTPUT_NAME "openamp_dart_ffi"
    )
else()
    set_target_properties(openamp_dart_ffi PROPERTIES
        OUTPUT_NAME "openamp_dart_ffi"
    )
endif()

# ── Test executable (build only when BUILD_TESTS=ON) ──────────────────────
option(BUILD_TESTS "Build the FX unit test executable" OFF)

if(BUILD_TESTS)
    add_executable(openamp_fx_tests
        ${SRC_DIR}/fx_tests.cpp
        ${SRC_DIR}/fx_eq.cpp
        ${SRC_DIR}/fx_limiter.cpp
        ${SRC_DIR}/fx_rotary.cpp
        ${SRC_DIR}/fx_tremolo.cpp
        ${SRC_DIR}/fx_engine.cpp
        ${SRC_DIR}/legacy_fx.cpp
    )

    target_include_directories(openamp_fx_tests PRIVATE ${INC_DIR})

    target_link_libraries(openamp_fx_tests PRIVATE)

    set_target_properties(openamp_fx_tests PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}/build"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}/build"
    )

    # AudioStream tests — only on desktop with PortAudio
    if(NOT ANDROID)
        if(PORTAUDIO_FOUND OR PORTAUDIO_LIB)
            add_executable(openamp_stream_tests
                ${SRC_DIR}/audio_stream_test.cpp
                ${SRC_DIR}/audio_stream.cpp
                ${SRC_DIR}/audio_system.cpp
            )
            target_include_directories(openamp_stream_tests PRIVATE ${INC_DIR})
            if(PkgConfig_FOUND)
                target_include_directories(openamp_stream_tests PRIVATE ${PORTAUDIO_INCLUDE_DIRS})
            endif()
            target_link_libraries(openamp_stream_tests PRIVATE ${PORTAUDIO_LIBRARIES} ${PORTAUDIO_LIB})
            set_target_properties(openamp_stream_tests PROPERTIES
                LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}/build"
                RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}/build"
            )
        endif()
    endif()
endif()

# Install target so the Flutter project can find it
install(TARGETS openamp_dart_ffi
    LIBRARY DESTINATION ${CMAKE_CURRENT_LIST_DIR}
)
