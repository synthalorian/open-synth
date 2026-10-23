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
# The baseline must be rendered the way CI renders it: WITHOUT the sample
# library submodules (CI only fetches them for tag builds). This script
# refuses to run if any samples/ submodule is checked out.
#
# Usage: scripts/update_preset_baseline.sh [build-dir]   (default: build)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${1:-$REPO_ROOT/build}"
cd "$REPO_ROOT"

if git submodule status -- samples | grep -qv '^-'; then
    echo "error: sample submodules are checked out; CI renders without them." >&2
    echo "       Deinit them first (git submodule deinit samples/<name>) so the baseline matches CI." >&2
    exit 1
fi

cmake --build "$BUILD_DIR" --config Release --target preset_render_gate
if [[ -x "$BUILD_DIR/preset_render_gate" ]]; then
    GATE="$BUILD_DIR/preset_render_gate"
else
    GATE="$BUILD_DIR/Release/preset_render_gate.exe"
fi

"$GATE" --update-baseline --summary "$BUILD_DIR/preset_render_gate_summary.md"

echo
git --no-pager diff --stat -- tests/baselines/preset_levels.tsv
echo "Review with: git diff tests/baselines/preset_levels.tsv"
