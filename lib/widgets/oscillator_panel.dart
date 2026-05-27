import 'package:flutter/material.dart';
import '../models/oscillator.dart';
import '../models/waveform.dart';
import '../theme/synth_theme.dart';
import 'synth_knob.dart';
import 'waveform_selector.dart';

class OscillatorPanel extends StatelessWidget {
  final String title;
  final Oscillator oscillator;
  final ValueChanged<Oscillator> onChanged;
  final bool isLocked;

  const OscillatorPanel({
    super.key,
    required this.title,
    required this.oscillator,
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
        border: Border.all(
          color: oscillator.enabled
              ? SynthTheme.magenta.withValues(alpha: 0.3)
              : SynthTheme.purple.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              GestureDetector(
                onTap: () => onChanged(
                    oscillator.copyWith(enabled: !oscillator.enabled)),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: oscillator.enabled
                        ? SynthTheme.magenta
                        : SynthTheme.purple.withValues(alpha: 0.3),
                    boxShadow: oscillator.enabled
                        ? [
                            BoxShadow(
                              color: SynthTheme.magenta.withValues(alpha: 0.5),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: oscillator.enabled ? SynthTheme.magenta : SynthTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              if (isLocked) ...[
                const SizedBox(width: 6),
                Icon(Icons.lock, color: SynthTheme.magenta, size: 12),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Waveform selector
          Center(
            child: WaveformSelector(
              selected: oscillator.waveform,
              onChanged: (wf) =>
                  onChanged(oscillator.copyWith(waveform: wf)),
            ),
          ),
          const SizedBox(height: 8),

          // Knobs row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Octave
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _OctaveButton(
                        icon: Icons.remove,
                        onTap: oscillator.octave > -2
                            ? () => onChanged(
                                oscillator.copyWith(octave: oscillator.octave - 1))
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${oscillator.octave >= 0 ? "+" : ""}${oscillator.octave}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _OctaveButton(
                        icon: Icons.add,
                        onTap: oscillator.octave < 2
                            ? () => onChanged(
                                oscillator.copyWith(octave: oscillator.octave + 1))
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'OCTAVE',
                    style: TextStyle(
                      color: SynthTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SynthKnob(
                label: 'DETUNE',
                value: oscillator.detune,
                min: -100,
                max: 100,
                size: 50,
                formatValue: (v) => '${v.round()}c',
                onChanged: (v) =>
                    onChanged(oscillator.copyWith(detune: v)),
                activeColor: SynthTheme.orange,
              ),
              SynthKnob(
                label: 'PW',
                value: oscillator.pulseWidth,
                min: 0.05,
                max: 0.95,
                size: 50,
                formatValue: (v) => '${(v * 100).round()}%',
                onChanged: (v) =>
                    onChanged(oscillator.copyWith(pulseWidth: v)),
                activeColor: SynthTheme.purple,
              ),
              SynthKnob(
                label: 'VOL',
                value: oscillator.volume,
                min: 0,
                max: 1,
                size: 50,
                formatValue: (v) => '${(v * 100).round()}',
                onChanged: (v) =>
                    onChanged(oscillator.copyWith(volume: v)),
                activeColor: SynthTheme.cyan,
              ),
              if (oscillator.waveform == Waveform.wavetable)
                SynthKnob(
                  label: 'WT POS',
                  value: oscillator.wavetablePosition,
                  min: 0,
                  max: 1,
                  size: 50,
                  formatValue: (v) => '${(v * 100).round()}%',
                  onChanged: (v) =>
                      onChanged(oscillator.copyWith(wavetablePosition: v)),
                  activeColor: SynthTheme.purple,
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Unison section ──
          if (oscillator.unisonVoiceCount > 1)
            _buildUnisonSection(),
        ],
      ),
    );
  }

  Widget _buildUnisonSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: SynthTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: SynthTheme.cyan.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers, color: SynthTheme.cyan, size: 12),
              const SizedBox(width: 4),
              Text(
                'UNISON',
                style: TextStyle(
                  color: SynthTheme.cyan,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              // Voice count selector
              _buildUnisonVoiceSelector(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SynthKnob(
                label: 'SPREAD',
                value: oscillator.unisonDetuneSpread,
                min: 0,
                max: 50,
                size: 40,
                formatValue: (v) => '${v.round()}c',
                onChanged: (v) => onChanged(
                  oscillator.copyWith(unisonDetuneSpread: v),
                ),
                activeColor: SynthTheme.cyan,
              ),
              SynthKnob(
                label: 'STEREO',
                value: oscillator.unisonStereoSpread,
                min: 0,
                max: 1,
                size: 40,
                formatValue: (v) => '${(v * 100).round()}%',
                onChanged: (v) => onChanged(
                  oscillator.copyWith(unisonStereoSpread: v),
                ),
                activeColor: SynthTheme.purple,
              ),
              SynthKnob(
                label: 'MIX',
                value: oscillator.unisonMix,
                min: 0,
                max: 1,
                size: 40,
                formatValue: (v) => '${(v * 100).round()}%',
                onChanged: (v) => onChanged(
                  oscillator.copyWith(unisonMix: v),
                ),
                activeColor: SynthTheme.magenta,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnisonVoiceSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _UnisonChip(
          label: '1',
          selected: oscillator.unisonVoiceCount == 1,
          onTap: () => onChanged(
            oscillator.copyWith(unisonVoiceCount: 1),
          ),
        ),
        _UnisonChip(
          label: '2',
          selected: oscillator.unisonVoiceCount == 2,
          onTap: () => onChanged(
            oscillator.copyWith(unisonVoiceCount: 2),
          ),
        ),
        _UnisonChip(
          label: '4',
          selected: oscillator.unisonVoiceCount == 4,
          onTap: () => onChanged(
            oscillator.copyWith(unisonVoiceCount: 4),
          ),
        ),
        _UnisonChip(
          label: '8',
          selected: oscillator.unisonVoiceCount == 8,
          onTap: () => onChanged(
            oscillator.copyWith(unisonVoiceCount: 8),
          ),
        ),
      ],
    );
  }
}

class _UnisonChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnisonChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 26,
        height: 22,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          color: selected
              ? SynthTheme.cyan.withValues(alpha: 0.25)
              : SynthTheme.surface,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: selected
                ? SynthTheme.cyan
                : SynthTheme.purple.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? SynthTheme.cyan : SynthTheme.textSecondary,
            fontSize: 10,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _OctaveButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _OctaveButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: SynthTheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: onTap != null
                ? SynthTheme.purple.withValues(alpha: 0.5)
                : SynthTheme.purple.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap != null ? Colors.white : SynthTheme.textSecondary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
