#include "synth_preset.h"
#include <fstream>
#include <sstream>
#include <algorithm>
#include <cmath>

namespace opensynth {

void SynthPreset::setParam(const std::string& key, float value) {
    for (auto& p : params_) {
        if (p.key == key) {
            p.value = value;
            return;
        }
    }
    params_.push_back({key, value});
}

float SynthPreset::getParam(const std::string& key, float defaultValue) const {
    for (const auto& p : params_) {
        if (p.key == key) return p.value;
    }
    return defaultValue;
}

void SynthPreset::setIntParam(const std::string& key, int value) {
    setParam(key, static_cast<float>(value));
}

int SynthPreset::getIntParam(const std::string& key, int defaultValue) const {
    float v = getParam(key, static_cast<float>(defaultValue));
    return static_cast<int>(std::round(v));
}

int SynthPreset::save(const SynthPreset& preset, const std::string& path, std::string& outputPath) {
    std::ofstream file(path);
    if (!file.is_open()) return -1;

    for (const auto& p : preset.params_) {
        file << p.key << "=" << p.value << "\n";
    }
    outputPath = path;
    return 0;
}

int SynthPreset::load(const std::string& path, SynthPreset& preset, std::string& error) {
    std::ifstream file(path);
    if (!file.is_open()) {
        error = "Could not open file: " + path;
        return -1;
    }

    std::string line;
    int lineNum = 0;
    while (std::getline(file, line)) {
        lineNum++;
        // Skip comments and empty lines
        if (line.empty() || line[0] == '#' || line[0] == ';') continue;

        auto eq = line.find('=');
        if (eq == std::string::npos) {
            error = "Invalid syntax at line " + std::to_string(lineNum) + ": " + line;
            return -1;
        }

        std::string key = line.substr(0, eq);
        std::string val = line.substr(eq + 1);

        try {
            float fval = std::stof(val);
            preset.setParam(key, fval);
        } catch (...) {
            // Store as string? For now skip non-float values
            continue;
        }
    }

    return 0;
}

} // namespace opensynth
