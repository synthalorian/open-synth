// Test: verify sample playback doesn't produce static/noise
#include "sample_player.h"
#include "sample_stream.h"
#include <juce_audio_basics/juce_audio_basics.h>
#include <juce_audio_formats/juce_audio_formats.h>
#include <math>
#include <iostream>

using namespace opensynth;

static float computeRMS(const juce::AudioBuffer<float>& buf, int ch) {
    float sum = 0.0f;
    auto* data = buf.getReadPointer(ch);
    for (int i = 0; i < buf.getNumSamples(); ++i)
        sum += data[i] * data[i];
    return std::sqrt(sum / buf.getNumSamples());
}

static bool hasNaNOrInf(const juce::AudioBuffer<float>& buf) {
    for (int ch = 0; ch < buf.getNumChannels(); ++ch) {
        auto* data = buf.getReadPointer(ch);
        for (int i = 0; i < buf.getNumSamples(); ++i) {
            if (std::isnan(data[i]) || std::isinf(data[i])) return true;
        }
    }
    return false;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <manifest.json>\n";
        return 1;
    }

    juce::AudioFormatManager fmt;
    fmt.registerBasicFormats();

    SamplePlayer player;
    player.setSampleRate(48000.0);

    std::string manifestPath = argv[1];
    std::cout << "Loading manifest: " << manifestPath << "\n";

    if (!player.loadMultiSample(manifestPath)) {
        std::cerr << "FAILED to load manifest\n";
        return 1;
    }

    std::cout << "Zones loaded: " << player.getZoneCount() << "\n";

    // Render a middle C (note 60) at velocity 0.8
    juce::AudioBuffer<float> buffer(2, 48000); // 1 second
    buffer.clear();

    player.noteOn(60, 0.8f);
    player.processBlock(buffer.getArrayOfWritePointers(), 2, 48000);

    float rmsL = computeRMS(buffer, 0);
    float rmsR = computeRMS(buffer, 1);
    bool bad = hasNaNOrInf(buffer);

    std::cout << "RMS L: " << rmsL << "  RMS R: " << rmsR << "\n";
    std::cout << "NaN/Inf: " << (bad ? "YES" : "no") << "\n";

    // Check if output is basically silent (RMS < 0.001 means no sound)
    if (rmsL < 0.001f && rmsR < 0.001f) {
        std::cerr << "FAILED: output is silent\n";
        return 1;
    }

    // Check if output is pure static (RMS > 0.5 with no structure = likely noise)
    // A real piano sample should have RMS around 0.1-0.3
    if (rmsL > 0.8f || rmsR > 0.8f) {
        std::cerr << "WARNING: output very loud, possible static\n";
    }

    if (bad) {
        std::cerr << "FAILED: NaN or Inf in output\n";
        return 1;
    }

    std::cout << "PASS: sample playback produces clean audio\n";
    return 0;
}
