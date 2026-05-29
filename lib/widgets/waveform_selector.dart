import 'package:flutter/material.dart';
import '../models/waveform.dart';
import '../painters/waveform_icon_painter.dart';
import '../theme/synth_theme.dart';

class WaveformSelector extends StatelessWidget {
  final Waveform selected;
  final ValueChanged<Waveform> onChanged;

  const WaveformSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: Waveform.values.map((wf) {
        final isSelected = wf == selected;
        return GestureDetector(
          onTap: () => onChanged(wf),
          child: Tooltip(
            message: wf.displayName,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? SynthTheme.magenta.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? SynthTheme.magenta
                      : SynthTheme.purple.withValues(alpha: 0.3),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: SizedBox(
                width: 28,
                height: 18,
                child: CustomPaint(
                  painter: WaveformIconPainter(
                    type: wf.name,
                    color: isSelected ? SynthTheme.magenta : SynthTheme.textSecondary,
                    strokeWidth: isSelected ? 2.0 : 1.5,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
      ),
    );
  }
}
