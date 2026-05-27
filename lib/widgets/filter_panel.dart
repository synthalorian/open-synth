import 'package:flutter/material.dart';
import '../models/filter_config.dart';
import '../models/mod_target.dart';
import '../theme/synth_theme.dart';
import 'synth_knob.dart';

class FilterPanel extends StatelessWidget {
  final FilterConfig filter;
  final ValueChanged<FilterConfig> onChanged;
  final bool isLocked;

  const FilterPanel({
    super.key,
    required this.filter,
    required this.onChanged,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SynthTheme.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filter type selector
          Row(
            children: [
              Text(
                'FILTER',
                style: TextStyle(
                  color: SynthTheme.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              if (isLocked) ...[
                const SizedBox(width: 6),
                Icon(Icons.lock, color: SynthTheme.magenta, size: 12),
              ],
              const Spacer(),
              ...FilterType.values.map((ft) {
                final isSelected = ft == filter.type;
                return GestureDetector(
                  onTap: () => onChanged(filter.copyWith(type: ft)),
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SynthTheme.cyan.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? SynthTheme.cyan
                            : SynthTheme.purple.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      ft.displayName.split(' ').first.substring(0, 2).toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? SynthTheme.cyan : SynthTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),

          // Knobs: Cutoff (big center), Resonance, Env Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SynthKnob(
                label: 'RESO',
                value: filter.resonance,
                min: 0,
                max: 1,
                size: 50,
                formatValue: (v) => '${(v * 100).round()}',
                onChanged: (v) => onChanged(filter.copyWith(resonance: v)),
                activeColor: SynthTheme.purple,
              ),
              SynthKnob(
                label: 'CUTOFF',
                value: filter.cutoff,
                min: 20,
                max: 20000,
                size: 70,
                formatValue: (v) => v >= 1000
                    ? '${(v / 1000).toStringAsFixed(1)}k'
                    : '${v.round()}',
                onChanged: (v) => onChanged(filter.copyWith(cutoff: v)),
                activeColor: SynthTheme.cyan,
              ),
              SynthKnob(
                label: 'ENV',
                value: filter.envelopeAmount,
                min: -1,
                max: 1,
                size: 50,
                formatValue: (v) => '${(v * 100).round()}',
                onChanged: (v) =>
                    onChanged(filter.copyWith(envelopeAmount: v)),
                activeColor: SynthTheme.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
