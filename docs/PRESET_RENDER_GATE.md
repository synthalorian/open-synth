# Preset render gate

`preset_render_gate` (`tests/preset_render_gate.cpp`) renders every factory preset in
`include/preset_library_full.h` and fails CI if any preset

- is **silent**: peak below `--silence-peak` (default `1e-4`, -80 dBFS),
- produces **NaN/Inf**,
- **clips**: peak above `--clip-peak` (default `1.0`),
- **moved level**: RMS differs from `tests/baselines/preset_levels.tsv` by more than
  `--tolerance-db` (default `1.0` dB).

There is no allowlist: every failure is a real preset/engine problem to fix.

```bash
cmake --build build --config Release --target preset_render_gate
./build/preset_render_gate --results /tmp/presets.tsv    # run from the repo root
```

Exit code: `0` pass, `1` failing presets, `2` usage error / baseline unreadable.
A Markdown summary (counts + every failing preset with its reasons) goes to stdout and
`--summary` (default `preset_render_gate_summary.md`); `--results` writes a TSV row per
preset. CI uploads both as the `preset-render-gate-<platform>` artifact and appends the
summary to the job summary.

## Render protocol

Each preset gets a **fresh `OpenSynthProcessor`** and is loaded exactly like
`OpenSynthEditor::loadPresetByID`: `applyPresetToAPVTS` → `applyPresetToEngine` →
`configureSamplePlayerForPreset`. Audio comes from `processBlock`, so the processor's
per-block APVTS → engine parameter pull is part of what is measured.

- 48 kHz, 512-frame blocks, 4 unmeasured warm-up blocks (queued params drain first)
- C4/E4/G4 at velocity 100, held 47 blocks (~0.5 s), then 23 blocks (~0.25 s) release tail
- peak/RMS over both channels of the measured 70 blocks
- the processor's output safety limiter is bypassed (`setOutputLimiterEnabled(false)`)
  so hot presets are not masked by it
- `std::srand(1)` before every preset (several DSP noise sources use `std::rand()`)

Presets render serially in index order. That is deliberate: `std::rand()` and a few
DSP statics are process-global, so rendering presets on parallel threads would not be
deterministic. Same binary + same inputs gives a byte-identical baseline.

Note: the engine output stage runs through `tanh` (`SynthEngine::process`, drum mix),
so its peak cannot exceed 1.0; the clip check guards against that stage changing.
Near-ceiling presets show up as peaks close to 0 dBFS in the results TSV.

## Sample libraries

CI only fetches the sample-library submodules for tag builds. Without them the
manifests in `samples/manifests/` still resolve, but their sample files don't, so
sampled presets load **0 zones** and render their synth layer only (whatever the engine
does without samples). That is deterministic, and the baseline is rendered this way.

The baseline stores the loaded zone count per preset. When a run loads a different
number of zones than the baseline (e.g. tag builds, or a dev checkout with submodules),
that preset's level is **not compared** and it is counted under "Level not compared"
in the summary; the silent/NaN/clip checks still apply.

## Regenerating the baseline

```bash
scripts/update_preset_baseline.sh        # = preset_render_gate --update-baseline
git diff tests/baselines/preset_levels.tsv
```

Only do this **intentionally**, when a DSP change is expected to move preset levels,
and review the diff: every moved row should be explained by that change. Don't use it
to turn a red gate green. Silent/NaN/clip failures don't depend on the baseline, so
regenerating doesn't hide them. The script refuses to run with sample submodules
checked out, so the baseline matches CI.

PR #12 (filter output change) will most likely need a baseline regeneration after it
merges.
