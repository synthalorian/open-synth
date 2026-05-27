import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/keyboard_split.dart';
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
          // ── Header + Mode Toggle ──
          Row(
            children: [
              Text(
                'KEYBOARD',
                style: TextStyle(
                  color: split.enabled ? SynthTheme.cyan : SynthTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              _ModeBtn(
                label: 'NORM',
                active: split.mode == SplitMode.normal,
                onTap: () => ref.read(keyboardSplitProvider.notifier).setMode(SplitMode.normal),
              ),
              const SizedBox(width: 4),
              _ModeBtn(
                label: 'SPLIT',
                active: split.mode == SplitMode.split,
                onTap: () => ref.read(keyboardSplitProvider.notifier).setMode(SplitMode.split),
              ),
              const SizedBox(width: 4),
              _ModeBtn(
                label: 'LAYER',
                active: split.mode == SplitMode.layer,
                onTap: () => ref.read(keyboardSplitProvider.notifier).setMode(SplitMode.layer),
              ),
            ],
          ),

          if (split.mode != SplitMode.normal) ...[
            const SizedBox(height: 10),

            // ── Split Point Slider (only in split mode) ──
            if (split.mode == SplitMode.split)
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
                  // Crossfade width
                  Row(
                    children: [
                      Text(
                        'XFADE',
                        style: TextStyle(
                          color: SynthTheme.textSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: SynthTheme.orange,
                            inactiveTrackColor: SynthTheme.purple.withValues(alpha: 0.15),
                            thumbColor: SynthTheme.orange,
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: split.crossfadeWidth.toDouble(),
                            min: 0,
                            max: 12,
                            divisions: 12,
                            onChanged: (v) {
                              ref.read(keyboardSplitProvider.notifier).setCrossfadeWidth(v.round());
                            },
                          ),
                        ),
                      ),
                      Text(
                        '${split.crossfadeWidth}s',
                        style: TextStyle(
                          color: SynthTheme.orange,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 10),

            // ── Zone A & Zone B ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Zone A
                Expanded(
                  child: _ZoneCard(
                    label: 'ZONE A',
                    color: SynthTheme.cyan,
                    noteRange: split.mode == SplitMode.split
                        ? '24 — ${_formatNote(split.splitPoint - 1)}'
                        : 'FULL RANGE',
                    presetName: split.presetA.name,
                    volume: split.volumeA,
                    octaveShift: split.octaveShiftA,
                    onVolumeChanged: (v) {
                      ref.read(keyboardSplitProvider.notifier).setVolumeA(v);
                    },
                    onOctaveShift: (delta) {
                      ref.read(keyboardSplitProvider.notifier).setOctaveShiftA(
                        split.octaveShiftA + delta,
                      );
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
                    noteRange: split.mode == SplitMode.split
                        ? '${_formatNote(split.splitPoint)} — 108'
                        : 'FULL RANGE',
                    presetName: split.presetB.name,
                    volume: split.volumeB,
                    octaveShift: split.octaveShiftB,
                    onVolumeChanged: (v) {
                      ref.read(keyboardSplitProvider.notifier).setVolumeB(v);
                    },
                    onOctaveShift: (delta) {
                      ref.read(keyboardSplitProvider.notifier).setOctaveShiftB(
                        split.octaveShiftB + delta,
                      );
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

class _OctaveBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _OctaveBtn({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(
          icon,
          size: 10,
          color: color,
        ),
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? SynthTheme.cyan.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active ? SynthTheme.cyan.withValues(alpha: 0.5) : SynthTheme.purple.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? SynthTheme.cyan : SynthTheme.textSecondary,
            fontSize: 9,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final String label;
  final Color color;
  final String noteRange;
  final String presetName;
  final double volume;
  final int octaveShift;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<int> onOctaveShift;
  final VoidCallback onPresetTap;

  const _ZoneCard({
    required this.label,
    required this.color,
    required this.noteRange,
    required this.presetName,
    required this.volume,
    this.octaveShift = 0,
    required this.onVolumeChanged,
    required this.onOctaveShift,
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
          Row(
            children: [
              Expanded(
                child: SynthKnob(
                  label: 'VOL',
                  value: volume,
                  min: 0,
                  max: 1,
                  size: 40,
                  formatValue: (v) => '${(v * 100).round()}%',
                  onChanged: onVolumeChanged,
                  activeColor: color,
                ),
              ),
              const SizedBox(width: 4),
              Column(
                children: [
                  Text(
                    'OCT',
                    style: TextStyle(
                      color: SynthTheme.textSecondary,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _OctaveBtn(
                        icon: Icons.remove,
                        onTap: () => onOctaveShift(-1),
                        color: color,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        octaveShift >= 0 ? '+$octaveShift' : '$octaveShift',
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      _OctaveBtn(
                        icon: Icons.add,
                        onTap: () => onOctaveShift(1),
                        color: color,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
