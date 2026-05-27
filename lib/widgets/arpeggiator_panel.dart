import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/arpeggiator_config.dart';
import '../providers/arpeggiator_provider.dart';
import '../providers/clock_provider.dart';
import '../theme/synth_theme.dart';
import 'synth_knob.dart';

class ArpeggiatorPanel extends ConsumerWidget {
  const ArpeggiatorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(arpeggiatorConfigProvider);
    final notifier = ref.read(arpeggiatorConfigProvider.notifier);
    final currentStep = ref.watch(arpStepProvider);
    final totalSteps = ref.watch(arpTotalStepsProvider);
    final clockMode = ref.watch(clockModeProvider);
    final clockBpm = ref.watch(clockBpmProvider);
    final bpm = clockMode != ClockMode.off ? clockBpm.round() : 120;

    return Container(
      padding: const EdgeInsets.all(12),
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
          // ── Header row ──
          _HeaderRow(
            enabled: config.enabled,
            bpm: bpm,
            pattern: config.pattern,
            onToggle: () =>
                notifier.update((c) => c.copyWith(enabled: !c.enabled)),
            onRandomize: () => _randomizePattern(notifier),
          ),
          const SizedBox(height: 10),

          // ── Step LED indicator ──
          if (config.enabled && config.pattern != ArpPattern.off)
            _StepLedRow(
              currentStep: currentStep,
              totalSteps: totalSteps > 0 ? totalSteps : 8,
            ),
          if (config.enabled && config.pattern != ArpPattern.off)
            const SizedBox(height: 10),

          // ── Pattern selector ──
          _PatternSelector(
            selected: config.pattern,
            onChanged: (p) =>
                notifier.update((c) => c.copyWith(pattern: p)),
            enabled: config.enabled,
          ),
          const SizedBox(height: 10),

          // ── Rate + Octave + Swing row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RateDropdown(
                selected: config.rate,
                onChanged: (r) =>
                    notifier.update((c) => c.copyWith(rate: r)),
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
              SynthKnob(
                label: 'SWING',
                value: config.swing,
                min: 0,
                max: 1,
                size: 50,
                formatValue: (v) => '${(v * 100).round()}%',
                onChanged: (v) => notifier.update(
                  (c) => c.copyWith(swing: v),
                ),
                activeColor: SynthTheme.cyan,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Controls sub-section ──
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
                      label: 'HOLD',
                      isOn: config.hold,
                      onTap: () => notifier.update(
                        (c) => c.copyWith(hold: !c.hold),
                      ),
                      enabled: config.enabled,
                      activeColor: SynthTheme.magenta,
                    ),
                    const SizedBox(width: 8),
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
      swing: rng.nextDouble() * 0.6,
      seed: rng.nextInt(10000),
    ));
  }
}

// ── Header with toggle, BPM display, and randomize ──

class _HeaderRow extends StatelessWidget {
  final bool enabled;
  final int bpm;
  final ArpPattern pattern;
  final VoidCallback onToggle;
  final VoidCallback onRandomize;

  const _HeaderRow({
    required this.enabled,
    required this.bpm,
    required this.pattern,
    required this.onToggle,
    required this.onRandomize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Enable toggle LED
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? SynthTheme.orange
                  : SynthTheme.purple.withValues(alpha: 0.3),
              boxShadow: enabled
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
            color: enabled ? SynthTheme.orange : SynthTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),

        // BPM display (hardware LCD feel)
        if (enabled && pattern != ArpPattern.off) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0118),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: SynthTheme.cyan.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$bpm',
                  style: TextStyle(
                    color: SynthTheme.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  'BPM',
                  style: TextStyle(
                    color: SynthTheme.cyan.withValues(alpha: 0.6),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),
        _SmallBtn(
          label: 'Randomize',
          onTap: onRandomize,
          enabled: enabled,
        ),
      ],
    );
  }
}

// ── Step LED indicator row ──

class _StepLedRow extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepLedRow({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    // Cap display at 32 LEDs max — for huge octave ranges we compress
    final displaySteps = totalSteps.clamp(4, 32);
    final stepRatio = totalSteps > 0 ? currentStep / totalSteps : 0.0;
    final displayStep = (stepRatio * displaySteps).round().clamp(0, displaySteps - 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0118),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: SynthTheme.orange.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(displaySteps, (i) {
          final isActive = i == displayStep;
          // Beat markers: every 4th step gets a brighter base
          final isBeatMarker = i % 4 == 0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            width: displaySteps > 16 ? 5 : 8,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive
                  ? SynthTheme.orange
                  : isBeatMarker
                      ? SynthTheme.orange.withValues(alpha: 0.15)
                      : SynthTheme.purple.withValues(alpha: 0.1),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: SynthTheme.orange.withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

// ── Pattern selector ──

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

// ── Rate dropdown ──

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

// ── Small button ──

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

// ── Toggle button ──

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool isOn;
  final VoidCallback onTap;
  final bool enabled;
  final Color? activeColor;

  const _ToggleBtn({
    required this.label,
    required this.isOn,
    required this.onTap,
    required this.enabled,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? SynthTheme.orange;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isOn
              ? color.withValues(alpha: 0.25)
              : SynthTheme.surface,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isOn
                ? color
                : SynthTheme.purple.withValues(alpha: 0.3),
            width: isOn ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isOn
                ? color
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
