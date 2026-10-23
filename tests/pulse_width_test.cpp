// Pulse width tests: the per-oscillator pulse width parameter leaves existing
// sounds untouched at its 0.5 default, really changes the harmonic content,
// stays band-limited at extreme widths, and survives preset save/load (with
// presets that predate the key loading as 0.5).
#include <juce_audio_processors/juce_audio_processors.h>
#include "plugin_processor.h"
#include "plugin_editor.h"
#include "user_preset_manager.h"
#include "preset_data.h"
#include "preset_library_full.h"
#include "synth_engine.h"
#include "oscillator.h"

#include <cmath>
#include <complex>
#include <cstdio>
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

static constexpr int kDartSquare = 2;
static constexpr int kDartPulse = 5;

static float paramValue(OpenSynthProcessor& proc, const char* id) {
    return proc.getParameters().getRawParameterValue(id)->load();
}

static void setParam(OpenSynthProcessor& proc, const char* id, float v) {
    auto* p = proc.getParameters().getParameter(id);
    p->setValueNotifyingHost(p->convertTo0to1(v));
}

// ── Rendering helpers ───────────────────────────────────────────────────────

// Plays a two-note chord through the full plugin path (APVTS -> engine ->
// FX -> output limiter) and returns the left channel.
static std::vector<float> renderProcessor(OpenSynthProcessor& proc, int blocks) {
    const int block = 512;
    proc.prepareToPlay(48000.0, block);
    juce::AudioBuffer<float> buf(2, block);
    std::vector<float> out;
    out.reserve(static_cast<size_t>(blocks * block));
    for (int b = 0; b < blocks; ++b) {
        juce::MidiBuffer midi;
        if (b == 0) {
            midi.addEvent(juce::MidiMessage::noteOn(1, 48, (juce::uint8)100), 0);
            midi.addEvent(juce::MidiMessage::noteOn(1, 55, (juce::uint8)90), 7);
        }
        if (b == blocks - 20) {
            midi.addEvent(juce::MidiMessage::noteOff(1, 48), 3);
            midi.addEvent(juce::MidiMessage::noteOff(1, 55), 3);
        }
        buf.clear();
        proc.processBlock(buf, midi);
        const float* l = buf.getReadPointer(0);
        out.insert(out.end(), l, l + block);
    }
    return out;
}

static std::vector<float> renderFactoryPreset(const PresetData& p, int blocks) {
    OpenSynthProcessor proc;
    proc.prepareToPlay(48000.0, 512);
    applyPresetToAPVTS(p, proc.getParameters());
    applyPresetToEngine(p, proc.getSynth());
    return renderProcessor(proc, blocks);
}

static double maxAbsDiff(const std::vector<float>& a, const std::vector<float>& b) {
    if (a.size() != b.size()) return 1e30;
    double d = 0.0;
    for (size_t i = 0; i < a.size(); ++i) d = std::max(d, (double)std::abs(a[i] - b[i]));
    return d;
}

static double peak(const std::vector<float>& a) {
    double m = 0.0;
    for (float v : a) m = std::max(m, (double)std::abs(v));
    return m;
}

static std::vector<float> renderOsc(int dartWave, float pw, double f0, double sr, size_t n) {
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

static std::vector<float> renderNaivePulse(float pw, double f0, double sr, size_t n) {
    std::vector<float> out(n);
    float phase = 0.0f;
    const float inc = static_cast<float>(f0 / sr);
    for (size_t i = 0; i < n; ++i) {
        out[i] = phase < pw ? 1.0f : -1.0f;
        phase += inc;
        if (phase >= 1.0f) phase -= 1.0f;
    }
    return out;
}

// ── Spectrum helpers ────────────────────────────────────────────────────────

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

// Blackman-Harris windowed power spectrum (bins 0 .. n/2).
static std::vector<double> powerSpectrum(const std::vector<float>& sig) {
    const size_t n = sig.size();
    std::vector<std::complex<double>> x(n);
    for (size_t i = 0; i < n; ++i) {
        double w = 0.35875 - 0.48829 * std::cos(2 * M_PI * i / (n - 1)) +
                   0.14128 * std::cos(4 * M_PI * i / (n - 1)) -
                   0.01168 * std::cos(6 * M_PI * i / (n - 1));
        x[i] = sig[i] * w;
    }
    fft(x);
    std::vector<double> p(n / 2);
    for (size_t k = 0; k < n / 2; ++k) p[k] = std::norm(x[k]);
    return p;
}

// Energy (dB) of harmonic h of f0, summed over the window's main lobe.
static double harmonicDb(const std::vector<double>& p, size_t n, double f0, int h, double sr) {
    const double binHz = sr / static_cast<double>(n);
    const long centre = std::lround(h * f0 / binHz);
    double e = 0.0;
    for (long k = centre - 4; k <= centre + 4; ++k)
        if (k > 0 && k < (long)p.size()) e += p[(size_t)k];
    return 10.0 * std::log10(std::max(e, 1e-30));
}

// Inharmonic energy in dB: relative to AC energy, or a fixed N^2 FFT scale.
static double aliasDb(const std::vector<float>& sig, double f0, double sr, bool fixedReference = false) {
    const size_t n = sig.size();
    auto p = powerSpectrum(sig);
    const double binHz = sr / static_cast<double>(n);
    double total = 0.0, harmonic = 0.0;
    for (size_t k = 1; k < n / 2; ++k) {
        total += p[k];
        double f = static_cast<double>(k) * binHz;
        double h = std::round(f / f0);
        if (std::abs(f - h * f0) <= 6.0 * binHz) harmonic += p[k];
    }
    return 10.0 * std::log10(std::max(total - harmonic, 1e-30) / (fixedReference ? static_cast<double>(n) * n : total));
}

// ── 1. Defaults render exactly as before ────────────────────────────────────

static void testDefaultsUnchanged() {
    std::printf("[compat] pulse width 0.5 renders exactly as before\n");

    // Parameters exist, are per oscillator and default to 0.5.
    {
        OpenSynthProcessor proc;
        auto* p1 = proc.getParameters().getParameter("osc1PulseWidth");
        auto* p2 = proc.getParameters().getParameter("osc2PulseWidth");
        check(p1 != nullptr && p2 != nullptr, "osc1PulseWidth and osc2PulseWidth parameters exist");
        if (!p1 || !p2) return;
        check(p1->isAutomatable() && p2->isAutomatable(), "pulse width parameters are automatable");
        auto* f1 = dynamic_cast<juce::AudioParameterFloat*>(p1);
        check(f1 && f1->range.start == 0.05f && f1->range.end == 0.95f, "range is 0.05 - 0.95");
        check(paramValue(proc, "osc1PulseWidth") == 0.5f && paramValue(proc, "osc2PulseWidth") == 0.5f,
              "default is exactly 0.5");
    }

    // Every factory preset stores 0.5, so applying the field changes nothing.
    int pulsePresets = 0, off = 0;
    for (int i = 0; i < kNumFullPresets; ++i) {
        const auto& p = kFullPresets[i];
        if (p.osc1PulseWidth != 0.5f || p.osc2PulseWidth != 0.5f) ++off;
        if (p.osc1Waveform == kDartPulse || p.osc2Waveform == kDartPulse) ++pulsePresets;
    }
    std::printf("        %d factory presets, %d use the pulse waveform, %d store pw != 0.5\n",
                kNumFullPresets, pulsePresets, off);
    check(off == 0, "all factory presets store pulse width 0.5");

    // Before this change PULSE was a fixed 50% wave, the same code path as
    // SQUARE. With pw at its default the pulse presets must render
    // bit-identically to the same preset with SQUARE (the pre-change sound).
    int compared = 0;
    double worst = 0.0;
    for (int i = 0, stride = 0; i < kNumFullPresets && compared < 6; ++i) {
        const auto& p = kFullPresets[i];
        if (p.osc1Waveform != kDartPulse && p.osc2Waveform != kDartPulse) continue;
        if (stride++ % 150 != 0) continue;  // spread across categories
        PresetData legacy = p;
        if (legacy.osc1Waveform == kDartPulse) legacy.osc1Waveform = kDartSquare;
        if (legacy.osc2Waveform == kDartPulse) legacy.osc2Waveform = kDartSquare;
        auto now = renderFactoryPreset(p, 120);
        auto before = renderFactoryPreset(legacy, 120);
        double d = maxAbsDiff(now, before);
        std::printf("        %-28s peak %.3f, max |diff| vs 50%% square %.3g\n", p.name, peak(now), d);
        worst = std::max(worst, d);
        ++compared;
    }
    check(compared >= 4 && worst == 0.0, "pulse presets at pw 0.5 are bit-identical to the pre-change 50% pulse");

    // Explicitly setting 0.5 is the same as never touching it, and a value
    // restored from saved host state (normalised round trip) still is 0.5.
    {
        OpenSynthProcessor a, b;
        setParam(a, "osc1Waveform", (float)kDartPulse);
        setParam(b, "osc1Waveform", (float)kDartPulse);
        setParam(b, "osc1PulseWidth", 0.3f);
        setParam(b, "osc1PulseWidth", 0.5f);
        juce::MemoryBlock state;
        b.getStateInformation(state);
        OpenSynthProcessor c;
        c.setStateInformation(state.getData(), (int)state.getSize());
        std::printf("        pw after set 0.3 -> 0.5: %.9f, after state restore: %.9f\n",
                    paramValue(b, "osc1PulseWidth"), paramValue(c, "osc1PulseWidth"));
        auto ra = renderProcessor(a, 60);
        auto rb = renderProcessor(b, 60);
        auto rc = renderProcessor(c, 60);
        check(peak(ra) > 0.05 && maxAbsDiff(ra, rb) == 0.0 && maxAbsDiff(ra, rc) == 0.0,
              "default, explicit 0.5 and restored 0.5 render bit-identically");
    }

    // Engine level: setting 0.5 equals the untouched oscillator default.
    {
        auto run = [](bool touch) {
            SynthEngine e(48000.0, 256);
            e.setOsc1Waveform(kDartPulse);
            e.setOsc2Waveform(kDartPulse);
            e.setOsc2Volume(0.5f);
            if (touch) { e.setOsc1PulseWidth(0.5f); e.setOsc2PulseWidth(0.5f); }
            e.noteOn(60, 0.9f, 0);
            std::vector<float> data(256 * 2), out;
            for (int b = 0; b < 40; ++b) {
                std::fill(data.begin(), data.end(), 0.0f);
                AudioBuffer ab;
                ab.numChannels = 2;
                ab.numFrames = 256;
                ab.data = data.data();
                e.process(ab);
                out.insert(out.end(), data.begin(), data.end());
            }
            return out;
        };
        check(maxAbsDiff(run(false), run(true)) == 0.0, "engine: explicit pw 0.5 == untouched default");
    }
}

// ── 2. Pulse width changes the harmonic content ─────────────────────────────

static void testHarmonics() {
    std::printf("[harmonics] pulse width shapes the spectrum\n");
    const double sr = 48000.0;
    const size_t n = 16384;
    const double f0 = sr * 64.0 / static_cast<double>(n);  // 187.5 Hz, bin-centred

    // Ideal pulse: |a_h| ~ |sin(pi h d)| / h. At d = 0.5 even harmonics
    // vanish; at d = 0.25 h2 sits ~3 dB under h1 and h4 vanishes.
    struct Row { float pw; double h2, h4; };
    Row rows[3];
    const float widths[] = {0.5f, 0.25f, 0.75f};
    for (int i = 0; i < 3; ++i) {
        auto p = powerSpectrum(renderOsc(kDartPulse, widths[i], f0, sr, n));
        double h1 = harmonicDb(p, n, f0, 1, sr);
        rows[i] = {widths[i], harmonicDb(p, n, f0, 2, sr) - h1, harmonicDb(p, n, f0, 4, sr) - h1};
        std::printf("        osc pw %.2f: h2 %.1f dB, h4 %.1f dB (re h1)\n", rows[i].pw, rows[i].h2, rows[i].h4);
    }
    check(rows[0].h2 < -60.0, "pw 0.50: 2nd harmonic absent (< -60 dB re h1)");
    check(rows[1].h2 > -6.0 && rows[1].h2 < 0.0, "pw 0.25: 2nd harmonic present (-6..0 dB re h1, ideal -3 dB)");
    check(rows[1].h4 < -40.0, "pw 0.25: 4th harmonic cancelled (< -40 dB re h1)");
    check(std::abs(rows[2].h2 - rows[1].h2) < 0.5, "pw 0.75 mirrors pw 0.25");

    // Same measurement through the plugin parameter (APVTS -> engine).
    auto pluginH2 = [&](float pw, int osc) {
        OpenSynthProcessor proc;
        setParam(proc, "osc1Waveform", (float)kDartPulse);
        setParam(proc, "osc2Waveform", (float)kDartPulse);
        setParam(proc, "osc1Volume", osc == 1 ? 0.8f : 0.0f);
        setParam(proc, "osc2Volume", osc == 2 ? 0.8f : 0.0f);
        setParam(proc, osc == 1 ? "osc1PulseWidth" : "osc2PulseWidth", pw);
        setParam(proc, "filterCutoff", 20000.0f);
        setParam(proc, "ampAttack", 0.1f);
        setParam(proc, "ampSustain", 1.0f);
        proc.prepareToPlay(sr, 512);
        juce::AudioBuffer<float> buf(2, 512);
        std::vector<float> out;
        for (int b = 0; b < 40; ++b) {
            juce::MidiBuffer midi;
            if (b == 0) midi.addEvent(juce::MidiMessage::noteOn(1, 54, (juce::uint8)100), 0);  // F#3
            buf.clear();
            proc.processBlock(buf, midi);
            out.insert(out.end(), buf.getReadPointer(0), buf.getReadPointer(0) + 512);
        }
        std::vector<float> tail(out.end() - (long)n, out.end());  // skip the attack
        const double f = 440.0 * std::pow(2.0, (54 - 69) / 12.0);
        auto p = powerSpectrum(tail);
        return harmonicDb(p, n, f, 2, sr) - harmonicDb(p, n, f, 1, sr);
    };
    for (int osc : {1, 2}) {
        double at50 = pluginH2(0.5f, osc), at25 = pluginH2(0.25f, osc);
        std::printf("        plugin osc%dPulseWidth 0.50: h2 %.1f dB, 0.25: h2 %.1f dB (re h1)\n", osc, at50, at25);
        check(at50 < -40.0 && at25 > -10.0, "plugin parameter changes the sound (h2 appears at 0.25)");
    }
}

// ── 3. No aliasing regression at extreme widths ─────────────────────────────

static void testExtremeWidthAliasing() {
    const double f0 = 4987.0;
    const size_t n = 16384;
    for (double sr : {44100.0, 48000.0, 96000.0}) {
        std::printf("[aliasing] pulse at f0 = 4987 Hz, %.1f kHz\n", sr / 1000.0);
        auto square = renderOsc(kDartPulse, 0.5f, f0, sr, n);
        const double ref = aliasDb(square, f0, sr);
        const double refEnergy = aliasDb(square, f0, sr, true);
        std::printf("        pw 0.50 band-limited %.1f dB\n", ref);
        for (float pw : {0.05f, 0.95f}) {
            double naive = aliasDb(renderNaivePulse(pw, f0, sr, n), f0, sr);
            auto pulse = renderOsc(kDartPulse, pw, f0, sr, n);
            double bl = aliasDb(pulse, f0, sr);
            // Compare absolute inharmonic energy on a common FFT scale:
            // narrow pulses have much less AC energy than a 50% square, so
            // dividing by each waveform's own energy biases that comparison.
            double energy = aliasDb(pulse, f0, sr, true);
            std::printf("        inharmonic energy vs 50%% width: %+.1f dB\n", energy - refEnergy);
            std::printf("        pw %.2f naive %.1f dB, band-limited %.1f dB\n", pw, naive, bl);
            char msg[128];
            std::snprintf(msg, sizeof msg, "%.1f kHz pw %.2f: aliasing reduced >= 10 dB, below -20 dB, energy within 6 dB of pw 0.5",
                          sr / 1000.0, pw);
            check(naive - bl >= 10.0 && bl < -20.0 && energy <= refEnergy + 6.0, msg);
        }
    }
}

// ── 4. Preset save / load ───────────────────────────────────────────────────

static void testPresetRoundTrip() {
    std::printf("[presets] save / load pulse width\n");
    auto dir = juce::File::createTempFile("open-synth-pw-test");
    dir.createDirectory();

    // User preset (user_presets.json): round trip keeps both widths.
    {
        OpenSynthProcessor src;
        setParam(src, "osc1PulseWidth", 0.25f);
        setParam(src, "osc2PulseWidth", 0.8f);
        UserPresetManager mgr(dir);
        check(mgr.savePreset("Thin Pulse", "Custom", {}, src.getParameters()), "user preset saved");
        auto presets = mgr.getUserPresets();
        check(presets.size() == 1 && presets[0].parameterValues.hasProperty("osc1PulseWidth")
                  && presets[0].parameterValues.hasProperty("osc2PulseWidth"),
              "user preset file contains osc1PulseWidth / osc2PulseWidth keys");
        OpenSynthProcessor dst;
        if (!presets.empty()) mgr.loadPreset(presets[0], dst.getParameters());
        std::printf("        loaded osc1 %.3f, osc2 %.3f\n", paramValue(dst, "osc1PulseWidth"), paramValue(dst, "osc2PulseWidth"));
        check(std::abs(paramValue(dst, "osc1PulseWidth") - 0.25f) < 1e-4f
                  && std::abs(paramValue(dst, "osc2PulseWidth") - 0.8f) < 1e-4f,
              "user preset round trip restores both pulse widths");

        // A preset written before the key existed loads as 0.5, even over a
        // non-default current value.
        if (!presets.empty()) {
            auto legacy = presets[0];
            juce::DynamicObject::Ptr copy = legacy.parameterValues.getDynamicObject()->clone().release();
            copy->removeProperty("osc1PulseWidth");
            copy->removeProperty("osc2PulseWidth");
            legacy.parameterValues = juce::var(copy.get());
            mgr.loadPreset(legacy, dst.getParameters());
            check(paramValue(dst, "osc1PulseWidth") == 0.5f && paramValue(dst, "osc2PulseWidth") == 0.5f,
                  "ID-keyed preset without the key loads pulse width 0.5");

            // Legacy v2.1.0 presets keyed by display name.
            setParam(dst, "osc1PulseWidth", 0.3f);
            juce::DynamicObject::Ptr byName = new juce::DynamicObject();
            byName->setProperty("Volume", 0.5);
            byName->setProperty("Cutoff", 0.4);
            UserPreset old;
            old.name = "Old";
            old.parameterValues = juce::var(byName.get());
            mgr.loadPreset(old, dst.getParameters());
            check(paramValue(dst, "osc1PulseWidth") == 0.5f, "display-name keyed legacy preset loads pulse width 0.5");
        }
    }

    // Host / .osj state (APVTS XML): round trip and missing child -> 0.5.
    {
        OpenSynthProcessor src;
        setParam(src, "osc1PulseWidth", 0.1f);
        setParam(src, "osc2PulseWidth", 0.9f);
        juce::MemoryBlock state;
        src.getStateInformation(state);
        OpenSynthProcessor dst;
        dst.setStateInformation(state.getData(), (int)state.getSize());
        check(std::abs(paramValue(dst, "osc1PulseWidth") - 0.1f) < 1e-4f
                  && std::abs(paramValue(dst, "osc2PulseWidth") - 0.9f) < 1e-4f,
              "plugin state round trip restores both pulse widths");

        auto xml = src.getParameters().copyState().createXml();
        for (auto* id : {"osc1PulseWidth", "osc2PulseWidth"})
            if (auto* child = xml->getChildByAttribute("id", id))
                xml->removeChildElement(child, true);
        juce::MemoryBlock oldState;
        juce::AudioProcessor::copyXmlToBinary(*xml, oldState);
        dst.setStateInformation(oldState.getData(), (int)oldState.getSize());
        check(paramValue(dst, "osc1PulseWidth") == 0.5f && paramValue(dst, "osc2PulseWidth") == 0.5f,
              "plugin state without the key loads pulse width 0.5");
    }

    // Engine text preset (key=value): round trip and missing key -> 0.5.
    {
        auto file = dir.getChildFile("engine.preset");
        SynthEngine a(48000.0, 256);
        a.setOsc1PulseWidth(0.2f);
        a.setOsc2PulseWidth(0.7f);
        a.savePreset(file.getFullPathName().toRawUTF8());
        check(file.loadFileAsString().contains("osc1_pulse_width=0.2"), "engine preset file has osc1_pulse_width");
        SynthEngine b(48000.0, 256);
        b.loadPreset(file.getFullPathName().toRawUTF8());
        check(std::abs(b.part(0).osc1.pulseWidth() - 0.2f) < 1e-6f
                  && std::abs(b.part(0).osc2.pulseWidth() - 0.7f) < 1e-6f,
              "engine preset round trip restores both pulse widths");
        file.replaceWithText("osc1_waveform=5\nosc1_volume=0.8\n");
        b.loadPreset(file.getFullPathName().toRawUTF8());
        check(b.part(0).osc1.pulseWidth() == 0.5f && b.part(0).osc2.pulseWidth() == 0.5f,
              "engine preset without the key loads pulse width 0.5");
    }

    dir.deleteRecursively();
}

static void testPulseWidthUI() {
    OpenSynthProcessor proc;
    for (int osc : {1, 2}) {
        OscPanel panel(proc.getParameters(), osc);
        panel.setSize(330, 220);
        juce::Slider* pw = nullptr;
        juce::ComboBox* wave = nullptr;
        for (auto* child : panel.getChildren()) {
            if (auto* slider = dynamic_cast<juce::Slider*>(child))
                if (std::abs(slider->getMinimum() - 0.05) < 1e-6) pw = slider;
            if (auto* combo = dynamic_cast<juce::ComboBox*>(child)) wave = combo;
        }
        check(pw && wave, "oscillator panel exposes PW and waveform controls");
        if (!pw || !wave) continue;
        check(wave->getNumItems() == 24 && wave->getItemText(5) == "Pulse",
              "waveform selector matches parameter ids 0-23, Pulse at 5");
        check(!pw->isEnabled(), "PW disabled for default sine");
        setParam(proc, osc == 1 ? "osc1Waveform" : "osc2Waveform", 5.0f);
        check(pw->isEnabled() && panel.getLocalBounds().contains(pw->getBounds()),
              "PW enabled for Pulse and fits panel");
        setParam(proc, osc == 1 ? "osc1Waveform" : "osc2Waveform", 2.0f);
        check(!pw->isEnabled(), "PW disabled for square");
    }
}

int main() {
    juce::ScopedJuceInitialiser_GUI init;
    testPulseWidthUI();
    testDefaultsUnchanged();
    testHarmonics();
    testExtremeWidthAliasing();
    testPresetRoundTrip();
    std::printf("\n%d passed, %d failed\n", g_passed, g_failed);
    return g_failed == 0 ? 0 : 1;
}
