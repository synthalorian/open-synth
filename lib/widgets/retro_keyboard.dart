import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/retro_theme.dart';

/// A retro-styled piano keyboard widget.
///
/// Aged ivory white keys, warm black keys, amber LED indicators
/// for active notes. Optimized for both desktop and mobile.
class RetroKeyboard extends ConsumerStatefulWidget {
  final Set<int> activeNotes;
  final ValueChanged<int>? onNoteOn;
  final ValueChanged<int>? onNoteOff;
  final int baseOctave;

  const RetroKeyboard({
    super.key,
    this.activeNotes = const {},
    this.onNoteOn,
    this.onNoteOff,
    this.baseOctave = 4,
  });

  @override
  ConsumerState<RetroKeyboard> createState() => _RetroKeyboardState();
}

class _RetroKeyboardState extends ConsumerState<RetroKeyboard> {
  final Map<int, int> _pointerToNote = {};
  final Map<int, int> _noteRefCount = {};

  static const _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  static const _isBlack = [false, true, false, true, false, false, true, false, true, false, true, false];

  void _handlePointerDown(PointerDownEvent event, int midiNote) {
    _pointerToNote[event.pointer] = midiNote;
    _noteRefCount[midiNote] = (_noteRefCount[midiNote] ?? 0) + 1;
    if (_noteRefCount[midiNote] == 1) {
      widget.onNoteOn?.call(midiNote);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final midiNote = _pointerToNote.remove(event.pointer);
    if (midiNote == null) return;
    final count = (_noteRefCount[midiNote] ?? 1) - 1;
    if (count <= 0) {
      _noteRefCount.remove(midiNote);
      widget.onNoteOff?.call(midiNote);
    } else {
      _noteRefCount[midiNote] = count;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RetroTheme.chassis,
        border: Border(
          top: BorderSide(color: RetroTheme.highlight.withOpacity(0.2), width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const whiteKeysCount = 14; // 2 octaves
          final whiteKeyWidth = constraints.maxWidth / whiteKeysCount;
          final blackKeyWidth = whiteKeyWidth * 0.6;
          final whiteKeyHeight = constraints.maxHeight;
          final blackKeyHeight = whiteKeyHeight * 0.62;

          final baseNote = widget.baseOctave * 12;

          return Stack(
            children: [
              // White keys
              Row(
                children: List.generate(whiteKeysCount, (i) {
                  final whiteIndex = i;
                  final midiNote = baseNote + _whiteToMidi(whiteIndex);
                  final isActive = widget.activeNotes.contains(midiNote);

                  return Listener(
                    onPointerDown: (e) => _handlePointerDown(e, midiNote),
                    onPointerUp: _handlePointerUp,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: whiteKeyWidth,
                      height: whiteKeyHeight,
                      decoration: BoxDecoration(
                        color: isActive ? RetroTheme.keyPressed : RetroTheme.keyWhite,
                        border: Border(
                          right: BorderSide(color: RetroTheme.shadow.withOpacity(0.3), width: 1),
                          bottom: BorderSide(color: RetroTheme.shadow.withOpacity(0.2), width: 2),
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: RetroTheme.neonYellow.withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isActive
                          ? Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: RetroTheme.ledOn,
                                  boxShadow: [
                                    BoxShadow(
                                      color: RetroTheme.ledOn.withOpacity(0.6),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),
              // Black keys
              ..._buildBlackKeys(baseNote, whiteKeyWidth, blackKeyWidth, whiteKeyHeight, blackKeyHeight),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildBlackKeys(int baseNote, double whiteWidth, double blackWidth, double whiteHeight, double blackHeight) {
    final List<Widget> keys = [];
    // Black key positions (between white keys): after C, D, F, G, A
    const blackOffsets = [0, 1, 3, 4, 5]; // white key indices before each black key
    const blackSemitones = [1, 3, 6, 8, 10]; // semitone offset from octave start

    for (int octave = 0; octave < 2; octave++) {
      for (int i = 0; i < 5; i++) {
        final whiteIndex = octave * 7 + blackOffsets[i];
        final midiNote = baseNote + octave * 12 + blackSemitones[i];
        final isActive = widget.activeNotes.contains(midiNote);

        keys.add(
          Positioned(
            left: whiteWidth * (whiteIndex + 1) - blackWidth / 2,
            child: Listener(
              onPointerDown: (e) => _handlePointerDown(e, midiNote),
              onPointerUp: _handlePointerUp,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: blackWidth,
                height: blackHeight,
                decoration: BoxDecoration(
                  color: isActive ? RetroTheme.neonYellow.withOpacity(0.3) : RetroTheme.keyBlack,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                  border: Border(
                    left: BorderSide(color: RetroTheme.highlight.withOpacity(0.2), width: 1),
                    right: BorderSide(color: RetroTheme.shadow.withOpacity(0.5), width: 1),
                    bottom: BorderSide(color: RetroTheme.shadow.withOpacity(0.3), width: 2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                    if (isActive)
                      BoxShadow(
                        color: RetroTheme.neonYellow.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: isActive
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 3),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: RetroTheme.ledOn,
                            boxShadow: [
                              BoxShadow(
                                color: RetroTheme.ledOn.withOpacity(0.6),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        );
      }
    }
    return keys;
  }

  int _whiteToMidi(int whiteIndex) {
    // Map white key index to semitone: C=0, D=2, E=4, F=5, G=7, A=9, B=11
    const whiteToSemitone = [0, 2, 4, 5, 7, 9, 11];
    return whiteToSemitone[whiteIndex % 7] + (whiteIndex ~/ 7) * 12;
  }
}
