// DSP regression tests: envelope release clicks, voice-steal fade, oscillator
// band-limiting, sub-oscillator DC and per-instance noise state.
#include "envelope.h"
#include "oscillator.h"
#include "synth_engine.h"
#include "voice_allocator.h"
#include "audio_buffer.h"

#include <cmath>
#include <complex>
#include <cstdio>
#include <memory>
#include <vector>

using namespace opensynth;

static int g_failed = 0;
static int g_passed = 0;

static void check(bool ok, const char* what) {
    if (ok) {
        ++g_passed;
        std::printf("  PASS  %s\n", what);
    } else {
        ++g_failed;
        std::printf("  FAIL  %s\n", what);
    }
}

// ── Envelope ────────────────────────────────────────────────────────────────

static void testEnvelopeReleaseDuringAttack() {
    std::printf("[envelope] noteOff during attack\n");
    const double sr = 48000.0;
    Envelope e;
    e.setAttack(100.0f);
    e.setDecay(100.0f);
    e.setSustain(0.8f);
    e.setRelease(10.0f);
    e.noteOn();
    float prev = 0.0f;
    for (int i = 0; i < 2400; ++i) prev = e.process(sr);  // 25 ms: ~0.25
    e.noteOff();
    float maxStep = 0.0f;
    int samplesToIdle = 0;
    for (int i = 0; i < 4800 && e.isActive(); ++i) {
        float v = e.process(sr);
        maxStep = std::max(maxStep, std::abs(v - prev));
        prev = v;
        ++samplesToIdle;
    }
    std::printf("        level at noteOff ~0.25, max step %.5f, release took %d samples\n",
                maxStep, samplesToIdle);
    check(maxStep < 0.01f, "no discontinuity at noteOff during attack (< 0.01)");
    check(samplesToIdle >= 470 && samplesToIdle <= 490,
          "release lasts the configured 10 ms regardless of start level");
}

static void testEnvelopeReleaseDuringDecay() {
    std::printf("[envelope] noteOff during decay\n");
    const double sr = 48000.0;
    Envelope e;
    e.setAttack(1.0f);
    e.setDecay(200.0f);
    e.setSustain(0.2f);
    e.setRelease(50.0f);
    e.noteOn();
    float prev = 0.0f;
    for (int i = 0; i < 48 + 2400; ++i) prev = e.process(sr);
    e.noteOff();
    float first = e.process(sr);
    std::printf("        before noteOff %.4f, first release sample %.4f\n", prev, first);
    check(std::abs(first - prev) < 0.01f, "release starts from the current (decay) level");
}

static void testEnvelopeCurvedRelease() {
    std::printf("[envelope] curved release from sustain\n");
    const double sr = 48000.0;
    for (int curve = 0; curve <= 2; ++curve) {
        Envelope e;
        e.setAttack(1.0f);
        e.setDecay(1.0f);
        e.setSustain(0.6f);
        e.setRelease(20.0f);
        e.setReleaseCurve(curve);
        e.noteOn();
        float prev = 0.0f;
        for (int i = 0; i < 480; ++i) prev = e.process(sr);
        e.noteOff();
        float first = e.process(sr);
        // The logarithmic curve is steep at its start by design, so for every
        // curve check the release begins at the current level: the first
        // sample is at or below it and well above zero, and it keeps falling.
        float second = e.process(sr);
        char msg[112];
        std::snprintf(msg, sizeof msg, "curve %d: release starts at the current level (%.4f -> %.4f)",
                      curve, prev, first);
        check(first <= prev && first > 0.5f * prev && second <= first, msg);
    }
}

// ── Voice stealing ──────────────────────────────────────────────────────────

static void testAllocatorOldest() {
    std::printf("[voices] oldest-voice selection\n");
    VoiceAllocator a;
    a.setSampleRate(48000.0);
    // Start voices in an order that does not match the array order.
    const int first = 77;
    a.noteOn(first, 1.0f);
    for (int n = 0; n < VoiceAllocator::MAX_VOICES; ++n) {
        if (n == first) continue;
        if (n >= 128) break;
        a.noteOn(n, 1.0f);
    }
    check(a.activeVoiceCount() == VoiceAllocator::MAX_VOICES, "all voices busy");
    Voice* stolen = a.noteOn(60, 1.0f, /*partIndex*/ 1);
    check(stolen && stolen->midiNote == first, "steals the oldest note, not the first array slot");
    check(stolen && stolen->hasPending && stolen->pendingNote == 60, "stolen voice queues the new note");
    check(stolen && stolen->stealFadeTotal == 144, "steal fade is 3 ms (144 samples at 48 kHz)");

    // Prefer the oldest *releasing* voice when there is one.
    VoiceAllocator b;
    b.setSampleRate(48000.0);
    for (int n = 0; n < VoiceAllocator::MAX_VOICES; ++n) b.noteOn(n, 1.0f);
    for (int n = 0; n < VoiceAllocator::MAX_VOICES; ++n) {
        for (int i = 0; i < 480; ++i) b.voice(n)->ampEnv.process(48000.0);
    }
    b.noteOff(90);
    b.noteOff(30);
    Voice* r = b.noteOn(64, 1.0f, 1);
    check(r && r->midiNote == 30, "prefers the oldest releasing voice");

    // A note-off for the queued note is honoured once it starts.
    b.noteOff(64, 1);
    check(r && r->pendingReleased, "note-off during the fade is remembered");
    b.startPendingNote(*r);
    bool sounded = false;
    for (int i = 0; i < 48000 && r && r->ampEnv.isActive(); ++i) {
        if (r->ampEnv.process(48000.0) > 0.5f) sounded = true;
    }
    check(r && !r->hasPending && r->midiNote == 64 && sounded && !r->ampEnv.isActive(),
          "queued note starts, plays its attack, then releases");
}

// Renders an engine with 128 sustained sine voices; optionally steals one at
// stealFrame. Returns the left channel.
static std::vector<float> renderStealScene(bool doSteal, int fadeOverrideRate, int stealFrame, int frames,
                                           double sr = 48000.0) {
    const int block = 64;
    auto eng = std::make_unique<SynthEngine>(sr, block);
    eng->setMasterVolume(0.25f);  // keep the output soft clipper near-linear
    for (int p = 0; p < 2; ++p) {
        SynthPart& part = eng->part(p);
        part.osc1.setWaveform(0);  // sine
        part.osc2.setWaveform(0);
        part.ampAttack = 1.0f;
        part.ampDecay = 1.0f;
        part.ampSustain = 1.0f;
        part.ampRelease = 2000.0f;
        part.filter.setCutoff(20000.0f);
        // Isolate the steal itself from the intentional key-click transient.
        part.realismClickMix = 0.0f;
    }
    eng->part(1).midiChannel = 1;
    if (fadeOverrideRate > 0) eng->allocator().setSampleRate(fadeOverrideRate);

    eng->noteOn(60, 1.0f, 0);  // oldest
    for (int n = 0; n < 128; ++n) {
        if (n != 60) eng->noteOn(n, 1.0f, 0);
    }
    std::vector<float> out;
    out.reserve(static_cast<size_t>(frames));
    std::vector<float> buf(static_cast<size_t>(block) * 2);
    for (int f = 0; f < frames; f += block) {
        if (doSteal && f == stealFrame) eng->noteOn(62, 1.0f, 1);
        AudioBuffer ab(buf.data(), block, 2);
        eng->process(ab);
        for (int i = 0; i < block; ++i) out.push_back(buf[static_cast<size_t>(i) * 2]);
    }
    return out;
}

// Largest second difference of (b - a): a step (click) shows up as a spike,
// while smooth signals and linear fades stay small.
static float maxKinkAround(const std::vector<float>& a, const std::vector<float>& b, int from, int to) {
    float m = 0.0f;
    for (int i = from + 2; i < to; ++i) {
        float d0 = b[i - 2] - a[i - 2];
        float d1 = b[i - 1] - a[i - 1];
        float d2 = b[i] - a[i];
        m = std::max(m, std::abs(d2 - 2.0f * d1 + d0));
    }
    return m;
}

static void testEngineStealFade() {
    std::printf("[voices] engine steal is click-free\n");
    const int stealFrame = 4800;
    const int frames = 9600;
    for (double sr : {44100.0, 48000.0, 96000.0}) {
        // The hard-reset step depends on where the old note's waveform is at
        // the steal, so try several steal points and compare the worst cases.
        auto ref = renderStealScene(false, 0, stealFrame, frames, sr);
        const int window = static_cast<int>(200.0 * sr / 48000.0);
        float fadedKink = 0.0f, hardKink = 0.0f;
        for (int k = 0; k < 6; ++k) {
            const int at = stealFrame + 64 * k;
            auto faded = renderStealScene(true, 0, at, frames, sr);
            auto hard = renderStealScene(true, 1, at, frames, sr);  // 1-sample fade = old hard reset
            fadedKink = std::max(fadedKink, maxKinkAround(ref, faded, at - 4, at + window));
            hardKink = std::max(hardKink, maxKinkAround(ref, hard, at - 4, at + window));
        }
        std::printf("        %.1f kHz: max discontinuity (2nd difference) of the stolen voice over 6 steal points:"
                    " hard reset %.5f, 3 ms fade %.5f (%.1fx lower)\n", sr / 1000.0, hardKink, fadedKink,
                    fadedKink > 0.0f ? hardKink / fadedKink : 0.0f);
        char msg[128];
        std::snprintf(msg, sizeof msg, "%.1f kHz: fade cuts the steal discontinuity by more than 10x", sr / 1000.0);
        check(hardKink > 0.0f && fadedKink < 0.1f * hardKink, msg);

        VoiceAllocator a;
        a.setSampleRate(sr);
        for (int n = 0; n < VoiceAllocator::MAX_VOICES; ++n) a.noteOn(n, 1.0f);
        Voice* v = a.noteOn(60, 1.0f, 1);  // other part, so it steals
        const int expect = static_cast<int>(std::lround(0.003 * sr));
        std::snprintf(msg, sizeof msg, "%.1f kHz: steal fade is 3 ms (%d samples)", sr / 1000.0, expect);
        check(v && std::abs(v->stealFadeTotal - expect) <= 1, msg);
    }
}

// ── Retrigger ───────────────────────────────────────────────────────────────

static void testRetrigger() {
    std::printf("[envelope] retrigger of a held note continues from the current level\n");
    const double sr = 48000.0;
    const char* curveNames[] = {"linear", "exponential", "logarithmic"};
    for (int curve = 0; curve < 3; ++curve) {
        Envelope e;
        e.setAttack(10.0f);
        e.setDecay(50.0f);
        e.setSustain(0.6f);
        e.setRelease(100.0f);
        e.setAttackCurve(curve);
        e.noteOn();
        float prev = 0.0f;
        for (int i = 0; i < 9600; ++i) prev = e.process(sr);  // at sustain
        e.retrigger();
        float maxStep = 0.0f, peak = 0.0f;
        for (int i = 0; i < 2400; ++i) {
            float v = e.process(sr);
            maxStep = std::max(maxStep, std::abs(v - prev));
            peak = std::max(peak, v);
            prev = v;
        }
        char msg[128];
        std::snprintf(msg, sizeof msg, "%s attack: no step on retrigger (max step %.4f), re-attacks to 1.0",
                      curveNames[curve], maxStep);
        // A 10 ms attack moves at most ~1/480 per sample on the linear curve;
        // the curved shapes are steeper at one end (exp: 3x at the start).
        check(maxStep < 0.01f && peak > 0.999f, msg);
    }

    // Retrigger during release resumes the attack from the release level.
    {
        Envelope e;
        e.setAttack(5.0f); e.setDecay(5.0f); e.setSustain(0.8f); e.setRelease(200.0f);
        e.noteOn();
        float prev = 0.0f;
        for (int i = 0; i < 2400; ++i) prev = e.process(sr);
        e.noteOff();
        for (int i = 0; i < 2400; ++i) prev = e.process(sr);
        e.retrigger();
        float v = e.process(sr);
        check(std::abs(v - prev) < 0.01f && prev > 0.1f, "retrigger during release continues from the release level");
    }

    // Through the allocator: same note on a sounding voice.
    {
        VoiceAllocator a;
        a.setSampleRate(sr);
        Voice* v = a.noteOn(60, 1.0f);
        v->ampEnv.setAttack(5.0f); v->ampEnv.setDecay(20.0f); v->ampEnv.setSustain(0.6f);
        float prev = 0.0f;
        for (int i = 0; i < 4800; ++i) prev = v->ampEnv.process(sr);
        v->osc1Phase[0] = 0.37f;
        Voice* r = a.noteOn(60, 1.0f);
        float next = r ? r->ampEnv.process(sr) : -1.0f;
        std::printf("        allocator retrigger step: %.4f (was %.4f with a reset to 0)\n",
                    std::abs(next - prev), prev);
        check(r == v && std::abs(next - prev) < 0.01f, "allocator retrigger reuses the voice without an amplitude step");
        check(r && r->osc1Phase[0] == 0.37f, "retrigger keeps the oscillator phase (no waveform jump)");
    }
}

// ── Retrigger velocity ramp ─────────────────────────────────────────────────

static void testRetriggerVelocityRamp() {
    std::printf("[voice] retrigger ramps velocity over ~3 ms; fresh note-on is instant\n");
    const double rates[] = {44100.0, 48000.0, 96000.0};
    for (double sr : rates) {
        VoiceAllocator a;
        a.setSampleRate(sr);
        Voice* v = a.noteOn(60, 0.1f);
        char msg[160];
        std::snprintf(msg, sizeof msg, "%.1f kHz: fresh note-on applies velocity instantly", sr / 1000.0);
        check(v && v->velocity == 0.1f && v->targetVelocity == 0.1f, msg);
        if (!v) continue;
        v->ampEnv.setAttack(5.0f); v->ampEnv.setDecay(20.0f); v->ampEnv.setSustain(0.6f);
        float prev = 0.0f;
        const int settle = static_cast<int>(0.1 * sr);
        for (int i = 0; i < settle; ++i) {
            v->advanceVelocity(sr);
            prev = v->ampEnv.process(sr) * v->velocity;
        }
        Voice* r = a.noteOn(60, 1.0f);
        float maxStep = 0.0f;
        int reached = -1;
        const int len = static_cast<int>(0.02 * sr);
        for (int i = 0; i < len && r; ++i) {
            r->advanceVelocity(sr);
            float g = r->ampEnv.process(sr) * r->velocity;
            maxStep = std::max(maxStep, std::abs(g - prev));
            prev = g;
            if (reached < 0 && r->velocity == 1.0f) reached = i + 1;
        }
        const int expect = static_cast<int>(0.003 * sr);
        std::printf("        %.1f kHz: retrigger 0.1 -> 1.0 max gain step %.4f, velocity settles in %d samples\n",
                    sr / 1000.0, maxStep, reached);
        std::snprintf(msg, sizeof msg, "%.1f kHz: retrigger velocity 0.1 -> 1.0 has no step (< 0.02) and settles in 3 ms",
                      sr / 1000.0);
        check(r == v && maxStep < 0.02f && std::abs(reached - expect) <= 1, msg);
    }
}

// ── Pulse edge rounding ─────────────────────────────────────────────────────

static void testPulseEdgeRounding() {
    std::printf("[osc] BLEP edges never overshoot when phase lands on the edge\n");
    // Regression: wrap01(phase + 1 - pw) rounded to 1.0 just past the edge,
    // giving a one-sample spike to |2.0| (seen at pw 0.02, 20 Hz).
    const double sr = 48000.0;
    float worst = 0.0f;
    float worstPw = 0.0f, worstF = 0.0f;
    const float freqs[] = {20.0f, 27.5f, 110.0f, 1000.0f};
    for (int wf : {1, 5}) {  // square, pulse (Dart ids)
        for (float pw = 0.01f; pw < 0.995f; pw += 0.01f) {
            for (float f : freqs) {
                Oscillator o;
                o.setWaveform(wf);
                o.setVolume(1.0f);
                o.setPulseWidth(pw);
                o.setSubOscMode(1);  // square sub, exercises its edge too
                o.setSubOscVolume(0.5f);
                OscVoiceState st;
                const float inc = f / static_cast<float>(sr);
                float phase = 0.0f;
                for (int i = 0; i < 48000; ++i) {
                    float v = std::abs(o.processVoice(phase, inc, 0, st));
                    if (v > worst) { worst = v; worstPw = pw; worstF = f; }
                    phase += inc;
                    if (phase >= 1.0f) phase -= 1.0f;
                }
            }
        }
    }
    std::printf("        peak |output| over square/pulse, pw 0.01-0.99, 20 Hz-1 kHz: %.4f (pw %.2f, %.1f Hz)\n",
                worst, worstPw, worstF);
    check(worst <= 1.05f, "no overshoot spikes (|out| <= 1.05)");

    // The exact reported case, sample by sample around every edge.
    Oscillator o;
    o.setWaveform(5);
    o.setVolume(1.0f);
    o.setPulseWidth(0.02f);
    OscVoiceState st;
    const float inc = 20.0f / static_cast<float>(sr);
    float phase = 0.0f, peak = 0.0f;
    for (int i = 0; i < 48000 * 5; ++i) {
        peak = std::max(peak, std::abs(o.processVoice(phase, inc, 0, st)));
        phase += inc;
        if (phase >= 1.0f) phase -= 1.0f;
    }
    char msg[96];
    std::snprintf(msg, sizeof msg, "pulse pw 0.02 at 20 Hz: peak %.4f <= 1.0", peak);
    check(peak <= 1.0f + 1e-6f, msg);
}

// ── Oscillator band-limiting ────────────────────────────────────────────────

static void fft(std::vector<std::complex<double>>& x) {
    const size_t n = x.size();
    for (size_t i = 1, j = 0; i < n; ++i) {
        size_t bit = n >> 1;
        for (; j & bit; bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) std::swap(x[i], x[j]);
    }
    for (size_t len = 2; len <= n; len <<= 1) {
        double ang = -2.0 * M_PI / static_cast<double>(len);
        std::complex<double> wl(std::cos(ang), std::sin(ang));
        for (size_t i = 0; i < n; i += len) {
            std::complex<double> w(1.0);
            for (size_t k = 0; k < len / 2; ++k) {
                auto u = x[i + k];
                auto v = x[i + k + len / 2] * w;
                x[i + k] = u + v;
                x[i + k + len / 2] = u - v;
                w *= wl;
            }
        }
    }
}

// Ratio (dB) of energy outside the true harmonics of f0 to the total energy.
static double aliasDb(const std::vector<float>& sig, double f0, double sr) {
    const size_t n = sig.size();
    std::vector<std::complex<double>> x(n);
    for (size_t i = 0; i < n; ++i) {
        double w = 0.35875 - 0.48829 * std::cos(2 * M_PI * i / (n - 1)) +
                   0.14128 * std::cos(4 * M_PI * i / (n - 1)) -
                   0.01168 * std::cos(6 * M_PI * i / (n - 1));
        x[i] = sig[i] * w;
    }
    fft(x);
    const double binHz = sr / static_cast<double>(n);
    double total = 0.0;
    double harmonic = 0.0;
    for (size_t k = 1; k < n / 2; ++k) {
        double p = std::norm(x[k]);
        total += p;
        double f = static_cast<double>(k) * binHz;
        double h = std::round(f / f0);
        // h == 0 is the DC region (window leakage of a pulse's DC offset).
        if (std::abs(f - h * f0) <= 6.0 * binHz) harmonic += p;
    }
    double alias = std::max(total - harmonic, 1e-30);
    return 10.0 * std::log10(alias / total);
}

static std::vector<float> renderOsc(int dartWave, double f0, double sr, size_t n, float pw = 0.5f) {
    Oscillator o;
    o.setWaveform(dartWave);
    o.setVolume(1.0f);
    o.setPulseWidth(pw);
    std::vector<float> out(n);
    float phase = 0.0f;
    const float inc = static_cast<float>(f0 / sr);
    for (size_t i = 0; i < n; ++i) {
        out[i] = o.process(phase, 0, static_cast<float>(f0), sr);
        phase += inc;
        if (phase >= 1.0f) phase -= 1.0f;
    }
    return out;
}

static std::vector<float> renderNaive(int which, double f0, double sr, size_t n, float pw = 0.5f) {
    std::vector<float> out(n);
    float phase = 0.0f;
    const float inc = static_cast<float>(f0 / sr);
    for (size_t i = 0; i < n; ++i) {
        switch (which) {
            case 0: out[i] = 2.0f * phase - 1.0f; break;
            case 1: out[i] = phase < 0.5f ? 1.0f : -1.0f; break;
            case 2: out[i] = 4.0f * std::abs(phase - 0.5f) - 1.0f; break;
            default: out[i] = phase < pw ? 1.0f : -1.0f; break;
        }
        phase += inc;
        if (phase >= 1.0f) phase -= 1.0f;
    }
    return out;
}

static void testAliasing() {
    // Triangle (BLAMP) thresholds are per rate, 0.5 dB under the measured
    // improvement: 44.1k 3.5, 48k 4.9, 88.2k 4.6, 96k 2.9 dB.
    const double rates[] = {44100.0, 48000.0, 88200.0, 96000.0};
    const double triThreshold[] = {3.0, 4.4, 4.1, 2.4};
    const double f0 = 4987.0;
    const size_t n = 16384;
    struct Case { const char* name; int dart; int naive; float pw; double minGainDb; };
    const Case cases[] = {
        {"saw", 1, 0, 0.5f, 10.0},
        {"square", 2, 1, 0.5f, 10.0},
        {"pulse 30%", 5, 3, 0.3f, 10.0},
        {"triangle", 3, 2, 0.5f, 0.0},
    };
    for (int ri = 0; ri < 4; ++ri) {
        const double sr = rates[ri];
        std::printf("[oscillator] aliasing at f0 = 4987 Hz, %.1f kHz\n", sr / 1000.0);
        for (Case c : cases) {
            if (c.dart == 3) c.minGainDb = triThreshold[ri];
            double before = aliasDb(renderNaive(c.naive, f0, sr, n, c.pw), f0, sr);
            double after = aliasDb(renderOsc(c.dart, f0, sr, n, c.pw), f0, sr);
            std::printf("        %-10s alias energy: naive %.1f dB, band-limited %.1f dB (%.1f dB better)\n",
                        c.name, before, after, before - after);
            char msg[96];
            std::snprintf(msg, sizeof msg, "%.1f kHz: %s aliasing reduced by >= %.1f dB",
                          sr / 1000.0, c.name, c.minGainDb);
            check(before - after >= c.minGainDb, msg);
        }
    }
}

// ── Sub oscillator and noise ────────────────────────────────────────────────

static void testSubOscillator() {
    std::printf("[oscillator] sub oscillator\n");
    const double sr = 48000.0;
    for (int mode = 1; mode <= 3; ++mode) {
        Oscillator o;
        o.setWaveform(0);  // sine
        o.setVolume(1.0f);
        o.setSubOscMode(mode);
        o.setSubOscVolume(1.0f);
        OscVoiceState st;
        const float f = 220.0f;
        const float inc = static_cast<float>(f / sr);
        float phase = 0.0f;
        double sum = 0.0;
        double sumSq = 0.0;
        const int n = 48000 * 2;
        for (int i = 0; i < n; ++i) {
            float v = o.processVoice(phase, inc, 0, st);
            sum += v;
            sumSq += static_cast<double>(v) * v;
            phase += inc;
            if (phase >= 1.0f) phase -= 1.0f;
        }
        double mean = sum / n;
        double rms = std::sqrt(sumSq / n);
        std::printf("        mode %d: mean %.4f, rms %.3f\n", mode, mean, rms);
        char msg[96];
        std::snprintf(msg, sizeof msg, "sub mode %d has no DC (|mean| < 0.02) and real level (rms > 0.3)", mode);
        check(std::abs(mean) < 0.02 && rms > 0.3, msg);
    }
}

static void testBrownNoiseState() {
    std::printf("[oscillator] brown noise state is per instance / per voice\n");
    const double sr = 48000.0;
    auto make = [] {
        Oscillator o;
        o.setWaveform(4);
        o.setNoiseType(2);
        o.setVolume(1.0f);
        return o;
    };
    const int n = 4096;
    const float inc = 0.0137f;
    // Reference: one oscillator alone.
    std::vector<float> ref(n);
    {
        Oscillator a = make();
        float ph = 0.0f;
        for (int i = 0; i < n; ++i) {
            ref[i] = a.process(ph, 0, 657.6f, sr);
            ph += inc;
            if (ph >= 1.0f) ph -= 1.0f;
        }
    }
    // Interleave with a second instance on different phases.
    bool same = true;
    {
        Oscillator a = make();
        Oscillator b = make();
        float pa = 0.0f;
        float pb = 0.5f;
        for (int i = 0; i < n; ++i) {
            float va = a.process(pa, 0, 657.6f, sr);
            (void)b.process(pb, 0, 900.0f, sr);
            if (va != ref[i]) same = false;
            pa += inc;
            if (pa >= 1.0f) pa -= 1.0f;
            pb += 0.0211f;
            if (pb >= 1.0f) pb -= 1.0f;
        }
    }
    check(same, "two oscillator instances do not share brown-noise state");

    // Two voices on one oscillator (per-voice state).
    bool sameVoices = true;
    {
        Oscillator a = make();
        OscVoiceState v1;
        OscVoiceState v2;
        float p1 = 0.0f;
        float p2 = 0.25f;
        for (int i = 0; i < n; ++i) {
            float x = a.processVoice(p1, inc, 0, v1);
            (void)a.processVoice(p2, 0.03f, 0, v2);
            if (x != ref[i]) sameVoices = false;
            p1 += inc;
            if (p1 >= 1.0f) p1 -= 1.0f;
            p2 += 0.03f;
            if (p2 >= 1.0f) p2 -= 1.0f;
        }
    }
    check(sameVoices, "two voices on one oscillator do not share brown-noise state");
}

int main() {
    testEnvelopeReleaseDuringAttack();
    testEnvelopeReleaseDuringDecay();
    testEnvelopeCurvedRelease();
    testAllocatorOldest();
    testEngineStealFade();
    testRetrigger();
    testRetriggerVelocityRamp();
    testPulseEdgeRounding();
    testAliasing();
    testSubOscillator();
    testBrownNoiseState();
    std::printf("\nResults: %d passed, %d failed\n", g_passed, g_failed);
    return g_failed == 0 ? 0 : 1;
}
