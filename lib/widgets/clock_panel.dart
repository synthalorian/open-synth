import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/clock_provider.dart';
import '../theme/synth_theme.dart';

class ClockPanel extends ConsumerWidget {
  const ClockPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(clockModeProvider);
    final bpm = ref.watch(clockBpmProvider);
    final isPlaying = ref.watch(clockTransportProvider);
    final tick = ref.watch(clockTickProvider);

    // Keep engine alive
    ref.watch(midiClockEngineProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: mode != ClockMode.off
              ? SynthTheme.orange.withValues(alpha: 0.4)
              : SynthTheme.purple.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mode != ClockMode.off
                      ? SynthTheme.orange
                      : SynthTheme.purple.withValues(alpha: 0.3),
                  boxShadow: mode != ClockMode.off
                      ? [BoxShadow(color: SynthTheme.orange.withValues(alpha: 0.5), blurRadius: 8)]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'MIDI CLOCK / SYNC',
                style: TextStyle(
                  color: mode != ClockMode.off ? SynthTheme.orange : SynthTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              // Mode selector
              _ModeSelector(
                mode: mode,
                onChanged: (m) => ref.read(clockModeProvider.notifier).state = m,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // BPM + Transport + Tick display
          Row(
            children: [
              // BPM control
              _BpmKnob(bpm: bpm, enabled: mode != ClockMode.slave),
              const SizedBox(width: 16),
              // Transport
              _TransportControl(
                isPlaying: isPlaying,
                onPlay: () => ref.read(clockTransportProvider.notifier).play(),
                onStop: () => ref.read(clockTransportProvider.notifier).stop(),
                enabled: mode != ClockMode.off,
              ),
              const SizedBox(width: 16),
              // Tick indicator
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TICK',
                      style: TextStyle(
                        color: SynthTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(6, (i) {
                        final active = (tick % 6) == i;
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? SynthTheme.orange
                                  : SynthTheme.surface,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: active
                                  ? [BoxShadow(color: SynthTheme.orange.withValues(alpha: 0.5), blurRadius: 4)]
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode == ClockMode.slave ? 'SLAVE • BPM estimated' : 'BPM locked',
                      style: TextStyle(
                        color: SynthTheme.textSecondary.withValues(alpha: 0.5),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final ClockMode mode;
  final ValueChanged<ClockMode> onChanged;

  const _ModeSelector({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: SynthTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClockMode>(
          value: mode,
          isDense: true,
          dropdownColor: SynthTheme.card,
          style: TextStyle(
            color: mode != ClockMode.off ? SynthTheme.orange : SynthTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          iconSize: 14,
          iconEnabledColor: SynthTheme.textSecondary,
          items: ClockMode.values.map((m) {
            return DropdownMenuItem(
              value: m,
              child: Text(m.displayName),
            );
          }).toList(),
          onChanged: (m) => onChanged(m!),
        ),
      ),
    );
  }
}

class _BpmKnob extends ConsumerWidget {
  final double bpm;
  final bool enabled;

  const _BpmKnob({required this.bpm, required this.enabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: enabled
                  ? () => ref.read(clockBpmProvider.notifier).state = (bpm - 1).clamp(30.0, 300.0)
                  : null,
              child: Icon(Icons.remove, color: enabled ? SynthTheme.orange : SynthTheme.textSecondary.withValues(alpha: 0.3), size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              '${bpm.round()}',
              style: GoogleFonts.orbitron(
                color: enabled ? SynthTheme.orange : SynthTheme.textSecondary.withValues(alpha: 0.3),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: enabled
                  ? () => ref.read(clockBpmProvider.notifier).state = (bpm + 1).clamp(30.0, 300.0)
                  : null,
              child: Icon(Icons.add, color: enabled ? SynthTheme.orange : SynthTheme.textSecondary.withValues(alpha: 0.3), size: 16),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'BPM',
          style: TextStyle(
            color: SynthTheme.textSecondary.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TransportControl extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onStop;
  final bool enabled;

  const _TransportControl({
    required this.isPlaying,
    required this.onPlay,
    required this.onStop,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: enabled ? onPlay : null,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPlaying
                  ? SynthTheme.cyan.withValues(alpha: 0.2)
                  : SynthTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isPlaying
                    ? SynthTheme.cyan
                    : enabled
                        ? SynthTheme.purple.withValues(alpha: 0.3)
                        : SynthTheme.purple.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              Icons.play_arrow,
              color: isPlaying
                  ? SynthTheme.cyan
                  : enabled
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.2),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: enabled ? onStop : null,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: !isPlaying
                  ? Colors.redAccent.withValues(alpha: 0.15)
                  : SynthTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: !isPlaying
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : enabled
                        ? SynthTheme.purple.withValues(alpha: 0.3)
                        : SynthTheme.purple.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              Icons.stop,
              color: !isPlaying
                  ? Colors.redAccent
                  : enabled
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.2),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
