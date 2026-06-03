#pragma once
#include <cstdint>
#include <array>
#include <functional>
#include "audio_buffer.h"

namespace opensynth {

/// Maximum number of MFX (multi-FX) slots
static constexpr int MAX_FX_SLOTS = 4;

/// Maximum number of parameters per FX processor
static constexpr int MAX_FX_PARAMS = 8;

/// Parameter descriptor for UI range mapping
struct FxParamDescriptor {
    const char* name = "";
    float minValue = 0.0f;
    float maxValue = 1.0f;
    float defaultValue = 0.5f;
    const char* unit = "";
};

/// FX type descriptor containing parameter info for all 4 UI params
struct FxTypeDescriptor {
    const char* name = "";
    int numParams = 0;
    FxParamDescriptor params[MAX_FX_PARAMS];
};

/// Unique type IDs for each FX processor type
enum class FxType : uint8_t {
    None = 0,
    Chorus,
    Delay,
    Reverb,
    Phaser,
    Flanger,
    Compressor,
    Drive,
    Equalizer,
    Limiter,
    Rotary,
    Tremolo,
    // Phase 5: MFX Expansion
    AutoWah,
    Bitcrusher,
    RingMod,
    PitchShift,
    MultitapDelay,
    PingPongDelay,
    SpringReverb,
    GatedReverb,
    AmpSimulator,
    StereoWidener,
    // Juno-Di inspired
    Vocoder,
};

/// Base class for all FX processors.
/// Each processor has a set of float parameters, stereo processing,
/// and reset/state-clear methods.
class FxProcessor {
public:
    FxProcessor(FxType type) : type_(type) {}
    virtual ~FxProcessor() = default;

    /// Set the sample rate. Called during initialization before any
    /// process() calls. Useful for pre-computing sample-rate-dependent
    /// coefficients (biquads, delay interpolation, envelope times).
    /// Default is no-op for processors that don't need pre-configuration.
    virtual void setSampleRate(double /*sampleRate*/) {}

    /// Process a stereo pair of samples in-place.
    virtual void process(float& left, float& right, double sampleRate) = 0;

    /// Reset internal state (delay lines, envelopes, etc.)
    virtual void reset() = 0;

    /// Set a parameter by index (0 to MAX_FX_PARAMS-1).
    virtual void setParam(int index, float value) = 0;

    /// Get a parameter by index.
    virtual float getParam(int index) const = 0;

    /// Get the number of parameters this processor exposes.
    virtual int paramCount() const = 0;

    /// Get parameter name for UI display.
    virtual const char* paramName(int index) const = 0;

    FxType type() const { return type_; }
    bool enabled() const { return enabled_; }
    void setEnabled(bool e) { enabled_ = e; }

    /// Wet/dry mix (0.0 = dry, 1.0 = wet).
    float mix() const { return mix_; }
    void setMix(float m) { mix_ = m; }

    // Stub implementations for descriptor system — full tables TBD
    static float mapNormalized(int /*fxTypeId*/, int /*paramIndex*/, float normalized) { return normalized; }
    static float unmapNormalized(int /*fxTypeId*/, int /*paramIndex*/, float actual) { return actual; }
    static FxTypeDescriptor getDescriptor(int fxTypeId);

protected:
    FxType type_;
    bool enabled_ = false;
    float mix_ = 0.3f;

    /// Apply wet/dry mix.
    float applyMix(float dry, float wet) const {
        return dry * (1.0f - mix_) + wet * mix_;
    }
};

/// A slot holds an FX processor and its bypass state.
struct FxSlot {
    FxProcessor* processor = nullptr;
    bool bypassed = false;

    ~FxSlot() { delete processor; processor = nullptr; }

    void process(float& left, float& right, double sampleRate) {
        if (processor && processor->enabled() && !bypassed) {
            processor->process(left, right, sampleRate);
        }
    }

    void reset() {
        if (processor) processor->reset();
    }

    /// Set processor, taking ownership. Deletes any previous processor.
    void setProcessor(FxProcessor* p) {
        delete processor;
        processor = p;
    }

    FxType type() const { return processor ? processor->type() : FxType::None; }
};

/// The FX engine manages a chain of FX slots.
/// Slots are processed in order (series configuration).
class FxEngine {
public:
    FxEngine() = default;
    ~FxEngine() = default;

    /// Process all enabled slots in series.
    void process(float& left, float& right, double sampleRate);

    /// Reset all slots.
    void reset();

    /// Get a slot by index.
    FxSlot& slot(int index) { return slots_[index]; }
    const FxSlot& slot(int index) const { return slots_[index]; }

    /// Get the number of slots.
    int slotCount() const { return MAX_FX_SLOTS; }

    /// Set the processor for a specific slot.
    void setSlotProcessor(int index, FxProcessor* processor);

    /// Enable/disable a slot.
    void setSlotEnabled(int index, bool enabled);

    /// Bypass a slot (true = audio passes through unchanged).
    void setSlotBypassed(int index, bool bypassed);

    /// Set a parameter on the processor in a specific slot.
    void setSlotParam(int index, int paramIdx, float value);

    /// Set a normalized parameter (0-1) mapped to actual range for the FX type.
    void setSlotParamNormalized(int slotIndex, int fxTypeId, int paramIdx, float normalized);

    /// Get slot parameters as a flat float array for UI/param-queue.
    void getSlotParams(int index, float* out, int maxCount) const;

    /// Get the type of the processor in a slot.
    FxType slotType(int index) const { return slots_[index].type(); }

    /// Get the number of active (non-none) slots.
    int activeSlotCount() const;

    /// Enable/disable the entire FX engine.
    void setMasterEnabled(bool e) { masterEnabled_ = e; }
    bool masterEnabled() const { return masterEnabled_; }

    /// Master wet/dry for the entire FX chain.
    void setMasterMix(float m) { masterMix_ = m; }
    float masterMix() const { return masterMix_; }

private:
    std::array<FxSlot, MAX_FX_SLOTS> slots_;
    bool masterEnabled_ = true;
    float masterMix_ = 1.0f;
};

} // namespace opensynth
