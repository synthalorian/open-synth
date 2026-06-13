#!/usr/bin/env bash
# Download additional free sample libraries for Open Synth.
#
# Libraries:
#   1. Salamander Grand Piano (CC0) — 1.2GB, quality sampled grand piano
#   2. MT Power Drum Kit (free) — rock drum kit
#
# Usage:
#   bash scripts/download-extra-samples.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SAMPLES_DIR="$PROJECT_DIR/assets/samples"

echo "═══════════════════════════════════════════════════════════════"
echo "  Open Synth — Extra Sample Library Downloader"
echo "═══════════════════════════════════════════════════════════════"
echo ""

mkdir -p "$SAMPLES_DIR"

# ── Salamander Grand Piano (CC0) ──────────────────────────────
SALAMANDER_DIR="$SAMPLES_DIR/SalamanderGrandPianoV3"
if [[ -d "$SALAMANDER_DIR" ]]; then
    echo "  ✓ Salamander Grand Piano already exists"
else
    echo "  → Downloading Salamander Grand Piano (CC0)..."
    echo "    Source: https://archive.org/details/SalamanderGrandPianoV3"
    echo ""
    
    TEMP_ARCHIVE="/tmp/salamander_piano.tar.bz2"
    
    # Download from archive.org (48kHz/24bit version, best quality)
    curl -L -o "$TEMP_ARCHIVE" \
        "https://archive.org/download/SalamanderGrandPianoV3/SalamanderGrandPianoV3_48khz24bit.tar.bz2" \
        || { echo "    ERROR: Download failed"; exit 1; }
    
    echo "    Extracting..."
    mkdir -p "$SAMPLES_DIR"
    tar -xjf "$TEMP_ARCHIVE" -C "$SAMPLES_DIR/"
    rm "$TEMP_ARCHIVE"
    
    echo "  ✓ Salamander Grand Piano installed"
fi

echo ""

# ── MT Power Drum Kit (free) ──────────────────────────────────
MT_POWER_DIR="$SAMPLES_DIR/MT-PowerDrumKit"
if [[ -d "$MT_POWER_DIR" ]]; then
    echo "  ✓ MT Power Drum Kit already exists"
else
    echo "  → MT Power Drum Kit requires manual download:"
    echo ""
    echo "    1. Visit: https://mtpowerdrumkit.com/"
    echo "    2. Download the free version"
    echo "    3. Extract to: $MT_POWER_DIR"
    echo ""
    echo "    The free version includes:"
    echo "      - Kick, Snare, Toms, Hi-hats, Cymbals"
    echo "      - Multiple velocity layers"
    echo "      - SFZ format compatible with sfizz"
    echo ""
fi

# ── Summary ───────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
echo "  Sample Library Summary"
echo "═══════════════════════════════════════════════════════════════"
echo ""

for dir in "$SAMPLES_DIR"/*; do
    if [[ -d "$dir" ]]; then
        name=$(basename "$dir")
        size=$(du -sh "$dir" | cut -f1)
        echo "  • $name: $size"
    fi
done

echo ""
echo "  Total: $(du -sh "$SAMPLES_DIR" | cut -f1)"
echo ""
echo "═══════════════════════════════════════════════════════════════"
