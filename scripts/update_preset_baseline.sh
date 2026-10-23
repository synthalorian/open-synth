#!/usr/bin/env bash
# Regenerate tests/baselines/preset_levels.tsv, the RMS baseline used by the
# preset_render_gate CI check.
#
# ONLY run this intentionally, when a DSP change is EXPECTED to change preset
# levels (e.g. a filter rewrite such as PR #12). Then review the diff: every
# row that moved should be explained by that change. Never run it just to make
# a red gate green — silent/NaN/clipping presets are real bugs, and the gate
# keeps failing on them regardless of the baseline.
#
# Two baselines exist:
#   tests/baselines/preset_levels.tsv          rendered WITHOUT sample libraries
#                                              (PR / branch CI; default mode)
#   tests/baselines/preset_levels_samples.tsv  rendered WITH every sample
#                                              submodule checked out (tag CI,
#                                              which also passes --require-samples)
# Default mode refuses to run if any samples/ submodule is checked out;
# --with-samples refuses unless all of them are
# (git submodule update --init --recursive, the same as tag CI).
#
# Usage: scripts/update_preset_baseline.sh [--with-samples] [build-dir]   (default: build)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WITH_SAMPLES=0
if [[ "${1:-}" == "--with-samples" ]]; then WITH_SAMPLES=1; shift; fi
BUILD_DIR="${1:-$REPO_ROOT/build}"
cd "$REPO_ROOT"

if [[ $WITH_SAMPLES == 1 ]]; then
    BASELINE=tests/baselines/preset_levels_samples.tsv
    EXTRA=(--require-samples)
    if git submodule status -- samples | grep -q '^-'; then
        echo "error: --with-samples needs every samples/ submodule checked out." >&2
        echo "       Run: git submodule update --init --recursive" >&2
        exit 1
    fi
else
    BASELINE=tests/baselines/preset_levels.tsv
    EXTRA=()
    if git submodule status -- samples | grep -qv '^-'; then
        echo "error: sample submodules are checked out; branch CI renders without them." >&2
        echo "       Deinit them (git submodule deinit -f samples/*) or use --with-samples." >&2
        exit 1
    fi
fi

cmake --build "$BUILD_DIR" --config Release --target preset_render_gate
if [[ -x "$BUILD_DIR/preset_render_gate" ]]; then
    GATE="$BUILD_DIR/preset_render_gate"
else
    GATE="$BUILD_DIR/Release/preset_render_gate.exe"
fi

"$GATE" --update-baseline --baseline "$BASELINE" "${EXTRA[@]+"${EXTRA[@]}"}" --summary "$BUILD_DIR/preset_render_gate_summary.md"

echo
git --no-pager diff --stat -- "$BASELINE"
echo "Review with: git diff $BASELINE"
