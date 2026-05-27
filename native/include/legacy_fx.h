#pragma once
#include "fx_engine.h"
#include <cmath>
#include <algorithm>

namespace openamp {

/// Legacy FX processor — wraps the original inline effects (Chorus, Delay,
/// Reverb, Phaser, Flanger, Compressor, Drive) into a single FxProcessor
/// that can be hosted on FxEngine slot 0 for backward compatibility.
class LegacyFxProcessor : public FxProcessor {
public:
    LegacyFxProcessor();
    ~LegacyFxProcessor() override = default;

    void process(float& left, float& right, double sampleRate) override;
    void reset() override;

    void setParam(int index, float value) override;
    float getParam(int index) const override;
    int paramCount() const override { return LEGACY_PARAM_COUNT; }
    const char* paramName(int index) const override;

    // ── Legacy effect enable flags ──────────────────────────────────────────

    bool chorusEnabled() const { return chorusEnabled_; }
    void setChorusEnabled(bool e) { chorusEnabled_ = e; }

    bool delayEnabled() const { return delayEnabled_; }
    void setDelayEnabled(bool e) { delayEnabled_ = e; }

    bool reverbEnabled() const { return reverbEnabled_; }
    void setReverbEnabled(bool e) { reverbEnabled_ = e; }

    bool phaserEnabled() const { return phaserEnabled_; }
    void setPhaserEnabled(bool e) { phaserEnabled_ = e; }

    bool driveEnabled() const { return driveEnabled_; }
    void setDriveEnabled(bool e) { driveEnabled_ = e; }

    bool flangerEnabled() const { return flangerEnabled_; }
    void setFlangerEnabled(bool e) { flangerEnabled_ = e; }

    bool compressorEnabled() const { return compressorEnabled_; }
    void setCompressorEnabled(bool e) { compressorEnabled_ = e; }

    // ── Legacy effect parameter setters (called from SynthEngine) ──────────

    // Chorus
    void setChorusRate(float hz) { chorusRate_ = hz; }
    void setChorusDepth(float d) { chorusDepth_ = d; }
    void setChorusMix(float m) { chorusMix_ = m; }

    // Delay
    void setDelayTime(float ms) {
        delayTimeMs_ = ms;
        updateDelayBufferSize(sampleRate_);
    }
    void setDelayFeedback(float fb) { delayFeedback_ = fb; }
    void setDelayMix(float m) { delayMix_ = m; }

    // Reverb
    void setReverbSize(float s) { reverbSize_ = s; }
    void setReverbDamping(float d) { reverbDamping_ = d; }
    void setReverbMix(float m) { reverbMix_ = m; }

    // Phaser
    void setPhaserRate(float hz) { phaserRate_ = hz; }
    void setPhaserDepth(float d) { phaserDepth_ = d; }
    void setPhaserFeedback(float fb) { phaserFeedback_ = fb; }
    void setPhaserMix(float m) { phaserMix_ = m; }

    // Drive
    void setDriveAmount(float a) { driveAmount_ = a; }
    void setDriveType(int t) { driveType_ = t; }

    // Flanger
    void setFlangerRate(float hz) { flangerRate_ = hz; }
    void setFlangerDepth(float d) { flangerDepth_ = d; }
    void setFlangerFeedback(float fb) { flangerFeedback_ = fb; }
    void setFlangerMix(float m) { flangerMix_ = m; }

    // Compressor
    void setCompressorThreshold(float t) { compressorThreshold_ = t; }
    void setCompressorRatio(float r) { compressorRatio_ = r; }
    void setCompressorAttack(float a) { compressorAttack_ = a; }
    void setCompressorRelease(float r) { compressorRelease_ = r; }
    void setCompressorMakeupGain(float g) { compressorMakeupGain_ = g; }

    // Drive types
    static constexpr int DRIVE_SOFT_CLIP = 0;
    static constexpr int DRIVE_HARD_CLIP = 1;
    static constexpr int DRIVE_ASYMMETRIC = 2;

private:
    // ── Legacy param IDs (for setParam/getParam) ────────────────────────────
    enum LegacyParam : int {
        LEGACY_CHORUS_ENABLED = 0,
        LEGACY_CHORUS_RATE,
        LEGACY_CHORUS_DEPTH,
        LEGACY_CHORUS_MIX,
        LEGACY_DELAY_ENABLED,
        LEGACY_DELAY_TIME,
        LEGACY_DELAY_FEEDBACK,
        LEGACY_DELAY_MIX,
        LEGACY_REVERB_ENABLED,
        LEGACY_REVERB_SIZE,
        LEGACY_REVERB_DAMPING,
        LEGACY_REVERB_MIX,
        LEGACY_PHASER_ENABLED,
        LEGACY_PHASER_RATE,
        LEGACY_PHASER_DEPTH,
        LEGACY_PHASER_FEEDBACK,
        LEGACY_PHASER_MIX,
        LEGACY_DRIVE_ENABLED,
        LEGACY_DRIVE_AMOUNT,
        LEGACY_DRIVE_TYPE,
        LEGACY_FLANGER_ENABLED,
        LEGACY_FLANGER_RATE,
        LEGACY_FLANGER_DEPTH,
        LEGACY_FLANGER_FEEDBACK,
        LEGACY_FLANGER_MIX,
        LEGACY_COMPRESSOR_ENABLED,
        LEGACY_COMPRESSOR_THRESHOLD,
        LEGACY_COMPRESSOR_RATIO,
        LEGACY_COMPRESSOR_ATTACK,
        LEGACY_COMPRESSOR_RELEASE,
        LEGACY_COMPRESSOR_MAKEUP_GAIN,
        LEGACY_PARAM_COUNT
    };

    static float clamp(float v, float lo, float hi) {
        return v < lo ? lo : (v > hi ? hi : v);
    }

    // ── Per-effect internal state ──────────────────────────────────────────

    // Enable flags
    bool chorusEnabled_ = false;
    bool delayEnabled_ = false;
    bool reverbEnabled_ = false;
    bool phaserEnabled_ = false;
    bool driveEnabled_ = false;
    bool flangerEnabled_ = false;
    bool compressorEnabled_ = false;

public:
    // Override FxProcessor::setSampleRate to pre-compute delay buffer size.
    // Public so tests and presets can set sample rate explicitly.
    void setSampleRate(double sampleRate) override {
        sampleRate_ = sampleRate;
        updateDelayBufferSize(sampleRate);
    }

private:

    // Chorus params
    float chorusRate_ = 0.5f;
    float chorusDepth_ = 0.5f;
    float chorusMix_ = 0.3f;
    float chorusPhase_ = 0.0f;

    // Delay params
    float delayTimeMs_ = 300.0f;
    float delayFeedback_ = 0.3f;
    float delayMix_ = 0.3f;
    static constexpr uint32_t MAX_DELAY_SAMPLES = 192000; // 4s at 48kHz
    float delayBuffer_[MAX_DELAY_SAMPLES]{};
    uint32_t delayWritePos_ = 0;
    uint32_t delayBufferSize_ = 14400; // 300ms at 48kHz

    // Reverb params
    float reverbSize_ = 0.5f;
    float reverbDamping_ = 0.5f;
    float reverbMix_ = 0.3f;
    static constexpr int REVERB_TAPS = 4;
    float reverbDelay_[REVERB_TAPS][4800]{};
    uint32_t reverbPos_[REVERB_TAPS]{};
    float reverbState_[REVERB_TAPS]{};

    // Phaser params
    float phaserRate_ = 0.5f;
    float phaserDepth_ = 0.5f;
    float phaserFeedback_ = 0.3f;
    float phaserMix_ = 0.3f;
    float phaserPhase_ = 0.0f;
    float phaserState1L_ = 0.0f, phaserState2L_ = 0.0f;
    float phaserState1R_ = 0.0f, phaserState2R_ = 0.0f;

    // Drive params
    float driveAmount_ = 0.5f;
    int driveType_ = 0;

    // Flanger params
    float flangerRate_ = 0.3f;
    float flangerDepth_ = 0.5f;
    float flangerFeedback_ = 0.3f;
    float flangerMix_ = 0.3f;
    float flangerPhase_ = 0.0f;
    static constexpr uint32_t FLANGER_DELAY_SAMPLES = 4096;
    float flangerDelayL_[FLANGER_DELAY_SAMPLES]{};
    float flangerDelayR_[FLANGER_DELAY_SAMPLES]{};
    uint32_t flangerWritePos_ = 0;

    // Compressor params
    float compressorThreshold_ = 0.5f;
    float compressorRatio_ = 3.0f;
    float compressorAttack_ = 5.0f;
    float compressorRelease_ = 100.0f;
    float compressorMakeupGain_ = 0.0f;
    float compressorEnvelope_ = 1.0f;

    double sampleRate_ = 44100.0;

    // ── Helper methods ──────────────────────────────────────────────────────
    float applyDistortion(float sample);
    void processChorus(float& left, float& right, double sampleRate);
    void processDelay(float& left, float& right, double sampleRate);
    void processReverb(float& left, float& right, double sampleRate);
    void processPhaser(float& left, float& right, double sampleRate);
    void processFlanger(float& left, float& right, double sampleRate);
    void processCompressor(float& left, float& right);
    // Only called from setSampleRate() now, not from processDelay().
    void updateDelayBufferSize(double sampleRate);
};

} // namespace openamp
