import 'package:flutter/material.dart';
import '../models/lfo_config.dart';
import '../models/mod_target.dart';
import '../theme/synth_theme.dart';
import 'synth_knob.dart';
import 'waveform_selector.dart';

class LfoPanel extends StatelessWidget {
  final String title;
  final LfoConfig lfo;
  final ValueChanged<LfoConfig> onChanged;
  final Color? accentColor;
  final bool isLocked;

  const LfoPanel({
    super.key,
    required this.title,
    required this.lfo,
    required this.onChanged,
    this.accentColor,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? SynthTheme.purple;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with target selector
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: SynthTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<LfoTarget>(
                    value: lfo.target,
                    isDense: true,
                    dropdownColor: SynthTheme.card,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    iconSize: 14,
                    iconEnabledColor: color,
                    items: LfoTarget.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.displayName),
                            ))
                        .toList(),
                    onChanged: (t) {
                      if (t != null) onChanged(lfo.copyWith(target: t));
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Waveform selector
          Center(
            child: WaveformSelector(
              selected: lfo.waveform,
              onChanged: (wf) => onChanged(lfo.copyWith(waveform: wf)),
            ),
          ),
          const SizedBox(height: 8),

          // Knobs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SynthKnob(
                label: 'RATE',
                value: lfo.rate,
                min: 0.1,
                max: 20,
                size: 50,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => onChanged(lfo.copyWith(rate: v)),
                activeColor: color,
              ),
              SynthKnob(
                label: 'DEPTH',
                value: lfo.depth,
                min: 0,
                max: 1,
                size: 50,
                formatValue: (v) => '${(v * 100).round()}',
                onChanged: (v) => onChanged(lfo.copyWith(depth: v)),
                activeColor: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
