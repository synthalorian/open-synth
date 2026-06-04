#include "fx_vinyl_simulator.h"
#include <algorithm>
#include <cstdlib>

namespace opensynth {

VinylSimulatorProcessor::VinylSimulatorProcessor()
    : FxProcessor(FxType::VinylSimulator) {}

void VinylSimulatorProcessor::reset() {
    warpPhase_ = 0.0f;
    warpSampleL_ = 0.0f;
    warpSampleR_ = 0.0f;
    dustTimer_ = 0.0f;
    dustImpulse_ = 0.0f;
    scratchTimer_ = 0.0f;
    scratchRemaining_ = 0;
    scratchValue_ = 0.0f;
}

void VinylSimulatorProcessor::process(float& left, float& right, double sampleRate) {
    nativeSampleRate_ = sampleRate;

    float inL = left;
    float inR = right;

    // --- Warp pitch wobble (slow LFO ~0.3Hz) ---
    float warpFreq = 0.3f;
    warpPhase_ += warpFreq / static_cast<float>(nativeSampleRate_);
    if (warpPhase_ >= 1.0f) warpPhase_ -= 1.0f;
    float warpLfo = std::sin(warpPhase_ * 2.0f * 3.14159265f);
    float warpOffset = warpLfo * warp_ * 0.015f; // max 15ms variation

    float wetL = inL + (inL - warpSampleL_) * warpOffset;
    float wetR = inR + (inR - warpSampleR_) * warpOffset;
    warpSampleL_ = inL;
    warpSampleR_ = inR;

    // --- Dust crackle (random impulses) ---
    float dust = generateDust();
    wetL += dust * 0.3f;
    wetR += dust * 0.3f;

    // --- Scratch bursts ---
    float scratch = generateScratch();
    wetL += scratch * 0.4f;
    wetR += scratch * 0.4f;

    left = applyMix(inL, wetL);
    right = applyMix(inR, wetR);
}

float VinylSimulatorProcessor::generateDust() {
    // Random impulses at density controlled by dust_
    dustTimer_ -= 1.0f;
    if (dustTimer_ <= 0.0f) {
        float density = 0.001f + dust_ * 0.02f; // average ms between impulses
        dustTimer_ = density * static_cast<float>(nativeSampleRate_);
        if ((static_cast<float>(std::rand()) / static_cast<float>(RAND_MAX)) < dust_ * 0.3f) {
            dustImpulse_ = (static_cast<float>(std::rand()) / static_cast<float>(RAND_MAX)) * 2.0f - 1.0f;
        }
    }
    // Decay impulse
    dustImpulse_ *= 0.95f;
    return dustImpulse_;
}

float VinylSimulatorProcessor::generateScratch() {
    if (scratchRemaining_ > 0) {
        scratchRemaining_--;
        scratchValue_ *= 0.92f;
        return scratchValue_;
    }
    scratchTimer_ -= 1.0f;
    if (scratchTimer_ <= 0.0f) {
        scratchTimer_ = (2.0f + (static_cast<float>(std::rand()) / static_cast<float>(RAND_MAX)) * 5.0f) * static_cast<float>(nativeSampleRate_);
        if ((static_cast<float>(std::rand()) / static_cast<float>(RAND_MAX)) < scratch_ * 0.15f) {
            scratchRemaining_ = static_cast<int>(0.005f * static_cast<float>(nativeSampleRate_)); // 5ms burst
            scratchValue_ = (static_cast<float>(std::rand()) / static_cast<float>(RAND_MAX)) * 2.0f - 1.0f;
            return scratchValue_;
        }
    }
    return 0.0f;
}

void VinylSimulatorProcessor::setParam(int index, float value) {
    switch (index) {
    case DUST:    dust_ = std::clamp(value, 0.0f, 1.0f); break;
    case SCRATCH: scratch_ = std::clamp(value, 0.0f, 1.0f); break;
    case WARP:    warp_ = std::clamp(value, 0.0f, 1.0f); break;
    case MIX:     mix_ = value; break;
    default: break;
    }
}

float VinylSimulatorProcessor::getParam(int index) const {
    switch (index) {
    case DUST:    return dust_;
    case SCRATCH: return scratch_;
    case WARP:    return warp_;
    case MIX:     return mix_;
    default: return 0.0f;
    }
}

const char* VinylSimulatorProcessor::paramName(int index) const {
    switch (index) {
    case DUST:    return "Dust";
    case SCRATCH: return "Scratch";
    case WARP:    return "Warp";
    case MIX:     return "Mix";
    default: return "Unknown";
    }
}

} // namespace opensynth
