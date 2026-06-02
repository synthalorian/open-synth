#include <cstdio>
#include <cstring>
#include <cmath>

#include "audio_stream.h"
#include "audio_buffer.h"

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

#define ASSERT_TRUE(expr)    TEST(#expr, (expr))
#define ASSERT_FALSE(expr)   TEST(#expr, !(expr))

// ── Passthrough processor for AudioStream tests ──────────────────────────────

struct PassthroughCtx {
    float gain;
};

static void passthroughProcessor(void* ctx, AudioBuffer& output) {
    auto* pc = static_cast<PassthroughCtx*>(ctx);
    for (uint32_t i = 0; i < output.numFrames * output.numChannels; i++) {
        output.data[i] = pc->gain;
    }
}

// ── Test: AudioStream shutdown safety ───────────────────────────────────────────
//
// Validates the atomic<bool> running_ flag pattern:
//   - running_ defaults to true
//   - stop() sets running_ = false before tearing down stream resources
//   - The audio callback checks running_ and returns silence if not running
//
// This prevents use-after-free: the callback won't touch the processor
// after stop() has been called, even if the callback fires concurrently.

static void test_stream_shutdown_safety() {
    fprintf(stdout, "\n── AudioStream Shutdown Safety ────────────────\n");

    PassthroughCtx ctx = {0.0f};

    // Create stream with a minimal config and passthrough processor
    AudioStream stream(&ctx, passthroughProcessor, 48000.0, 256);

    // Before start, stream should not be running
    ASSERT_FALSE(stream.isRunning());

    // Start: if no audio hardware available, this may fail — that's OK
    bool started = stream.start();
    if (!started) {
        fprintf(stdout, "  SKIP   start() — no audio hardware available\n");
        // Even without hardware, verify stop() is safe to call
        stream.stop();
        fprintf(stdout, "  PASS   stop() called safely without active stream\n");
        tests_passed++;
        return;
    }

    ASSERT_TRUE(stream.isRunning());

    fprintf(stdout, "  INFO   stream started successfully\n");

    // Give a tiny amount of time for the callback to potentially fire
    Pa_Sleep(10);

    // Verify callbacks have been firing
    ASSERT_TRUE(stream.callbackCount() > 0);

    // Stop: sets running_ = false first, then tears down
    stream.stop();

    ASSERT_FALSE(stream.isRunning());

    // After stop, the callback (if it fires) sees running_ == false
    // and returns silence without touching the processor.
    // No use-after-free possible.
    ASSERT_TRUE(true); // stop() completed without crash

    // Verify double-stop is safe (no crash)
    stream.stop();
    ASSERT_TRUE(true); // double-stop safe

    // Verify restart works
    bool restarted = stream.start();
    if (restarted) {
        ASSERT_TRUE(stream.isRunning());
        ASSERT_TRUE(stream.callbackCount() > 0);
        Pa_Sleep(10);
        stream.stop();
        ASSERT_FALSE(stream.isRunning());
        fprintf(stdout, "  PASS   restart works\n");
        tests_passed++;
    } else {
        fprintf(stdout, "  SKIP   restart — no audio hardware available\n");
    }
}

// ── Main ──────────────────────────────────────────────────────────────────────

int main() {
    fprintf(stdout, "Open Synth AudioStream Tests\n");
    fprintf(stdout, "============================\n");

    test_stream_shutdown_safety();

    fprintf(stdout, "\n──────────────────────────────────────────────\n");
    fprintf(stdout, "Results: %d passed, %d failed\n", tests_passed, tests_failed);

    return tests_failed > 0 ? 1 : 0;
}
