#include "rhythm_pattern_player.h"
#include "drum_synth.h"
#include "drum_kit_mapping.h"
#include <cmath>
#include <cstring>

namespace openamp {

// ── GM2 Drum Note Constants ───────────────────────────────────────────────────
static constexpr uint8_t KICK   = 36;
static constexpr uint8_t SNARE  = 38;
static constexpr uint8_t CLAP   = 39;
static constexpr uint8_t CHH    = 42;
static constexpr uint8_t OHH    = 46;
static constexpr uint8_t TOM_H  = 50;
static constexpr uint8_t TOM_M  = 47;
static constexpr uint8_t TOM_L  = 43;
static constexpr uint8_t CRASH  = 49;
static constexpr uint8_t RIDE   = 51;
static constexpr uint8_t COWBELL= 56;
static constexpr uint8_t RIM    = 37;
static constexpr uint8_t SHAKER = 82;  // GM2 shaker (approx)

// ── Pattern Builder Helper ────────────────────────────────────────────────────

static int addHit(DrumPattern& p, int idx, uint8_t note, uint8_t vel, uint8_t step,
                  float prob = 1.0f, float shift = 0.0f, float accent = 1.0f) {
    if (idx >= DrumPattern::MAX_HITS) return idx;
    p.hits[idx] = {note, vel, step, prob, shift, accent};
    return idx + 1;
}

// ── Pattern Definitions ───────────────────────────────────────────────────────
// Each pattern is defined as a static function that fills a DrumPattern.

// ── ROCK PATTERNS ─────────────────────────────────────────────────────────────

static void makeRockBasic(DrumPattern& p) {
    p = {};
    p.name = "Basic Rock"; p.style = "rock"; p.category = "Rock";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 120.0f; p.swing = 0.0f;
    int i = 0;
    i = addHit(p, i, KICK, 100, 0);
    i = addHit(p, i, CHH,  80,  0);
    i = addHit(p, i, CHH,  80,  1);
    i = addHit(p, i, SNARE,100, 2);
    i = addHit(p, i, CHH,  80,  2);
    i = addHit(p, i, CHH,  80,  3);
    i = addHit(p, i, KICK, 90,  4);
    i = addHit(p, i, CHH,  80,  4);
    i = addHit(p, i, CHH,  80,  5);
    i = addHit(p, i, SNARE,110, 6, 1.0f, 0.0f, 1.2f); // accent
    i = addHit(p, i, CHH,  80,  6);
    i = addHit(p, i, CHH,  80,  7);
    i = addHit(p, i, KICK, 100, 8);
    i = addHit(p, i, CHH,  80,  8);
    i = addHit(p, i, CHH,  80,  9);
    i = addHit(p, i, SNARE,100, 10);
    i = addHit(p, i, CHH,  80,  10);
    i = addHit(p, i, CHH,  80,  11);
    i = addHit(p, i, KICK, 90,  12);
    i = addHit(p, i, CHH,  80,  12);
    i = addHit(p, i, CHH,  80,  13);
    i = addHit(p, i, SNARE,100, 14);
    i = addHit(p, i, CHH,  80,  14);
    i = addHit(p, i, OHH,  90,  15); // open hat on last 16th
    p.hitCount = i;
}

static void makeRockBallad(DrumPattern& p) {
    p = {};
    p.name = "Rock Ballad"; p.style = "rock"; p.category = "Rock";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 72.0f; p.swing = 0.0f;
    int i = 0;
    i = addHit(p, i, KICK, 100, 0);
    i = addHit(p, i, CHH,  60,  0);
    i = addHit(p, i, CHH,  60,  2);
    i = addHit(p, i, SNARE,90,  4);
    i = addHit(p, i, CHH,  60,  4);
    i = addHit(p, i, CHH,  60,  6);
    i = addHit(p, i, KICK, 80,  8);
    i = addHit(p, i, CHH,  60,  8);
    i = addHit(p, i, CHH,  60,  10);
    i = addHit(p, i, SNARE,100, 12);
    i = addHit(p, i, CHH,  60,  12);
    i = addHit(p, i, CHH,  60,  14);
    p.hitCount = i;
}

static void makeDrivingRock(DrumPattern& p) {
    p = {};
    p.name = "Driving Rock"; p.style = "rock"; p.category = "Rock";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 140.0f; p.swing = 0.0f;
    int i = 0;
    // Heavy kick on 1, and-of-2, 3
    i = addHit(p, i, KICK, 110, 0);
    i = addHit(p, i, CHH,  90,  0);
    i = addHit(p, i, CHH,  90,  1);
    i = addHit(p, i, SNARE,110, 2);
    i = addHit(p, i, CHH,  90,  2);
    i = addHit(p, i, KICK, 100, 3);
    i = addHit(p, i, CHH,  90,  3);
    i = addHit(p, i, KICK, 110, 4);
    i = addHit(p, i, CHH,  90,  4);
    i = addHit(p, i, CHH,  90,  5);
    i = addHit(p, i, SNARE,110, 6);
    i = addHit(p, i, CHH,  90,  6);
    i = addHit(p, i, CHH,  90,  7);
    i = addHit(p, i, KICK, 110, 8);
    i = addHit(p, i, CHH,  90,  8);
    i = addHit(p, i, CHH,  90,  9);
    i = addHit(p, i, SNARE,110, 10);
    i = addHit(p, i, CHH,  90,  10);
    i = addHit(p, i, KICK, 100, 11);
    i = addHit(p, i, CHH,  90,  11);
    i = addHit(p, i, KICK, 110, 12);
    i = addHit(p, i, CHH,  90,  12);
    i = addHit(p, i, CHH,  90,  13);
    i = addHit(p, i, SNARE,120, 14, 1.0f, 0.0f, 1.3f);
    i = addHit(p, i, CHH,  90,  14);
    i = addHit(p, i, OHH,  100, 15);
    p.hitCount = i;
}

static void makeShuffleRock(DrumPattern& p) {
    p = {};
    p.name = "Shuffle Rock"; p.style = "rock"; p.category = "Rock";
    p.steps = 12; p.beatsPerBar = 4; p.subdivisions = 3; // triplet feel
    p.defaultTempo = 110.0f; p.swing = 0.33f;
    int i = 0;
    i = addHit(p, i, KICK, 100, 0);
    i = addHit(p, i, CHH,  70,  0);
    i = addHit(p, i, CHH,  70,  1);
    i = addHit(p, i, SNARE,100, 2);
    i = addHit(p, i, CHH,  70,  2);
    i = addHit(p, i, CHH,  70,  3);
    i = addHit(p, i, KICK, 90,  4);
    i = addHit(p, i, CHH,  70,  4);
    i = addHit(p, i, CHH,  70,  5);
    i = addHit(p, i, SNARE,110, 6);
    i = addHit(p, i, CHH,  70,  6);
    i = addHit(p, i, CHH,  70,  7);
    i = addHit(p, i, KICK, 100, 8);
    i = addHit(p, i, CHH,  70,  8);
    i = addHit(p, i, CHH,  70,  9);
    i = addHit(p, i, SNARE,100, 10);
    i = addHit(p, i, CHH,  70,  10);
    i = addHit(p, i, CHH,  70,  11);
    p.hitCount = i;
}

static void makeHalfTime(DrumPattern& p) {
    p = {};
    p.name = "Half Time"; p.style = "rock"; p.category = "Rock";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 85.0f; p.swing = 0.0f;
    int i = 0;
    // Snare on 3 only (beat 8 in 16ths)
    i = addHit(p, i, KICK, 110, 0);
    i = addHit(p, i, CHH,  80,  0);
    i = addHit(p, i, CHH,  80,  1);
    i = addHit(p, i, CHH,  80,  2);
    i = addHit(p, i, CHH,  80,  3);
    i = addHit(p, i, KICK, 90,  4);
    i = addHit(p, i, CHH,  80,  4);
    i = addHit(p, i, CHH,  80,  5);
    i = addHit(p, i, CHH,  80,  6);
    i = addHit(p, i, CHH,  80,  7);
    i = addHit(p, i, SNARE,120, 8,  1.0f, 0.0f, 1.3f);
    i = addHit(p, i, CHH,  80,  8);
    i = addHit(p, i, CHH,  80,  9);
    i = addHit(p, i, CHH,  80,  10);
    i = addHit(p, i, CHH,  80,  11);
    i = addHit(p, i, KICK, 100, 12);
    i = addHit(p, i, CHH,  80,  12);
    i = addHit(p, i, CHH,  80,  13);
    i = addHit(p, i, CHH,  80,  14);
    i = addHit(p, i, OHH,  90,  15);
    p.hitCount = i;
}

// ── POP PATTERNS ──────────────────────────────────────────────────────────────

static void makePopBasic(DrumPattern& p) {
    p = {};
    p.name = "Pop Basic"; p.style = "pop"; p.category = "Pop";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 118.0f; p.swing = 0.0f;
    int i = 0;
    i = addHit(p, i, KICK, 100, 0);
    i = addHit(p, i, CHH,  70,  0);
    i = addHit(p, i, CHH,  70,  1);
    i = addHit(p, i, SNARE,90,  2);
    i = addHit(p, i, CHH,  70,  2);
    i = addHit(p, i, CHH,  70,  3);
    i = addHit(p, i, KICK, 80,  4);
    i = addHit(p, i, CHH,  70,  4);
    i = addHit(p, i, CHH,  70,  5);
    i = addHit(p, i, SNARE,100, 6);
    i = addHit(p, i, CHH,  70,  6);
    i = addHit(p, i, CHH,  70,  7);
    i = addHit(p, i, KICK, 100, 8);
    i = addHit(p, i, CHH,  70,  8);
    i = addHit(p, i, CHH,  70,  9);
    i = addHit(p, i, SNARE,90,  10);
    i = addHit(p, i, CHH,  70,  10);
    i = addHit(p, i, CHH,  70,  11);
    i = addHit(p, i, KICK, 80,  12);
    i = addHit(p, i, CHH,  70,  12);
    i = addHit(p, i, CHH,  70,  13);
    i = addHit(p, i, SNARE,100, 14);
    i = addHit(p, i, CHH,  70,  14);
    i = addHit(p, i, OHH,  80,  15);
    p.hitCount = i;
}

static void makeDancePop(DrumPattern& p) {
    p = {};
    p.name = "Dance Pop"; p.style = "pop"; p.category = "Pop";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 128.0f; p.swing = 0.0f;
    int i = 0;
    // Four-on-the-floor kick
    i = addHit(p, i, KICK, 110, 0);
    i = addHit(p, i, CHH,  80,  0);
    i = addHit(p, i, CHH,  80,  1);
    i = addHit(p, i, CHH,  80,  2);
    i = addHit(p, i, CHH,  80,  3);
    i = addHit(p, i, KICK, 110, 4);
    i = addHit(p, i, CHH,  80,  4);
    i = addHit(p, i, CHH,  80,  5);
    i = addHit(p, i, SNARE,100, 6);
    i = addHit(p, i, CHH,  80,  6);
    i = addHit(p, i, CHH,  80,  7);
    i = addHit(p, i, KICK, 110, 8);
    i = addHit(p, i, CHH,  80,  8);
    i = addHit(p, i, CHH,  80,  9);
    i = addHit(p, i, CHH,  80,  10);
    i = addHit(p, i, CHH,  80,  11);
    i = addHit(p, i, KICK, 110, 12);
    i = addHit(p, i, CHH,  80,  12);
    i = addHit(p, i, CHH,  80,  13);
    i = addHit(p, i, SNARE,100, 14);
    i = addHit(p, i, CHH,  80,  14);
    i = addHit(p, i, OHH,  90,  15);
    p.hitCount = i;
}

static void makeSynthPop(DrumPattern& p) {
    p = {};
    p.name = "Synth Pop"; p.style = "pop"; p.category = "Pop";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 125.0f; p.swing = 0.0f;
    int i = 0;
    i = addHit(p, i, KICK, 100, 0);
    i = addHit(p, i, CHH,  70,  0);
    i = addHit(p, i, CHH,  70,  1);
    i = addHit(p, i, CLAP, 90,  2);
    i = addHit(p, i, CHH,  70,  2);
    i = addHit(p, i, CHH,  70,  3);
    i = addHit(p, i, KICK, 90,  4);
    i = addHit(p, i, CHH,  70,  4);
    i = addHit(p, i, CHH,  70,  5);
    i = addHit(p, i, CLAP, 100, 6);
    i = addHit(p, i, CHH,  70,  6);
    i = addHit(p, i, CHH,  70,  7);
    i = addHit(p, i, KICK, 100, 8);
    i = addHit(p, i, CHH,  70,  8);
    i = addHit(p, i, CHH,  70,  9);
    i = addHit(p, i, CLAP, 90,  10);
    i = addHit(p, i, CHH,  70,  10);
    i = addHit(p, i, CHH,  70,  11);
    i = addHit(p, i, KICK, 90,  12);
    i = addHit(p, i, CHH,  70,  12);
    i = addHit(p, i, CHH,  70,  13);
    i = addHit(p, i, CLAP, 100, 14);
    i = addHit(p, i, CHH,  70,  14);
    i = addHit(p, i, OHH,  80,  15);
    p.hitCount = i;
}

// ── FUNK PATTERNS ─────────────────────────────────────────────────────────────

static void makeFunk16th(DrumPattern& p) {
    p = {};
    p.name = "Funk 16th"; p.style = "funk"; p.category = "Funk";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 108.0f; p.swing = 0.15f;
    int i = 0;
    // Ghost notes on snare
    i = addHit(p, i, KICK, 100, 0);
    i = addHit(p, i, CHH,  80,  0);
    i = addHit(p, i, SNARE,60,  1,  1.0f, 0.0f, 0.6f); // ghost
    i = addHit(p, i, CHH,  80,  1);
    i = addHit(p, i, SNARE,110, 2);
    i = addHit(p, i, CHH,  80,  2);
    i = addHit(p, i, CHH,  80,  3);
    i = addHit(p, i, KICK, 90,  4);
    i = addHit(p, i, CHH,  80,  4);
    i = addHit(p, i, SNARE,60,  5,  1.0f, 0.0f, 0.6f);
    i = addHit(p, i, CHH,  80,  5);
    i = addHit(p, i, SNARE,110, 6);
    i = addHit(p, i, CHH,  80,  6);
    i = addHit(p, i, CHH,  80,  7);
    i = addHit(p, i, KICK, 100, 8);
    i = addHit(p, i, CHH,  80,  8);
    i = addHit(p, i, SNARE,60,  9,  1.0f, 0.0f, 0.6f);
    i = addHit(p, i, CHH,  80,  9);
    i = addHit(p, i, SNARE,110, 10);
    i = addHit(p, i, CHH,  80,  10);
    i = addHit(p, i, CHH,  80,  11);
    i = addHit(p, i, KICK, 90,  12);
    i = addHit(p, i, CHH,  80,  12);
    i = addHit(p, i, SNARE,60,  13, 1.0f, 0.0f, 0.6f);
    i = addHit(p, i, CHH,  80,  13);
    i = addHit(p, i, SNARE,120, 14, 1.0f, 0.0f, 1.3f);
    i = addHit(p, i, CHH,  80,  14);
    i = addHit(p, i, OHH,  90,  15);
    p.hitCount = i;
}

static void makeJamesBrown(DrumPattern& p) {
    p = {};
    p.name = "James Brown"; p.style = "funk"; p.category = "Funk";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 115.0f; p.swing = 0.2f;
    int i = 0;
    i = addHit(p, i, KICK, 100, 0);
    i = addHit(p, i, CHH,  80,  0);
    i = addHit(p, i, CHH,  80,  1);
    i = addHit(p, i, SNARE,110, 2);
    i = addHit(p, i, CHH,  80,  2);
    i = addHit(p, i, CHH,  80,  3);
    i = addHit(p, i, KICK, 90,  4);
    i = addHit(p, i, CHH,  80,  4);
    i = addHit(p, i, CHH,  80,  5);
    i = addHit(p, i, SNARE,100, 6);
    i = addHit(p, i, CHH,  80,  6);
    i = addHit(p, i, KICK, 80,  7);
    i = addHit(p, i, CHH,  80,  7);
    i = addHit(p, i, KICK, 100, 8);
    i = addHit(p, i, CHH,  80,  8);
    i = addHit(p, i, CHH,  80,  9);
    i = addHit(p, i, SNARE,110, 10);
    i = addHit(p, i, CHH,  80,  10);
    i = addHit(p, i, CHH,  80,  11);
    i = addHit(p, i, KICK, 90,  12);
    i = addHit(p, i, CHH,  80,  12);
    i = addHit(p, i, CHH,  80,  13);
    i = addHit(p, i, SNARE,120, 14, 1.0f, 0.0f, 1.3f);
    i = addHit(p, i, CHH,  80,  14);
    i = addHit(p, i, OHH,  90,  15);
    p.hitCount = i;
}

// ── JAZZ PATTERNS ─────────────────────────────────────────────────────────────

static void makeJazzSwing(DrumPattern& p) {
    p = {};
    p.name = "Jazz Swing"; p.style = "jazz"; p.category = "Jazz";
    p.steps = 12; p.beatsPerBar = 4; p.subdivisions = 3;
    p.defaultTempo = 140.0f; p.swing = 0.33f;
    int i = 0;
    // Ride cymbal on every triplet
    for (int s = 0; s < 12; s++) {
        i = addHit(p, i, RIDE, 70, s);
    }
    // Kick on 1, and-of-2
    i = addHit(p, i, KICK, 80, 0);
    i = addHit(p, i, KICK, 70, 4);
    // Snare on 2 and 4
    i = addHit(p, i, SNARE,70, 3);
    i = addHit(p, i, SNARE,70, 9);
    // CHH feathering
    i = addHit(p, i, CHH,  40, 1);
    i = addHit(p, i, CHH,  40, 7);
    p.hitCount = i;
}

static void makeJazzWaltz(DrumPattern& p) {
    p = {};
    p.name = "Jazz Waltz"; p.style = "jazz"; p.category = "Jazz";
    p.steps = 12; p.beatsPerBar = 3; p.subdivisions = 4;
    p.defaultTempo = 160.0f; p.swing = 0.0f;
    int i = 0;
    for (int s = 0; s < 12; s++) {
        i = addHit(p, i, RIDE, 70, s);
    }
    i = addHit(p, i, KICK, 80, 0);
    i = addHit(p, i, SNARE,70, 4);
    i = addHit(p, i, SNARE,70, 8);
    i = addHit(p, i, CHH,  40, 2);
    i = addHit(p, i, CHH,  40, 6);
    i = addHit(p, i, CHH,  40, 10);
    p.hitCount = i;
}

static void makeBrushPattern(DrumPattern& p) {
    p = {};
    p.name = "Brush Sweep"; p.style = "jazz"; p.category = "Jazz";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 120.0f; p.swing = 0.15f;
    int i = 0;
    // Simulated brush sweep with shaker
    for (int s = 0; s < 16; s++) {
        i = addHit(p, i, SHAKER, 50, s, 0.8f);
    }
    i = addHit(p, i, KICK, 80, 0);
    i = addHit(p, i, SNARE,60, 4, 1.0f, 0.0f, 0.7f);
    i = addHit(p, i, SNARE,60, 8, 1.0f, 0.0f, 0.7f);
    i = addHit(p, i, SNARE,60, 12, 1.0f, 0.0f, 0.7f);
    p.hitCount = i;
}

// ── LATIN PATTERNS ────────────────────────────────────────────────────────────

static void makeBossaNova(DrumPattern& p) {
    p = {};
    p.name = "Bossa Nova"; p.style = "latin"; p.category = "Latin";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 120.0f; p.swing = 0.0f;
    int i = 0;
    // Classic bossa: kick on 1, snare on 2+ and 3, kick on 4
    i = addHit(p, i, KICK, 90, 0);
    i = addHit(p, i, CHH,  60, 0);
    i = addHit(p, i, CHH,  60, 1);
    i = addHit(p, i, SNARE,70, 2);
    i = addHit(p, i, CHH,  60, 2);
    i = addHit(p, i, CHH,  60, 3);
    i = addHit(p, i, SNARE,60, 4, 1.0f, 0.0f, 0.7f); // ghost
    i = addHit(p, i, CHH,  60, 4);
    i = addHit(p, i, CHH,  60, 5);
    i = addHit(p, i, KICK, 80, 6);
    i = addHit(p, i, CHH,  60, 6);
    i = addHit(p, i, CHH,  60, 7);
    i = addHit(p, i, SNARE,70, 8);
    i = addHit(p, i, CHH,  60, 8);
    i = addHit(p, i, CHH,  60, 9);
    i = addHit(p, i, CHH,  60, 10);
    i = addHit(p, i, CHH,  60, 11);
    i = addHit(p, i, KICK, 90, 12);
    i = addHit(p, i, CHH,  60, 12);
    i = addHit(p, i, CHH,  60, 13);
    i = addHit(p, i, SNARE,70, 14);
    i = addHit(p, i, CHH,  60, 14);
    i = addHit(p, i, CHH,  60, 15);
    p.hitCount = i;
}

static void makeSamba(DrumPattern& p) {
    p = {};
    p.name = "Samba"; p.style = "latin"; p.category = "Latin";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 130.0f; p.swing = 0.0f;
    int i = 0;
    // Surdo-style kick pattern
    i = addHit(p, i, KICK, 100, 0);
    i = addHit(p, i, CHH,  70, 0);
    i = addHit(p, i, CHH,  70, 1);
    i = addHit(p, i, SNARE,80, 2);
    i = addHit(p, i, CHH,  70, 2);
    i = addHit(p, i, CHH,  70, 3);
    i = addHit(p, i, KICK, 90, 4);
    i = addHit(p, i, CHH,  70, 4);
    i = addHit(p, i, CHH,  70, 5);
    i = addHit(p, i, SNARE,80, 6);
    i = addHit(p, i, CHH,  70, 6);
    i = addHit(p, i, CHH,  70, 7);
    i = addHit(p, i, KICK, 100, 8);
    i = addHit(p, i, CHH,  70, 8);
    i = addHit(p, i, CHH,  70, 9);
    i = addHit(p, i, SNARE,80, 10);
    i = addHit(p, i, CHH,  70, 10);
    i = addHit(p, i, CHH,  70, 11);
    i = addHit(p, i, KICK, 90, 12);
    i = addHit(p, i, CHH,  70, 12);
    i = addHit(p, i, CHH,  70, 13);
    i = addHit(p, i, SNARE,80, 14);
    i = addHit(p, i, CHH,  70, 14);
    i = addHit(p, i, OHH,  80, 15);
    p.hitCount = i;
}

static void makeReggaeton(DrumPattern& p) {
    p = {};
    p.name = "Reggaeton"; p.style = "latin"; p.category = "Latin";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 95.0f; p.swing = 0.0f;
    int i = 0;
    // Dembow pattern
    i = addHit(p, i, KICK, 110, 0);
    i = addHit(p, i, CHH,  80, 0);
    i = addHit(p, i, CHH,  80, 1);
    i = addHit(p, i, CHH,  80, 2);
    i = addHit(p, i, CHH,  80, 3);
    i = addHit(p, i, SNARE,100, 4);
    i = addHit(p, i, CHH,  80, 4);
    i = addHit(p, i, CHH,  80, 5);
    i = addHit(p, i, CHH,  80, 6);
    i = addHit(p, i, CHH,  80, 7);
    i = addHit(p, i, KICK, 100, 8);
    i = addHit(p, i, CHH,  80, 8);
    i = addHit(p, i, CHH,  80, 9);
    i = addHit(p, i, CHH,  80, 10);
    i = addHit(p, i, CHH,  80, 11);
    i = addHit(p, i, SNARE,100, 12);
    i = addHit(p, i, CHH,  80, 12);
    i = addHit(p, i, CHH,  80, 13);
    i = addHit(p, i, CHH,  80, 14);
    i = addHit(p, i, CHH,  80, 15);
    p.hitCount = i;
}

// ── ELECTRONIC PATTERNS ───────────────────────────────────────────────────────

static void makeFourOnFloor(DrumPattern& p) {
    p = {};
    p.name = "Four on Floor"; p.style = "electronic"; p.category = "Electronic";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 128.0f; p.swing = 0.0f;
    int i = 0;
    for (int beat = 0; beat < 4; beat++) {
        int step = beat * 4;
        i = addHit(p, i, KICK, 110, step);
        i = addHit(p, i, CHH,  80, step);
        i = addHit(p, i, CHH,  80, step + 1);
        i = addHit(p, i, CHH,  80, step + 2);
        i = addHit(p, i, CHH,  80, step + 3);
    }
    i = addHit(p, i, SNARE,100, 4);
    i = addHit(p, i, SNARE,100, 12);
    p.hitCount = i;
}

static void makeHouse(DrumPattern& p) {
    p = {};
    p.name = "House"; p.style = "electronic"; p.category = "Electronic";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 124.0f; p.swing = 0.0f;
    int i = 0;
    i = addHit(p, i, KICK, 110, 0);
    i = addHit(p, i, CHH,  80, 0);
    i = addHit(p, i, CHH,  80, 1);
    i = addHit(p, i, CHH,  80, 2);
    i = addHit(p, i, CHH,  80, 3);
    i = addHit(p, i, KICK, 100, 4);
    i = addHit(p, i, CHH,  80, 4);
    i = addHit(p, i, SNARE,100, 5);
    i = addHit(p, i, CHH,  80, 5);
    i = addHit(p, i, CHH,  80, 6);
    i = addHit(p, i, CHH,  80, 7);
    i = addHit(p, i, KICK, 110, 8);
    i = addHit(p, i, CHH,  80, 8);
    i = addHit(p, i, CHH,  80, 9);
    i = addHit(p, i, CHH,  80, 10);
    i = addHit(p, i, CHH,  80, 11);
    i = addHit(p, i, KICK, 100, 12);
    i = addHit(p, i, CHH,  80, 12);
    i = addHit(p, i, SNARE,100, 13);
    i = addHit(p, i, CHH,  80, 13);
    i = addHit(p, i, CHH,  80, 14);
    i = addHit(p, i, OHH,  90,  15);
    p.hitCount = i;
}

static void makeTechno(DrumPattern& p) {
    p = {};
    p.name = "Techno"; p.style = "electronic"; p.category = "Electronic";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 135.0f; p.swing = 0.0f;
    int i = 0;
    i = addHit(p, i, KICK, 120, 0);
    i = addHit(p, i, CHH,  90,  0);
    i = addHit(p, i, CHH,  90,  1);
    i = addHit(p, i, CHH,  90,  2);
    i = addHit(p, i, CHH,  90,  3);
    i = addHit(p, i, KICK, 110, 4);
    i = addHit(p, i, CHH,  90,  4);
    i = addHit(p, i, CHH,  90,  5);
    i = addHit(p, i, CHH,  90,  6);
    i = addHit(p, i, CHH,  90,  7);
    i = addHit(p, i, KICK, 120, 8);
    i = addHit(p, i, CHH,  90,  8);
    i = addHit(p, i, CHH,  90,  9);
    i = addHit(p, i, CHH,  90,  10);
    i = addHit(p, i, CHH,  90,  11);
    i = addHit(p, i, KICK, 110, 12);
    i = addHit(p, i, CHH,  90,  12);
    i = addHit(p, i, CHH,  90,  13);
    i = addHit(p, i, CHH,  90,  14);
    i = addHit(p, i, OHH,  100, 15);
    p.hitCount = i;
}

static void makeDnB(DrumPattern& p) {
    p = {};
    p.name = "Drum & Bass"; p.style = "electronic"; p.category = "Electronic";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 174.0f; p.swing = 0.0f;
    int i = 0;
    // Breakbeat-style
    i = addHit(p, i, KICK, 110, 0);
    i = addHit(p, i, CHH,  80, 0);
    i = addHit(p, i, CHH,  80, 1);
    i = addHit(p, i, SNARE,100, 2);
    i = addHit(p, i, CHH,  80, 2);
    i = addHit(p, i, CHH,  80, 3);
    i = addHit(p, i, KICK, 90,  4);
    i = addHit(p, i, CHH,  80, 4);
    i = addHit(p, i, CHH,  80, 5);
    i = addHit(p, i, SNARE,110, 6);
    i = addHit(p, i, CHH,  80, 6);
    i = addHit(p, i, CHH,  80, 7);
    i = addHit(p, i, KICK, 100, 8);
    i = addHit(p, i, CHH,  80, 8);
    i = addHit(p, i, CHH,  80, 9);
    i = addHit(p, i, SNARE,100, 10);
    i = addHit(p, i, CHH,  80, 10);
    i = addHit(p, i, CHH,  80, 11);
    i = addHit(p, i, KICK, 90,  12);
    i = addHit(p, i, CHH,  80, 12);
    i = addHit(p, i, CHH,  80, 13);
    i = addHit(p, i, SNARE,120, 14, 1.0f, 0.0f, 1.3f);
    i = addHit(p, i, CHH,  80, 14);
    i = addHit(p, i, OHH,  90,  15);
    p.hitCount = i;
}

static void makeTrap(DrumPattern& p) {
    p = {};
    p.name = "Trap"; p.style = "electronic"; p.category = "Electronic";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 140.0f; p.swing = 0.0f;
    int i = 0;
    // 808-style: long kicks, rapid hi-hats
    i = addHit(p, i, KICK, 120, 0);
    i = addHit(p, i, CHH,  70, 0);
    i = addHit(p, i, CHH,  70, 1);
    i = addHit(p, i, CHH,  70, 2);
    i = addHit(p, i, CHH,  70, 3);
    i = addHit(p, i, CHH,  70, 4);
    i = addHit(p, i, SNARE,110, 4);
    i = addHit(p, i, CHH,  70, 5);
    i = addHit(p, i, CHH,  70, 6);
    i = addHit(p, i, CHH,  70, 7);
    i = addHit(p, i, KICK, 100, 8);
    i = addHit(p, i, CHH,  70, 8);
    i = addHit(p, i, CHH,  70, 9);
    i = addHit(p, i, CHH,  70, 10);
    i = addHit(p, i, CHH,  70, 11);
    i = addHit(p, i, CHH,  70, 12);
    i = addHit(p, i, SNARE,110, 12);
    i = addHit(p, i, CHH,  70, 13);
    i = addHit(p, i, CHH,  70, 14);
    i = addHit(p, i, CHH,  70, 15);
    p.hitCount = i;
}

static void makeUKGarage(DrumPattern& p) {
    p = {};
    p.name = "UK Garage"; p.style = "electronic"; p.category = "Electronic";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 130.0f; p.swing = 0.2f;
    int i = 0;
    // Skippy garage beat
    i = addHit(p, i, KICK, 100, 0);
    i = addHit(p, i, CHH,  80, 0);
    i = addHit(p, i, CHH,  80, 1);
    i = addHit(p, i, CHH,  80, 2);
    i = addHit(p, i, CHH,  80, 3);
    i = addHit(p, i, SNARE,90,  4);
    i = addHit(p, i, CHH,  80, 4);
    i = addHit(p, i, CHH,  80, 5);
    i = addHit(p, i, CHH,  80, 6);
    i = addHit(p, i, CHH,  80, 7);
    i = addHit(p, i, KICK, 90,  8);
    i = addHit(p, i, CHH,  80, 8);
    i = addHit(p, i, CHH,  80, 9);
    i = addHit(p, i, SNARE,100, 10);
    i = addHit(p, i, CHH,  80, 10);
    i = addHit(p, i, CHH,  80, 11);
    i = addHit(p, i, CHH,  80, 12);
    i = addHit(p, i, CHH,  80, 13);
    i = addHit(p, i, CHH,  80, 14);
    i = addHit(p, i, OHH,  90,  15);
    p.hitCount = i;
}

// ── WORLD PATTERNS ────────────────────────────────────────────────────────────

static void makeAfrobeat(DrumPattern& p) {
    p = {};
    p.name = "Afrobeat"; p.style = "world"; p.category = "World";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 110.0f; p.swing = 0.1f;
    int i = 0;
    // Tony Allen-inspired
    i = addHit(p, i, KICK, 100, 0);
    i = addHit(p, i, CHH,  70, 0);
    i = addHit(p, i, CHH,  70, 1);
    i = addHit(p, i, SNARE,80, 2);
    i = addHit(p, i, CHH,  70, 2);
    i = addHit(p, i, CHH,  70, 3);
    i = addHit(p, i, KICK, 90, 4);
    i = addHit(p, i, CHH,  70, 4);
    i = addHit(p, i, CHH,  70, 5);
    i = addHit(p, i, SNARE,80, 6);
    i = addHit(p, i, CHH,  70, 6);
    i = addHit(p, i, CHH,  70, 7);
    i = addHit(p, i, KICK, 100, 8);
    i = addHit(p, i, CHH,  70, 8);
    i = addHit(p, i, CHH,  70, 9);
    i = addHit(p, i, SNARE,80, 10);
    i = addHit(p, i, CHH,  70, 10);
    i = addHit(p, i, CHH,  70, 11);
    i = addHit(p, i, KICK, 90, 12);
    i = addHit(p, i, CHH,  70, 12);
    i = addHit(p, i, CHH,  70, 13);
    i = addHit(p, i, SNARE,80, 14);
    i = addHit(p, i, CHH,  70, 14);
    i = addHit(p, i, OHH,  80, 15);
    p.hitCount = i;
}

static void makeReggae(DrumPattern& p) {
    p = {};
    p.name = "Reggae"; p.style = "world"; p.category = "World";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 80.0f; p.swing = 0.0f;
    int i = 0;
    // One drop: kick and snare on 3
    i = addHit(p, i, CHH,  60, 0);
    i = addHit(p, i, CHH,  60, 1);
    i = addHit(p, i, CHH,  60, 2);
    i = addHit(p, i, CHH,  60, 3);
    i = addHit(p, i, CHH,  60, 4);
    i = addHit(p, i, CHH,  60, 5);
    i = addHit(p, i, CHH,  60, 6);
    i = addHit(p, i, CHH,  60, 7);
    i = addHit(p, i, KICK, 100, 8);
    i = addHit(p, i, SNARE,100, 8);
    i = addHit(p, i, CHH,  60, 8);
    i = addHit(p, i, CHH,  60, 9);
    i = addHit(p, i, CHH,  60, 10);
    i = addHit(p, i, CHH,  60, 11);
    i = addHit(p, i, CHH,  60, 12);
    i = addHit(p, i, CHH,  60, 13);
    i = addHit(p, i, CHH,  60, 14);
    i = addHit(p, i, CHH,  60, 15);
    p.hitCount = i;
}

static void makeWaltz(DrumPattern& p) {
    p = {};
    p.name = "Waltz"; p.style = "world"; p.category = "World";
    p.steps = 12; p.beatsPerBar = 3; p.subdivisions = 4;
    p.defaultTempo = 90.0f; p.swing = 0.0f;
    int i = 0;
    i = addHit(p, i, KICK, 100, 0);
    i = addHit(p, i, CHH,  70, 0);
    i = addHit(p, i, CHH,  70, 1);
    i = addHit(p, i, CHH,  70, 2);
    i = addHit(p, i, CHH,  70, 3);
    i = addHit(p, i, SNARE,90,  4);
    i = addHit(p, i, CHH,  70, 4);
    i = addHit(p, i, CHH,  70, 5);
    i = addHit(p, i, CHH,  70, 6);
    i = addHit(p, i, CHH,  70, 7);
    i = addHit(p, i, KICK, 90,  8);
    i = addHit(p, i, CHH,  70, 8);
    i = addHit(p, i, CHH,  70, 9);
    i = addHit(p, i, CHH,  70, 10);
    i = addHit(p, i, CHH,  70, 11);
    p.hitCount = i;
}

// ── SYNTHWAVE PATTERNS ────────────────────────────────────────────────────────

static void makeOutrun(DrumPattern& p) {
    p = {};
    p.name = "Outrun"; p.style = "synthwave"; p.category = "Synthwave";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 125.0f; p.swing = 0.0f;
    int i = 0;
    i = addHit(p, i, KICK, 110, 0);
    i = addHit(p, i, CHH,  80, 0);
    i = addHit(p, i, CHH,  80, 1);
    i = addHit(p, i, CHH,  80, 2);
    i = addHit(p, i, CHH,  80, 3);
    i = addHit(p, i, KICK, 100, 4);
    i = addHit(p, i, CHH,  80, 4);
    i = addHit(p, i, SNARE,100, 5);
    i = addHit(p, i, CHH,  80, 5);
    i = addHit(p, i, CHH,  80, 6);
    i = addHit(p, i, CHH,  80, 7);
    i = addHit(p, i, KICK, 110, 8);
    i = addHit(p, i, CHH,  80, 8);
    i = addHit(p, i, CHH,  80, 9);
    i = addHit(p, i, CHH,  80, 10);
    i = addHit(p, i, CHH,  80, 11);
    i = addHit(p, i, KICK, 100, 12);
    i = addHit(p, i, CHH,  80, 12);
    i = addHit(p, i, SNARE,100, 13);
    i = addHit(p, i, CHH,  80, 13);
    i = addHit(p, i, CHH,  80, 14);
    i = addHit(p, i, OHH,  90, 15);
    p.hitCount = i;
}

static void makeDarksynth(DrumPattern& p) {
    p = {};
    p.name = "Darksynth"; p.style = "synthwave"; p.category = "Synthwave";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 110.0f; p.swing = 0.0f;
    int i = 0;
    // Industrial, heavy
    i = addHit(p, i, KICK, 120, 0);
    i = addHit(p, i, CHH,  80, 0);
    i = addHit(p, i, CHH,  80, 1);
    i = addHit(p, i, CHH,  80, 2);
    i = addHit(p, i, CHH,  80, 3);
    i = addHit(p, i, KICK, 110, 4);
    i = addHit(p, i, CHH,  80, 4);
    i = addHit(p, i, SNARE,110, 5);
    i = addHit(p, i, CHH,  80, 5);
    i = addHit(p, i, CHH,  80, 6);
    i = addHit(p, i, CHH,  80, 7);
    i = addHit(p, i, KICK, 120, 8);
    i = addHit(p, i, CHH,  80, 8);
    i = addHit(p, i, CHH,  80, 9);
    i = addHit(p, i, CHH,  80, 10);
    i = addHit(p, i, CHH,  80, 11);
    i = addHit(p, i, KICK, 110, 12);
    i = addHit(p, i, CHH,  80, 12);
    i = addHit(p, i, SNARE,120, 13, 1.0f, 0.0f, 1.3f);
    i = addHit(p, i, CHH,  80, 13);
    i = addHit(p, i, CHH,  80, 14);
    i = addHit(p, i, CRASH,100, 15);
    p.hitCount = i;
}

// ── FILLS ─────────────────────────────────────────────────────────────────────

static void makeRockFill(DrumPattern& p) {
    p = {};
    p.name = "Rock Fill"; p.style = "fill"; p.category = "Fills";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 120.0f; p.swing = 0.0f;
    int i = 0;
    i = addHit(p, i, KICK, 100, 0);
    i = addHit(p, i, CHH,  80, 0);
    i = addHit(p, i, CHH,  80, 1);
    i = addHit(p, i, SNARE,90, 2);
    i = addHit(p, i, CHH,  80, 2);
    i = addHit(p, i, CHH,  80, 3);
    i = addHit(p, i, KICK, 90, 4);
    i = addHit(p, i, CHH,  80, 4);
    i = addHit(p, i, CHH,  80, 5);
    i = addHit(p, i, SNARE,100, 6);
    i = addHit(p, i, CHH,  80, 6);
    i = addHit(p, i, CHH,  80, 7);
    // Fill starts at beat 3
    i = addHit(p, i, TOM_L, 90, 8);
    i = addHit(p, i, TOM_M, 90, 9);
    i = addHit(p, i, TOM_H, 90, 10);
    i = addHit(p, i, SNARE,120, 11, 1.0f, 0.0f, 1.3f);
    i = addHit(p, i, SNARE,100, 12);
    i = addHit(p, i, SNARE,100, 13);
    i = addHit(p, i, SNARE,120, 14, 1.0f, 0.0f, 1.3f);
    i = addHit(p, i, CRASH,110, 15);
    p.hitCount = i;
}

static void makeDnBFill(DrumPattern& p) {
    p = {};
    p.name = "DnB Fill"; p.style = "fill"; p.category = "Fills";
    p.steps = 16; p.beatsPerBar = 4; p.subdivisions = 4;
    p.defaultTempo = 174.0f; p.swing = 0.0f;
    int i = 0;
    i = addHit(p, i, KICK, 100, 0);
    i = addHit(p, i, CHH,  80, 0);
    i = addHit(p, i, CHH,  80, 1);
    i = addHit(p, i, SNARE,100, 2);
    i = addHit(p, i, CHH,  80, 2);
    i = addHit(p, i, CHH,  80, 3);
    i = addHit(p, i, KICK, 90, 4);
    i = addHit(p, i, CHH,  80, 4);
    i = addHit(p, i, CHH,  80, 5);
    i = addHit(p, i, SNARE,110, 6);
    i = addHit(p, i, CHH,  80, 6);
    i = addHit(p, i, CHH,  80, 7);
    // Rapid snare roll
    i = addHit(p, i, SNARE,80, 8, 1.0f, 0.0f, 0.8f);
    i = addHit(p, i, SNARE,90, 9);
    i = addHit(p, i, SNARE,100, 10);
    i = addHit(p, i, SNARE,110, 11);
    i = addHit(p, i, SNARE,120, 12, 1.0f, 0.0f, 1.3f);
    i = addHit(p, i, SNARE,100, 13);
    i = addHit(p, i, SNARE,130, 14, 1.0f, 0.0f, 1.4f);
    i = addHit(p, i, CRASH,120, 15);
    p.hitCount = i;
}

// ── Pattern Library ───────────────────────────────────────────────────────────

static constexpr int kPatternCount = 24;

static const DrumPattern* buildPatternLibrary() {
    static DrumPattern library[kPatternCount];
    static bool initialized = false;
    if (initialized) return library;

    makeRockBasic(library[0]);
    makeRockBallad(library[1]);
    makeDrivingRock(library[2]);
    makeShuffleRock(library[3]);
    makeHalfTime(library[4]);
    makePopBasic(library[5]);
    makeDancePop(library[6]);
    makeSynthPop(library[7]);
    makeFunk16th(library[8]);
    makeJamesBrown(library[9]);
    makeJazzSwing(library[10]);
    makeJazzWaltz(library[11]);
    makeBrushPattern(library[12]);
    makeBossaNova(library[13]);
    makeSamba(library[14]);
    makeReggaeton(library[15]);
    makeFourOnFloor(library[16]);
    makeHouse(library[17]);
    makeTechno(library[18]);
    makeDnB(library[19]);
    makeTrap(library[20]);
    makeUKGarage(library[21]);
    makeAfrobeat(library[22]);
    makeReggae(library[23]);
    // Fills and more variations can be added as indices 24+

    initialized = true;
    return library;
}

static const char* kCategories[] = {
    "Rock", "Pop", "Funk", "Jazz", "Latin",
    "Electronic", "World", "Synthwave", "Fills"
};
static constexpr int kCategoryCount = 9;

// ── Public API ────────────────────────────────────────────────────────────────

const DrumPattern* RhythmPatternPlayer::getPattern(int index) {
    const auto* lib = buildPatternLibrary();
    if (index < 0 || index >= kPatternCount) return nullptr;
    return &lib[index];
}

int RhythmPatternPlayer::patternCount() {
    return kPatternCount;
}

const char* RhythmPatternPlayer::getCategoryName(int categoryIndex) {
    if (categoryIndex < 0 || categoryIndex >= kCategoryCount) return "";
    return kCategories[categoryIndex];
}

int RhythmPatternPlayer::categoryCount() {
    return kCategoryCount;
}

// ── Construction ──────────────────────────────────────────────────────────────

RhythmPatternPlayer::RhythmPatternPlayer()
    : playing_(false), tempo_(120.0f), currentPattern_(0),
      currentStep_(0), currentVariation_(PatternVariation::MainA),
      sampleAccumulator_(0.0), samplesPerStep_(0.0), songMode_(false),
      variationCounter_(0) {}

// ── Transport ─────────────────────────────────────────────────────────────────

void RhythmPatternPlayer::play() {
    playing_.store(true, std::memory_order_release);
    currentStep_.store(0, std::memory_order_release);
    sampleAccumulator_ = 0.0;
}

void RhythmPatternPlayer::stop() {
    playing_.store(false, std::memory_order_release);
    currentStep_.store(0, std::memory_order_release);
    sampleAccumulator_ = 0.0;
}

// ── Tempo ─────────────────────────────────────────────────────────────────────

void RhythmPatternPlayer::setTempo(float bpm) {
    tempo_.store(bpm, std::memory_order_release);
}

// ── Pattern ───────────────────────────────────────────────────────────────────

void RhythmPatternPlayer::setPattern(int index) {
    currentPattern_.store(index, std::memory_order_release);
    currentStep_.store(0, std::memory_order_release);
    sampleAccumulator_ = 0.0;
}

void RhythmPatternPlayer::setVariation(PatternVariation var) {
    currentVariation_.store(var, std::memory_order_release);
}

// ── Timing ────────────────────────────────────────────────────────────────────

void RhythmPatternPlayer::recalcTiming(double sampleRate) {
    float bpm = tempo_.load(std::memory_order_acquire);
    if (bpm < 20.0f) bpm = 20.0f;
    if (bpm > 300.0f) bpm = 300.0f;

    const auto* pat = getPattern(currentPattern_.load(std::memory_order_acquire));
    if (!pat) return;

    // Steps per beat = subdivisions (4 = 16th notes, 3 = triplets, etc.)
    float stepsPerBeat = static_cast<float>(pat->subdivisions);
    float beatsPerSecond = bpm / 60.0f;
    float stepsPerSecond = stepsPerBeat * beatsPerSecond;
    samplesPerStep_ = sampleRate / stepsPerSecond;
}

int RhythmPatternPlayer::totalSteps() const {
    const auto* pat = getPattern(currentPattern_.load(std::memory_order_acquire));
    return pat ? pat->steps : 16;
}

// ── Process ───────────────────────────────────────────────────────────────────

void RhythmPatternPlayer::process(DrumKit& drumKit, uint32_t numFrames, double sampleRate) {
    if (!playing_.load(std::memory_order_acquire)) return;

    recalcTiming(sampleRate);
    if (samplesPerStep_ <= 0.0) return;

    sampleAccumulator_ += static_cast<double>(numFrames);

    while (sampleAccumulator_ >= samplesPerStep_) {
        sampleAccumulator_ -= samplesPerStep_;

        int step = currentStep_.load(std::memory_order_acquire);
        triggerStep(drumKit, step);

        step++;
        int maxSteps = totalSteps();
        if (step >= maxSteps) {
            step = 0;
            variationCounter_++;
            if (songMode_ && variationCounter_ >= 4) {
                variationCounter_ = 0;
                advanceVariation();
            }
        }
        currentStep_.store(step, std::memory_order_release);
    }
}

void RhythmPatternPlayer::triggerStep(DrumKit& drumKit, int step) {
    const auto* pat = getPattern(currentPattern_.load(std::memory_order_acquire));
    if (!pat) return;

    for (int h = 0; h < pat->hitCount; h++) {
        const auto& hit = pat->hits[h];
        if (hit.step != step) continue;

        // Apply swing to even steps (steps 1, 3, 5, 7...)
        // Swing delays the off-beat by a fraction of the step duration
        // For now we trigger immediately; micro-timing is a future enhancement

        // Apply probability
        float r = static_cast<float>(rand()) / RAND_MAX;
        if (r > hit.probability) continue;

        float vel = static_cast<float>(hit.velocity) / 127.0f;
        vel *= hit.accent;
        if (vel > 1.0f) vel = 1.0f;

        drumKit.noteOn(hit.note, vel);
    }
}

// ── Song Mode ─────────────────────────────────────────────────────────────────

void RhythmPatternPlayer::nextVariation() {
    auto var = currentVariation_.load(std::memory_order_acquire);
    switch (var) {
        case PatternVariation::Intro:
            var = PatternVariation::MainA;
            break;
        case PatternVariation::MainA:
            var = PatternVariation::FillA;
            break;
        case PatternVariation::FillA:
            var = PatternVariation::MainB;
            break;
        case PatternVariation::MainB:
            var = PatternVariation::FillB;
            break;
        case PatternVariation::FillB:
            var = PatternVariation::MainA; // Loop back
            break;
        case PatternVariation::Ending:
            var = PatternVariation::Intro;
            break;
        default:
            var = PatternVariation::MainA;
    }
    currentVariation_.store(var, std::memory_order_release);
}

void RhythmPatternPlayer::advanceVariation() {
    nextVariation();
}

} // namespace openamp
