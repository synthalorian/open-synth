#include "sample_player.h"
#include <iostream>
#include <filesystem>
#include <vector>
#include <string>

namespace fs = std::filesystem;

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: sample_load_test <samples_directory>\n";
        return 1;
    }

    fs::path samplesDir = argv[1];
    if (!fs::exists(samplesDir) || !fs::is_directory(samplesDir)) {
        std::cerr << "Invalid samples directory: " << samplesDir << "\n";
        return 1;
    }

    int total = 0;
    int passed = 0;
    int failed = 0;

    for (const auto& categoryDir : fs::directory_iterator(samplesDir)) {
        if (!categoryDir.is_directory()) continue;
        for (const auto& entry : fs::directory_iterator(categoryDir)) {
            if (!entry.is_regular_file()) continue;
            auto path = entry.path();
            if (path.extension() != ".wav") continue;

            ++total;
            opensynth::SamplePlayer player;
            bool ok = player.loadSample(path.string(), 60, 0, 127);
            if (ok) {
                ++passed;
                std::cout << "[PASS] " << path.string() << "\n";
            } else {
                ++failed;
                std::cerr << "[FAIL] " << path.string() << "\n";
            }
        }
    }

    std::cout << "\n=========================\n";
    std::cout << "Total:  " << total << "\n";
    std::cout << "Passed: " << passed << "\n";
    std::cout << "Failed: " << failed << "\n";

    return failed > 0 ? 1 : 0;
}
