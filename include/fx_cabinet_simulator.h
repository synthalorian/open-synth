#pragma once
#include "fx_engine.h"
#include <cmath>

namespace opensynth {

/// Guitar cabinet IR emulation using resonant lowpass + highpass + notch.
class CabinetSimulatorProcessor : public FxProcessor {
public:
    enum Param {
        TYPE = 0,     // 0-3: 1x12, 2x12, 4x12, 1x15
        MIC = 1,      // 0-2: dynamic, condenser, ribbon
        DISTANCE = 2, // 0 - 1
        MIX = 3,      // 0 - 1
    };

    explicit CabinetSimulatorProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float type_ = 0.0f;
    float mic_ = 0.0f;
    float distance_ = 0.3f;

    // Lowpass state
    float lpL_ = 0.0f, lpR_ = 0.0f;

    // Highpass state
    float hpL_ = 0.0f, hpR_ = 0.0f;

    // Notch state (SVF)
    float notchZ1L_ = 0.0f, notchZ2L_ = 0.0f;
    float notchZ1R_ = 0.0f, notchZ2R_ = 0.0f;

    double nativeSampleRate_ = 48000.0;

    float lowpass(float input, float& state, float freq, double sr);
    float highpass(float input, float& state, float freq, double sr);
    float notchSVF(float input, float& z1, float& z2, float freq, float q, double sr);

    void getCabinetFreqs(float& lpFreq, float& hpFreq, float& notchFreq, float& notchQ);
    void getMicEmphasis(float& midBoost, float& trebleBoost);
};

} // namespace opensynth
