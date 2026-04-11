// FL Studio-style computer-keyboard-as-piano binding for the open-synth
// playable surface. Wraps any child widget in a Focus + KeyboardListener
// that translates physical keypresses into MIDI noteOn / noteOff events
// against the existing playbackStateProvider.
//
// Key map (matches FL Studio's Typing Keyboard layout):
//
//   Upper octave  (current octave + 1):
//     Q  2  W  3  E  R  5  T  6  Y  7  U  I
//     C  C# D  D# E  F  F# G  G# A  A# B  C
//
//   Lower octave  (current octave):
//     Z  S  X  D  C  V  G  B  H  N  J  M  ,
//     C  C# D  D# E  F  F# G  G# A  A# B  C
//
//   Octave shift:  [  = down,  ]  = up
//   Panic:         \  = all notes off
//
// Implementation notes:
//
// - Each physical press is mapped to its MIDI note at press-time and
//   stashed in `_activeKeys`. noteOff uses the stashed value, NOT the
//   current octave, so shifting octaves mid-hold doesn't strand voices.
// - Key repeats from the OS auto-repeat feature are filtered: if the
//   key is already in `_activeKeys`, the down event is ignored.
// - The Focus is auto-requested on mount and on every tap inside the
//   widget so the user never has to think about "is the keyboard
//   focused" — touching anywhere inside open-synth gets keys back.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/synth_providers.dart';

/// Maps a [LogicalKeyboardKey] to a semitone offset from the lower
/// octave's C. Lower-octave row first, then upper-octave row.
final Map<LogicalKeyboardKey, int> _keyToSemitones = {
  // ── Lower octave (Z row + S row) ─────────────────────────────────────
  LogicalKeyboardKey.keyZ: 0, // C
  LogicalKeyboardKey.keyS: 1, // C#
  LogicalKeyboardKey.keyX: 2, // D
  LogicalKeyboardKey.keyD: 3, // D#
  LogicalKeyboardKey.keyC: 4, // E
  LogicalKeyboardKey.keyV: 5, // F
  LogicalKeyboardKey.keyG: 6, // F#
  LogicalKeyboardKey.keyB: 7, // G
  LogicalKeyboardKey.keyH: 8, // G#
  LogicalKeyboardKey.keyN: 9, // A
  LogicalKeyboardKey.keyJ: 10, // A#
  LogicalKeyboardKey.keyM: 11, // B
  LogicalKeyboardKey.comma: 12, // C (next octave)
  LogicalKeyboardKey.keyL: 13, // C# (above next-octave C)
  LogicalKeyboardKey.period: 14, // D
  LogicalKeyboardKey.semicolon: 15, // D#
  LogicalKeyboardKey.slash: 16, // E

  // ── Upper octave (Q row + 2 row) ─────────────────────────────────────
  LogicalKeyboardKey.keyQ: 12, // C
  LogicalKeyboardKey.digit2: 13, // C#
  LogicalKeyboardKey.keyW: 14, // D
  LogicalKeyboardKey.digit3: 15, // D#
  LogicalKeyboardKey.keyE: 16, // E
  LogicalKeyboardKey.keyR: 17, // F
  LogicalKeyboardKey.digit5: 18, // F#
  LogicalKeyboardKey.keyT: 19, // G
  LogicalKeyboardKey.digit6: 20, // G#
  LogicalKeyboardKey.keyY: 21, // A
  LogicalKeyboardKey.digit7: 22, // A#
  LogicalKeyboardKey.keyU: 23, // B
  LogicalKeyboardKey.keyI: 24, // C (next octave)
  LogicalKeyboardKey.digit9: 25, // C#
  LogicalKeyboardKey.keyO: 26, // D
  LogicalKeyboardKey.digit0: 27, // D#
  LogicalKeyboardKey.keyP: 28, // E
};

/// Wrap [child] to receive FL Studio-style piano keybinds. Sits between
/// the Scaffold body and the rest of the synth UI; touch anywhere inside
/// to focus, then start playing.
class ComputerKeyboardListener extends ConsumerStatefulWidget {
  const ComputerKeyboardListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<ComputerKeyboardListener> createState() =>
      _ComputerKeyboardListenerState();
}

class _ComputerKeyboardListenerState
    extends ConsumerState<ComputerKeyboardListener> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'open_synth_keyboard');

  /// Physical keys currently held → the MIDI note they fired. Stashing
  /// the *original* MIDI note is what makes octave shifts safe during
  /// a held chord.
  final Map<LogicalKeyboardKey, int> _activeKeys = {};

  @override
  void initState() {
    super.initState();
    // Defer focus until after first build so the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    // Defensive: release any held notes if the screen tears down with
    // keys still in the down state.
    if (_activeKeys.isNotEmpty) {
      ref.read(playbackStateProvider.notifier).allNotesOff();
      _activeKeys.clear();
    }
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    // ── Octave shift / panic — independent of the piano map ─────────
    if (event is KeyDownEvent) {
      if (key == LogicalKeyboardKey.bracketLeft) {
        final current = ref.read(keyboardOctaveProvider);
        if (current > 0) {
          ref.read(keyboardOctaveProvider.notifier).state = current - 1;
        }
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.bracketRight) {
        final current = ref.read(keyboardOctaveProvider);
        if (current < 8) {
          ref.read(keyboardOctaveProvider.notifier).state = current + 1;
        }
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.backslash) {
        ref.read(playbackStateProvider.notifier).allNotesOff();
        _activeKeys.clear();
        return KeyEventResult.handled;
      }
    }

    // ── Piano key ───────────────────────────────────────────────────
    final semitones = _keyToSemitones[key];
    if (semitones == null) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      // Filter OS key repeats.
      if (_activeKeys.containsKey(key)) return KeyEventResult.handled;

      final octave = ref.read(keyboardOctaveProvider);
      // MIDI 0 = C-1, so MIDI for "C in octave N" is (N + 1) * 12.
      final midi = (octave + 1) * 12 + semitones;
      if (midi < 0 || midi > 127) return KeyEventResult.handled;

      _activeKeys[key] = midi;
      ref.read(playbackStateProvider.notifier).noteOn(midi);
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      final midi = _activeKeys.remove(key);
      if (midi != null) {
        ref.read(playbackStateProvider.notifier).noteOff(midi);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: GestureDetector(
        // Tap-to-refocus so the user never gets stuck without keys.
        // Use translucent so this doesn't intercept presses on inner
        // widgets (knobs, buttons, the on-screen piano keys).
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => _focusNode.requestFocus(),
        child: widget.child,
      ),
    );
  }
}
