#include "drum_kit_mapping.h"
#include "drum_synth.h"

namespace opensynth {

// ── GM2 Percussion Note → DrumType mapping ──────────────────────────────────

int gm2NoteToDrumType(int midiNote) {
    switch (midiNote) {
        // ── Kick ───────────────────────────────────────────────────────
        case 35:  // Acoustic Bass Drum
        case 36:  // Bass Drum 1
            return static_cast<int>(DrumType::KICK);

        // ── Rimshot ────────────────────────────────────────────────────
        case 37:  // Side Stick
            return static_cast<int>(DrumType::RIMSHOT);

        // ── Snare ──────────────────────────────────────────────────────
        case 38:  // Acoustic Snare
        case 40:  // Electric Snare
            return static_cast<int>(DrumType::SNARE);

        // ── Clap ───────────────────────────────────────────────────────
        case 39:  // Hand Clap
            return static_cast<int>(DrumType::CLAP);

        // ── Low Tom ────────────────────────────────────────────────────
        case 41:  // Low Floor Tom
            return static_cast<int>(DrumType::TOM_LOW);

        // ── Closed Hi-hat ──────────────────────────────────────────────
        case 42:  // Closed Hi-Hat
        case 44:  // Pedal Hi-Hat
            return static_cast<int>(DrumType::CLOSED_HH);

        // ── Mid Tom ────────────────────────────────────────────────────
        case 45:  // Low Tom
            return static_cast<int>(DrumType::TOM_MID);

        // ── Open Hi-hat ────────────────────────────────────────────────
        case 46:  // Open Hi-Hat
            return static_cast<int>(DrumType::OPEN_HH);

        // ── High Tom ───────────────────────────────────────────────────
        case 48:  // Hi-Mid Tom
            return static_cast<int>(DrumType::TOM_HIGH);

        // ── Crash ──────────────────────────────────────────────────────
        case 49:  // Crash Cymbal 1
        case 52:  // Chinese Cymbal
        case 55:  // Splash Cymbal
        case 57:  // Crash Cymbal 2
            return static_cast<int>(DrumType::CRASH);

        // ── Ride ───────────────────────────────────────────────────────
        case 51:  // Ride Cymbal 1
        case 53:  // Ride Bell
        case 59:  // Ride Cymbal 2
            return static_cast<int>(DrumType::RIDE);

        // ── Cowbell ────────────────────────────────────────────────────
        case 56:  // Cowbell
            return static_cast<int>(DrumType::COWBELL);

        // ── Shaker ─────────────────────────────────────────────────────
        case 54:  // Tambourine
        case 70:  // Maracas
            return static_cast<int>(DrumType::SHAKER);

        // ── Conga High ─────────────────────────────────────────────────
        case 62:  // Mute Hi Conga
            return static_cast<int>(DrumType::CONGA_HIGH);

        // ── Conga Low ──────────────────────────────────────────────────
        case 64:  // Low Conga
            return static_cast<int>(DrumType::CONGA_LOW);

        default:
            return -1;
    }
}

const char* drumTypeName(int type) {
    if (type < 0 || type >= static_cast<int>(DrumType::COUNT)) return "Unknown";
    switch (static_cast<DrumType>(type)) {
        case DrumType::KICK:       return "Kick";
        case DrumType::SNARE:      return "Snare";
        case DrumType::CLOSED_HH:  return "Closed HH";
        case DrumType::OPEN_HH:    return "Open HH";
        case DrumType::TOM_HIGH:   return "Tom High";
        case DrumType::TOM_MID:    return "Tom Mid";
        case DrumType::TOM_LOW:    return "Tom Low";
        case DrumType::CRASH:      return "Crash";
        case DrumType::RIDE:       return "Ride";
        case DrumType::CLAP:       return "Clap";
        case DrumType::RIMSHOT:    return "Rimshot";
        case DrumType::COWBELL:    return "Cowbell";
        case DrumType::SHAKER:     return "Shaker";
        case DrumType::CONGA_HIGH: return "Conga High";
        case DrumType::CONGA_LOW:  return "Conga Low";
        default:                   return "Unknown";
    }
}

// ── Kit presets ─────────────────────────────────────────────────────────────

// Helper: build a default config for a drum type
static DrumSoundConfig mkCfg(float tuning, float level, float decay, float toneMix) {
    DrumSoundConfig c;
    c.tuning  = tuning;
    c.level   = level;
    c.decay   = decay;
    c.toneMix = toneMix;
    return c;
}

// Every preset has exactly 16 entries (one per DrumType, in enum order).
// Index in the array = static_cast<int>(DrumType).

// ── 0: Standard ──────────────────────────────────────────────────────────
static const DrumSoundConfig stdCfg[16] = {
    // KICK
    mkCfg(1.0f, 1.0f, -1.0f, 0.0f),
    // SNARE
    mkCfg(1.0f, 1.0f, -1.0f, 0.5f),
    // CLOSED_HH
    mkCfg(1.0f, 0.8f, -1.0f, 0.0f),
    // OPEN_HH
    mkCfg(1.0f, 0.7f, -1.0f, 0.0f),
    // TOM_HIGH
    mkCfg(1.0f, 0.9f, -1.0f, 0.0f),
    // TOM_MID
    mkCfg(1.0f, 0.9f, -1.0f, 0.0f),
    // TOM_LOW
    mkCfg(1.0f, 1.0f, -1.0f, 0.0f),
    // CRASH
    mkCfg(1.0f, 0.7f, -1.0f, 0.0f),
    // RIDE
    mkCfg(1.0f, 0.65f, -1.0f, 0.3f),
    // CLAP
    mkCfg(1.0f, 0.8f, -1.0f, 0.0f),
    // RIMSHOT
    mkCfg(1.0f, 0.75f, -1.0f, 0.0f),
    // COWBELL
    mkCfg(1.0f, 0.7f, -1.0f, 0.0f),
    // SHAKER
    mkCfg(1.0f, 0.6f, -1.0f, 0.0f),
    // CONGA_HIGH
    mkCfg(1.0f, 0.8f, -1.0f, 0.0f),
    // CONGA_LOW
    mkCfg(1.0f, 0.85f, -1.0f, 0.0f),
    // COUNT placeholder
    mkCfg(1.0f, 0.0f, 0.0f, 0.0f),
};

// ── 1: Room — longer decays, more air ────────────────────────────────────
static const DrumSoundConfig roomCfg[16] = {
    mkCfg(1.0f,  1.0f, 0.6f,  0.0f),
    mkCfg(1.0f,  1.0f, 0.5f,  0.4f),
    mkCfg(1.0f,  0.7f, 0.06f, 0.0f),
    mkCfg(1.0f,  0.65f, 0.5f, 0.0f),
    mkCfg(1.0f,  0.9f, 0.35f, 0.0f),
    mkCfg(1.0f,  0.9f, 0.35f, 0.0f),
    mkCfg(1.0f,  1.0f, 0.4f,  0.0f),
    mkCfg(1.0f,  0.7f, 3.0f,  0.0f),
    mkCfg(1.0f,  0.65f, 1.2f, 0.35f),
    mkCfg(1.0f,  0.8f, 0.3f,  0.0f),
    mkCfg(1.0f,  0.7f, 0.04f, 0.0f),
    mkCfg(1.0f,  0.7f, 0.25f, 0.0f),
    mkCfg(1.0f,  0.5f, 0.12f, 0.0f),
    mkCfg(1.0f,  0.8f, 0.3f,  0.0f),
    mkCfg(1.0f,  0.85f, 0.3f, 0.0f),
    mkCfg(1.0f,  0.0f, 0.0f,  0.0f),
};

// ── 2: Power — louder, more punch ────────────────────────────────────────
static const DrumSoundConfig powerCfg[16] = {
    mkCfg(1.15f, 1.0f, 0.25f, 0.0f),
    mkCfg(1.1f,  1.0f, 0.25f, 0.6f),
    mkCfg(1.0f,  0.9f, 0.02f, 0.0f),
    mkCfg(1.0f,  0.8f, 0.25f, 0.0f),
    mkCfg(1.1f,  1.0f, 0.15f, 0.0f),
    mkCfg(1.05f, 1.0f, 0.15f, 0.0f),
    mkCfg(1.0f,  1.0f, 0.18f, 0.0f),
    mkCfg(1.0f,  0.8f, 1.8f,  0.0f),
    mkCfg(1.0f,  0.75f, 0.7f, 0.3f),
    mkCfg(1.0f,  0.9f, 0.18f, 0.0f),
    mkCfg(1.1f,  0.85f, 0.015f, 0.0f),
    mkCfg(1.1f,  0.8f, 0.12f, 0.0f),
    mkCfg(1.0f,  0.7f, 0.06f, 0.0f),
    mkCfg(1.05f, 0.9f, 0.15f, 0.0f),
    mkCfg(1.0f,  0.95f, 0.18f, 0.0f),
    mkCfg(1.0f,  0.0f, 0.0f,  0.0f),
};

// ── 3: TR-808 — classic electronic drum sounds ────────────────────────────
static const DrumSoundConfig tr808Cfg[16] = {
    mkCfg(0.9f,  1.0f, 0.35f, 0.0f),
    mkCfg(1.0f,  1.0f, 0.2f,  0.4f),
    mkCfg(1.5f,  0.75f, 0.02f, 0.0f),
    mkCfg(1.3f,  0.65f, 0.15f, 0.0f),
    mkCfg(1.0f,  0.85f, 0.15f, 0.0f),
    mkCfg(1.0f,  0.85f, 0.15f, 0.0f),
    mkCfg(1.0f,  0.9f, 0.18f,  0.0f),
    mkCfg(1.0f,  0.6f, 1.0f,  0.0f),
    mkCfg(1.0f,  0.6f, 0.6f,  0.25f),
    mkCfg(1.0f,  0.75f, 0.15f, 0.0f),
    mkCfg(1.2f,  0.7f, 0.012f, 0.0f),
    mkCfg(1.0f,  0.8f, 0.1f,  0.0f),
    mkCfg(1.5f,  0.55f, 0.05f, 0.0f),
    mkCfg(1.0f,  0.7f, 0.12f,  0.0f),
    mkCfg(1.0f,  0.8f, 0.15f,  0.0f),
    mkCfg(1.0f,  0.0f, 0.0f,  0.0f),
};

// ── 4: TR-909 — slightly longer than 808 ─────────────────────────────────
static const DrumSoundConfig tr909Cfg[16] = {
    mkCfg(1.0f,  1.0f, 0.3f,  0.0f),
    mkCfg(1.0f,  1.0f, 0.25f, 0.5f),
    mkCfg(1.3f,  0.8f, 0.03f, 0.0f),
    mkCfg(1.1f,  0.7f, 0.25f, 0.0f),
    mkCfg(1.0f,  0.9f, 0.18f, 0.0f),
    mkCfg(1.0f,  0.9f, 0.18f, 0.0f),
    mkCfg(1.0f,  0.95f, 0.2f, 0.0f),
    mkCfg(1.0f,  0.7f, 1.5f,  0.0f),
    mkCfg(1.0f,  0.65f, 0.7f, 0.3f),
    mkCfg(1.0f,  0.8f, 0.18f, 0.0f),
    mkCfg(1.1f,  0.75f, 0.015f, 0.0f),
    mkCfg(1.0f,  0.75f, 0.12f, 0.0f),
    mkCfg(1.2f,  0.6f, 0.07f, 0.0f),
    mkCfg(1.0f,  0.75f, 0.15f, 0.0f),
    mkCfg(1.0f,  0.8f, 0.18f, 0.0f),
    mkCfg(1.0f,  0.0f, 0.0f,  0.0f),
};

// ── 5: Electronic — modern EDM ────────────────────────────────────────────
static const DrumSoundConfig electronicCfg[16] = {
    mkCfg(1.1f,  1.0f, 0.22f, 0.0f),
    mkCfg(1.1f,  1.0f, 0.2f,  0.35f),
    mkCfg(1.4f,  0.85f, 0.025f, 0.0f),
    mkCfg(1.2f,  0.75f, 0.2f,  0.0f),
    mkCfg(1.05f, 0.9f, 0.12f,  0.0f),
    mkCfg(1.0f,  0.9f, 0.14f,  0.0f),
    mkCfg(1.0f,  0.95f, 0.16f, 0.0f),
    mkCfg(1.1f,  0.75f, 1.5f,  0.0f),
    mkCfg(1.05f, 0.7f, 0.6f,  0.35f),
    mkCfg(1.1f,  0.85f, 0.15f, 0.0f),
    mkCfg(1.3f,  0.8f, 0.01f,  0.0f),
    mkCfg(1.1f,  0.7f, 0.1f,  0.0f),
    mkCfg(1.0f,  0.65f, 0.06f, 0.0f),
    mkCfg(1.1f,  0.8f, 0.16f,  0.0f),
    mkCfg(1.05f, 0.85f, 0.18f, 0.0f),
    mkCfg(1.0f,  0.0f, 0.0f,  0.0f),
};

// ── 6: Jazz — brush-like, softer ─────────────────────────────────────────
static const DrumSoundConfig jazzCfg[16] = {
    mkCfg(0.95f, 0.8f,  0.4f,  0.0f),
    mkCfg(1.0f,  0.55f, 0.15f,  0.2f),
    mkCfg(1.1f,  0.45f, 0.04f,  0.0f),
    mkCfg(1.0f,  0.4f,  0.35f,  0.0f),
    mkCfg(1.0f,  0.7f,  0.25f,  0.0f),
    mkCfg(1.0f,  0.7f,  0.25f,  0.0f),
    mkCfg(1.0f,  0.75f, 0.28f,  0.0f),
    mkCfg(0.95f, 0.45f, 2.5f,   0.0f),
    mkCfg(1.0f,  0.4f,  1.0f,   0.2f),
    mkCfg(1.0f,  0.5f,  0.18f,  0.0f),
    mkCfg(1.0f,  0.4f,  0.02f,  0.0f),
    mkCfg(1.0f,  0.5f,  0.18f,  0.0f),
    mkCfg(1.0f,  0.25f, 0.06f,  0.0f),
    mkCfg(1.0f,  0.6f,  0.22f,  0.0f),
    mkCfg(1.0f,  0.65f, 0.25f,  0.0f),
    mkCfg(1.0f,  0.0f,  0.0f,   0.0f),
};

// ── 7: Brush — very soft, snare is brush sweep ───────────────────────────
static const DrumSoundConfig brushCfg[16] = {
    mkCfg(0.9f,  0.7f,  0.5f,  0.0f),
    mkCfg(1.0f,  0.35f, 0.5f,  0.1f),
    mkCfg(1.0f,  0.35f, 0.08f, 0.0f),
    mkCfg(1.0f,  0.3f,  0.4f,  0.0f),
    mkCfg(1.0f,  0.6f,  0.3f,  0.0f),
    mkCfg(1.0f,  0.6f,  0.3f,  0.0f),
    mkCfg(1.0f,  0.65f, 0.35f, 0.0f),
    mkCfg(0.9f,  0.4f,  3.0f,  0.0f),
    mkCfg(1.0f,  0.35f, 1.0f,  0.15f),
    mkCfg(1.0f,  0.4f,  0.25f, 0.0f),
    mkCfg(1.0f,  0.35f, 0.025f, 0.0f),
    mkCfg(1.0f,  0.4f,  0.2f,  0.0f),
    mkCfg(1.0f,  0.15f, 0.1f,  0.0f),
    mkCfg(1.0f,  0.5f,  0.28f, 0.0f),
    mkCfg(1.0f,  0.55f, 0.3f,  0.0f),
    mkCfg(1.0f,  0.0f,  0.0f,  0.0f),
};

// ── 8: Orchestra — big, sustained crash/ride ─────────────────────────────
static const DrumSoundConfig orchestraCfg[16] = {
    mkCfg(1.0f,  1.0f, 0.65f, 0.0f),
    mkCfg(1.0f,  0.9f, 0.5f,  0.45f),
    mkCfg(1.0f,  0.6f, 0.08f, 0.0f),
    mkCfg(1.0f,  0.55f, 0.6f, 0.0f),
    mkCfg(1.0f,  0.85f, 0.35f, 0.0f),
    mkCfg(1.0f,  0.85f, 0.35f, 0.0f),
    mkCfg(1.0f,  0.9f, 0.4f,  0.0f),
    mkCfg(1.0f,  0.7f, 4.0f,  0.0f),
    mkCfg(1.0f,  0.65f, 1.5f, 0.4f),
    mkCfg(1.0f,  0.6f, 0.35f, 0.0f),
    mkCfg(1.0f,  0.55f, 0.04f, 0.0f),
    mkCfg(1.0f,  0.6f, 0.3f,  0.0f),
    mkCfg(1.0f,  0.35f, 0.15f, 0.0f),
    mkCfg(1.0f,  0.75f, 0.35f, 0.0f),
    mkCfg(1.0f,  0.8f, 0.4f,  0.0f),
    mkCfg(1.0f,  0.0f, 0.0f,  0.0f),
};

// ── 9: SFX — extreme tunings, unusual sounds ─────────────────────────────
static const DrumSoundConfig sfxCfg[16] = {
    mkCfg(0.4f,  1.0f, 0.6f,  0.0f),
    mkCfg(2.0f,  1.0f, 0.1f,  0.7f),
    mkCfg(0.3f,  0.8f, 0.05f, 0.0f),
    mkCfg(0.5f,  0.7f, 0.6f,  0.0f),
    mkCfg(1.8f,  0.9f, 0.1f,  0.0f),
    mkCfg(0.7f,  0.9f, 0.25f, 0.0f),
    mkCfg(0.5f,  1.0f, 0.35f, 0.0f),
    mkCfg(1.5f,  0.8f, 5.0f,  0.0f),
    mkCfg(0.6f,  0.7f, 1.5f,  0.5f),
    mkCfg(2.0f,  0.9f, 0.12f, 0.0f),
    mkCfg(3.0f,  0.85f, 0.01f, 0.0f),
    mkCfg(2.0f,  0.8f, 0.08f, 0.0f),
    mkCfg(0.3f,  0.6f, 0.2f,  0.0f),
    mkCfg(0.6f,  0.8f, 0.25f, 0.0f),
    mkCfg(0.4f,  0.9f, 0.35f, 0.0f),
    mkCfg(1.0f,  0.0f, 0.0f,  0.0f),
};

// ── 10: Latin — congas and timbale-style tunings ─────────────────────────
static const DrumSoundConfig latinCfg[16] = {
    mkCfg(0.95f, 0.9f,  0.35f, 0.0f),
    mkCfg(1.0f,  0.8f,  0.25f, 0.35f),
    mkCfg(1.2f,  0.6f,  0.04f, 0.0f),
    mkCfg(1.1f,  0.55f, 0.4f,  0.0f),
    mkCfg(1.15f, 0.85f, 0.2f,  0.0f),
    mkCfg(1.1f,  0.85f, 0.2f,  0.0f),
    mkCfg(1.05f, 0.9f,  0.22f, 0.0f),
    mkCfg(1.0f,  0.65f, 2.0f,  0.0f),
    mkCfg(1.0f,  0.6f,  0.8f,  0.3f),
    mkCfg(1.0f,  0.75f, 0.2f,  0.0f),
    mkCfg(1.1f,  0.7f,  0.025f, 0.0f),
    mkCfg(1.2f,  0.75f, 0.18f, 0.0f),
    mkCfg(1.1f,  0.55f, 0.08f, 0.0f),
    mkCfg(1.15f, 0.85f, 0.18f, 0.0f),
    mkCfg(1.1f,  0.9f,  0.2f,  0.0f),
    mkCfg(1.0f,  0.0f,  0.0f,  0.0f),
};

// ── 11: Metal — heavy, aggressive, long cymbals ──────────────────────────
static const DrumSoundConfig metalCfg[16] = {
    mkCfg(1.2f,  1.0f,  0.55f, 0.0f),
    mkCfg(1.15f, 1.0f,  0.35f, 0.55f),
    mkCfg(1.3f,  0.85f, 0.05f, 0.0f),
    mkCfg(1.2f,  0.75f, 0.5f,  0.0f),
    mkCfg(1.2f,  0.95f, 0.22f, 0.0f),
    mkCfg(1.15f, 0.95f, 0.22f, 0.0f),
    mkCfg(1.1f,  1.0f,  0.25f, 0.0f),
    mkCfg(1.1f,  0.8f,  4.0f,  0.0f),
    mkCfg(1.05f, 0.75f, 1.2f,  0.4f),
    mkCfg(1.1f,  0.9f,  0.22f, 0.0f),
    mkCfg(1.2f,  0.85f, 0.02f, 0.0f),
    mkCfg(1.2f,  0.8f,  0.15f, 0.0f),
    mkCfg(1.1f,  0.65f, 0.08f, 0.0f),
    mkCfg(1.15f, 0.9f,  0.2f,  0.0f),
    mkCfg(1.1f,  0.95f, 0.22f, 0.0f),
    mkCfg(1.0f,  0.0f,  0.0f,  0.0f),
};

// ── 12: Vintage — lo-fi, noisy, short ────────────────────────────────────
static const DrumSoundConfig vintageCfg[16] = {
    mkCfg(0.85f, 0.9f,  0.4f,  0.0f),
    mkCfg(0.95f, 0.75f, 0.18f, 0.25f),
    mkCfg(1.1f,  0.55f, 0.035f, 0.0f),
    mkCfg(1.0f,  0.5f,  0.35f, 0.0f),
    mkCfg(1.05f, 0.75f, 0.18f, 0.0f),
    mkCfg(1.0f,  0.75f, 0.18f, 0.0f),
    mkCfg(0.95f, 0.8f,  0.2f,  0.0f),
    mkCfg(0.9f,  0.5f,  2.5f,  0.0f),
    mkCfg(0.95f, 0.45f, 0.8f,  0.2f),
    mkCfg(1.0f,  0.65f, 0.2f,  0.0f),
    mkCfg(1.1f,  0.6f,  0.02f, 0.0f),
    mkCfg(1.0f,  0.55f, 0.14f, 0.0f),
    mkCfg(1.0f,  0.35f, 0.07f, 0.0f),
    mkCfg(1.05f, 0.7f,  0.18f, 0.0f),
    mkCfg(1.0f,  0.75f, 0.2f,  0.0f),
    mkCfg(1.0f,  0.0f,  0.0f,  0.0f),
};

// ── 13: Dance — tight, punchy, short ─────────────────────────────────────
static const DrumSoundConfig danceCfg[16] = {
    mkCfg(1.15f, 1.0f,  0.18f, 0.0f),
    mkCfg(1.1f,  1.0f,  0.16f, 0.4f),
    mkCfg(1.5f,  0.9f,  0.02f, 0.0f),
    mkCfg(1.3f,  0.8f,  0.18f, 0.0f),
    mkCfg(1.1f,  0.95f, 0.1f,  0.0f),
    mkCfg(1.05f, 0.95f, 0.12f, 0.0f),
    mkCfg(1.0f,  1.0f,  0.14f, 0.0f),
    mkCfg(1.1f,  0.8f,  1.2f,  0.0f),
    mkCfg(1.05f, 0.75f, 0.5f,  0.35f),
    mkCfg(1.1f,  0.9f,  0.14f, 0.0f),
    mkCfg(1.3f,  0.85f, 0.01f, 0.0f),
    mkCfg(1.1f,  0.75f, 0.1f,  0.0f),
    mkCfg(1.0f,  0.7f,  0.05f, 0.0f),
    mkCfg(1.1f,  0.85f, 0.14f, 0.0f),
    mkCfg(1.05f, 0.9f,  0.16f, 0.0f),
    mkCfg(1.0f,  0.0f,  0.0f,  0.0f),
};

// ── 14: Acoustic — natural, open decays ──────────────────────────────────
static const DrumSoundConfig acousticCfg[16] = {
    mkCfg(1.0f,  1.0f, 0.5f,  0.0f),
    mkCfg(1.0f,  0.9f, 0.3f,  0.4f),
    mkCfg(1.0f,  0.75f, 0.06f, 0.0f),
    mkCfg(1.0f,  0.7f,  0.55f, 0.0f),
    mkCfg(1.0f,  0.9f,  0.3f,  0.0f),
    mkCfg(1.0f,  0.9f,  0.3f,  0.0f),
    mkCfg(1.0f,  0.95f, 0.32f, 0.0f),
    mkCfg(1.0f,  0.75f, 3.5f,  0.0f),
    mkCfg(1.0f,  0.7f,  1.2f,  0.35f),
    mkCfg(1.0f,  0.85f, 0.28f, 0.0f),
    mkCfg(1.0f,  0.75f, 0.04f, 0.0f),
    mkCfg(1.0f,  0.75f, 0.25f, 0.0f),
    mkCfg(1.0f,  0.5f,  0.12f, 0.0f),
    mkCfg(1.0f,  0.85f, 0.28f, 0.0f),
    mkCfg(1.0f,  0.9f,  0.3f,  0.0f),
    mkCfg(1.0f,  0.0f,  0.0f,  0.0f),
};

// ── 15: Hip Hop — deep kick, crisp snare, tight hats ─────────────────────
static const DrumSoundConfig hiphopCfg[16] = {
    mkCfg(0.9f,  1.0f, 0.55f, 0.0f),
    mkCfg(1.05f, 1.0f, 0.28f, 0.45f),
    mkCfg(1.3f,  0.8f, 0.03f, 0.0f),
    mkCfg(1.1f,  0.7f, 0.45f, 0.0f),
    mkCfg(1.05f, 0.9f, 0.22f, 0.0f),
    mkCfg(1.0f,  0.9f, 0.24f, 0.0f),
    mkCfg(0.95f, 0.95f, 0.28f, 0.0f),
    mkCfg(1.0f,  0.7f, 2.0f,  0.0f),
    mkCfg(1.0f,  0.65f, 0.8f,  0.3f),
    mkCfg(1.05f, 0.85f, 0.22f, 0.0f),
    mkCfg(1.2f,  0.8f, 0.015f, 0.0f),
    mkCfg(1.05f, 0.75f, 0.14f, 0.0f),
    mkCfg(1.0f,  0.6f,  0.07f, 0.0f),
    mkCfg(1.05f, 0.85f, 0.22f, 0.0f),
    mkCfg(1.0f,  0.9f,  0.25f, 0.0f),
    mkCfg(1.0f,  0.0f,  0.0f,  0.0f),
};

// ── 16: Percussion — focused on congas/shakers/cowbells ──────────────────
static const DrumSoundConfig percussionCfg[16] = {
    mkCfg(1.0f,  0.85f, 0.3f,  0.0f),
    mkCfg(1.0f,  0.6f,  0.12f, 0.2f),
    mkCfg(1.3f,  0.7f,  0.05f, 0.0f),
    mkCfg(1.2f,  0.65f, 0.35f, 0.0f),
    mkCfg(1.2f,  0.8f,  0.15f, 0.0f),
    mkCfg(1.15f, 0.8f,  0.15f, 0.0f),
    mkCfg(1.1f,  0.85f, 0.18f, 0.0f),
    mkCfg(1.1f,  0.7f,  2.5f,  0.0f),
    mkCfg(1.05f, 0.65f, 0.9f,  0.25f),
    mkCfg(1.1f,  0.8f,  0.15f, 0.0f),
    mkCfg(1.25f, 0.75f, 0.02f, 0.0f),
    mkCfg(1.3f,  0.85f, 0.2f,  0.0f),
    mkCfg(1.2f,  0.7f,  0.1f,  0.0f),
    mkCfg(1.15f, 0.9f,  0.16f, 0.0f),
    mkCfg(1.1f,  0.9f,  0.18f, 0.0f),
    mkCfg(1.0f,  0.0f,  0.0f,  0.0f),
};

// ── 17: Cinematic — huge, dramatic, long tails ───────────────────────────
static const DrumSoundConfig cinematicCfg[16] = {
    mkCfg(1.0f,  1.0f,  0.75f, 0.0f),
    mkCfg(1.0f,  0.95f, 0.45f, 0.5f),
    mkCfg(1.0f,  0.7f,  0.1f,  0.0f),
    mkCfg(1.0f,  0.65f, 0.7f,  0.0f),
    mkCfg(1.0f,  0.9f,  0.4f,  0.0f),
    mkCfg(1.0f,  0.9f,  0.4f,  0.0f),
    mkCfg(1.0f,  0.95f, 0.42f, 0.0f),
    mkCfg(1.0f,  0.8f,  5.0f,  0.0f),
    mkCfg(1.0f,  0.75f, 1.8f,  0.45f),
    mkCfg(1.0f,  0.85f, 0.35f, 0.0f),
    mkCfg(1.0f,  0.7f,  0.05f, 0.0f),
    mkCfg(1.0f,  0.75f, 0.3f,  0.0f),
    mkCfg(1.0f,  0.45f, 0.18f, 0.0f),
    mkCfg(1.0f,  0.9f,  0.35f, 0.0f),
    mkCfg(1.0f,  0.95f, 0.4f,  0.0f),
    mkCfg(1.0f,  0.0f,  0.0f,  0.0f),
};

// ── All presets table ───────────────────────────────────────────────────────

static const DrumSoundConfig* kitPresetTable[18] = {
    stdCfg,         // 0: Standard
    roomCfg,        // 1: Room
    powerCfg,       // 2: Power
    tr808Cfg,       // 3: TR-808
    tr909Cfg,       // 4: TR-909
    electronicCfg,  // 5: Electronic
    jazzCfg,        // 6: Jazz
    brushCfg,       // 7: Brush
    orchestraCfg,   // 8: Orchestra
    sfxCfg,         // 9: SFX
    latinCfg,       // 10: Latin
    metalCfg,       // 11: Metal
    vintageCfg,     // 12: Vintage
    danceCfg,       // 13: Dance
    acousticCfg,    // 14: Acoustic
    hiphopCfg,      // 15: Hip Hop
    percussionCfg,  // 16: Percussion
    cinematicCfg,   // 17: Cinematic
};

static const char* kitPresetNames[18] = {
    "Standard",
    "Room",
    "Power",
    "TR-808",
    "TR-909",
    "Electronic",
    "Jazz",
    "Brush",
    "Orchestra",
    "SFX",
    "Latin",
    "Metal",
    "Vintage",
    "Dance",
    "Acoustic",
    "Hip Hop",
    "Percussion",
    "Cinematic",
};

// ── Initialize kits in DrumKit ──────────────────────────────────────────────

// Called from DrumKit constructor to populate kits_[].
// Defined here so that the presets above stay co-located with the mapping code.
namespace {
    // We expose a function for the DrumKit to call during construction.
    // This avoids a circular dependency (drum_synth.cpp includes drum_kit_mapping.h).
}

void initDrumKitPresets(DrumKitPreset kits[18]) {
    for (int k = 0; k < 18; ++k) {
        kits[k].name = kitPresetNames[k];
        for (int i = 0; i < 16; ++i) {
            kits[k].sounds[i] = kitPresetTable[k][i];
        }
    }
}

} // namespace opensynth