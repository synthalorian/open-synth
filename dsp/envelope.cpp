#include "envelope.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

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
    lastOut_ = 0.0f;
    releaseStart_ = 0.0f;
    releasePhase_ = 0.0f;
    releaseAfterAttack_ = false;
}

void Envelope::noteOn() {
    if (delayMs_ > 0.0f) {
        state_ = DELAY;
    } else {
        state_ = ATTACK;
    }
    level_ = 0.0f;
    lastOut_ = 0.0f;
    releaseAfterAttack_ = false;
}

void Envelope::retrigger() {
    if (state_ == IDLE || lastOut_ <= 0.0f) {
        noteOn();
        return;
    }
    // Attack output is applyCurve(level_); invert it so the first attack
    // sample continues from lastOut_.
    const float out = std::clamp(lastOut_, 0.0f, 1.0f);
    float lin = out;
    switch (attackCurve_) {
    case EnvCurve::EXPONENTIAL: lin = 1.0f - std::cbrt(1.0f - out); break;  // inverse of 1-(1-x)^3
    case EnvCurve::LOGARITHMIC: lin = std::pow(out, 1.0f / 0.33f); break;   // inverse of x^0.33
    case EnvCurve::LINEAR:
    default: break;
    }
    level_ = std::clamp(lin, 0.0f, 1.0f);
    state_ = ATTACK;
    releaseAfterAttack_ = false;
}

void Envelope::noteOff() {
    if (state_ == IDLE || state_ == RELEASE) return;
    // Release from wherever the envelope currently is (attack, hold, decay,
    // sustain), not from the sustain level, so there is no step at noteOff.
    if ((state_ == DELAY || state_ == ATTACK) && lastOut_ <= 0.0f) {
        // Note-off before the envelope produced any output (e.g. note-on and
        // note-off in the same block): play the attack, then release, so very
        // short notes are still heard.
        releaseAfterAttack_ = true;
        return;
    }
    releaseStart_ = lastOut_;
    releasePhase_ = 0.0f;
    if (releaseStart_ <= 0.0f) {
        reset();
        return;
    }
    state_ = RELEASE;
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
    lastOut_ = processStage(sampleRate);
    return lastOut_;
}

float Envelope::processStage(double sampleRate) {
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
            if (releaseAfterAttack_) {
                releaseAfterAttack_ = false;
                releaseStart_ = 1.0f;
                releasePhase_ = 0.0f;
                state_ = RELEASE;
                return 1.0f;
            }
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

    case RELEASE: {
        // Release time is independent of the starting level.
        releasePhase_ += 1.0f / (releaseMs_ * 0.001f * static_cast<float>(sampleRate));
        if (releasePhase_ >= 1.0f) {
            releasePhase_ = 1.0f;
            level_ = 0.0f;
            state_ = IDLE;
            return 0.0f;
        }
        float curved = applyCurve(releasePhase_, releaseCurve_);
        level_ = releaseStart_ * (1.0f - curved);
        return level_;
    }

    default:
        break;
    }

    return level_;
}

} // namespace opensynth
