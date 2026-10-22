// Regression tests for the wavetable mip levels and the state-variable
// filter (output taps, parameter smoothing, cutoff cap, envelope range).
// Prints before/after measurements; exits non-zero on any failure.

#include "filter.h"
#include "oscillator.h"
#include "wavetable_bank.h"
#include "wavetable_oscillator.h"
#include "synth_engine.h"
#include "preset_data.h"
#include "preset_library_full.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <complex>
#include <cstdio>
#include <fstream>
#include <vector>

using namespace opensynth;

static int gFailures = 0;
static int gChecks = 0;

static void check(bool ok, const char* what) {
    ++gChecks;
    std::printf("  [%s] %s\n", ok ? "PASS" : "FAIL", what);
    if (!ok) ++gFailures;
}

// ── Helpers ─────────────────────────────────────────────────────────────────

static void fft(std::vector<std::complex<double>>& a) {
    const size_t n = a.size();
    for (size_t i = 1, j = 0; i < n; ++i) {
        size_t bit = n >> 1;
        for (; j & bit; bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) std::swap(a[i], a[j]);
    }
    for (size_t len = 2; len <= n; len <<= 1) {
        const double ang = -2.0 * M_PI / static_cast<double>(len);
        const std::complex<double> wl(std::cos(ang), std::sin(ang));
        for (size_t i = 0; i < n; i += len) {
            std::complex<double> w(1.0);
            for (size_t k = 0; k < len / 2; ++k) {
                auto u = a[i + k], v = a[i + k + len / 2] * w;
                a[i + k] = u + v;
                a[i + k + len / 2] = u - v;
                w *= wl;
            }
        }
    }
}

// Fraction of signal energy that is not at a harmonic of f0, in dB.
// Blackman-Harris window; bins within +-6 of k*f0 (k >= 0) count as harmonic.
static double aliasDb(const std::vector<float>& x, double f0, double sr) {
    const size_t n = x.size();
    std::vector<std::complex<double>> a(n);
    for (size_t i = 0; i < n; ++i) {
        const double t = 2.0 * M_PI * static_cast<double>(i) / static_cast<double>(n - 1);
        const double w = 0.35875 - 0.48829 * std::cos(t) + 0.14128 * std::cos(2 * t) - 0.01168 * std::cos(3 * t);
        a[i] = x[i] * w;
    }
    fft(a);
    const double binHz = sr / static_cast<double>(n);
    double harm = 0.0, other = 0.0;
    for (size_t b = 0; b <= n / 2; ++b) {
        const double e = std::norm(a[b]);
        const double f = b * binHz;
        const double k = std::round(f / f0);
        if (std::fabs(f - k * f0) <= 6.0 * binHz) harm += e; else other += e;
    }
    return 10.0 * std::log10(other / (harm + other) + 1e-30);
}

// The pre-change filter, kept verbatim for before/after comparison
// (key tracking omitted; LP/BP returned the integrator states).
struct OldFilter {
    int type = 0;
    float cutoff = 20000.0f, resonance = 0.0f, envAmount = 0.0f, drive = 0.0f;
    float lp = 0, bp = 0, hp = 0;
    static float applyDrive(float s, float a) {
        if (a < 0.01f) return s;
        return std::tanh(s * (1.0f + a * 4.0f)) / std::tanh(1.0f + a * 4.0f);
    }
    float process(float input, float envMod, double sr) {
        float c = cutoff * std::pow(2.0f, (envMod * envAmount * 5.0f) / 12.0f);
        c = std::clamp(c, 20.0f, 20000.0f);
        float s = applyDrive(input, drive);
        float g = std::tan(M_PI * c / (float)sr);
        g = std::clamp(g, 0.0f, 10.0f);
        float k = 2.0f - 2.0f * std::clamp(resonance, 0.0f, 0.99f);
        const float a1 = 1.0f / (1.0f + g * (g + k)), a2 = g * a1, a3 = g * a2;
        const float v3 = s - lp;
        const float v1 = a1 * bp + a2 * v3;
        const float v2 = lp + a2 * bp + a3 * v3;
        bp = 2.0f * v1 - bp;
        lp = 2.0f * v2 - lp;
        hp = s - k * v1 - v2;
        switch (type) {
        case 0: return lp;
        case 1: return hp;
        case 2: return bp;
        case 3: return lp + hp;
        }
        return lp;
    }
};

// Magnitude (dB) of a filter at f, from an 8192-sample impulse response.
template <typename Fn>
static std::vector<double> responseDb(Fn&& step, const std::vector<double>& freqs, double sr) {
    const int n = 8192;
    std::vector<float> h(n);
    for (int i = 0; i < n; ++i) h[i] = step(i == 0 ? 1.0f : 0.0f);
    std::vector<double> out;
    for (double f : freqs) {
        std::complex<double> acc = 0.0;
        for (int i = 0; i < n; ++i) acc += (double)h[i] * std::polar(1.0, -2.0 * M_PI * f * i / sr);
        out.push_back(20.0 * std::log10(std::abs(acc) + 1e-12));
    }
    return out;
}

// Ideal (bilinear-transformed analog SVF) magnitude in dB.
static double idealDb(int type, double f, double fc, double k, double sr) {
    const double x = std::tan(M_PI * f / sr) / std::tan(M_PI * fc / sr);
    const double re = 1.0 - x * x, im = k * x;
    const double den = std::sqrt(re * re + im * im);
    double num = 1.0;
    if (type == 1) num = x * x;            // HP
    else if (type == 2) num = x;           // BP (v1)
    else if (type == 3) num = std::fabs(1.0 - x * x); // notch
    return 20.0 * std::log10(num / den + 1e-12);
}

static float d4(const std::vector<float>& y, size_t n) {
    return std::fabs(y[n] - 4 * y[n - 1] + 6 * y[n - 2] - 4 * y[n - 3] + y[n - 4]);
}

// ── Wavetable tests ─────────────────────────────────────────────────────────

static void testWavetableMips() {
    std::printf("\nWavetable mip levels\n");
    const double sr = 48000.0;

    auto t0 = std::chrono::steady_clock::now();
    (void)getBuiltinWavetable(0);  // forces table + mip construction
    auto t1 = std::chrono::steady_clock::now();
    size_t ownedBuffers = 0, tables = 0;
    for (int t = 0; t < getBuiltinWavetableCount(); ++t) {
        for (float vel : {0.2f, 0.6f, 0.9f}) {
            const Wavetable* wt = getBuiltinWavetableWithVelocity(t, vel);
            ++tables;
            for (int l = 1; l < wt->numMips; ++l)
                if (wt->mips[l] != wt->mips[l - 1]) ++ownedBuffers;
        }
    }
    std::printf("  init incl. mips: %.1f ms, extra mip buffers: %zu (%.2f MB, counted per velocity layer)\n",
                std::chrono::duration<double, std::milli>(t1 - t0).count(), ownedBuffers,
                ownedBuffers * 2048 * 4 / 1048576.0);
    check(getBuiltinWavetable(3)->numMips > 1, "mip levels are built for builtin tables");

    // Low notes read the original table bit-for-bit (no tone change).
    {
        WavetableOscillator osc;
        osc.setWavetable(getBuiltinWavetable(3));
        const double inc = 440.0 / sr;
        bool same = true;
        float ph = 0.0f;
        for (int i = 0; i < 4800; ++i) {
            ph += (float)inc; if (ph >= 1.0f) ph -= 1.0f;
            same = same && osc.getSampleAtPhase(ph) == osc.getSampleAtPhase(ph, inc);
        }
        check(same, "A4 on a 16-harmonic table is bit-identical to the original table");
    }

    // Aliasing at high notes, old (full table) vs new (mip level).
    struct Case { int table; const char* name; double f0; };
    const Case cases[] = {
        {30, "Saw Lead", 2637.0}, {30, "Saw Lead", 4186.0},
        {3,  "Brass",    3520.0}, {7,  "Bell",     1760.0}, {7, "Bell", 3520.0},
    };
    for (const auto& c : cases) {
        WavetableOscillator osc;
        osc.setWavetable(getBuiltinWavetable(c.table));
        const double inc = c.f0 / sr;
        std::vector<float> a(16384), b(16384);
        double ph = 0.0;
        for (size_t i = 0; i < a.size(); ++i) {
            a[i] = osc.getSampleAtPhase((float)ph);
            b[i] = osc.getSampleAtPhase((float)ph, inc);
            ph += inc; ph -= std::floor(ph);
        }
        const double before = aliasDb(a, c.f0, sr), after = aliasDb(b, c.f0, sr);
        std::printf("  %-8s %6.0f Hz: alias energy %7.1f dB -> %7.1f dB\n", c.name, c.f0, before, after);
        char msg[128];
        std::snprintf(msg, sizeof msg, "%s at %.0f Hz: aliasing reduced by >= 20 dB (or below -90 dB)", c.name, c.f0);
        check(after <= -90.0 || after <= before - 20.0, msg);
    }

    // The Oscillator wavetable path uses the band-limited read.
    {
        Oscillator osc;
        osc.setWaveform(9);  // WT_BRASS
        WavetableOscillator ref;
        ref.setWavetable(getBuiltinWavetable(3));
        const float f = 3520.0f;
        bool same = true;
        float ph = 0.0f;
        for (int i = 0; i < 2000; ++i) {
            ph += f / (float)sr; if (ph >= 1.0f) ph -= 1.0f;
            const float o = osc.process(ph, 0, f, sr) / std::max(osc.volume(), 1e-6f);
            const float r = ref.getSampleAtPhase(ph, osc.phaseIncrement(f, 0, sr));
            same = same && std::fabs(o - r) < 1e-4f;
        }
        check(same, "Oscillator::process reads the mip level for its pitch");
    }

    // Move keeps ownership of mip buffers (no double free / leak path).
    {
        Wavetable w;
        w.samples = new float[2048];
        w.sampleCount = 2048;
        for (int i = 0; i < 2048; ++i) w.samples[i] = (i < 1024) ? 1.0f : -1.0f;
        w.buildMips();
        Wavetable m(std::move(w));
        check(m.numMips > 1 && w.numMips == 0 && w.samples == nullptr, "moved Wavetable takes its mips");
    }
}

// ── Filter tests ────────────────────────────────────────────────────────────

static void testFilterTaps() {
    std::printf("\nFilter outputs vs ideal bilinear SVF (48 kHz, resonance 0.5)\n");
    const double sr = 48000.0;
    std::vector<double> freqs;
    for (double f = 100.0; f < 23000.0; f *= 1.12) freqs.push_back(f);
    const char* names[] = {"LP", "HP", "BP", "Notch"};
    for (int type = 0; type < 4; ++type) {
        for (double fc : {1000.0, 8000.0, 16000.0}) {
            const float res = 0.5f;
            const double k = 2.0 - 2.0 * res;
            OldFilter of; of.type = type; of.cutoff = (float)fc; of.resonance = res;
            StateVariableFilter nf; nf.setType(type); nf.setCutoff((float)fc); nf.setResonance(res);
            FilterState st;
            auto oldR = responseDb([&](float x) { return of.process(x, 0.0f, sr); }, freqs, sr);
            auto newR = responseDb([&](float x) { return nf.process(x, 0.0f, sr, 69, st); }, freqs, sr);
            double oldErr = 0, newErr = 0;
            for (size_t i = 0; i < freqs.size(); ++i) {
                const double id = idealDb(type, freqs[i], fc, k, sr);
                if (id < -60.0) continue;  // ignore deep stop band
                oldErr = std::max(oldErr, std::fabs(oldR[i] - id));
                newErr = std::max(newErr, std::fabs(newR[i] - id));
            }
            std::printf("  %-5s fc=%5.0f: max error %6.2f dB -> %6.3f dB\n", names[type], fc, oldErr, newErr);
            char msg[96];
            std::snprintf(msg, sizeof msg, "%s at %.0f Hz matches the ideal response within 0.1 dB", names[type], fc);
            check(newErr < 0.1, msg);
        }
    }
}

static void testSmoothing() {
    std::printf("\nParameter steps (peak 4th difference in the 20 ms after the step / larger settled value, 1 kHz sine at -26 dBFS)\n");
    const double sr = 48000.0;
    struct StepCase { const char* name; int which; float from, to; };
    const StepCase cases[] = {
        {"cutoff 5000 -> 300 Hz", 0, 5000.0f, 300.0f},
        {"resonance 0 -> 0.9",    1, 0.0f, 0.9f},
        {"drive 0 -> 0.8",        2, 0.0f, 0.8f},
    };
    for (const auto& c : cases) {
        OldFilter of; of.cutoff = 2000.0f; of.resonance = 0.3f;
        StateVariableFilter nf; nf.setCutoff(2000.0f); nf.setResonance(0.3f);
        FilterState st;
        auto apply = [&](float v) {
            if (c.which == 0) { of.cutoff = v; nf.setCutoff(v); }
            if (c.which == 1) { of.resonance = v; nf.setResonance(v); }
            if (c.which == 2) { of.drive = v; nf.setDrive(v); }
        };
        apply(c.from);
        const int n = 9600, stepAt = 4800;
        std::vector<float> yo(n), yn(n);
        for (int i = 0; i < n; ++i) {
            if (i == stepAt) apply(c.to);
            // small level keeps the saturator near-linear, so its gain step shows
            const float x = 0.05f * std::sin(2.0 * M_PI * 1000.0 * i / sr);
            yo[i] = of.process(x, 0.0f, sr);
            yn[i] = nf.process(x, 0.0f, sr, 69, st);
        }
        float baseO = 0, baseN = 0, spikeO = 0, spikeN = 0;
        // steady state = the larger of the settled signal before and after
        for (int i = stepAt - 960; i < stepAt; ++i) { baseO = std::max(baseO, d4(yo, i)); baseN = std::max(baseN, d4(yn, i)); }
        for (int i = n - 960; i < n; ++i) { baseO = std::max(baseO, d4(yo, i)); baseN = std::max(baseN, d4(yn, i)); }
        for (int i = stepAt; i < stepAt + 960; ++i) { spikeO = std::max(spikeO, d4(yo, i)); spikeN = std::max(spikeN, d4(yn, i)); }
        const float before = spikeO / baseO, after = spikeN / baseN;
        std::printf("  %-22s: spike/steady %7.1fx -> %5.2fx\n", c.name, before, after);
        char msg[112];
        std::snprintf(msg, sizeof msg, "%s: step transient < 5x steady state and >= 10x smaller than before", c.name);
        check(after < 5.0f && after * 10.0f <= before, msg);
    }

    // Smoothing must not delay the first sample of a fresh voice.
    StateVariableFilter nf; nf.setCutoff(300.0f);
    FilterState st;
    nf.process(0.0f, 0.0f, 48000.0, 69, st);
    check(std::fabs(std::exp2(st.cutoffLog2) - 300.0f) < 0.01f, "fresh state snaps to the target cutoff");
}

static void testCutoffCap() {
    std::printf("\nCutoff cap\n");
    // 22.05 kHz: the old fixed 20 kHz cap is above Nyquist, tan() goes
    // negative, g clamps to 0 and the low-pass outputs silence.
    const double sr = 22050.0;
    OldFilter of; of.cutoff = 20000.0f;
    StateVariableFilter nf; nf.setCutoff(20000.0f);
    FilterState st;
    double eo = 0, en = 0, ex = 0;
    for (int i = 0; i < 22050; ++i) {
        const float x = std::sin(2.0 * M_PI * 1000.0 * i / sr);
        const float o = of.process(x, 0.0f, sr), nn = nf.process(x, 0.0f, sr, 69, st);
        if (i > 2000) { eo += o * o; en += nn * nn; ex += x * x; }
    }
    const double go = 10 * std::log10(eo / ex + 1e-30), gn = 10 * std::log10(en / ex + 1e-30);
    std::printf("  22.05 kHz, cutoff 20 kHz, 1 kHz sine: gain %.1f dB -> %.2f dB\n", go, gn);
    check(std::fabs(gn) < 0.5, "cutoff above 0.45*sr is capped, not inverted");

    // 96 kHz: envelope can push past the old 20 kHz ceiling, up to 0.45*sr.
    StateVariableFilter f96; f96.setCutoff(20000.0f); f96.setEnvAmount(1.0f);
    f96.setEnvRangeSemitones(24.0f);
    FilterState s96;
    bool finite = true;
    for (int i = 0; i < 9600; ++i)
        finite = finite && std::isfinite(f96.process(std::sin(i * 0.3f), 1.0f, 96000.0, 69, s96));
    check(finite, "96 kHz with env pushing past 43.2 kHz stays finite");
}

static void testEnvRange() {
    std::printf("\nEnvelope range\n");
    const double sr = 48000.0;
    auto gainAt = [&](float rangeSemis, bool setRange) {
        StateVariableFilter f; f.setCutoff(500.0f); f.setEnvAmount(1.0f);
        if (setRange) f.setEnvRangeSemitones(rangeSemis);
        FilterState st;
        double ey = 0, ex = 0;
        for (int i = 0; i < 9600; ++i) {
            const float x = std::sin(2.0 * M_PI * 2000.0 * i / sr);
            const float y = f.process(x, 1.0f, sr, 69, st);
            if (i > 2400) { ey += y * y; ex += x * x; }
        }
        return 10 * std::log10(ey / ex);
    };
    // Reference: env 0 with the cutoff moved by exactly 5 semitones.
    StateVariableFilter ref; ref.setCutoff(500.0f * std::pow(2.0f, 5.0f / 12.0f));
    FilterState rs;
    double er = 0, ex = 0;
    for (int i = 0; i < 9600; ++i) {
        const float x = std::sin(2.0 * M_PI * 2000.0 * i / sr);
        const float y = ref.process(x, 0.0f, sr, 69, rs);
        if (i > 2400) { er += y * y; ex += x * x; }
    }
    const double five = 10 * std::log10(er / ex), def = gainAt(0, false), wide = gainAt(36.0f, true);
    std::printf("  base 500 Hz, env 1.0, 2 kHz tone: +5 st reference %.2f dB, default %.2f dB, range 36 st %.2f dB\n", five, def, wide);
    check(std::fabs(five - def) < 0.05, "default range is the historical +-5 semitone sweep");
    check(wide > def + 10.0, "wider range opens the filter further");

    // Engine presets: files without filter_env_range load with the default.
    SynthEngine e(48000.0, 512);
    e.setFilterEnvRange(30.0f);
    const char* path = "/tmp/osp_env_range_test.preset";
    { std::ofstream f(path); f << "filter_env_amount=0.5\n"; }
    e.loadPreset(path);
    std::remove(path);
    check(std::fabs(e.part(0).filter.envRangeSemitones() - 5.0f) < 1e-6f,
          "loading a preset without filter_env_range restores the 5-semitone default");
}

// How much the LP/BP/notch tap fix changes the factory presets: a 110 Hz
// naive saw through the old and new filter for each preset's cutoff,
// resonance and drive (env 0), comparing level overall and above 5/10 kHz.
static double bandDb(const std::vector<float>& y, double sr, double lo) {
    const size_t n = 8192;
    std::vector<std::complex<double>> a(n);
    for (size_t i = 0; i < n; ++i) a[i] = y[y.size() - n + i] * (0.5 - 0.5 * std::cos(2 * M_PI * i / (n - 1)));
    fft(a);
    double e = 0;
    for (size_t b = 0; b <= n / 2; ++b) if (b * sr / n >= lo) e += std::norm(a[b]);
    return 10 * std::log10(e + 1e-30);
}

static void testPresetImpact() {
    std::printf("\nFactory preset impact of the output-tap fix (48 kHz, 110 Hz saw, env 0)\n");
    const double sr = 48000.0;
    int total = 0, byType[5] = {}, cutHi = 0;
    int full05 = 0, full1 = 0, hi5_3 = 0, hi10_3 = 0;
    double worstFull = 0, worstHi = 0; const char* worstFullName = ""; const char* worstHiName = "";
    int drive0 = 0, driveLow = 0, driveOn = 0;
    for (const auto& p : kFullPresets) {
        ++total;
        byType[std::clamp(p.filterType, 0, 4)]++;
        if (p.filterDrive <= 0.0f) ++drive0; else if (p.filterDrive < 0.01f) ++driveLow; else ++driveOn;
        const int type = (p.filterType >= 0 && p.filterType <= 3) ? p.filterType : 0;
        const float cut = std::clamp(p.filterCutoff, 20.0f, 20000.0f);
        if (cut >= 10000.0f) ++cutHi;
        const float res = std::clamp(p.filterResonance, 0.0f, 0.75f);
        const float drv = std::clamp(p.filterDrive, 0.0f, 0.8f);
        OldFilter of; of.type = type; of.cutoff = cut; of.resonance = res; of.drive = drv;
        StateVariableFilter nf; nf.setType(type); nf.setCutoff(cut); nf.setResonance(res); nf.setDrive(drv);
        FilterState st;
        std::vector<float> yo(12288), yn(12288);
        double ph = 0;
        for (size_t i = 0; i < yo.size(); ++i) {
            const float x = 0.5f * (float)(2.0 * ph - 1.0);
            ph += 110.0 / sr; ph -= std::floor(ph);
            yo[i] = of.process(x, 0.0f, sr);
            yn[i] = nf.process(x, 0.0f, sr, 69, st);
        }
        const double dFull = std::fabs(bandDb(yo, sr, 0) - bandDb(yn, sr, 0));
        const double d5 = bandDb(yo, sr, 5000) - bandDb(yn, sr, 5000);
        const double d10 = bandDb(yo, sr, 10000) - bandDb(yn, sr, 10000);
        if (dFull > 0.5) ++full05;
        if (dFull > 1.0) ++full1;
        if (d5 > 3.0) ++hi5_3;
        if (d10 > 3.0) ++hi10_3;
        if (dFull > worstFull) { worstFull = dFull; worstFullName = p.name; }
        if (d10 > worstHi) { worstHi = d10; worstHiName = p.name; }
    }
    std::printf("  presets: %d (filter type LP %d, HP %d, BP %d, notch %d, other %d); cutoff >= 10 kHz: %d\n",
                total, byType[0], byType[1], byType[2], byType[3], byType[4], cutHi);
    std::printf("  drive: 0 -> %d, (0, 0.01) -> %d, >= 0.01 -> %d\n", drive0, driveLow, driveOn);
    std::printf("  overall level change: > 0.5 dB %d, > 1 dB %d; worst %.2f dB (%s)\n",
                full05, full1, worstFull, worstFullName);
    std::printf("  old louder by > 3 dB above 5 kHz: %d, above 10 kHz: %d; worst above 10 kHz %.1f dB (%s)\n",
                hi5_3, hi10_3, worstHi, worstHiName);
    check(total > 0, "preset impact measured");
}

int main() {
    testWavetableMips();
    testFilterTaps();
    testSmoothing();
    testCutoffCap();
    testEnvRange();
    testPresetImpact();
    std::printf("\n%d/%d checks passed\n", gChecks - gFailures, gChecks);
    return gFailures == 0 ? 0 : 1;
}
