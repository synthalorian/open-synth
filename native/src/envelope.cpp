#include "envelope.h"
#include <algorithm>

namespace openamp {

void Envelope::setAttack(float ms) { attackMs_ = ms < 0.1f ? 0.1f : ms; }
void Envelope::setDecay(float ms) { decayMs_ = ms < 1.0f ? 1.0f : ms; }
void Envelope::setSustain(float level) { sustainLevel_ = std::clamp(level, 0.0f, 1.0f); }
void Envelope::setRelease(float ms) { releaseMs_ = ms < 1.0f ? 1.0f : ms; }
void Envelope::setDelay(float ms) { delayMs_ = std::clamp(ms, 0.0f, 2000.0f); }
void Envelope::setHold(float ms) { holdMs_ = std::clamp(ms, 0.0f, 2000.0f); }
void Envelope::setAttackCurve(int c) { attackCurve_ = static_cast<EnvCurve>(std::clamp(c, 0, 2)); }
void Envelope::setDecayCurve(int c) { decayCurve_ = static_cast<EnvCurve>(std::clamp(c, 0, 2)); }
void Envelope::setReleaseCurve(int c) { releaseCurve_ = static_cast<EnvCurve>(std::clamp(c, 0, 2)); }

void Envelope::reset() {
    state_ = IDLE;
    level_ = 0.0f;
}

void Envelope::noteOn() {
    if (delayMs_ > 0.0f) {
        state_ = DELAY;
    } else {
        state_ = ATTACK;
    }
    level_ = 0.0f;
}

void Envelope::noteOff() {
    if (state_ != IDLE) {
        state_ = RELEASE;
    }
}

float Envelope::applyCurve(float linearPhase, EnvCurve curve) const {
    // linearPhase: 0..1 representing progress through the stage
    switch (curve) {
    case EnvCurve::EXPONENTIAL:
        // exp curve: fast start, slow end
        return 1.0f - std::pow(1.0f - linearPhase, 3.0f);
    case EnvCurve::LOGARITHMIC:
        // log curve: slow start, fast end
        return std::pow(linearPhase, 0.33f);
    case EnvCurve::LINEAR:
    default:
        return linearPhase;
    }
}

float Envelope::process(double sampleRate) {
    if (state_ == IDLE) return 0.0f;

    switch (state_) {
    case DELAY:
        rate_ = delayMs_ > 0.0f ? 1.0f / (delayMs_ * 0.001f * sampleRate) : 1.0f;
        level_ += rate_;
        if (level_ >= 1.0f) {
            level_ = 0.0f;
            state_ = ATTACK;
        }
        return 0.0f;

    case ATTACK:
        rate_ = 1.0f / (attackMs_ * 0.001f * sampleRate);
        level_ += rate_;
        if (level_ >= 1.0f) {
            level_ = 1.0f;
            if (holdMs_ > 0.0f) {
                state_ = HOLD;
                holdPhase_ = 0.0f;
            } else {
                state_ = DECAY;
            }
        }
        // Apply curve: map linear ramp to shaped envelope
        return applyCurve(level_, attackCurve_);

    case HOLD: {
        float holdRate = holdMs_ > 0.0f ? 1.0f / (holdMs_ * 0.001f * sampleRate) : 1.0f;
        holdPhase_ += holdRate;
        if (holdPhase_ >= 1.0f) {
            level_ = 1.0f;
            state_ = DECAY;
        }
        return 1.0f;
    }

    case DECAY:
        rate_ = 1.0f / (decayMs_ * 0.001f * sampleRate);
        level_ -= rate_;
        if (level_ <= sustainLevel_) {
            level_ = sustainLevel_;
            if (sustainLevel_ == 0.0f) {
                state_ = IDLE;
            } else {
                state_ = SUSTAIN;
            }
        }
        // level_ goes from 1.0 down to sustainLevel_
        // Map to 0..1 curve phase: 0=peak, 1=sustain
        {
            float range = 1.0f - sustainLevel_;
            float phase = (range > 0.0f) ? (1.0f - level_) / range : 1.0f;
            phase = std::clamp(phase, 0.0f, 1.0f);
            float curved = applyCurve(phase, decayCurve_);
            return 1.0f - curved * range;
        }

    case SUSTAIN:
        return sustainLevel_;

    case RELEASE:
        rate_ = 1.0f / (releaseMs_ * 0.001f * sampleRate);
        level_ -= rate_;
        if (level_ <= 0.0f) {
            level_ = 0.0f;
            state_ = IDLE;
        }
        // level_ goes from sustainLevel_ down to 0
        // Map to 0..1 curve phase: 0=start of release, 1=silence
        {
            float phase = sustainLevel_ > 0.0f ? 1.0f - (level_ / sustainLevel_) : 1.0f;
            phase = std::clamp(phase, 0.0f, 1.0f);
            float curved = applyCurve(phase, releaseCurve_);
            return sustainLevel_ * (1.0f - curved);
        }

    default:
        break;
    }

    return level_;
}

} // namespace openamp
