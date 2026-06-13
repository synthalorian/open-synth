#pragma once
#include <cstdint>
#include <array>
#include <functional>
#include "audio_buffer.h"

namespace opensynth {

/// Maximum number of MFX (multi-FX) slots — Juno-Di: 3 MFX + Reverb + Chorus
static constexpr int MAX_MFX_SLOTS = 3;
static constexpr int MAX_FX_SLOTS = 5;  // 3 MFX + Reverb + Chorus

/// FX routing configuration: parallel or series
enum class FxRouting : uint8_t {
    SERIES = 0,      // All 5 slots in series (legacy)
    PARALLEL_MFX,    // 3 MFX parallel → Reverb → Chorus
    PARALLEL_FULL,   // All 5 parallel, mixed at output
};

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
/// Aligned with Juno-Di / Roland MFX architecture
enum class FxType : uint8_t {
    None = 0,
    // ── Legacy basic FX ──
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
    // ── Phase 5: MFX Expansion ──
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
    Vocoder,
    // ── Phase 6: Juno-Di FX parity (23-78) ──
    // Distortion family
    Distortion,
    Overdrive,
    Fuzz,
    TubeDrive,
    // Filter family
    ResonantFilter,
    FormantFilter,
    CombFilter,
    TalkBox,
    // Modulation family
    Vibrato,
    AutoPan,
    UniVibe,
    ChorusEnsemble,
    DimensionD,
    // Delay family
    ReverseDelay,
    TapeDelay,
    AnalogDelay,
    DiffusionDelay,
    // Reverb family
    RoomReverb,
    HallReverb,
    PlateReverb,
    ShimmerReverb,
    NonLinearReverb,
    // Pitch/Time family
    Harmonizer,
    Octaver,
    Detune,
    // Dynamics family
    NoiseGate,
    DeEsser,
    TransientShaper,
    MultibandCompressor,
    // Lo-Fi / Special FX
    LoFi,
    VinylSimulator,
    RadioSimulator,
    TelephoneSimulator,
    // Guitar / Amp
    CabinetSimulator,
    GraphicEQ,
    ParametricEQ,
    WahWah,
    // Mastering
    Maximizer,
    Exciter,
    StereoImager,
    // Synth FX
    Resonator,
    GrainDelay,
    SpectralFreeze,
    // Total count
    COUNT
};

inline constexpr int NUM_FX_TYPES = static_cast<int>(FxType::COUNT);

/// Base class for all FX processors.
class FxProcessor {
public:
    FxProcessor(FxType type) : type_(type) {}
    virtual ~FxProcessor() = default;

    virtual void setSampleRate(double /*sampleRate*/) {}
    virtual void process(float& left, float& right, double sampleRate) = 0;
    virtual void reset() = 0;
    virtual void setParam(int index, float value) = 0;
    virtual float getParam(int index) const = 0;
    virtual int paramCount() const = 0;
    virtual const char* paramName(int index) const = 0;

    FxType type() const { return type_; }
    bool enabled() const { return enabled_; }
    void setEnabled(bool e) { enabled_ = e; }

    float mix() const { return mix_; }
    void setMix(float m) { mix_ = m; }

    static float mapNormalized(int /*fxTypeId*/, int /*paramIndex*/, float normalized) { return normalized; }
    static float unmapNormalized(int /*fxTypeId*/, int /*paramIndex*/, float actual) { return actual; }
    static FxTypeDescriptor getDescriptor(int fxTypeId);

protected:
    FxType type_;
    bool enabled_ = false;
    float mix_ = 0.3f;

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

    void setProcessor(FxProcessor* p) {
        delete processor;
        processor = p;
    }

    FxType type() const { return processor ? processor->type() : FxType::None; }
};

/// The FX engine manages a chain of FX slots.
/// Supports series and parallel routing configurations.
class FxEngine {
public:
    FxEngine() = default;
    ~FxEngine() = default;

    /// Process with current routing configuration.
    void process(float& left, float& right, double sampleRate);

    /// Reset all slots.
    void reset();

    FxSlot& slot(int index) { return slots_[static_cast<size_t>(index)]; }
    const FxSlot& slot(int index) const { return slots_[static_cast<size_t>(index)]; }

    int slotCount() const { return MAX_FX_SLOTS; }

    void setSlotProcessor(int index, FxProcessor* processor);
    void setSlotEnabled(int index, bool enabled);
    void setSlotBypassed(int index, bool bypassed);
    void setSlotParam(int index, int paramIdx, float value);
    void setSlotParamNormalized(int slotIndex, int fxTypeId, int paramIdx, float normalized);
    void getSlotParams(int index, float* out, int maxCount) const;

    FxType slotType(int index) const { return slots_[static_cast<size_t>(index)].type(); }
    int activeSlotCount() const;

    void setMasterEnabled(bool e) { masterEnabled_ = e; }
    bool masterEnabled() const { return masterEnabled_; }

    void setMasterMix(float m) { masterMix_ = m; }
    float masterMix() const { return masterMix_; }

    // ── Routing ──
    void setRouting(FxRouting r) { routing_ = r; }
    FxRouting routing() const { return routing_; }

    /// Set bus gain for parallel mixing (0-2 = MFX, 3 = Reverb, 4 = Chorus)
    void setBusGain(int bus, float gain);
    float busGain(int bus) const;

private:
    std::array<FxSlot, MAX_FX_SLOTS> slots_;
    bool masterEnabled_ = true;
    float masterMix_ = 1.0f;

    FxRouting routing_ = FxRouting::SERIES;
    std::array<float, MAX_FX_SLOTS> busGains_ = {1.0f, 1.0f, 1.0f, 1.0f, 1.0f};

    void processSeries(float& left, float& right, double sampleRate);
    void processParallelMfx(float& left, float& right, double sampleRate);
};

} // namespace opensynth
