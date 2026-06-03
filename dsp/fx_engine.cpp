#include "fx_engine.h"
#include <algorithm>
#include <cmath>

namespace opensynth {

// ── FX Type Descriptor Table ────────────────────────────────────────────────

FxTypeDescriptor FxProcessor::getDescriptor(int fxTypeId)
{
    FxTypeDescriptor d;
    switch (fxTypeId)
    {
    case 0: // None
        d.name = "None";
        d.numParams = 0;
        break;

    case 1: // Chorus
        d.name = "Chorus";
        d.numParams = 4;
        d.params[0] = {"Rate", 0.1f, 10.0f, 0.5f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Width", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 2: // Delay
        d.name = "Delay";
        d.numParams = 4;
        d.params[0] = {"Time", 10.0f, 2000.0f, 300.0f, "ms"};
        d.params[1] = {"Feedback", 0.0f, 0.95f, 0.3f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Tone", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 3: // Reverb
        d.name = "Reverb";
        d.numParams = 4;
        d.params[0] = {"Size", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Damping", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Width", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 4: // Phaser
        d.name = "Phaser";
        d.numParams = 4;
        d.params[0] = {"Rate", 0.1f, 10.0f, 0.5f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Feedback", 0.0f, 0.95f, 0.3f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 5: // Flanger
        d.name = "Flanger";
        d.numParams = 4;
        d.params[0] = {"Rate", 0.1f, 10.0f, 0.3f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Feedback", 0.0f, 0.95f, 0.3f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 6: // Compressor
        d.name = "Compressor";
        d.numParams = 4;
        d.params[0] = {"Threshold", -60.0f, 0.0f, -20.0f, "dB"};
        d.params[1] = {"Ratio", 1.0f, 20.0f, 3.0f, ":1"};
        d.params[2] = {"Attack", 0.1f, 100.0f, 5.0f, "ms"};
        d.params[3] = {"Release", 1.0f, 1000.0f, 100.0f, "ms"};
        break;

    case 7: // Drive
        d.name = "Drive";
        d.numParams = 4;
        d.params[0] = {"Amount", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Type", 0.0f, 2.0f, 0.0f, ""};
        d.params[2] = {"Tone", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Output", 0.0f, 1.0f, 0.8f, ""};
        break;

    case 8: // Equalizer
        d.name = "EQ";
        d.numParams = 4;
        d.params[0] = {"Low", -18.0f, 18.0f, 0.0f, "dB"};
        d.params[1] = {"Mid", -18.0f, 18.0f, 0.0f, "dB"};
        d.params[2] = {"High", -18.0f, 18.0f, 0.0f, "dB"};
        d.params[3] = {"Freq", 200.0f, 8000.0f, 1000.0f, "Hz"};
        break;

    case 9: // Limiter
        d.name = "Limiter";
        d.numParams = 4;
        d.params[0] = {"Threshold", -20.0f, 0.0f, -3.0f, "dB"};
        d.params[1] = {"Release", 1.0f, 1000.0f, 100.0f, "ms"};
        d.params[2] = {"Ceiling", -12.0f, 0.0f, -0.1f, "dB"};
        d.params[3] = {"Lookahead", 0.0f, 10.0f, 1.0f, "ms"};
        break;

    case 10: // Rotary
        d.name = "Rotary";
        d.numParams = 4;
        d.params[0] = {"Speed", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Drive", 0.0f, 1.0f, 0.0f, ""};
        break;

    case 11: // Tremolo
        d.name = "Tremolo";
        d.numParams = 4;
        d.params[0] = {"Rate", 0.1f, 20.0f, 4.0f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Wave", 0.0f, 3.0f, 0.0f, ""};
        d.params[3] = {"Phase", 0.0f, 1.0f, 0.0f, ""};
        break;

    case 12: // Auto-Wah
        d.name = "Auto-Wah";
        d.numParams = 4;
        d.params[0] = {"Rate", 0.1f, 10.0f, 2.0f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.7f, ""};
        d.params[2] = {"Resonance", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 13: // Bitcrusher
        d.name = "Bitcrusher";
        d.numParams = 4;
        d.params[0] = {"Bits", 1.0f, 16.0f, 8.0f, ""};
        d.params[1] = {"Rate", 0.01f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Fold", 0.0f, 1.0f, 0.0f, ""};
        break;

    case 14: // Ring Mod
        d.name = "Ring Mod";
        d.numParams = 4;
        d.params[0] = {"Freq", 20.0f, 2000.0f, 440.0f, "Hz"};
        d.params[1] = {"Depth", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Wave", 0.0f, 3.0f, 0.0f, ""};
        break;

    case 15: // Pitch Shift
        d.name = "Pitch Shift";
        d.numParams = 4;
        d.params[0] = {"Shift", -12.0f, 12.0f, 0.0f, "st"};
        d.params[1] = {"Fine", -100.0f, 100.0f, 0.0f, "ct"};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Quality", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 16: // Multi-tap Delay
        d.name = "Multi-tap";
        d.numParams = 4;
        d.params[0] = {"Time", 10.0f, 1000.0f, 250.0f, "ms"};
        d.params[1] = {"Spread", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Feedback", 0.0f, 0.95f, 0.3f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        break;

    case 17: // Ping-Pong Delay
        d.name = "Ping-Pong";
        d.numParams = 4;
        d.params[0] = {"Time", 10.0f, 1000.0f, 300.0f, "ms"};
        d.params[1] = {"Feedback", 0.0f, 0.95f, 0.4f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Width", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 18: // Spring Reverb
        d.name = "Spring";
        d.numParams = 4;
        d.params[0] = {"Size", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Damping", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Drive", 0.0f, 1.0f, 0.0f, ""};
        break;

    case 19: // Gated Reverb
        d.name = "Gated";
        d.numParams = 4;
        d.params[0] = {"Size", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Gate", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.3f, ""};
        d.params[3] = {"Attack", 0.1f, 50.0f, 1.0f, "ms"};
        break;

    case 20: // Amp Sim
        d.name = "Amp Sim";
        d.numParams = 4;
        d.params[0] = {"Gain", 0.0f, 1.0f, 0.5f, ""};
        d.params[1] = {"Tone", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Cab", 0.0f, 3.0f, 0.0f, ""};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 21: // Stereo Widener
        d.name = "Widener";
        d.numParams = 4;
        d.params[0] = {"Width", 0.0f, 2.0f, 1.0f, ""};
        d.params[1] = {"Mono", 0.0f, 1.0f, 0.0f, ""};
        d.params[2] = {"Delay", 0.0f, 20.0f, 0.0f, "ms"};
        d.params[3] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        break;

    case 22: // Vocoder
        d.name = "Vocoder";
        d.numParams = 4;
        d.params[0] = {"Bands", 4.0f, 32.0f, 16.0f, ""};
        d.params[1] = {"Range", 0.0f, 1.0f, 0.5f, ""};
        d.params[2] = {"Mix", 0.0f, 1.0f, 0.5f, ""};
        d.params[3] = {"Carrier", 0.0f, 2.0f, 0.0f, ""};
        break;

    default:
        d.name = "Unknown";
        d.numParams = 0;
        break;
    }
    return d;
}

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

} // namespace opensynth
