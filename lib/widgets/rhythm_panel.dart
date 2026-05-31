import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/rhythm_pattern.dart';
import '../providers/rhythm_provider.dart';
import '../theme/synth_theme.dart';
import 'synth_knob.dart';

/// Rhythm pattern player panel with transport, pattern browser, and step indicator.
class RhythmPanel extends ConsumerWidget {
  const RhythmPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rhythm = ref.watch(rhythmProvider);
    final notifier = ref.read(rhythmProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SynthTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SynthTheme.magenta.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Icon(
                Icons.music_note,
                color: SynthTheme.magenta,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'RHYTHM PLAYER',
                style: TextStyle(
                  color: SynthTheme.magenta,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              // Play/Stop button
              _TransportButton(
                isPlaying: rhythm.isPlaying,
                onTap: notifier.toggle,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Pattern Selector ──
          _PatternSelector(
            currentIndex: rhythm.patternIndex,
            onSelect: notifier.setPattern,
          ),
          const SizedBox(height: 16),

          // ── Controls row ──
          Row(
            children: [
              // Tempo knob
              Expanded(
                child: SynthKnob(
                  label: 'TEMPO',
                  value: rhythm.tempo,
                  min: 20,
                  max: 300,
                  size: 48,
                  onChanged: notifier.setTempo,
                ),
              ),
              const SizedBox(width: 16),
              // Volume knob
              Expanded(
                child: SynthKnob(
                  label: 'VOLUME',
                  value: rhythm.volume,
                  min: 0,
                  max: 1,
                  size: 48,
                  onChanged: notifier.setVolume,
                ),
              ),
              const SizedBox(width: 16),
              // Variation selector
              Expanded(
                child: _VariationSelector(
                  variation: rhythm.variation,
                  onChange: notifier.setVariation,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Step indicator ──
          _StepIndicator(
            currentStep: rhythm.currentStep,
            totalSteps: rhythm.totalSteps,
            isPlaying: rhythm.isPlaying,
          ),
          const SizedBox(height: 8),

          // ── Song mode toggle ──
          Row(
            children: [
              _SongModeToggle(
                enabled: rhythm.songMode,
                onToggle: notifier.setSongMode,
              ),
              const Spacer(),
              Text(
                '${kRhythmPatterns[rhythm.patternIndex].name} • ${rhythm.tempo.toStringAsFixed(0)} BPM',
                style: TextStyle(
                  color: SynthTheme.cyan.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Transport Button ──────────────────────────────────────────────────────────

class _TransportButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _TransportButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPlaying
              ? SynthTheme.magenta.withValues(alpha: 0.3)
              : SynthTheme.cyan.withValues(alpha: 0.2),
          border: Border.all(
            color: isPlaying ? SynthTheme.magenta : SynthTheme.cyan,
            width: 2,
          ),
          boxShadow: isPlaying
              ? [
                  BoxShadow(
                    color: SynthTheme.magenta.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          isPlaying ? Icons.stop : Icons.play_arrow,
          color: isPlaying ? SynthTheme.magenta : SynthTheme.cyan,
          size: 28,
        ),
      ),
    );
  }
}

// ── Pattern Selector ──────────────────────────────────────────────────────────

class _PatternSelector extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _PatternSelector({required this.currentIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PATTERN',
          style: TextStyle(
            color: SynthTheme.cyan.withValues(alpha: 0.6),
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: kRhythmPatterns.length,
            itemBuilder: (context, index) {
              final pattern = kRhythmPatterns[index];
              final isSelected = index == currentIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelect(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SynthTheme.magenta.withValues(alpha: 0.2)
                          : SynthTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? SynthTheme.magenta
                            : SynthTheme.cyan.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      pattern.name,
                      style: TextStyle(
                        color: isSelected ? SynthTheme.magenta : SynthTheme.cyan,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Variation Selector ────────────────────────────────────────────────────────

class _VariationSelector extends StatelessWidget {
  final PatternVariation variation;
  final ValueChanged<PatternVariation> onChange;

  const _VariationSelector({required this.variation, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'VARIATION',
          style: TextStyle(
            color: SynthTheme.cyan.withValues(alpha: 0.6),
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: SynthTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: SynthTheme.cyan.withValues(alpha: 0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PatternVariation>(
              value: variation,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: SynthTheme.cyan,
                size: 18,
              ),
              dropdownColor: SynthTheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              items: PatternVariation.values.map((v) {
                return DropdownMenuItem(
                  value: v,
                  child: Text(
                    v.displayName,
                    style: TextStyle(
                      color: SynthTheme.cyan,
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) onChange(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step Indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isPlaying;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = index == currentStep && isPlaying;
          final isBeat = index % 4 == 0;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? SynthTheme.magenta
                    : isBeat
                        ? SynthTheme.cyan.withValues(alpha: 0.4)
                        : SynthTheme.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: SynthTheme.magenta.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Song Mode Toggle ──────────────────────────────────────────────────────────

class _SongModeToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const _SongModeToggle({required this.enabled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!enabled),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: enabled
                  ? SynthTheme.magenta.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
              border: Border.all(
                color: enabled ? SynthTheme.magenta : SynthTheme.cyan.withValues(alpha: 0.3),
              ),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled ? SynthTheme.magenta : SynthTheme.cyan,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'SONG MODE',
            style: TextStyle(
              color: enabled ? SynthTheme.magenta : SynthTheme.cyan.withValues(alpha: 0.6),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
