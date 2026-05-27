#pragma once
#include <string>
#include <vector>
#include <cstdint>

namespace openamp {

class SynthPreset {
public:
    // Save current engine state to a preset file
    static int save(const SynthPreset& preset, const std::string& path, std::string& outputPath);

    // Load preset from a file
    static int load(const std::string& path, SynthPreset& preset, std::string& error);

    // Parameter storage (for JSON-like save/load)
    void setParam(const std::string& key, float value);
    float getParam(const std::string& key, float defaultValue = 0.0f) const;
    void setIntParam(const std::string& key, int value);
    int getIntParam(const std::string& key, int defaultValue = 0) const;

private:
    struct Param {
        std::string key;
        float value;
    };
    std::vector<Param> params_;
};

} // namespace openamp
