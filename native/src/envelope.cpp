#include "envelope.h"
#include <algorithm>

namespace openamp {

void Envelope::setAttack(float ms) { attackMs_ = ms < 0.1f ? 0.1f : ms; }
void Envelope::setDecay(float ms) { decayMs_ = ms < 1.0f ? 1.0f : ms; }
void Envelope::setSustain(float level) { sustainLevel_ = std::clamp(level, 0.0f, 1.0f); }
void Envelope::setRelease(float ms) { releaseMs_ = ms < 1.0f ? 1.0f : ms; }

void Envelope::reset() {
    state_ = IDLE;
    level_ = 0.0f;
}

void Envelope::noteOn() {
    state_ = ATTACK;
    level_ = 0.0f;
}

void Envelope::noteOff() {
    if (state_ != IDLE) {
        state_ = RELEASE;
    }
}

float Envelope::process(double sampleRate) {
    if (state_ == IDLE) return 0.0f;

    switch (state_) {
    case ATTACK:
        rate_ = 1.0f / (attackMs_ * 0.001f * sampleRate);
        level_ += rate_;
        if (level_ >= 1.0f) {
            level_ = 1.0f;
            state_ = DECAY;
        }
        break;

    case DECAY:
        rate_ = 1.0f / (decayMs_ * 0.001f * sampleRate);
        level_ -= rate_;
        if (level_ <= sustainLevel_) {
            level_ = sustainLevel_;
            // When sustain is 0, the envelope has decayed to silence —
            // nothing left to sustain. Skip straight to IDLE so the
            // voice frees up and doesn't hang active-silent forever.
            if (sustainLevel_ == 0.0f) {
                state_ = IDLE;
            } else {
                state_ = SUSTAIN;
            }
        }
        break;

    case SUSTAIN:
        // level stays at sustainLevel_
        break;

    case RELEASE:
        rate_ = 1.0f / (releaseMs_ * 0.001f * sampleRate);
        level_ -= rate_;
        if (level_ <= 0.0f) {
            level_ = 0.0f;
            state_ = IDLE;
        }
        break;

    default:
        break;
    }

    return level_;
}

} // namespace openamp
