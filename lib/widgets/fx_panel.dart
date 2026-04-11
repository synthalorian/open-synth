import 'package:flutter/material.dart';
import '../models/fx_config.dart';
import '../theme/synth_theme.dart';
import 'synth_knob.dart';

class FxPanel extends StatelessWidget {
  final ChorusConfig chorus;
  final DelayConfig delay;
  final ReverbConfig reverb;
  final PhaserConfig phaser;
  final DriveConfig drive;
  final Function(ChorusConfig) onChorusChanged;
  final Function(DelayConfig) onDelayChanged;
  final Function(ReverbConfig) onReverbChanged;
  final Function(PhaserConfig) onPhaserChanged;
  final Function(DriveConfig) onDriveChanged;

  const FxPanel({
    super.key,
    required this.chorus,
    required this.delay,
    required this.reverb,
    required this.phaser,
    required this.drive,
    required this.onChorusChanged,
    required this.onDelayChanged,
    required this.onReverbChanged,
    required this.onPhaserChanged,
    required this.onDriveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drive Section
        _FxSection(
          title: 'DRIVE',
          enabled: drive.enabled,
          onToggle: (v) => onDriveChanged(drive.copyWith(enabled: v)),
          accentColor: Colors.redAccent,
          children: [
            Column(
              children: [
                DropdownButton<DriveType>(
                  value: drive.type,
                  dropdownColor: SynthTheme.surface,
                  underline: Container(),
                  style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  onChanged: (v) {
                    if (v != null) onDriveChanged(drive.copyWith(type: v));
                  },
                  items: DriveType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                ),
                const Text('TYPE', style: TextStyle(color: Colors.white24, fontSize: 8)),
              ],
            ),
            SynthKnob(
              label: 'AMOUNT',
              value: drive.amount,
              min: 0,
              max: 1,
              size: 45,
              onChanged: (v) => onDriveChanged(drive.copyWith(amount: v)),
              activeColor: Colors.redAccent,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Chorus
        _FxSection(
          title: 'CHORUS',
          enabled: chorus.enabled,
          onToggle: (v) => onChorusChanged(chorus.copyWith(enabled: v)),
          accentColor: SynthTheme.cyan,
          children: [
            SynthKnob(
              label: 'RATE',
              value: chorus.rate,
              min: 0.1,
              max: 10.0,
              size: 45,
              onChanged: (v) => onChorusChanged(chorus.copyWith(rate: v)),
              activeColor: SynthTheme.cyan,
            ),
            SynthKnob(
              label: 'DEPTH',
              value: chorus.depth,
              min: 0,
              max: 1,
              size: 45,
              onChanged: (v) => onChorusChanged(chorus.copyWith(depth: v)),
              activeColor: SynthTheme.cyan,
            ),
            SynthKnob(
              label: 'MIX',
              value: chorus.mix,
              min: 0,
              max: 1,
              size: 45,
              onChanged: (v) => onChorusChanged(chorus.copyWith(mix: v)),
              activeColor: SynthTheme.cyan,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Delay
        _FxSection(
          title: 'DELAY',
          enabled: delay.enabled,
          onToggle: (v) => onDelayChanged(delay.copyWith(enabled: v)),
          accentColor: SynthTheme.orange,
          children: [
            SynthKnob(
              label: 'TIME',
              value: delay.timeMs,
              min: 10,
              max: 1000,
              size: 45,
              formatValue: (v) => '${v.round()}ms',
              onChanged: (v) => onDelayChanged(delay.copyWith(timeMs: v)),
              activeColor: SynthTheme.orange,
            ),
            SynthKnob(
              label: 'FEEDBK',
              value: delay.feedback,
              min: 0,
              max: 0.9,
              size: 45,
              onChanged: (v) => onDelayChanged(delay.copyWith(feedback: v)),
              activeColor: SynthTheme.orange,
            ),
            SynthKnob(
              label: 'MIX',
              value: delay.mix,
              min: 0,
              max: 1,
              size: 45,
              onChanged: (v) => onDelayChanged(delay.copyWith(mix: v)),
              activeColor: SynthTheme.orange,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Reverb
        _FxSection(
          title: 'REVERB',
          enabled: reverb.enabled,
          onToggle: (v) => onReverbChanged(reverb.copyWith(enabled: v)),
          accentColor: SynthTheme.magenta,
          children: [
            SynthKnob(
              label: 'SIZE',
              value: reverb.size,
              min: 0,
              max: 1,
              size: 45,
              onChanged: (v) => onReverbChanged(reverb.copyWith(size: v)),
              activeColor: SynthTheme.magenta,
            ),
            SynthKnob(
              label: 'DAMP',
              value: reverb.damping,
              min: 0,
              max: 1,
              size: 45,
              onChanged: (v) => onReverbChanged(reverb.copyWith(damping: v)),
              activeColor: SynthTheme.magenta,
            ),
            SynthKnob(
              label: 'MIX',
              value: reverb.mix,
              min: 0,
              max: 1,
              size: 45,
              onChanged: (v) => onReverbChanged(reverb.copyWith(mix: v)),
              activeColor: SynthTheme.magenta,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Phaser
        _FxSection(
          title: 'PHASER',
          enabled: phaser.enabled,
          onToggle: (v) => onPhaserChanged(phaser.copyWith(enabled: v)),
          accentColor: SynthTheme.purple,
          children: [
            SynthKnob(
              label: 'RATE',
              value: phaser.rate,
              min: 0.1,
              max: 10.0,
              size: 45,
              onChanged: (v) => onPhaserChanged(phaser.copyWith(rate: v)),
              activeColor: SynthTheme.purple,
            ),
            SynthKnob(
              label: 'DEPTH',
              value: phaser.depth,
              min: 0,
              max: 1,
              size: 45,
              onChanged: (v) => onPhaserChanged(phaser.copyWith(depth: v)),
              activeColor: SynthTheme.purple,
            ),
            SynthKnob(
              label: 'FEEDBK',
              value: phaser.feedback,
              min: 0,
              max: 0.95,
              size: 45,
              onChanged: (v) => onPhaserChanged(phaser.copyWith(feedback: v)),
              activeColor: SynthTheme.purple,
            ),
            SynthKnob(
              label: 'MIX',
              value: phaser.mix,
              min: 0,
              max: 1,
              size: 45,
              onChanged: (v) => onPhaserChanged(phaser.copyWith(mix: v)),
              activeColor: SynthTheme.purple,
            ),
          ],
        ),
      ],
    );
  }
}

class _FxSection extends StatelessWidget {
  final String title;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final Color accentColor;
  final List<Widget> children;

  const _FxSection({
    required this.title,
    required this.enabled,
    required this.onToggle,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled ? accentColor.withValues(alpha: 0.3) : SynthTheme.purple.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => onToggle(!enabled),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: enabled ? accentColor : SynthTheme.purple.withValues(alpha: 0.3),
                    boxShadow: enabled ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                      )
                    ] : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: enabled ? accentColor : SynthTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: children,
          ),
        ],
      ),
    );
  }
}
