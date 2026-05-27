import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/arpeggiator_provider.dart';
import '../models/keyboard_split.dart';
import '../providers/keyboard_split_provider.dart';
import '../providers/midi_recorder_provider.dart';
import '../providers/synth_providers.dart';
import '../theme/synth_theme.dart';

class KeyboardWidget extends ConsumerWidget {
  const KeyboardWidget({super.key});

  // Note names for one octave
  static const _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  static const _isBlack = [false, true, false, true, false, false, true, false, true, false, true, false];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final octave = ref.watch(keyboardOctaveProvider);
    final split = ref.watch(keyboardSplitProvider);
    final activeNotes = ref.watch(playbackStateProvider);
    final zoneBActive = ref.watch(zoneBPlaybackProvider);

    // Combined active notes for both zones
    final allActive = {...activeNotes, ...zoneBActive};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: SynthTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: SynthTheme.magenta.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          // Octave controls + split indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _OctaveBtn(
                icon: Icons.keyboard_arrow_down,
                onTap: octave > 1
                    ? () => ref.read(keyboardOctaveProvider.notifier).state = octave - 1
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'C$octave — C${octave + 2}',
                  style: TextStyle(
                    color: SynthTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _OctaveBtn(
                icon: Icons.keyboard_arrow_up,
                onTap: octave < 7
                    ? () => ref.read(keyboardOctaveProvider.notifier).state = octave + 1
                    : null,
              ),
              if (split.enabled) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: split.mode == SplitMode.layer
                        ? SynthTheme.orange.withValues(alpha: 0.15)
                        : SynthTheme.magenta.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    split.mode == SplitMode.layer ? 'LAYER' : 'SPLIT',
                    style: TextStyle(
                      color: split.mode == SplitMode.layer
                          ? SynthTheme.orange
                          : SynthTheme.magenta,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Piano keys — 2 octaves
          SizedBox(
            height: 100,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 2 octaves = 14 white keys
                const whiteKeysCount = 14;
                final whiteKeyWidth = constraints.maxWidth / whiteKeysCount;
                final blackKeyWidth = whiteKeyWidth * 0.6;

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
                            height: 100,
                            label: _noteNames[i],
                            isActive: isActive,
                            isSplitPoint: isSplitPoint,
                            isZoneB: isZoneB,
                            onTapDown: () {
                              _noteOn(ref, midiNote);
                            },
                            onTapUp: () {
                              _noteOff(ref, midiNote);
                            },
                          ),
                        ),
                      );
                      whiteX += whiteKeyWidth;
                    } else {
                      // Black key — position relative to previous white key
                      final x = whiteX - blackKeyWidth / 2;
                      blackKeys.add(
                        Positioned(
                          left: x,
                          top: 0,
                          child: _BlackKey(
                            width: blackKeyWidth,
                            height: 60,
                            isActive: isActive,
                            isZoneB: isZoneB,
                            onTapDown: () {
                              _noteOn(ref, midiNote);
                            },
                            onTapUp: () {
                              _noteOff(ref, midiNote);
                            },
                          ),
                        ),
                      );
                    }
                  }
                }

                return Stack(children: [...whiteKeys, ...blackKeys]);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _noteOn(WidgetRef ref, int midiNote) {
    final split = ref.read(keyboardSplitProvider);
    final zones = split.zonesForNote(midiNote);

    // Update arp notes regardless of zone
    ref.read(arpNotesProvider.notifier).update((set) => {...set, midiNote});

    for (final zone in zones) {
      final shiftedNote = split.shiftedNote(midiNote, zone);
      if (zone == 1) {
        ref.read(zoneBPlaybackProvider.notifier).noteOn(shiftedNote);
      } else {
        ref.read(playbackStateProvider.notifier).noteOn(shiftedNote);
      }
    }
    recordNoteOn(ref, midiNote);
  }

  void _noteOff(WidgetRef ref, int midiNote) {
    final split = ref.read(keyboardSplitProvider);
    final zones = split.zonesForNote(midiNote);

    ref.read(arpNotesProvider.notifier).update((set) => {...set}..remove(midiNote));

    for (final zone in zones) {
      final shiftedNote = split.shiftedNote(midiNote, zone);
      if (zone == 1) {
        ref.read(zoneBPlaybackProvider.notifier).noteOff(shiftedNote);
      } else {
        ref.read(playbackStateProvider.notifier).noteOff(shiftedNote);
      }
    }
    recordNoteOff(ref, midiNote);
  }
}

class _OctaveBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _OctaveBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: SynthTheme.card,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: onTap != null
                ? SynthTheme.magenta.withValues(alpha: 0.5)
                : SynthTheme.purple.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? SynthTheme.magenta : SynthTheme.textSecondary.withValues(alpha: 0.3),
        ),
      ),
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
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _WhiteKey({
    required this.width,
    required this.height,
    required this.label,
    required this.isActive,
    required this.isSplitPoint,
    required this.isZoneB,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
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
            top: BorderSide(
              color: isSplitPoint
                  ? SynthTheme.magenta
                  : Colors.black.withValues(alpha: 0.2),
              width: isSplitPoint ? 3 : 0.5,
            ),
            bottom: BorderSide(
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
              : isSplitPoint
                  ? [
                      BoxShadow(
                        color: SynthTheme.magenta.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? (isZoneB ? SynthTheme.magenta : SynthTheme.cyan)
                    : Colors.black.withValues(alpha: 0.4),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSplitPoint) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.swap_horiz,
                size: 10,
                color: SynthTheme.magenta.withValues(alpha: 0.8),
              ),
            ],
          ],
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
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _BlackKey({
    required this.width,
    required this.height,
    required this.isActive,
    required this.isZoneB,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
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
