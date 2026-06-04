#include "sample_player.h"
#include <iostream>
#include <cmath>
#include <filesystem>

namespace fs = std::filesystem;

static bool floatEq(float a, float b, float eps = 1e-6f) {
    return std::fabs(a - b) < eps;
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: sample_player_block_test <samples_directory>\n";
        return 1;
    }

    fs::path samplesDir = argv[1];
    if (!fs::exists(samplesDir) || !fs::is_directory(samplesDir)) {
        std::cerr << "Invalid samples directory: " << samplesDir << "\n";
        return 1;
    }

    // Find first WAV file
    fs::path wavPath;
    for (const auto& categoryDir : fs::directory_iterator(samplesDir)) {
        if (!categoryDir.is_directory()) continue;
        for (const auto& entry : fs::directory_iterator(categoryDir)) {
            if (entry.is_regular_file() && entry.path().extension() == ".wav") {
                wavPath = entry.path();
                break;
            }
        }
        if (!wavPath.empty()) break;
    }

    if (wavPath.empty()) {
        std::cerr << "No WAV files found in " << samplesDir << "\n";
        return 1;
    }

    std::cout << "Using sample: " << wavPath << "\n";

    opensynth::SamplePlayer player;
    if (!player.loadSample(wavPath.string(), 60, 0, 127)) {
        std::cerr << "[FAIL] loadSample returned false\n";
        return 1;
    }

    player.prepare(48000.0);
    player.waitForPreload();
    player.setMixLevel(1.0f);
    player.setAttack(10.0f);
    player.setDecay(100.0f);
    player.setSustain(0.8f);
    player.setRelease(200.0f);

    constexpr int blockSize = 256;
    float outL[blockSize] = {};
    float outR[blockSize] = {};

    // Trigger note and process one block
    player.noteOn(60, 0.8f);
    player.processBlock(outL, outR, blockSize);

    float maxAbs = 0.0f;
    for (int i = 0; i < blockSize; ++i) {
        maxAbs = std::max(maxAbs, std::fabs(outL[i]));
        maxAbs = std::max(maxAbs, std::fabs(outR[i]));
    }

    if (maxAbs <= 0.0f) {
        std::cerr << "[FAIL] Block output is silent (maxAbs=" << maxAbs << ")\n";
        return 1;
    }

    std::cout << "[PASS] Block output maxAbs=" << maxAbs << "\n";

    // Test pitch bend: same note with +2 semitones should produce different output
    float outL_bend[blockSize] = {};
    float outR_bend[blockSize] = {};
    player.allNotesOff();
    player.setPitchBend(2.0f);
    player.noteOn(60, 0.8f);
    player.processBlock(outL_bend, outR_bend, blockSize);

    float diff = 0.0f;
    for (int i = 0; i < blockSize; ++i) {
        diff += std::fabs(outL[i] - outL_bend[i]) + std::fabs(outR[i] - outR_bend[i]);
    }

    if (diff <= 0.0f) {
        std::cerr << "[FAIL] Pitch bend produced identical output (diff=" << diff << ")\n";
        return 1;
    }

    std::cout << "[PASS] Pitch bend produces different output (diff=" << diff << ")\n";

    // Test ADSR: very short attack should reach higher peak faster
    player.allNotesOff();
    player.setPitchBend(0.0f);
    player.setAttack(0.1f);
    float outL_fast[blockSize] = {};
    float outR_fast[blockSize] = {};
    player.noteOn(60, 0.8f);
    player.processBlock(outL_fast, outR_fast, blockSize);

    float maxFast = 0.0f;
    for (int i = 0; i < 16; ++i) { // first 16 samples
        maxFast = std::max(maxFast, std::fabs(outL_fast[i]));
    }

    // Reset to slow attack for comparison
    player.allNotesOff();
    player.setAttack(1000.0f);
    float outL_slow[blockSize] = {};
    float outR_slow[blockSize] = {};
    player.noteOn(60, 0.8f);
    player.processBlock(outL_slow, outR_slow, blockSize);

    float maxSlow = 0.0f;
    for (int i = 0; i < 16; ++i) {
        maxSlow = std::max(maxSlow, std::fabs(outL_slow[i]));
    }

    if (maxFast <= maxSlow) {
        std::cerr << "[FAIL] Fast attack did not exceed slow attack (fast=" << maxFast << " slow=" << maxSlow << ")\n";
        return 1;
    }

    std::cout << "[PASS] ADSR attack responds to parameter (fast=" << maxFast << " slow=" << maxSlow << ")\n";

    std::cout << "\n=========================\n";
    std::cout << "All sample player block tests passed.\n";
    return 0;
}
