// Preset render gate: renders every factory preset through the plugin's own
// preset-load path and fails on silent / non-finite / clipping output or an
// RMS level that moved more than --tolerance-db against the committed baseline.
//
// Usage (run from the repo root so samples/ and tests/baselines/ resolve):
//   preset_render_gate [--baseline tests/baselines/preset_levels.tsv]
//                      [--summary preset_render_gate_summary.md]
//                      [--results <all-presets.tsv>]
//                      [--clip-peak 1.0] [--silence-peak 0.0001]
//                      [--tolerance-db 1.0] [--update-baseline]
//
// See docs/PRESET_RENDER_GATE.md for the render protocol and how to
// regenerate the baseline (scripts/update_preset_baseline.sh).
#include <juce_audio_processors/juce_audio_processors.h>
#include "plugin_processor.h"
#include "preset_data.h"
#include "preset_library_full.h"
#include "sample_player.h"
#include "synth_engine.h"
#include <chrono>
#include <cerrno>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

using namespace opensynth;

namespace {

// ── Render protocol (changing any of these invalidates the baseline) ────────
constexpr double kSampleRate   = 48000.0;
constexpr int    kBlock        = 512;
constexpr int    kWarmupBlocks = 4;   // let queued preset params drain before the note
constexpr int    kHoldBlocks   = 47;  // ~0.50 s held chord
constexpr int    kTailBlocks   = 23;  // ~0.25 s release tail
constexpr int    kVelocity     = 100;
constexpr int    kNotes[]      = { 60, 64, 67 };  // C major triad around middle C
constexpr unsigned kRandSeed   = 1;   // DSP noise sources use std::rand()

constexpr double kFloorDb = -200.0;   // stand-in for -inf in files

struct Options {
    std::string baseline = "tests/baselines/preset_levels.tsv";
    std::string summary  = "preset_render_gate_summary.md";
    std::string results;
    double clipPeak      = 1.0;
    double silencePeak   = 1e-4;
    double toleranceDb   = 1.0;
    bool updateBaseline  = false;
};

struct BaselineEntry {
    int zones = 0;
    double rmsDb = 0.0;
};

struct Result {
    int index = 0;
    const PresetData* preset = nullptr;
    int zones = 0;           // sample zones loaded (0 = synth layer only)
    bool wantsSamples = false;
    double peak = 0.0;
    double rmsDb = kFloorDb;
    double peakDb = kFloorDb;
    bool nonFinite = false;
    bool levelChecked = false;
    double deltaDb = 0.0;
    std::vector<std::string> reasons;
};

double toDb(double v) { return v > 0.0 ? std::max(kFloorDb, 20.0 * std::log10(v)) : kFloorDb; }

std::string fmt(const char* f, double v)
{
    char buf[64];
    std::snprintf(buf, sizeof(buf), f, v);
    return buf;
}

Result renderPreset(int index)
{
    Result r;
    r.index = index;
    r.preset = &kFullPresets[index];
    const auto& p = *r.preset;
    r.wantsSamples = p.sampleMix > 0.0f && p.sampleManifestId[0] != '\0';

    std::srand(kRandSeed);

    // Fresh processor per preset; same sequence as OpenSynthEditor::loadPresetByID.
    OpenSynthProcessor proc;
    proc.setOutputLimiterEnabled(false);
    proc.prepareToPlay(kSampleRate, kBlock);
    applyPresetToAPVTS(p, proc.getParameters());
    applyPresetToEngine(p, proc.getSynth());
    configureSamplePlayerForPreset(p, proc.getSynth());

    if (auto* sp = proc.getSynth().getEngine()->getSamplePlayer()) {
        sp->waitForPreload();
        r.zones = sp->zoneCount();
    }

    juce::AudioBuffer<float> buf(2, kBlock);
    juce::MidiBuffer midi;
    double sumSq = 0.0;
    long long count = 0;
    float peak = 0.0f;

    const int total = kWarmupBlocks + kHoldBlocks + kTailBlocks;
    for (int b = 0; b < total; ++b) {
        midi.clear();
        if (b == kWarmupBlocks)
            for (int n : kNotes)
                midi.addEvent(juce::MidiMessage::noteOn(1, n, (juce::uint8) kVelocity), 0);
        else if (b == kWarmupBlocks + kHoldBlocks)
            for (int n : kNotes)
                midi.addEvent(juce::MidiMessage::noteOff(1, n), 0);

        buf.clear();
        proc.processBlock(buf, midi);
        if (b < kWarmupBlocks) continue;

        for (int ch = 0; ch < 2; ++ch) {
            const float* d = buf.getReadPointer(ch);
            for (int i = 0; i < kBlock; ++i) {
                const float s = d[i];
                if (!std::isfinite(s)) { r.nonFinite = true; continue; }
                peak = std::max(peak, std::fabs(s));
                sumSq += static_cast<double>(s) * s;
                ++count;
            }
        }
    }

    r.peak = peak;
    r.peakDb = toDb(peak);
    r.rmsDb = toDb(count > 0 ? std::sqrt(sumSq / static_cast<double>(count)) : 0.0);
    proc.releaseResources();
    return r;
}

// Strict numeric field parsers: the whole field must be consumed and the
// value finite, so a corrupt baseline cannot silently turn into 0 / NaN.
bool parseDouble(const std::string& field, double& out)
{
    if (field.empty()) return false;
    char* end = nullptr;
    errno = 0;
    const double v = std::strtod(field.c_str(), &end);
    if (errno != 0 || end != field.c_str() + field.size() || !std::isfinite(v)) return false;
    out = v;
    return true;
}

bool parseInt(const std::string& field, int& out)
{
    if (field.empty()) return false;
    char* end = nullptr;
    errno = 0;
    const long v = std::strtol(field.c_str(), &end, 10);
    if (errno != 0 || end != field.c_str() + field.size() || v < 0 || v > 1000000) return false;
    out = static_cast<int>(v);
    return true;
}

// Returns an empty string on success, otherwise a human-readable error.
std::string loadBaseline(const std::string& path, std::map<std::string, BaselineEntry>& out)
{
    std::ifstream in(path);
    if (!in) return "cannot read baseline " + path + " (run from the repo root, or create it with "
                     "scripts/update_preset_baseline.sh)";
    std::map<std::string, int> firstLine;
    std::string line;
    int lineNo = 0;
    while (std::getline(in, line)) {
        ++lineNo;
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.empty() || line[0] == '#' || line.rfind("id\t", 0) == 0) continue;
        const std::string where = path + ":" + std::to_string(lineNo) + ": ";
        std::vector<std::string> cols;
        std::stringstream ss(line);
        std::string c;
        while (std::getline(ss, c, '\t')) cols.push_back(c);
        // id, name, category, zones, rms_dbfs, peak_dbfs
        if (cols.size() < 6)
            return where + "expected 6 tab-separated columns, got " + std::to_string(cols.size());
        if (cols[0].empty()) return where + "empty preset id";
        BaselineEntry e;
        double peakDb = 0.0;
        if (!parseInt(cols[3], e.zones))
            return where + "zones field '" + cols[3] + "' is not a non-negative integer";
        if (!parseDouble(cols[4], e.rmsDb))
            return where + "rms_dbfs field '" + cols[4] + "' is not a finite number";
        if (!parseDouble(cols[5], peakDb))
            return where + "peak_dbfs field '" + cols[5] + "' is not a finite number";
        const auto [it, inserted] = firstLine.emplace(cols[0], lineNo);
        if (!inserted)
            return where + "duplicate preset id '" + cols[0] + "' (first seen on line "
                   + std::to_string(it->second) + ")";
        out[cols[0]] = e;
    }
    return {};
}

void writeTable(std::ostream& o, const std::vector<Result>& results, bool withStatus)
{
    o << "id\tname\tcategory\tzones\trms_dbfs\tpeak_dbfs";
    if (withStatus) o << "\tdelta_db\tstatus";
    o << "\n";
    for (const auto& r : results) {
        o << r.preset->id << '\t' << r.preset->name << '\t' << r.preset->category << '\t'
          << r.zones << '\t' << fmt("%.2f", r.rmsDb) << '\t' << fmt("%.2f", r.peakDb);
        if (withStatus) {
            o << '\t' << (r.levelChecked ? fmt("%+.2f", r.deltaDb) : std::string("-")) << '\t';
            if (r.reasons.empty()) o << "ok";
            for (size_t i = 0; i < r.reasons.size(); ++i) o << (i ? "; " : "") << r.reasons[i];
        }
        o << "\n";
    }
}

int usage()
{
    std::fprintf(stderr,
        "usage: preset_render_gate [--baseline FILE] [--summary FILE] [--results FILE]\n"
        "                          [--clip-peak X] [--silence-peak X] [--tolerance-db X]\n"
        "                          [--update-baseline]\n");
    return 2;
}

} // namespace

int main(int argc, char** argv)
{
    Options opt;
    for (int i = 1; i < argc; ++i) {
        const std::string a = argv[i];
        auto next = [&]() -> const char* { return i + 1 < argc ? argv[++i] : nullptr; };
        const char* v = nullptr;
        if (a == "--update-baseline") opt.updateBaseline = true;
        else if (a == "--baseline" && (v = next())) opt.baseline = v;
        else if (a == "--summary" && (v = next())) opt.summary = v;
        else if (a == "--results" && (v = next())) opt.results = v;
        else if (a == "--clip-peak" && (v = next())) opt.clipPeak = std::atof(v);
        else if (a == "--silence-peak" && (v = next())) opt.silencePeak = std::atof(v);
        else if (a == "--tolerance-db" && (v = next())) opt.toleranceDb = std::atof(v);
        else return usage();
    }

    juce::ScopedJuceInitialiser_GUI init;

    std::map<std::string, BaselineEntry> baseline;
    if (!opt.updateBaseline) {
        const std::string err = loadBaseline(opt.baseline, baseline);
        if (!err.empty()) {
            std::fprintf(stderr, "error: %s\n", err.c_str());
            return 2;
        }
    }

    const auto t0 = std::chrono::steady_clock::now();
    std::vector<Result> results;
    results.reserve(kNumFullPresets);
    for (int i = 0; i < kNumFullPresets; ++i) {
        results.push_back(renderPreset(i));
        if ((i + 1) % 500 == 0) { std::fprintf(stderr, "  rendered %d/%d\n", i + 1, kNumFullPresets); }
    }
    const double seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();

    int nSilent = 0, nNonFinite = 0, nClip = 0, nLevel = 0, nMissing = 0, nEnvMismatch = 0;
    int nWantSamples = 0, nWithSamples = 0;
    for (auto& r : results) {
        if (r.wantsSamples) { ++nWantSamples; if (r.zones > 0) ++nWithSamples; }
        if (r.nonFinite) { r.reasons.push_back("NaN/Inf in output"); ++nNonFinite; }
        if (r.peak < opt.silencePeak) {
            r.reasons.push_back("silent (peak " + fmt("%.1f", r.peakDb) + " dBFS)");
            ++nSilent;
        }
        if (r.peak > opt.clipPeak) {
            r.reasons.push_back("clips (peak " + fmt("%.4f", r.peak) + " > " + fmt("%.4f", opt.clipPeak) + ")");
            ++nClip;
        }
        if (opt.updateBaseline) continue;

        auto it = baseline.find(r.preset->id);
        if (it == baseline.end()) {
            r.reasons.push_back("missing from baseline");
            ++nMissing;
        } else if (it->second.zones != r.zones) {
            // Different sample library than the baseline was rendered with:
            // the level is not comparable, so it is reported but not gated.
            ++nEnvMismatch;
        } else {
            r.levelChecked = true;
            const bool bothSilent = r.rmsDb <= -120.0 && it->second.rmsDb <= -120.0;
            r.deltaDb = bothSilent ? 0.0 : r.rmsDb - it->second.rmsDb;
            if (std::fabs(r.deltaDb) > opt.toleranceDb) {
                r.reasons.push_back("level " + fmt("%+.2f", r.deltaDb) + " dB vs baseline ("
                                    + fmt("%.2f", it->second.rmsDb) + " -> " + fmt("%.2f", r.rmsDb) + " dBFS)");
                ++nLevel;
            }
        }
    }

    std::vector<const Result*> failing;
    for (const auto& r : results)
        if (!r.reasons.empty()) failing.push_back(&r);

    if (opt.updateBaseline) {
        std::ofstream out(opt.baseline, std::ios::binary);
        if (!out) { std::fprintf(stderr, "cannot write %s\n", opt.baseline.c_str()); return 2; }
        out << "# preset_render_gate RMS baseline. Regenerate ONLY with scripts/update_preset_baseline.sh\n"
               "# when a DSP change is expected to move preset levels, and review the diff.\n"
               "# Protocol: 48 kHz, 512-frame blocks, notes 60/64/67 vel 100, 0.5 s hold + 0.25 s tail,\n"
               "# output limiter bypassed, srand(1). zones = sample zones loaded (0 = no sample library).\n";
        writeTable(out, results, false);
    }

    if (!opt.results.empty()) {
        std::ofstream out(opt.results, std::ios::binary);
        writeTable(out, results, true);
    }

    // ── Summary ──
    std::ostringstream s;
    s << "# Preset render gate\n\n"
      << (opt.updateBaseline ? "Mode: **update baseline** (`" + opt.baseline + "` rewritten)\n\n"
                             : "Baseline: `" + opt.baseline + "`\n\n")
      << "| Check | Count |\n|---|---|\n"
      << "| Presets rendered | " << results.size() << " |\n"
      << "| Silent (peak < " << fmt("%g", opt.silencePeak) << ") | " << nSilent << " |\n"
      << "| NaN/Inf | " << nNonFinite << " |\n"
      << "| Clipping (peak > " << fmt("%g", opt.clipPeak) << ") | " << nClip << " |\n";
    if (!opt.updateBaseline)
        s << "| RMS moved > " << fmt("%g", opt.toleranceDb) << " dB | " << nLevel << " |\n"
          << "| Missing from baseline | " << nMissing << " |\n"
          << "| Level compared against baseline | " << (results.size() - nMissing - nEnvMismatch) << " |\n"
          << "| Level NOT compared — skipped, sample zones differ from baseline (not a failure) | "
          << nEnvMismatch << " |\n";
    s << "| **Failing presets** | **" << failing.size() << "** |\n\n"
      << "Sampled presets: " << nWantSamples << ", rendered with their sample library: " << nWithSamples
      << ", without (synth layer only): " << (nWantSamples - nWithSamples) << "\n\n"
      << "Render time: " << fmt("%.1f", seconds) << " s\n\n";
    if (!failing.empty()) {
        s << "## Failing presets\n\n| # | id | name | category | rms dBFS | peak dBFS | reasons |\n|---|---|---|---|---|---|---|\n";
        for (const auto* r : failing) {
            s << "| " << r->index << " | " << r->preset->id << " | " << r->preset->name << " | " << r->preset->category
              << " | " << fmt("%.2f", r->rmsDb) << " | " << fmt("%.2f", r->peakDb) << " | ";
            for (size_t i = 0; i < r->reasons.size(); ++i) s << (i ? "; " : "") << r->reasons[i];
            s << " |\n";
        }
    }
    if (!opt.summary.empty()) {
        std::ofstream out(opt.summary, std::ios::binary);
        out << s.str();
    }
    std::fputs(s.str().c_str(), stdout);

    if (opt.updateBaseline) {
        std::printf("\nWrote %s. Review the diff before committing.\n", opt.baseline.c_str());
        // The baseline only records levels; silent/NaN/clipping presets are
        // still bugs, so updating must not turn a red gate green.
        if (!failing.empty())
            std::printf("FAIL: %zu preset(s) fail silent/NaN/Inf/clip checks (baseline written anyway)\n",
                        failing.size());
        return failing.empty() ? 0 : 1;
    }
    std::printf("\n%s: %zu failing preset(s)", failing.empty() ? "PASS" : "FAIL", failing.size());
    if (nEnvMismatch > 0)
        std::printf(", %d preset(s) level-skipped (sample zones differ from baseline)", nEnvMismatch);
    std::printf("\n");
    return failing.empty() ? 0 : 1;
}
