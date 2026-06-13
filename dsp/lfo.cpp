#include "lfo.h"
#include <algorithm>
#include <cstdlib>

namespace opensynth {

void LFO::setWaveform(int w) {
    waveform_ = static_cast<Waveform>(std::clamp(w, 0, 6));
}

void LFO::setRate(float hz) {
    rate_ = std::clamp(hz, 0.01f, 50.0f);
}

void LFO::setDepth(float depth) {
    depth_ = std::clamp(depth, 0.0f, 1.0f);
}

void LFO::setTarget(int target) {
    target_ = static_cast<Target>(std::clamp(target, 0, 3));
}

void LFO::setFadeIn(float seconds) {
    fadeIn_ = std::clamp(seconds, 0.0f, 10.0f);
}

void LFO::setTempoSync(bool enabled) {
    tempoSync_ = enabled;
}

void LFO::setTempoNoteDivision(int div) {
    tempoNoteDivision_ = std::clamp(div, 1, 64);
}

void LFO::setTempoRateBpm(float bpm, int division) {
    // Convert BPM + note division to Hz
    // division: 1=whole, 2=half, 4=quarter, 8=eighth, 16=16th
    float beatsPerSecond = bpm / 60.0f;
    float notesPerBeat = static_cast<float>(division) / 4.0f; // quarter=1, eighth=2, etc.
    rate_ = beatsPerSecond * notesPerBeat;
    tempoNoteDivision_ = division;
}

void LFO::prepare(double sampleRate) {
    sampleRate_ = sampleRate;
    phaseIncrement_ = rate_ / sampleRate_;
}

void LFO::reset() {
    phase_ = 0.0;
    value_ = 0.0f;
    currentTarget_ = 0.0f;
    previousTarget_ = 0.0f;
    smoothPhase_ = 0.0f;
    fadeInPhase_ = 0.0f;
    fadeInComplete_ = (fadeIn_ <= 0.0f);
}

float LFO::randomValue() {
    return 2.0f * static_cast<float>(std::rand()) / static_cast<float>(RAND_MAX) - 1.0f;
}

float LFO::process() {
    if (phaseIncrement_ <= 0.0) {
        prepare(sampleRate_);
    }

    // Advance phase
    phase_ += phaseIncrement_;
    if (phase_ >= 1.0) phase_ -= 1.0;

    // Generate waveform
    float v = 0.0f;
    switch (waveform_) {
    case Waveform::SINE:
        v = static_cast<float>(std::sin(2.0 * M_PI * phase_));
        break;
    case Waveform::TRIANGLE:
        v = 4.0f * std::abs(static_cast<float>(phase_) - 0.5f) - 1.0f;
        break;
    case Waveform::SAW:
        v = 2.0f * static_cast<float>(phase_) - 1.0f;
        break;
    case Waveform::SQUARE:
        v = phase_ < 0.5f ? 1.0f : -1.0f;
        break;
    case Waveform::RANDOM_SH:
        // Sample-and-hold: pick a new random target when phase wraps
        if (phase_ < phaseIncrement_) {
            currentTarget_ = randomValue();
        }
        v = currentTarget_;
        break;
    case Waveform::SMOOTHED_SH:
        // Smoothed S&H: interpolate between random targets
        if (phase_ < phaseIncrement_) {
            previousTarget_ = currentTarget_;
            currentTarget_ = randomValue();
            smoothPhase_ = 0.0;
        }
        // Interpolate linearly between previous and current target
        if (phaseIncrement_ > 0.0) {
            smoothPhase_ = static_cast<float>(phase_) / static_cast<float>(phaseIncrement_);
            smoothPhase_ = std::min(smoothPhase_, 1.0f);
        } else {
            smoothPhase_ = 1.0f;
        }
        v = previousTarget_ + (currentTarget_ - previousTarget_) * smoothPhase_;
        break;
    case Waveform::RANDOM_WALK:
        // Random walk: drift randomly at audio rate with rate-controlled stepping
        // Use a step counter to slow down the random updates
        {
            static float walkTarget = 0.0f;
            // Update the walk target at multiples of the LFO rate
            if (phase_ < phaseIncrement_) {
                walkTarget = randomValue() * 0.3f; // Smaller steps for walk
            }
            // Smoothly follow the walk target
            currentTarget_ += (walkTarget - currentTarget_) * 0.01f;
            v = currentTarget_;
        }
        break;
    }

    // Apply fade-in
    float fadeGain = 1.0f;
    if (!fadeInComplete_) {
        fadeInPhase_ += static_cast<float>(phaseIncrement_);
        float fadeDuration = fadeIn_ * static_cast<float>(rate_);
        if (fadeDuration > 0.0f) {
            fadeGain = std::min(fadeInPhase_ / fadeDuration, 1.0f);
        } else {
            fadeGain = 1.0f;
        }
        if (fadeGain >= 1.0f) {
            fadeInComplete_ = true;
        }
    }

    // Scale by depth (0..1) and fade-in
    value_ = v * depth_ * fadeGain;
    return value_;
}

} // namespace opensynth
