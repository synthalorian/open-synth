#!/usr/bin/env bash
# Deploy desktop build with sample assets.
#
# Flutter desktop builds do NOT bundle arbitrary assets into the release
# bundle. This script copies the sample library next to the executable
# so the runtime path resolver can find them.
#
# Usage:
#   bash scripts/deploy-desktop.sh [build_mode]
#
#   build_mode: debug (default) | profile | release

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_MODE="${1:-release}"

BUNDLE_DIR="$PROJECT_DIR/build/linux/x64/$BUILD_MODE/bundle"
SAMPLES_SRC="$PROJECT_DIR/assets/samples"
SAMPLES_DST="$BUNDLE_DIR/assets/samples"

echo "═══════════════════════════════════════════════════════════════"
echo "  Open Synth Desktop Deployment"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  Build mode:  $BUILD_MODE"
echo "  Bundle dir:  $BUNDLE_DIR"
echo "  Samples src: $SAMPLES_SRC"
echo "  Samples dst: $SAMPLES_DST"
echo ""

# Check bundle exists
if [[ ! -d "$BUNDLE_DIR" ]]; then
    echo "ERROR: Bundle directory not found."
    echo "       Run: flutter build linux --$BUILD_MODE"
    exit 1
fi

# Check samples exist
if [[ ! -d "$SAMPLES_SRC" ]]; then
    echo "ERROR: Samples directory not found at $SAMPLES_SRC"
    echo "       Download VSCO 2 CE and extract to assets/samples/"
    exit 1
fi

# Copy native .so (Flutter doesn't rebuild it automatically)
if [[ -f "$PROJECT_DIR/native/libopenamp_dart_ffi.so" ]]; then
    echo "  → Copying native library..."
    cp "$PROJECT_DIR/native/libopenamp_dart_ffi.so" "$BUNDLE_DIR/lib/"
else
    echo "  WARNING: Native library not found at $PROJECT_DIR/native/libopenamp_dart_ffi.so"
    echo "           Run: cd native/build && cmake .. && make -j\$(nproc)"
fi

# Copy samples (rsync for incremental updates)
echo "  → Copying sample assets..."
mkdir -p "$SAMPLES_DST"
rsync -a --delete "$SAMPLES_SRC/" "$SAMPLES_DST/"

# Report size
echo ""
echo "  Samples size: $(du -sh "$SAMPLES_DST" | cut -f1)"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Deployment complete!"
echo ""
echo "  Run the app:"
echo "    $BUNDLE_DIR/open_synth"
echo ""
echo "  Or install system-wide:"
echo "    cp -r $BUNDLE_DIR ~/.local/share/open_synth"
echo "═══════════════════════════════════════════════════════════════"
