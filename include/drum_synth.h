#pragma once
#include <cstdint>
#include <cmath>

namespace openamp {

// ── Drum type identifiers ───────────────────────────────────────────────────

enum class DrumType : uint8_t {
    KICK = 0,
    SNARE,
    CLOSED_HH,
    OPEN_HH,
    TOM_HIGH,
    TOM_MID,
    TOM_LOW,
    CRASH,
    RIDE,
    CLAP,
    RIMSHOT,
    COWBELL,
    SHAKER,
    CONGA_HIGH,
    CONGA_LOW,
    COUNT
};

// ── Per-voice synthesis state ──────────────────────────────────────────────

struct DrumVoice {
    DrumType type = DrumType::KICK;
    bool active = false;
    float velocity = 0.0f;
    float envelopePhase = 0.0f;  // 0→1 over the drum's lifetime
    float baseDecay = 0.3f;       // decay time in seconds

    // Synthesis state (not all used by every drum type):
    float phase = 0.0f;           // for oscillators
    float noiseState = 0.0f;      // for noise generator
    float pitchStart = 0.0f;      // pitch envelope start (Hz)
    float pitchEnd = 0.0f;        // pitch envelope end (Hz)
    float pitchSweepTime = 0.03f; // how long the pitch sweep takes (seconds)
    float noiseLevel = 0.0f;      // 0-1 noise mix
    float toneLevel = 0.0f;       // 0-1 tone mix
    float filterState1 = 0.0f;    // for BPF / HPF filters (simple one-pole)
    float filterState2 = 0.0f;
    float burstTimer = 0.0f;      // for clap burst pattern
    int burstCount = 0;
    float detune = 0.0f;          // for cowbell dual-osc detune
    float phase2 = 0.0f;          // second oscillator phase (cowbell, crash bell, ride)
    float subPhase = 0.0f;        // independent sub-oscillator phase (kick)
    int midiNote = 0;
    // For hi-hat choke
    float tuning = 1.0f;          // pitch tuning multiplier from preset
    float chokeLevel = 1.0f;      // 1.0 = unchoked, ramps to 0 when choked

    // Pink noise filter states (Paul Kellet's method)
    float pinkB0 = 0.0f, pinkB1 = 0.0f, pinkB2 = 0.0f, pinkB3 = 0.0f;
    float pinkB4 = 0.0f, pinkB5 = 0.0f, pinkB6 = 0.0f;

    // Multi-mode oscillator phases (for cymbals, drumheads)
    float modePhases[8] = {};
    int modeCount = 0;
};

// ── Per-drum-type sound configuration ──────────────────────────────────────

struct DrumSoundConfig {
    float tuning = 1.0f;   // 0.5–2.0 multiplier on base pitch
    float level = 1.0f;    // 0.0–1.0 volume
    float decay = -1.0f;   // seconds; -1 = use default for type
    float toneMix = 0.5f;  // 0-1 balance between tone and noise
};

// ── Full kit preset (16 drum types) ────────────────────────────────────────

struct DrumKitPreset {
    const char* name;
    DrumSoundConfig sounds[16];  // indexed by DrumType cast to int
};

// ── Drum Kit ───────────────────────────────────────────────────────────────

class DrumKit {
public:
    explicit DrumKit(double sampleRate);

    // No copy
    DrumKit(const DrumKit&) = delete;
    DrumKit& operator=(const DrumKit&) = delete;

    /// Trigger a drum hit. MIDI note follows GM2 percussion map.
    void noteOn(int midiNote, float velocity);

    /// Stop a drum hit (primarily for hi-hat choke).
    void noteOff(int midiNote);

    /// Generate audio into separate left/right buffers.
    /// Caller MUST zero the output buffers before calling if needed —
    /// process() will MIX into them (not replace).
    void process(float* leftOut, float* rightOut, uint32_t numFrames);

    /// Select a preset kit by index (0–9).
    void setKitPreset(int index);

    /// Master drum level (0.0–1.0).
    void setLevel(float level);

    /// Kill all sounding voices.
    void allNotesOff();

private:
    static constexpr int kMaxVoices = 32;
    DrumVoice voices_[kMaxVoices];
    double sampleRate_;
    float masterLevel_ = 0.8f;
    DrumKitPreset kits_[10];
    int currentKit_ = 0;

    int findFreeVoice();
    void configureVoice(DrumVoice& v, DrumType type, const DrumSoundConfig& cfg,
                        float velocity, int note);

    static float midiToFreq(int note);
    static float fastRand(float& seed);
};

} // namespace openamp