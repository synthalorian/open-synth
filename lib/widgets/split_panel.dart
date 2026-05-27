import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/keyboard_split_provider.dart';
import '../providers/synth_providers.dart';
import '../theme/synth_theme.dart';
import 'synth_knob.dart';

class SplitPanel extends ConsumerWidget {
  const SplitPanel({super.key});

  static const _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  String _formatNote(int midiNote) {
    final octave = (midiNote ~/ 12) - 1;
    final name = _noteNames[midiNote % 12];
    return '$name$octave';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final split = ref.watch(keyboardSplitProvider);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: split.enabled
              ? SynthTheme.cyan.withValues(alpha: 0.4)
              : SynthTheme.purple.withValues(alpha: 0.15),
        ),
        gradient: split.enabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SynthTheme.card,
                  SynthTheme.card.withValues(alpha: 0.85),
                ],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              GestureDetector(
                onTap: () => ref.read(keyboardSplitProvider.notifier).toggle(),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: split.enabled
                        ? SynthTheme.cyan
                        : SynthTheme.purple.withValues(alpha: 0.3),
                    boxShadow: split.enabled
                        ? [
                            BoxShadow(
                              color: SynthTheme.cyan.withValues(alpha: 0.5),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'KEYBOARD SPLIT',
                style: TextStyle(
                  color: split.enabled ? SynthTheme.cyan : SynthTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              if (split.enabled) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: SynthTheme.magenta.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SPLIT AT ${_formatNote(split.splitPoint)}',
                    style: TextStyle(
                      color: SynthTheme.magenta,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (split.enabled)
                GestureDetector(
                  onTap: () => _showPresetPicker(context, ref, isZoneB: false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SynthTheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      'Set Presets',
                      style: TextStyle(
                        color: SynthTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          if (split.enabled) ...[
            const SizedBox(height: 12),

            // ── Split Point Slider ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'SPLIT POINT',
                      style: TextStyle(
                        color: SynthTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatNote(split.splitPoint),
                      style: TextStyle(
                        color: SynthTheme.magenta,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: GoogleFonts.orbitron().fontFamily,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'C1',
                      style: TextStyle(
                        color: SynthTheme.textSecondary.withValues(alpha: 0.5),
                        fontSize: 9,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: SynthTheme.magenta,
                          inactiveTrackColor: SynthTheme.purple.withValues(alpha: 0.2),
                          thumbColor: SynthTheme.magenta,
                          overlayColor: SynthTheme.magenta.withValues(alpha: 0.2),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: split.splitPoint.toDouble(),
                          min: 24,
                          max: 96,
                          divisions: 72,
                          onChanged: (v) {
                            ref.read(keyboardSplitProvider.notifier).setSplitPoint(v.round());
                          },
                        ),
                      ),
                    ),
                    Text(
                      'C7',
                      style: TextStyle(
                        color: SynthTheme.textSecondary.withValues(alpha: 0.5),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Zone A & Zone B ──
            Row(
              children: [
                // Zone A
                Expanded(
                  child: _ZoneCard(
                    label: 'ZONE A',
                    color: SynthTheme.cyan,
                    noteRange: '24 — ${_formatNote(split.splitPoint - 1)}',
                    presetName: split.presetA.name,
                    volume: split.volumeA,
                    onVolumeChanged: (v) {
                      ref.read(keyboardSplitProvider.notifier).setVolumeA(v);
                    },
                    onPresetTap: () => _showPresetPicker(context, ref, isZoneB: false),
                  ),
                ),
                const SizedBox(width: 8),
                // Zone B
                Expanded(
                  child: _ZoneCard(
                    label: 'ZONE B',
                    color: SynthTheme.magenta,
                    noteRange: '${_formatNote(split.splitPoint)} — 108',
                    presetName: split.presetB.name,
                    volume: split.volumeB,
                    onVolumeChanged: (v) {
                      ref.read(keyboardSplitProvider.notifier).setVolumeB(v);
                    },
                    onPresetTap: () => _showPresetPicker(context, ref, isZoneB: true),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showPresetPicker(BuildContext context, WidgetRef ref,
      {required bool isZoneB}) {
    final allPresets = ref.read(presetListProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: SynthTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select preset for ${isZoneB ? 'Zone B' : 'Zone A'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  child: ListView.separated(
                    itemCount: allPresets.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: Colors.transparent),
                    itemBuilder: (_, i) {
                      final p = allPresets[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          p.name,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        subtitle: Text(
                          p.category.displayName,
                          style: TextStyle(
                            color: SynthTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        onTap: () {
                          if (isZoneB) {
                            ref.read(keyboardSplitProvider.notifier).setPresetB(p);
                          } else {
                            ref.read(keyboardSplitProvider.notifier).setPresetA(p);
                          }
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final String label;
  final Color color;
  final String noteRange;
  final String presetName;
  final double volume;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onPresetTap;

  const _ZoneCard({
    required this.label,
    required this.color,
    required this.noteRange,
    required this.presetName,
    required this.volume,
    required this.onVolumeChanged,
    required this.onPresetTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: SynthTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            noteRange,
            style: TextStyle(
              color: SynthTheme.textSecondary,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onPresetTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                presetName,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SynthKnob(
            label: 'VOL',
            value: volume,
            min: 0,
            max: 1,
            size: 40,
            formatValue: (v) => '${(v * 100).round()}%',
            onChanged: onVolumeChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }
}
