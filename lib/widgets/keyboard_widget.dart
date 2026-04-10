import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final activeNotes = ref.watch(playbackStateProvider);

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
          // Octave controls
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
                    final isActive = activeNotes.contains(midiNote);

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
                            onTapDown: () =>
                                ref.read(playbackStateProvider.notifier).noteOn(midiNote),
                            onTapUp: () =>
                                ref.read(playbackStateProvider.notifier).noteOff(midiNote),
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
                            onTapDown: () =>
                                ref.read(playbackStateProvider.notifier).noteOn(midiNote),
                            onTapUp: () =>
                                ref.read(playbackStateProvider.notifier).noteOff(midiNote),
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
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _WhiteKey({
    required this.width,
    required this.height,
    required this.label,
    required this.isActive,
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
                ? [
                    SynthTheme.magenta.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0.95),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.85),
                  ],
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
          border: Border.all(
            color: isActive
                ? SynthTheme.magenta.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.2),
            width: 0.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: SynthTheme.magenta.withValues(alpha: 0.4),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? SynthTheme.magenta : Colors.black.withValues(alpha: 0.4),
            fontSize: 8,
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
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _BlackKey({
    required this.width,
    required this.height,
    required this.isActive,
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
                ? [
                    SynthTheme.magenta,
                    SynthTheme.magenta.withValues(alpha: 0.7),
                  ]
                : [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF0F0F1A),
                  ],
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? SynthTheme.magenta.withValues(alpha: 0.5)
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
