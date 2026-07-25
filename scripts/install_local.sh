#!/usr/bin/env bash
# Install Open Synth standalone locally (freedesktop): binary + samples,
# application entry, and icon. Safe to re-run (idempotent).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTEFACTS="$REPO_ROOT/build/OpenSynth_artefacts/Release/Standalone"
PREFIX="$HOME/.local/share/opensynth"

if [[ ! -x "$ARTEFACTS/Open Synth" ]]; then
    echo "error: $ARTEFACTS/Open Synth not found — build first (cmake --build build --config Release)" >&2
    exit 1
fi

echo "Installing to $PREFIX ..."
mkdir -p "$PREFIX"
cp -f "$ARTEFACTS/Open Synth" "$PREFIX/"
rm -rf "$PREFIX/samples"
cp -r "$ARTEFACTS/samples" "$PREFIX/"

# Icon
install -Dm644 "$REPO_ROOT/assets/icon_512.png" \
    "$HOME/.local/share/icons/hicolor/512x512/apps/open-synth.png"

# Desktop entry
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/open-synth.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Open Synth
Comment=Open-source synthesizer — 5,600 presets, sample ROMpler, Juno-style
Exec="$PREFIX/Open Synth"
Icon=open-synth
Terminal=false
Categories=AudioVideo;Audio;X-Synthesis;Midi;
Keywords=synth;synthesizer;piano;midi;music;keyboard;
StartupWMClass=Open Synth
EOF

# Refresh caches (best-effort; not all environments have these)
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
if command -v kbuildsycoca6 >/dev/null; then
    kbuildsycoca6 --noincremental 2>/dev/null || true
fi

echo "Done. 'Open Synth' should now appear in your application launcher."
