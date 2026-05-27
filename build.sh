#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$PROJECT_DIR/native"
BUNDLE_DIR="$PROJECT_DIR/build/linux/x64/release/bundle"

echo "==> Building native FFI library..."
cd "$NATIVE_DIR/build"
cmake .. -DCMAKE_BUILD_TYPE=Release 2>&1 | tail -3
make -j"$(nproc)" 2>&1 | tail -3

echo "==> Ensuring flutter_midi_command_linux visibility fix..."
# The flutter_midi_command_linux plugin sets CXX_VISIBILITY_PRESET hidden,
# which hides none_register_with_registrar from the shared library.
# This sed re-applies the visibility attribute if flutter pub get regenerated the file.
MIDI_PLUGIN_SRC="$PROJECT_DIR/linux/flutter/ephemeral/.plugin_symlinks/flutter_midi_command_linux/linux/flutter_midi_command_linux_plugin.cc"
if grep -q "CXX_VISIBILITY_PRESET hidden" "$PROJECT_DIR/linux/flutter/ephemeral/.plugin_symlinks/flutter_midi_command_linux/linux/CMakeLists.txt" 2>/dev/null; then
    if ! grep -q "__attribute__.*visibility.*default.*none_register" "$MIDI_PLUGIN_SRC" 2>/dev/null; then
        sed -i 's/^void none_register_with_registrar/__attribute__((visibility("default"))) void none_register_with_registrar/' "$MIDI_PLUGIN_SRC"
        echo "   ✅ Visibility fix applied to flutter_midi_command_linux"
    else
        echo "   ✅ Visibility fix already in place"
    fi
fi

echo "==> Building Flutter Linux app..."
cd "$PROJECT_DIR"
flutter build linux --release 2>&1 | tail -5

echo "==> Installing for walker..."
bash "$PROJECT_DIR/install.sh"

echo ""
echo "✅ Open Synth is ready!"
echo "   Press Super+Space and type 'Open Synth' to launch"
echo "   Or run: $BUNDLE_DIR/open_synth"
