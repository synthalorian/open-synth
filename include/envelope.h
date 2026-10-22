#pragma once
#include <cmath>
#include <algorithm>

namespace opensynth {

/// Envelope curve type for attack, decay, release stages.
enum class EnvCurve : int {
    LINEAR = 0,
    EXPONENTIAL = 1,
    LOGARITHMIC = 2,
};

class Envelope {
public:
    enum State { IDLE, DELAY, ATTACK, HOLD, DECAY, SUSTAIN, RELEASE };

    Envelope() = default;

    void setAttack(float ms);
    void setDecay(float ms);
    void setSustain(float level);
    void setRelease(float ms);
    void setDelay(float ms);
    void setHold(float ms);
    void setAttackCurve(int curve);
    void setDecayCurve(int curve);
    void setReleaseCurve(int curve);

    void reset();
    void noteOn();
    // Legato-style retrigger of a sounding envelope: re-enters the attack
    // from the current output level instead of 0 (no delay stage), so a
    // repeated note does not click. Same as noteOn() when idle.
    void retrigger();
    void noteOff();
    float process(double sampleRate);

    State state() const { return state_; }
    bool isActive() const { return state_ != IDLE; }

    float delayMs() const { return delayMs_; }
    float holdMs() const { return holdMs_; }
    float attackMs() const { return attackMs_; }
    float decayMs() const { return decayMs_; }
    float sustainLevel() const { return sustainLevel_; }
    float releaseMs() const { return releaseMs_; }

private:
    State state_ = IDLE;
    float delayMs_ = 0.0f;
    float holdMs_ = 0.0f;
    float attackMs_ = 10.0f;
    float decayMs_ = 100.0f;
    float sustainLevel_ = 0.8f;
    float releaseMs_ = 200.0f;
    float level_ = 0.0f;
    float rate_ = 0.0f;
    float holdPhase_ = 0.0f;
    float lastOut_ = 0.0f;       // most recent output value
    float releaseStart_ = 0.0f;  // output level captured at noteOff
    float releasePhase_ = 0.0f;  // 0..1 progress through release
    bool releaseAfterAttack_ = false;  // noteOff arrived before any output
    EnvCurve attackCurve_ = EnvCurve::LINEAR;
    EnvCurve decayCurve_ = EnvCurve::LINEAR;
    EnvCurve releaseCurve_ = EnvCurve::LINEAR;

    float applyCurve(float linearPhase, EnvCurve curve) const;
    float processStage(double sampleRate);
};

} // namespace opensynth
