// Headless engine render test: reproduce what the app plays and measure noise.
// Usage: engine_render_test [seconds]  (run from repo root so samples/ resolves)
#include "synth_engine_wrapper.h"
#include "synth_engine.h"
#include "preset_data.h"
#include "preset_library_full.h"
#include "sample_player.h"
#include <juce_audio_basics/juce_audio_basics.h>
#include <juce_audio_formats/juce_audio_formats.h>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <vector>

using namespace opensynth;

int main(int argc, char** argv) {
    const double sr = 48000.0;
    const int block = 512;
    const int seconds = (argc > 1) ? std::atoi(argv[1]) : 6;

    fprintf(stderr, "[1] prepare\n"); fflush(stderr);
    SynthEngineWrapper w;
    w.prepare(sr, block);
    auto* engine = w.getEngine();
    if (!engine) { fprintf(stderr, "no engine\n"); return 1; }

    fprintf(stderr, "[2] sample player\n"); fflush(stderr);
    auto sp = std::make_unique<SamplePlayer>();
    sp->prepare(sr);
    engine->setSamplePlayer(std::move(sp));

    fprintf(stderr, "[3] apply preset\n"); fflush(stderr);
    // Grand Piano — juno-0001, first entry in the generated library
    applyPresetToEngine(kFullPresets[0], w);

    // Layer isolation modes: argv[2] = "synth" (no samples), "sample" (no osc), "both"
    const char* mode = (argc > 2) ? argv[2] : "both";
    if (std::strcmp(mode, "synth") == 0) {
        engine->getSamplePlayer()->setMixLevel(0.0f);
        fprintf(stderr, "mode=synth-only\n");
    } else if (std::strcmp(mode, "synthdry") == 0) {
        engine->getSamplePlayer()->setMixLevel(0.0f);
        engine->setReverbEnabled(false);
        w.setFxEnabled(1, false);
        w.setFxEnabled(2, false);
        w.setFxEnabled(3, false);
        fprintf(stderr, "mode=synth-dry (no samples, no FX)\n");
    } else if (std::strcmp(mode, "sine") == 0) {
        engine->getSamplePlayer()->setMixLevel(0.0f);
        w.setOsc1Waveform(0); // force plain sine — isolates osc path from downstream
        fprintf(stderr, "mode=synth-sine-only\n");
    } else if (std::strcmp(mode, "sample") == 0) {
        w.setOsc1Volume(0.0f);
        w.setOsc2Volume(0.0f);
        fprintf(stderr, "mode=sample-only\n");
    } else if (std::strcmp(mode, "split") == 0) {
        engine->getSamplePlayer()->setMixLevel(0.0f);
        w.setSplitEnabled(true);
        w.setSplitPoint(60);
        fprintf(stderr, "mode=split (low notes -> part 1 bass, high -> part 0)\n");
    } else if (std::strcmp(mode, "layer") == 0) {
        engine->getSamplePlayer()->setMixLevel(0.0f);
        w.setLayerEnabled(true);
        fprintf(stderr, "mode=layer (part 0 + detuned part 1)\n");
    }
    fprintf(stderr, "[4] wait preload\n"); fflush(stderr);
    engine->getSamplePlayer()->waitForPreload();
    fprintf(stderr, "[5] render\n"); fflush(stderr);
    printf("zones loaded: %d\n", engine->getSamplePlayer()->zoneCount());

    juce::AudioBuffer<float> buf(2, block);
    juce::MidiBuffer midi;
    const bool perfMode = std::strcmp(mode, "split") == 0 || std::strcmp(mode, "layer") == 0;
    if (perfMode) {
        // One note below the split point, one above
        midi.addEvent(juce::MidiMessage::noteOn(1, 48, (juce::uint8)100), 0);  // C3 — lower zone
        midi.addEvent(juce::MidiMessage::noteOn(1, 72, (juce::uint8)100), 0);  // C5 — upper zone
    } else {
        midi.addEvent(juce::MidiMessage::noteOn(1, 60, (juce::uint8)100), 0);
        midi.addEvent(juce::MidiMessage::noteOn(1, 64, (juce::uint8)100), 0);
        midi.addEvent(juce::MidiMessage::noteOn(1, 67, (juce::uint8)100), 0);
    }

    std::vector<float> rendered;
    rendered.reserve(static_cast<size_t>(seconds * sr) * 2);

    const int totalBlocks = static_cast<int>(seconds * sr) / block;
    const int bucketFrames = static_cast<int>(sr * 0.1); // 100ms buckets
    bool nanSeen = false;

    for (int b = 0; b < totalBlocks; ++b) {
        if (b % 50 == 0) { fprintf(stderr, "[block %d]\n", b); fflush(stderr); }
        buf.clear();
        // Let the param queue drain for the first blocks before the note —
        // render() processes MIDI before draining queued preset params, so a
        // block-0 noteOn would latch the default envelope.
        w.render(buf, b == 10 ? midi : juce::MidiBuffer());
        if (b == 11 && perfMode) {
            auto& alloc = engine->allocator();
            for (int v = 0; v < VoiceAllocator::MAX_VOICES; ++v) {
                auto* voice = alloc.voice(v);
                if (voice->active)
                    printf("  routed: note=%d -> part %d\n", voice->midiNote, voice->partIndex);
            }
        }
        for (int f = 0; f < block; ++f) {
            float l = buf.getSample(0, f), r = buf.getSample(1, f);
            if (std::isnan(l) || std::isinf(l) || std::isnan(r) || std::isinf(r)) nanSeen = true;
            rendered.push_back(l);
            rendered.push_back(r);
        }
    }

    // RMS per 100ms bucket (left channel)
    printf("\n100ms-bucket RMS profile (L):\n");
    size_t frames = rendered.size() / 2;
    for (size_t start = 0; start + bucketFrames <= frames; start += bucketFrames) {
        double sum = 0.0;
        float peak = 0.0f;
        for (size_t i = start; i < start + bucketFrames; ++i) {
            float s = rendered[i * 2];
            sum += static_cast<double>(s) * s;
            peak = std::max(peak, std::fabs(s));
        }
        double rms = std::sqrt(sum / bucketFrames);
        printf("  %4.1fs  rms=%.6f  peak=%.4f %s\n", start * 0.1, rms, peak,
               (rms > 0.001 && start > 40) ? "  <-- noise floor?" : "");
    }

    // Write WAV for listening
    juce::File out("/tmp/engine_render_piano.wav");
    out.deleteFile();
    juce::WavAudioFormat wav;
    auto os = out.createOutputStream();
    if (os) {
        auto* writer = wav.createWriterFor(os.get(), sr, 2, 16, {}, 0);
        if (writer) {
            os.release(); // writer takes ownership of the stream
            juce::AudioBuffer<float> wb(2, static_cast<int>(frames));
            for (size_t i = 0; i < frames; ++i) {
                wb.setSample(0, static_cast<int>(i), rendered[i * 2]);
                wb.setSample(1, static_cast<int>(i), rendered[i * 2 + 1]);
            }
            writer->writeFromAudioSampleBuffer(wb, 0, static_cast<int>(frames));
            delete writer;
            printf("\nwrote /tmp/engine_render_piano.wav\n");
        }
    }

    printf("NaN/Inf: %s\n", nanSeen ? "YES (BAD)" : "no");
    return nanSeen ? 1 : 0;
}
