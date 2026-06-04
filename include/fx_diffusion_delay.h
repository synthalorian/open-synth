#pragma once
#include "fx_engine.h"

namespace opensynth {

class DiffusionDelayProcessor : public FxProcessor {
public:
    DiffusionDelayProcessor();
    void process(float& left, float& right, double sampleRate) override;
    void reset() override;
    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return 4; }
    const char* paramName(int index) const override;

private:
    float params_[4] = {0.5f, 0.5f, 0.5f, 0.5f};
};

} // namespace opensynth
