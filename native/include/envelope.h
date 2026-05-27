#pragma once
#include <cmath>

namespace openamp {

class Envelope {
public:
    enum State { IDLE, ATTACK, DECAY, SUSTAIN, RELEASE };

    Envelope() = default;

    void setAttack(float ms);
    void setDecay(float ms);
    void setSustain(float level);
    void setRelease(float ms);

    void reset();
    void noteOn();
    void noteOff();
    float process(double sampleRate);

    State state() const { return state_; }
    bool isActive() const { return state_ != IDLE; }

private:
    State state_ = IDLE;
    float attackMs_ = 10.0f;
    float decayMs_ = 100.0f;
    float sustainLevel_ = 0.8f;
    float releaseMs_ = 200.0f;
    float level_ = 0.0f;
    float rate_ = 0.0f;
};

} // namespace openamp
