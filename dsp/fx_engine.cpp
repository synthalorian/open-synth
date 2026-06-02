#include "fx_engine.h"
#include <algorithm>
#include <cmath>

namespace openamp {

void FxEngine::process(float& left, float& right, double sampleRate) {
    if (!masterEnabled_) return;

    for (int i = 0; i < MAX_FX_SLOTS; i++) {
        slots_[i].process(left, right, sampleRate);
    }
}

void FxEngine::reset() {
    for (int i = 0; i < MAX_FX_SLOTS; i++) {
        slots_[i].reset();
    }
}

void FxEngine::setSlotProcessor(int index, FxProcessor* processor) {
    if (index >= 0 && index < MAX_FX_SLOTS) {
        slots_[index].setProcessor(processor);
    }
}

void FxEngine::setSlotEnabled(int index, bool enabled) {
    if (index >= 0 && index < MAX_FX_SLOTS && slots_[index].processor) {
        slots_[index].processor->setEnabled(enabled);
    }
}

void FxEngine::setSlotBypassed(int index, bool bypassed) {
    if (index >= 0 && index < MAX_FX_SLOTS) {
        slots_[index].bypassed = bypassed;
    }
}

void FxEngine::setSlotParam(int index, int paramIdx, float value) {
    if (index >= 0 && index < MAX_FX_SLOTS && slots_[index].processor) {
        slots_[index].processor->setParam(paramIdx, value);
    }
}

void FxEngine::setSlotParamNormalized(int slotIndex, int fxTypeId, int paramIdx, float normalized) {
    if (slotIndex >= 0 && slotIndex < MAX_FX_SLOTS && slots_[slotIndex].processor) {
        // Simple linear mapping for now — each param is 0-1 in the engine
        slots_[slotIndex].processor->setParam(paramIdx, normalized);
    }
}

void FxEngine::getSlotParams(int index, float* out, int maxCount) const {
    if (index >= 0 && index < MAX_FX_SLOTS && slots_[index].processor) {
        auto* proc = slots_[index].processor;
        int count = std::min(maxCount, proc->paramCount());
        for (int i = 0; i < count; i++) {
            out[i] = proc->getParam(i);
        }
    }
}

int FxEngine::activeSlotCount() const {
    int count = 0;
    for (int i = 0; i < MAX_FX_SLOTS; i++) {
        if (slots_[i].type() != FxType::None) count++;
    }
    return count;
}

} // namespace openamp
