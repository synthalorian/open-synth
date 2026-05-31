import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/arpeggiator_provider.dart';
import '../providers/keyboard_split_provider.dart';
import '../providers/midi_recorder_provider.dart';
import '../providers/synth_providers.dart';
import '../theme/synth_theme.dart';

/// A playable piano keyboard widget optimized for mobile touch.
///
/// Uses [Listener] for raw pointer events to support multi-touch and
/// finger gliding across keys. Keys fill the entire available height —
/// no wasted space for octave controls (those live in the mobile top bar).
class KeyboardWidget extends ConsumerStatefulWidget {
  const KeyboardWidget({super.key});

  @override
  ConsumerState<KeyboardWidget> createState() => _KeyboardWidgetState();
}

class _KeyboardWidgetState extends ConsumerState<KeyboardWidget> {
  // ── Tracking which pointer IDs are on which keys ──
  final Map<int, int> _pointerToNote = {}; // pointer ID → MIDI note
  final Map<int, int> _noteRefCount = {};   // MIDI note → how many pointers on it

  static const _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  static const _isBlack = [false, true, false, true, false, false, true, false, true, false, true, false];

  @override
  void dispose() {
    // Release any stuck notes
    _pointerToNote.clear();
    _noteRefCount.clear();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event, int midiNote, WidgetRef ref) {
    _pointerToNote[event.pointer] = midiNote;
    _noteRefCount[midiNote] = (_noteRefCount[midiNote] ?? 0) + 1;
    if (_noteRefCount[midiNote] == 1) {
      _noteOn(ref, midiNote);
    }
  }

  void _handlePointerMove(PointerMoveEvent event, WidgetRef ref) {
    // This fires when the finger is already down and moves to a new key.
    // We don't get the new key directly from the event — instead we let
    // each key's Listener handle PointerMove after the pointer enters its bounds.
    // Flutter's hit testing re-evaluates on each move, so each key's onPointerMove
    // fires when the finger slides into it.
  }

  void _handlePointerUp(PointerUpEvent event, WidgetRef ref) {
    _releasePointer(event.pointer, ref);
  }

  void _handlePointerCancel(PointerCancelEvent event, WidgetRef ref) {
    _releasePointer(event.pointer, ref);
  }

  void _releasePointer(int pointerId, WidgetRef ref) {
    final midiNote = _pointerToNote.remove(pointerId);
    if (midiNote == null) return;
    final count = (_noteRefCount[midiNote] ?? 1) - 1;
    if (count <= 0) {
      _noteRefCount.remove(midiNote);
      _noteOff(ref, midiNote);
    } else {
      _noteRefCount[midiNote] = count;
    }
  }

  void _noteOn(WidgetRef ref, int midiNote) {
    // Use NoteRouter for proper split/layer routing and zone tracking.
    // This ensures note-off always hits the same zones even if split
    // config changes while the key is held.
    ref.read(arpNotesProvider.notifier).update((set) => {...set, midiNote});
    ref.read(noteRouterProvider).noteOn(midiNote);
    recordNoteOn(ref, midiNote);
  }

  void _noteOff(WidgetRef ref, int midiNote) {
    ref.read(arpNotesProvider.notifier).update((set) => {...set}..remove(midiNote));
    ref.read(noteRouterProvider).noteOff(midiNote);
    recordNoteOff(ref, midiNote);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final octave = ref.watch(keyboardOctaveProvider);
        final split = ref.watch(keyboardSplitProvider);
        final activeNotes = ref.watch(playbackStateProvider);
        final zoneBActive = ref.watch(zoneBPlaybackProvider);
        final allActive = {...activeNotes, ...zoneBActive};

        return Container(
          decoration: BoxDecoration(
            color: SynthTheme.surface,
            border: Border(
              top: BorderSide(color: SynthTheme.magenta.withValues(alpha: 0.3)),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 2 octaves = 14 white keys
              const whiteKeysCount = 14;
              final whiteKeyWidth = constraints.maxWidth / whiteKeysCount;
              final blackKeyWidth = whiteKeyWidth * 0.6;
              // White keys fill full height; black keys are 62% of that
              final whiteKeyHeight = constraints.maxHeight;
              final blackKeyHeight = whiteKeyHeight * 0.62;

              final whiteKeys = <Widget>[];
              final blackKeys = <Widget>[];

              double whiteX = 0;

              for (int octIdx = 0; octIdx < 2; octIdx++) {
                for (int i = 0; i < 12; i++) {
                  final midiNote = (octave + octIdx) * 12 + i;
                  final isActive = allActive.contains(midiNote);
                  final isSplitPoint = split.enabled && midiNote == split.splitPoint;
                  final isZoneB = split.enabled && midiNote >= split.splitPoint;

                  if (!_isBlack[i]) {
                    // White key
                    final x = whiteX;
                    whiteKeys.add(
                      Positioned(
                        left: x,
                        top: 0,
                        child: _WhiteKey(
                          width: whiteKeyWidth - 1,
                          height: whiteKeyHeight,
                          label: _noteNames[i],
                          isActive: isActive,
                          isSplitPoint: isSplitPoint,
                          isZoneB: isZoneB,
                          midiNote: midiNote,
                          onPointerDown: (event) => _handlePointerDown(event, midiNote, ref),
                          onPointerMove: (event) => _handlePointerMove(event, ref),
                          onPointerUp: (event) => _handlePointerUp(event, ref),
                          onPointerCancel: (event) => _handlePointerCancel(event, ref),
                        ),
                      ),
                    );
                    whiteX += whiteKeyWidth;
                  } else {
                    // Black key — positioned relative to previous white key
                    final x = whiteX - blackKeyWidth / 2;
                    blackKeys.add(
                      Positioned(
                        left: x,
                        top: 0,
                        child: _BlackKey(
                          width: blackKeyWidth,
                          height: blackKeyHeight,
                          isActive: isActive,
                          isZoneB: isZoneB,
                          midiNote: midiNote,
                          onPointerDown: (event) => _handlePointerDown(event, midiNote, ref),
                          onPointerMove: (event) => _handlePointerMove(event, ref),
                          onPointerUp: (event) => _handlePointerUp(event, ref),
                          onPointerCancel: (event) => _handlePointerCancel(event, ref),
                        ),
                      ),
                    );
                  }
                }
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [...whiteKeys, ...blackKeys],
              );
            },
          ),
        );
      },
    );
  }
}

class _WhiteKey extends StatelessWidget {
  final double width;
  final double height;
  final String label;
  final bool isActive;
  final bool isSplitPoint;
  final bool isZoneB;
  final int midiNote;
  final Function(PointerDownEvent) onPointerDown;
  final Function(PointerMoveEvent) onPointerMove;
  final Function(PointerUpEvent) onPointerUp;
  final Function(PointerCancelEvent) onPointerCancel;

  const _WhiteKey({
    required this.width,
    required this.height,
    required this.label,
    required this.isActive,
    required this.isSplitPoint,
    required this.isZoneB,
    required this.midiNote,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 40),
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isActive
                ? (isZoneB
                    ? [
                        SynthTheme.magenta.withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0.95),
                      ]
                    : [
                        SynthTheme.cyan.withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0.95),
                      ])
                : [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.85),
                  ],
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
          border: Border(
            left: isSplitPoint
                ? BorderSide(color: SynthTheme.magenta, width: 3)
                : BorderSide(
                    color: isActive
                        ? (isZoneB
                            ? SynthTheme.magenta.withValues(alpha: 0.6)
                            : SynthTheme.cyan.withValues(alpha: 0.6))
                        : Colors.black.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
            right: BorderSide(
              color: Colors.black.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: isZoneB
                        ? SynthTheme.magenta.withValues(alpha: 0.4)
                        : SynthTheme.cyan.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? (isZoneB ? SynthTheme.magenta : SynthTheme.cyan)
                : Colors.black.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BlackKey extends StatelessWidget {
  final double width;
  final double height;
  final bool isActive;
  final bool isZoneB;
  final int midiNote;
  final Function(PointerDownEvent) onPointerDown;
  final Function(PointerMoveEvent) onPointerMove;
  final Function(PointerUpEvent) onPointerUp;
  final Function(PointerCancelEvent) onPointerCancel;

  const _BlackKey({
    required this.width,
    required this.height,
    required this.isActive,
    required this.isZoneB,
    required this.midiNote,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 40),
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isActive
                ? (isZoneB
                    ? [
                        SynthTheme.magenta,
                        SynthTheme.magenta.withValues(alpha: 0.7),
                      ]
                    : [
                        SynthTheme.cyan,
                        SynthTheme.cyan.withValues(alpha: 0.7),
                      ])
                : [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF0F0F1A),
                  ],
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? (isZoneB
                      ? SynthTheme.magenta.withValues(alpha: 0.5)
                      : SynthTheme.cyan.withValues(alpha: 0.5))
                  : Colors.black.withValues(alpha: 0.5),
              blurRadius: isActive ? 8 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
