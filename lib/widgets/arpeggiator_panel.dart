import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/arpeggiator_config.dart';
import '../providers/arpeggiator_provider.dart';
import '../theme/synth_theme.dart';
import 'synth_knob.dart';

class ArpeggiatorPanel extends ConsumerWidget {
  const ArpeggiatorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(arpeggiatorConfigProvider);
    final notifier = ref.read(arpeggiatorConfigProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: config.enabled
              ? SynthTheme.orange.withValues(alpha: 0.4)
              : SynthTheme.purple.withValues(alpha: 0.15),
        ),
        gradient: config.enabled
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
          // Header with enable toggle
          Row(
            children: [
              GestureDetector(
                onTap: () => notifier.update((c) => c.copyWith(enabled: !c.enabled)),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: config.enabled
                        ? SynthTheme.orange
                        : SynthTheme.purple.withValues(alpha: 0.3),
                    boxShadow: config.enabled
                        ? [
                            BoxShadow(
                              color: SynthTheme.orange.withValues(alpha: 0.5),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ARPEGGIATOR',
                style: TextStyle(
                  color: config.enabled ? SynthTheme.orange : SynthTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              _SmallBtn(
                label: 'Randomize',
                onTap: () => _randomizePattern(notifier),
                enabled: config.enabled,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pattern selector
          Row(
            children: [
              Expanded(
                child: _PatternSelector(
                  selected: config.pattern,
                  onChanged: (p) => notifier.update((c) => c.copyWith(pattern: p)),
                  enabled: config.enabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Rate + Octave knobs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RateDropdown(
                selected: config.rate,
                onChanged: (r) => notifier.update((c) => c.copyWith(rate: r)),
                enabled: config.enabled,
              ),
              SynthKnob(
                label: 'OCTAVES',
                value: config.octaveRange.toDouble(),
                min: 1,
                max: 4,
                size: 50,
                formatValue: (v) => '${v.round()}',
                onChanged: (v) => notifier.update(
                  (c) => c.copyWith(octaveRange: v.round()),
                ),
                activeColor: SynthTheme.orange,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Randomization controls
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SynthTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: config.enabled
                    ? SynthTheme.orange.withValues(alpha: 0.2)
                    : SynthTheme.purple.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SynthKnob(
                      label: 'GATE VAR',
                      value: config.gateVariation,
                      min: 0,
                      max: 1,
                      size: 46,
                      formatValue: (v) => '${(v * 100).round()}',
                      onChanged: (v) => notifier.update(
                        (c) => c.copyWith(gateVariation: v),
                      ),
                      activeColor: SynthTheme.orange,
                    ),
                    SynthKnob(
                      label: 'SKIP %',
                      value: config.probSkip,
                      min: 0,
                      max: 1,
                      size: 46,
                      formatValue: (v) => '${(v * 100).round()}',
                      onChanged: (v) => notifier.update(
                        (c) => c.copyWith(probSkip: v),
                      ),
                      activeColor: SynthTheme.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ToggleBtn(
                      label: 'OCT JUMP',
                      isOn: config.octaveJump,
                      onTap: () => notifier.update(
                        (c) => c.copyWith(octaveJump: !c.octaveJump),
                      ),
                      enabled: config.enabled,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _randomizePattern(ArpeggiatorConfigNotifier notifier) {
    final rng = Random();
    notifier.update((c) => c.copyWith(
      pattern: ArpPattern.values[rng.nextInt(ArpPattern.values.length - 1) + 1],
      rate: ArpRate.values[rng.nextInt(ArpRate.values.length)],
      octaveRange: rng.nextInt(4) + 1,
      gateVariation: rng.nextDouble() * 0.8,
      probSkip: rng.nextDouble() * 0.5,
      octaveJump: rng.nextBool(),
      seed: rng.nextInt(10000),
    ));
  }
}

class _PatternSelector extends StatelessWidget {
  final ArpPattern selected;
  final ValueChanged<ArpPattern> onChanged;
  final bool enabled;

  const _PatternSelector({
    required this.selected,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: ArpPattern.values.map((pattern) {
        final isSelected = pattern == selected;
        return GestureDetector(
          onTap: enabled ? () => onChanged(pattern) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? SynthTheme.orange.withValues(alpha: 0.2)
                  : SynthTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? SynthTheme.orange
                    : SynthTheme.purple.withValues(alpha: 0.3),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              pattern.displayName,
              style: TextStyle(
                color: isSelected
                    ? SynthTheme.orange
                    : enabled
                        ? SynthTheme.textSecondary
                        : SynthTheme.textSecondary.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RateDropdown extends StatelessWidget {
  final ArpRate selected;
  final ValueChanged<ArpRate> onChanged;
  final bool enabled;

  const _RateDropdown({
    required this.selected,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: SynthTheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: enabled
                  ? SynthTheme.orange.withValues(alpha: 0.3)
                  : SynthTheme.purple.withValues(alpha: 0.15),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ArpRate>(
              value: selected,
              isDense: true,
              dropdownColor: SynthTheme.card,
              style: TextStyle(
                color: enabled ? SynthTheme.orange : SynthTheme.textSecondary.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              iconSize: 14,
              iconEnabledColor: enabled ? SynthTheme.orange : SynthTheme.textSecondary.withValues(alpha: 0.4),
              items: ArpRate.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.displayName),
                      ))
                  .toList(),
              onChanged: enabled ? (r) => onChanged(r!) : null,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'RATE',
          style: TextStyle(
            color: SynthTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _SmallBtn({
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: enabled ? SynthTheme.surface : SynthTheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: enabled
                ? SynthTheme.orange.withValues(alpha: 0.3)
                : SynthTheme.purple.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? SynthTheme.orange : SynthTheme.textSecondary.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool isOn;
  final VoidCallback onTap;
  final bool enabled;

  const _ToggleBtn({
    required this.label,
    required this.isOn,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isOn
              ? SynthTheme.orange.withValues(alpha: 0.25)
              : SynthTheme.surface,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isOn
                ? SynthTheme.orange
                : SynthTheme.purple.withValues(alpha: 0.3),
            width: isOn ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isOn
                ? SynthTheme.orange
                : enabled
                    ? SynthTheme.textSecondary
                    : SynthTheme.textSecondary.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: isOn ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
