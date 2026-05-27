#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUNDLE_DIR="$PROJECT_DIR/build/linux/x64/release/bundle"
INSTALL_DIR="$HOME/.local/share/open_synth"
APP_DIR="$HOME/.local/share/applications"
BIN_DIR="$HOME/.local/bin"

echo "==> Installing Open Synth to $INSTALL_DIR..."

# Build if needed
if [ ! -f "$BUNDLE_DIR/open_synth" ]; then
    echo "   Bundle not found — running build.sh first..."
    bash "$PROJECT_DIR/build.sh"
    exit 0
fi

# Copy bundle
mkdir -p "$INSTALL_DIR"
cp -r "$BUNDLE_DIR"/* "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/open_synth"

# Symlink into PATH
mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/open_synth" "$BIN_DIR/open_synth"

# Copy icon if it exists
ICON_PATH=""
if [ -f "$PROJECT_DIR/icon.png" ]; then
    cp "$PROJECT_DIR/icon.png" "$INSTALL_DIR/icon.png"
    ICON_PATH="$INSTALL_DIR/icon.png"
elif [ -f "$PROJECT_DIR/icon.svg" ]; then
    cp "$PROJECT_DIR/icon.svg" "$INSTALL_DIR/icon.svg"
    ICON_PATH="$INSTALL_DIR/icon.svg"
fi

# Create .desktop file for walker
mkdir -p "$APP_DIR"
cat > "$APP_DIR/open_synth.desktop" << EOF
[Desktop Entry]
Name=Open Synth
Comment=Software synthesizer with synthwave preset library
Exec=$INSTALL_DIR/open_synth
Icon=${ICON_PATH:-open_synth}
Terminal=false
Type=Application
Categories=Audio;Music;Synthesizer;
StartupNotify=true
EOF

# Update desktop database
update-desktop-database "$APP_DIR" 2>/dev/null || true

echo ""
echo "✅ Open Synth installed!"
echo "   Launch with Super+Space → type 'Open Synth'"
echo "   Or run: open_synth"
echo ""
echo "   Rebuild after code changes:  cd $PROJECT_DIR && ./build.sh"
