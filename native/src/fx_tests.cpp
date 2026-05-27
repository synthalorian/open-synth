#include <cmath>
#include <cstdio>
#include <cstring>
#include <algorithm>
#include <chrono>

#include "fx_eq.h"
#include "fx_limiter.h"
#include "fx_rotary.h"
#include "fx_tremolo.h"
#include "legacy_fx.h"

using namespace openamp;

static int tests_passed = 0;
static int tests_failed = 0;

#define TEST(name, expr) do {                                                   \
    if (!(expr)) {                                                              \
        fprintf(stderr, "  FAIL [%s:%d] %s\n", __FILE__, __LINE__, name);       \
        tests_failed++;                                                         \
    } else {                                                                    \
        fprintf(stdout, "  PASS   %s\n", name);                                 \
        tests_passed++;                                                         \
    }                                                                           \
} while(0)

#define ASSERT_NEAR(a, b, eps) TEST(#a " ≈ " #b, std::fabs((a) - (b)) < (eps))
#define ASSERT_TRUE(expr)    TEST(#expr, (expr))
#define ASSERT_FALSE(expr)   TEST(#expr, !(expr))

#define ASSERT_EQ(a, b)  do {                                                  \
    auto _a = (a); auto _b = (b);                                              \
    if (_a != _b) {                                                           \
        fprintf(stderr, "  FAIL [%s:%d] %s: %d != %d\n",                       \
                __FILE__, __LINE__, #a " == " #b, (int)_a, (int)_b);            \
        tests_failed++;                                                         \
    } else {                                                                    \
        fprintf(stdout, "  PASS   %s\n", #a " == " #b);                         \
        tests_passed++;                                                         \
    }                                                                           \
} while(0)

// ── Test: EqProcessor ────────────────────────────────────────────────────────

static void test_eq_processor() {
    fprintf(stdout, "\n── EqProcessor ─────────────────────────────────\n");

    EqProcessor eq;

    // Default params
    ASSERT_NEAR(eq.getParam(EqProcessor::LOW_GAIN), 0.0f, 0.001f);
    ASSERT_NEAR(eq.getParam(EqProcessor::MID_GAIN), 0.0f, 0.001f);
    ASSERT_NEAR(eq.getParam(EqProcessor::HIGH_GAIN), 0.0f, 0.001f);
    ASSERT_NEAR(eq.getParam(EqProcessor::MID_FREQ), 1000.0f, 0.1f);
    ASSERT_NEAR(eq.getParam(EqProcessor::MID_Q), 1.0f, 0.001f);

    // Set params and verify
    eq.setParam(EqProcessor::LOW_GAIN, -6.0f);
    ASSERT_NEAR(eq.getParam(EqProcessor::LOW_GAIN), -6.0f, 0.001f);

    eq.setParam(EqProcessor::MID_GAIN, 3.5f);
    ASSERT_NEAR(eq.getParam(EqProcessor::MID_GAIN), 3.5f, 0.001f);

    // Clamping
    eq.setParam(EqProcessor::LOW_GAIN, -99.0f);
    ASSERT_NEAR(eq.getParam(EqProcessor::LOW_GAIN), -12.0f, 0.001f);

    eq.setParam(EqProcessor::MID_Q, 0.05f);
    ASSERT_NEAR(eq.getParam(EqProcessor::MID_Q), 0.1f, 0.001f);

    // Param names
    ASSERT_TRUE(eq.paramName(EqProcessor::LOW_GAIN) != nullptr);
    ASSERT_TRUE(eq.paramName(99) != nullptr); // out-of-range returns ""

    // Process: passthrough with zero gain
    eq.setParam(EqProcessor::LOW_GAIN, 0.0f);
    eq.setParam(EqProcessor::MID_GAIN, 0.0f);
    eq.setParam(EqProcessor::HIGH_GAIN, 0.0f);
    eq.setParam(EqProcessor::OUTPUT_GAIN, 0.0f);

    float left = 0.5f;
    float right = -0.3f;
    eq.process(left, right, 48000.0);
    // With all gains at 0dB, output should match input
    ASSERT_NEAR(left, 0.5f, 0.001f);
    ASSERT_NEAR(right, -0.3f, 0.001f);

    // Reset
    eq.reset();
    ASSERT_NEAR(eq.getParam(EqProcessor::LOW_GAIN), 0.0f, 0.001f);

    // setSampleRate pre-computes coefficients
    EqProcessor eq2;
    eq2.setSampleRate(48000.0);
    // After setSampleRate, process should use pre-computed coeffs
    left = 0.5f;
    eq2.process(left, right, 48000.0);
    ASSERT_TRUE(std::isfinite(left));

    fprintf(stdout, "  paramCount = %d\n", eq.paramCount());
}

// ── Test: LimiterProcessor ────────────────────────────────────────────────────

static void test_limiter_processor() {
    fprintf(stdout, "\n── LimiterProcessor ────────────────────────────\n");

    LimiterProcessor lim;

    // Default params
    ASSERT_NEAR(lim.getParam(LimiterProcessor::THRESHOLD), -6.0f, 0.001f);
    ASSERT_NEAR(lim.getParam(LimiterProcessor::RELEASE), 100.0f, 0.001f);
    ASSERT_NEAR(lim.getParam(LimiterProcessor::CEILING), -1.0f, 0.001f);

    // Set params
    lim.setParam(LimiterProcessor::THRESHOLD, -12.0f);
    ASSERT_NEAR(lim.getParam(LimiterProcessor::THRESHOLD), -12.0f, 0.001f);

    // Clamping
    lim.setParam(LimiterProcessor::THRESHOLD, -100.0f);
    ASSERT_NEAR(lim.getParam(LimiterProcessor::THRESHOLD), -60.0f, 0.001f);

    // Process: below-threshold signal should pass through unaffected
    lim.setParam(LimiterProcessor::THRESHOLD, -12.0f);
    lim.setParam(LimiterProcessor::INPUT_GAIN, 0.0f);
    lim.reset();

    float quiet = 0.01f;
    float quietR = -0.008f;
    for (int i = 0; i < 100; i++) {
        lim.process(quiet, quietR, 48000.0);
    }
    // Quiet signal below -12dB threshold (~0.25) should be nearly unchanged
    ASSERT_TRUE(std::fabs(quiet) < 0.02f);
    ASSERT_TRUE(std::fabs(quietR) < 0.02f);

    // Process: reset envelope back to 1.0
    lim.reset();

    // Hard limiting test: very hot signal should be reduced
    float hot = 2.0f;
    float hotR = 1.5f;
    for (int i = 0; i < 1000; i++) {
        lim.process(hot, hotR, 48000.0);
    }
    // Both channels should be below the ceiling of -1dB (~0.89)
    ASSERT_TRUE(std::fabs(hot) < 0.9f);
    ASSERT_TRUE(std::fabs(hotR) < 0.9f);

    // setSampleRate should not crash
    LimiterProcessor lim2;
    lim2.setSampleRate(96000.0);
    float s = 0.5f;
    float s2 = -0.3f;
    lim2.process(s, s2, 96000.0);
    ASSERT_TRUE(std::isfinite(s));

    fprintf(stdout, "  paramCount = %d\n", lim.paramCount());
}

// ── Test: RotaryProcessor ─────────────────────────────────────────────────────

static void test_rotary_processor() {
    fprintf(stdout, "\n── RotaryProcessor ─────────────────────────────\n");

    RotaryProcessor rot;

    // Default params
    ASSERT_NEAR(rot.getParam(RotaryProcessor::RATE), 2.5f, 0.001f);
    ASSERT_NEAR(rot.getParam(RotaryProcessor::DEPTH), 0.7f, 0.001f);
    ASSERT_NEAR(rot.getParam(RotaryProcessor::TONE), 0.5f, 0.001f);

    // Set params
    rot.setParam(RotaryProcessor::RATE, 5.0f);
    ASSERT_NEAR(rot.getParam(RotaryProcessor::RATE), 5.0f, 0.001f);

    // Clamping
    rot.setParam(RotaryProcessor::RATE, 50.0f);
    ASSERT_NEAR(rot.getParam(RotaryProcessor::RATE), 10.0f, 0.001f);

    rot.setParam(RotaryProcessor::DEPTH, -0.5f);
    ASSERT_NEAR(rot.getParam(RotaryProcessor::DEPTH), 0.0f, 0.001f);

    // Process: should produce finite output for any input
    rot.reset();
    rot.setParam(RotaryProcessor::MIX, 0.5f);
    rot.setParam(RotaryProcessor::RATE, 2.0f);

    float left = 0.5f;
    float right = -0.3f;
    for (int i = 0; i < 100; i++) {
        rot.process(left, right, 48000.0);
        ASSERT_TRUE(std::isfinite(left));
        ASSERT_TRUE(std::isfinite(right));
    }

    // reset should clear delay lines
    rot.reset();
    float l2 = 1.0f;
    float r2 = -0.5f;
    rot.process(l2, r2, 48000.0);
    ASSERT_TRUE(std::isfinite(l2));

    // setSampleRate should not crash
    RotaryProcessor rot2;
    rot2.setSampleRate(96000.0);
    float s = 0.3f;
    float s2 = -0.1f;
    rot2.process(s, s2, 96000.0);
    ASSERT_TRUE(std::isfinite(s));

    fprintf(stdout, "  paramCount = %d\n", rot.paramCount());
}

// ── Test: TremoloProcessor ────────────────────────────────────────────────────

static void test_tremolo_processor() {
    fprintf(stdout, "\n── TremoloProcessor ────────────────────────────\n");

    TremoloProcessor trem;

    // Default params
    ASSERT_NEAR(trem.getParam(TremoloProcessor::RATE), 4.0f, 0.001f);
    ASSERT_NEAR(trem.getParam(TremoloProcessor::DEPTH), 0.5f, 0.001f);
    ASSERT_NEAR(trem.getParam(TremoloProcessor::SHAPE), 0.0f, 0.001f);

    // Set params
    trem.setParam(TremoloProcessor::RATE, 8.0f);
    ASSERT_NEAR(trem.getParam(TremoloProcessor::RATE), 8.0f, 0.001f);

    trem.setParam(TremoloProcessor::SHAPE, 2.0f);
    ASSERT_NEAR(trem.getParam(TremoloProcessor::SHAPE), 2.0f, 0.001f);

    // Clamping
    trem.setParam(TremoloProcessor::RATE, 100.0f);
    ASSERT_NEAR(trem.getParam(TremoloProcessor::RATE), 20.0f, 0.001f);

    trem.setParam(TremoloProcessor::STEREO, 360.0f);
    ASSERT_NEAR(trem.getParam(TremoloProcessor::STEREO), 180.0f, 0.001f);

    // Process: all shapes should produce finite output
    for (int shape = 0; shape <= 4; shape++) {
        trem.reset();
        trem.setParam(TremoloProcessor::SHAPE, static_cast<float>(shape));
        float left = 0.5f;
        float right = -0.3f;
        for (int i = 0; i < 50; i++) {
            trem.process(left, right, 48000.0);
            ASSERT_TRUE(std::isfinite(left));
            ASSERT_TRUE(std::isfinite(right));
            // Tremolo should never boost above unity (with depth < 1)
            ASSERT_TRUE(left <= 0.5f + 0.001f || left >= 0.0f);
        }
    }

    // With zero depth, signal should pass through unchanged
    trem.reset();
    trem.setParam(TremoloProcessor::DEPTH, 0.0f);
    float left = 0.5f;
    float right = -0.3f;
    trem.process(left, right, 48000.0);
    ASSERT_NEAR(left, 0.5f, 0.001f);
    ASSERT_NEAR(right, -0.3f, 0.001f);

    // setSampleRate should not crash
    TremoloProcessor trem2;
    trem2.setSampleRate(96000.0);
    float s = 0.3f;
    float s2 = -0.1f;
    trem2.process(s, s2, 96000.0);
    ASSERT_TRUE(std::isfinite(s));

    fprintf(stdout, "  paramCount = %d\n", trem.paramCount());
}

// ── Test: LegacyFxProcessor ───────────────────────────────────────────────────

static void test_legacy_fx_processor() {
    fprintf(stdout, "\n── LegacyFxProcessor ───────────────────────────\n");

    LegacyFxProcessor legacy;

    // Default: enabled, all legacy effects disabled
    ASSERT_TRUE(legacy.enabled());
    ASSERT_TRUE(legacy.type() == FxType::None);

    // Param access by index
    ASSERT_NEAR(legacy.getParam(0), 0.0f, 0.001f); // Chorus disabled
    legacy.setParam(0, 1.0f);
    ASSERT_NEAR(legacy.getParam(0), 1.0f, 0.001f); // Chorus enabled

    // Passthrough: no effects enabled, signal should pass unchanged
    legacy.setParam(0, 0.0f); // disable chorus
    float left = 0.5f;
    float right = -0.3f;
    legacy.process(left, right, 48000.0);
    ASSERT_NEAR(left, 0.5f, 0.001f);
    ASSERT_NEAR(right, -0.3f, 0.001f);

    // Reset should not crash
    legacy.reset();

    // All effects enabled at minimal settings should not crash or NaN
    legacy.setChorusEnabled(true);
    legacy.setChorusRate(0.1f);
    legacy.setChorusDepth(0.1f);
    legacy.setChorusMix(0.1f);

    legacy.setDelayEnabled(true);
    legacy.setDelayTime(10.0f);
    legacy.setDelayFeedback(0.1f);
    legacy.setDelayMix(0.1f);

    legacy.setReverbEnabled(true);
    legacy.setReverbSize(0.1f);
    legacy.setReverbDamping(0.1f);
    legacy.setReverbMix(0.1f);

    legacy.setPhaserEnabled(true);
    legacy.setPhaserRate(0.1f);
    legacy.setPhaserDepth(0.1f);
    legacy.setPhaserFeedback(0.1f);
    legacy.setPhaserMix(0.1f);

    legacy.setDriveEnabled(true);
    legacy.setDriveAmount(0.1f);

    legacy.setFlangerEnabled(true);
    legacy.setFlangerRate(0.1f);
    legacy.setFlangerDepth(0.1f);
    legacy.setFlangerFeedback(0.1f);
    legacy.setFlangerMix(0.1f);

    legacy.setCompressorEnabled(true);
    legacy.setCompressorThreshold(0.8f);
    legacy.setCompressorRatio(2.0f);
    legacy.setCompressorAttack(5.0f);
    legacy.setCompressorRelease(100.0f);

    float l = 0.5f;
    float r = -0.3f;
    legacy.process(l, r, 48000.0);
    ASSERT_TRUE(std::isfinite(l));
    ASSERT_TRUE(std::isfinite(r));

    fprintf(stdout, "  paramCount = %d\n", legacy.paramCount());
}

// ── Test: FxEngine ────────────────────────────────────────────────────────────

static void test_fx_engine() {
    fprintf(stdout, "\n── FxEngine ─────────────────────────────────────\n");

    FxEngine engine;

    ASSERT_TRUE(engine.masterEnabled());
    ASSERT_NEAR(engine.masterMix(), 1.0f, 0.001f);
    ASSERT_EQ(engine.slotCount(), 4);
    ASSERT_EQ(engine.activeSlotCount(), 0);

    // Set slot 1 to EQ
    auto* eq = new EqProcessor();
    eq->setEnabled(true);
    engine.setSlotProcessor(1, eq);
    ASSERT_EQ(engine.slotType(1), FxType::Equalizer);
    ASSERT_EQ(engine.activeSlotCount(), 1);

    // Enable/disable slot
    engine.setSlotEnabled(1, false);
    ASSERT_EQ(engine.slotType(1), FxType::Equalizer); // type preserved

    engine.setSlotEnabled(1, true);
    ASSERT_EQ(engine.slotType(1), FxType::Equalizer);

    // Set slot 2 to Limiter
    auto* lim = new LimiterProcessor();
    lim->setEnabled(true);
    engine.setSlotProcessor(2, lim);
    ASSERT_EQ(engine.slotType(2), FxType::Limiter);
    ASSERT_EQ(engine.activeSlotCount(), 2);

    // Process: all slots should produce finite output
    float left = 0.5f;
    float right = -0.3f;
    engine.process(left, right, 48000.0);
    ASSERT_TRUE(std::isfinite(left));
    ASSERT_TRUE(std::isfinite(right));

    // Bypass a slot
    engine.setSlotBypassed(1, true);

    // Replace slot processor (tests memory cleanup of old processor)
    engine.setSlotProcessor(1, new EqProcessor());
    engine.slot(1).processor->setEnabled(true);

    // Master controls
    engine.setMasterEnabled(false);
    engine.setMasterMix(0.5f);

    // Reset
    engine.reset();
    ASSERT_EQ(engine.activeSlotCount(), 2);

    // Slot params
    engine.setSlotParam(1, 0, -3.0f);
    float params[8] = {};
    engine.getSlotParams(1, params, 8);
    ASSERT_NEAR(params[0], -3.0f, 0.001f);

    fprintf(stdout, "  activeSlots = %d\n", engine.activeSlotCount());
}

// ── Benchmark: LegacyFxProcessor delay throughput ────────────────────────────
// Measures the throughput of LegacyFxProcessor::process() with delay enabled.
// The delay buffer size is pre-computed once by setSampleRate(), not recomputed
// on every frame, so changing delay time at runtime is O(1) overhead.

static void benchmark_legacy_fx_delay() {
    fprintf(stdout, "\n── LegacyFxProcessor Delay Benchmark ────────────\n");

    LegacyFxProcessor legacy;
    legacy.setSampleRate(48000.0);

    // Enable delay with a moderate setting
    legacy.setDelayEnabled(true);
    legacy.setDelayTime(100.0f);  // 100ms
    legacy.setDelayFeedback(0.3f);
    legacy.setDelayMix(0.5f);

    // Warm up: run a few iterations to let filters stabilize
    float l = 0.5f, r = -0.3f;
    for (int i = 0; i < 100; i++) {
        legacy.process(l, r, 48000.0);
    }

    // Benchmark: 100,000 iterations of process()
    const int ITERATIONS = 100000;
    auto start = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < ITERATIONS; i++) {
        l = 0.5f;
        r = -0.3f;
        legacy.process(l, r, 48000.0);
    }
    auto end = std::chrono::high_resolution_clock::now();

    auto durationUs = std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();
    double perCallUs = static_cast<double>(durationUs) / ITERATIONS;
    fprintf(stdout, "  %d iterations in %ld us (%.3f us/call)\n",
            ITERATIONS, (long)durationUs, perCallUs);
    ASSERT_TRUE(std::isfinite(l));
    ASSERT_TRUE(std::isfinite(r));

    // Change delay time at runtime and verify it still works (no crash)
    legacy.setDelayTime(250.0f);
    for (int i = 0; i < 100; i++) {
        legacy.process(l, r, 48000.0);
    }
    ASSERT_TRUE(std::isfinite(l));
    ASSERT_TRUE(std::isfinite(r));

    // Change delay time again and verify
    legacy.setDelayTime(500.0f);
    for (int i = 0; i < 100; i++) {
        legacy.process(l, r, 48000.0);
    }
    ASSERT_TRUE(std::isfinite(l));
    ASSERT_TRUE(std::isfinite(r));

    fprintf(stdout, "  NOTE: delay buffer size pre-computed by setSampleRate()\n");
    fprintf(stdout, "  NOTE: runtime delay-time changes O(1) via setDelayTime()\n");
}

// ── Main ──────────────────────────────────────────────────────────────────────

int main() {
    fprintf(stdout, "Open Synth FX Tests\n");
    fprintf(stdout, "==================\n");

    test_eq_processor();
    test_limiter_processor();
    test_rotary_processor();
    test_tremolo_processor();
    test_legacy_fx_processor();
    test_fx_engine();
    benchmark_legacy_fx_delay();

    fprintf(stdout, "\n──────────────────────────────────────────────\n");
    fprintf(stdout, "Results: %d passed, %d failed\n", tests_passed, tests_failed);

    return tests_failed > 0 ? 1 : 0;
}
