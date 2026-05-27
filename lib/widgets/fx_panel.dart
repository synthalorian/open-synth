import 'package:flutter/material.dart';
import '../models/fx_config.dart';
import '../painters/drive_wave_painter.dart';
import '../theme/synth_theme.dart';
import 'synth_knob.dart';

class FxPanel extends StatelessWidget {
  // ── Legacy FX ──
  final ChorusConfig chorus;
  final DelayConfig delay;
  final ReverbConfig reverb;
  final PhaserConfig phaser;
  final FlangerConfig flanger;
  final CompressorConfig compressor;
  final DriveConfig drive;
  final Function(ChorusConfig) onChorusChanged;
  final Function(DelayConfig) onDelayChanged;
  final Function(ReverbConfig) onReverbChanged;
  final Function(PhaserConfig) onPhaserChanged;
  final Function(FlangerConfig) onFlangerChanged;
  final Function(CompressorConfig) onCompressorChanged;
  final Function(DriveConfig) onDriveChanged;

  // ── New FX (Multi-Slot) ──
  final List<FxSlotConfig> slotConfigs; // slots 1-3 (slot 0 is legacy)
  final Function(int slotIndex, FxSlotConfig)? onSlotChanged;
  final EqConfig? eq;
  final Function(EqConfig)? onEqChanged;
  final LimiterConfig? limiter;
  final Function(LimiterConfig)? onLimiterChanged;
  final RotaryConfig? rotary;
  final Function(RotaryConfig)? onRotaryChanged;
  final TremoloConfig? tremolo;
  final Function(TremoloConfig)? onTremoloChanged;

  // Lock states
  final bool chorusLocked;
  final bool delayLocked;
  final bool reverbLocked;
  final bool phaserLocked;
  final bool flangerLocked;
  final bool compressorLocked;
  final bool driveLocked;

  const FxPanel({
    super.key,
    required this.chorus,
    required this.delay,
    required this.reverb,
    required this.phaser,
    required this.flanger,
    required this.compressor,
    required this.drive,
    required this.onChorusChanged,
    required this.onDelayChanged,
    required this.onReverbChanged,
    required this.onPhaserChanged,
    required this.onFlangerChanged,
    required this.onCompressorChanged,
    required this.onDriveChanged,
    this.slotConfigs = const [],
    this.onSlotChanged,
    this.eq,
    this.onEqChanged,
    this.limiter,
    this.onLimiterChanged,
    this.rotary,
    this.onRotaryChanged,
    this.tremolo,
    this.onTremoloChanged,
    this.chorusLocked = false,
    this.delayLocked = false,
    this.reverbLocked = false,
    this.phaserLocked = false,
    this.flangerLocked = false,
    this.compressorLocked = false,
    this.driveLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Legacy FX Sections ──
        _FxSection(
          title: 'DRIVE',
          enabled: drive.enabled,
          onToggle: (v) => onDriveChanged(drive.copyWith(enabled: v)),
          isLocked: driveLocked,
          accentColor: Colors.redAccent,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 28,
                  width: 64,
                  child: CustomPaint(
                    painter: DriveWavePainter(
                      driveType: drive.type,
                      amount: drive.amount,
                      enabled: drive.enabled,
                      activeColor: Colors.redAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 64,
                  child: DropdownButton<DriveType>(
                    value: drive.type,
                    dropdownColor: SynthTheme.surface,
                    underline: Container(),
                    isDense: true,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                    onChanged: (v) {
                      if (v != null) onDriveChanged(drive.copyWith(type: v));
                    },
                    items: DriveType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.name.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Text('TYPE', style: TextStyle(color: Colors.white24, fontSize: 7)),
              ],
            ),
            SynthKnob(
              label: 'AMOUNT',
              value: drive.amount,
              min: 0,
              max: 1,
              size: 40,
              onChanged: (v) => onDriveChanged(drive.copyWith(amount: v)),
              activeColor: Colors.redAccent,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _FxSection(
          title: 'CHORUS',
          enabled: chorus.enabled,
          onToggle: (v) => onChorusChanged(chorus.copyWith(enabled: v)),
          isLocked: chorusLocked,
          accentColor: SynthTheme.cyan,
          children: [
            SynthKnob(label: 'RATE', value: chorus.rate, min: 0.1, max: 10.0, size: 45,
              onChanged: (v) => onChorusChanged(chorus.copyWith(rate: v)),
              activeColor: SynthTheme.cyan),
            SynthKnob(label: 'DEPTH', value: chorus.depth, min: 0, max: 1, size: 45,
              onChanged: (v) => onChorusChanged(chorus.copyWith(depth: v)),
              activeColor: SynthTheme.cyan),
            SynthKnob(label: 'MIX', value: chorus.mix, min: 0, max: 1, size: 45,
              onChanged: (v) => onChorusChanged(chorus.copyWith(mix: v)),
              activeColor: SynthTheme.cyan),
          ],
        ),
        const SizedBox(height: 8),
        _FxSection(
          title: 'DELAY',
          enabled: delay.enabled,
          onToggle: (v) => onDelayChanged(delay.copyWith(enabled: v)),
          isLocked: delayLocked,
          accentColor: SynthTheme.orange,
          children: [
            SynthKnob(label: 'TIME', value: delay.timeMs, min: 10, max: 1000, size: 45,
              formatValue: (v) => '${v.round()}ms',
              onChanged: (v) => onDelayChanged(delay.copyWith(timeMs: v)),
              activeColor: SynthTheme.orange),
            SynthKnob(label: 'FEEDBK', value: delay.feedback, min: 0, max: 0.9, size: 45,
              onChanged: (v) => onDelayChanged(delay.copyWith(feedback: v)),
              activeColor: SynthTheme.orange),
            SynthKnob(label: 'MIX', value: delay.mix, min: 0, max: 1, size: 45,
              onChanged: (v) => onDelayChanged(delay.copyWith(mix: v)),
              activeColor: SynthTheme.orange),
          ],
        ),
        const SizedBox(height: 8),
        _FxSection(
          title: 'REVERB',
          enabled: reverb.enabled,
          onToggle: (v) => onReverbChanged(reverb.copyWith(enabled: v)),
          isLocked: reverbLocked,
          accentColor: SynthTheme.magenta,
          children: [
            SynthKnob(label: 'SIZE', value: reverb.size, min: 0, max: 1, size: 45,
              onChanged: (v) => onReverbChanged(reverb.copyWith(size: v)),
              activeColor: SynthTheme.magenta),
            SynthKnob(label: 'DAMP', value: reverb.damping, min: 0, max: 1, size: 45,
              onChanged: (v) => onReverbChanged(reverb.copyWith(damping: v)),
              activeColor: SynthTheme.magenta),
            SynthKnob(label: 'MIX', value: reverb.mix, min: 0, max: 1, size: 45,
              onChanged: (v) => onReverbChanged(reverb.copyWith(mix: v)),
              activeColor: SynthTheme.magenta),
          ],
        ),
        const SizedBox(height: 8),
        _FxSection(
          title: 'FLANGER',
          enabled: flanger.enabled,
          onToggle: (v) => onFlangerChanged(flanger.copyWith(enabled: v)),
          isLocked: flangerLocked,
          accentColor: SynthTheme.cyan,
          children: [
            SynthKnob(label: 'RATE', value: flanger.rate, min: 0.05, max: 5.0, size: 45,
              onChanged: (v) => onFlangerChanged(flanger.copyWith(rate: v)),
              activeColor: SynthTheme.cyan),
            SynthKnob(label: 'DEPTH', value: flanger.depth, min: 0, max: 1, size: 45,
              onChanged: (v) => onFlangerChanged(flanger.copyWith(depth: v)),
              activeColor: SynthTheme.cyan),
            SynthKnob(label: 'FEEDBK', value: flanger.feedback, min: 0, max: 0.95, size: 45,
              onChanged: (v) => onFlangerChanged(flanger.copyWith(feedback: v)),
              activeColor: SynthTheme.cyan),
            SynthKnob(label: 'MIX', value: flanger.mix, min: 0, max: 1, size: 45,
              onChanged: (v) => onFlangerChanged(flanger.copyWith(mix: v)),
              activeColor: SynthTheme.cyan),
          ],
        ),
        const SizedBox(height: 8),
        _FxSection(
          title: 'COMPRESSOR',
          enabled: compressor.enabled,
          onToggle: (v) => onCompressorChanged(compressor.copyWith(enabled: v)),
          isLocked: compressorLocked,
          accentColor: SynthTheme.orange,
          children: [
            SynthKnob(label: 'THRESH', value: compressor.threshold, min: 0, max: 1, size: 45,
              onChanged: (v) => onCompressorChanged(compressor.copyWith(threshold: v)),
              activeColor: SynthTheme.orange),
            SynthKnob(label: 'RATIO', value: compressor.ratio, min: 1, max: 20, size: 45,
              formatValue: (v) => '${v.round()}:1',
              onChanged: (v) => onCompressorChanged(compressor.copyWith(ratio: v)),
              activeColor: SynthTheme.orange),
            SynthKnob(label: 'ATTACK', value: compressor.attack, min: 0.1, max: 100, size: 45,
              formatValue: (v) => '${v.round()}ms',
              onChanged: (v) => onCompressorChanged(compressor.copyWith(attack: v)),
              activeColor: SynthTheme.orange),
            SynthKnob(label: 'RELEASE', value: compressor.release, min: 10, max: 500, size: 45,
              formatValue: (v) => '${v.round()}ms',
              onChanged: (v) => onCompressorChanged(compressor.copyWith(release: v)),
              activeColor: SynthTheme.orange),
            SynthKnob(label: 'MAKEUP', value: compressor.makeupGain, min: 0, max: 1, size: 45,
              onChanged: (v) => onCompressorChanged(compressor.copyWith(makeupGain: v)),
              activeColor: SynthTheme.orange),
          ],
        ),
        const SizedBox(height: 8),
        _FxSection(
          title: 'PHASER',
          enabled: phaser.enabled,
          onToggle: (v) => onPhaserChanged(phaser.copyWith(enabled: v)),
          isLocked: phaserLocked,
          accentColor: SynthTheme.purple,
          children: [
            SynthKnob(label: 'RATE', value: phaser.rate, min: 0.1, max: 10.0, size: 45,
              onChanged: (v) => onPhaserChanged(phaser.copyWith(rate: v)),
              activeColor: SynthTheme.purple),
            SynthKnob(label: 'DEPTH', value: phaser.depth, min: 0, max: 1, size: 45,
              onChanged: (v) => onPhaserChanged(phaser.copyWith(depth: v)),
              activeColor: SynthTheme.purple),
            SynthKnob(label: 'FEEDBK', value: phaser.feedback, min: 0, max: 0.95, size: 45,
              onChanged: (v) => onPhaserChanged(phaser.copyWith(feedback: v)),
              activeColor: SynthTheme.purple),
            SynthKnob(label: 'MIX', value: phaser.mix, min: 0, max: 1, size: 45,
              onChanged: (v) => onPhaserChanged(phaser.copyWith(mix: v)),
              activeColor: SynthTheme.purple),
          ],
        ),
        const SizedBox(height: 12),

        // ── Multi-Slot FX Section Divider ──
        Row(
          children: [
            Expanded(child: Divider(color: SynthTheme.purple, thickness: 0.5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'MFX SLOTS',
                style: TextStyle(
                  color: SynthTheme.magenta.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            Expanded(child: Divider(color: SynthTheme.purple, thickness: 0.5)),
          ],
        ),
        const SizedBox(height: 8),

        // ── Slot 1: EQ ──
        if (eq != null && onEqChanged != null)
          _buildEqSection(eq!, onEqChanged!),
        const SizedBox(height: 8),

        // ── Slot 2: Limiter ──
        if (limiter != null && onLimiterChanged != null)
          _buildLimiterSection(limiter!, onLimiterChanged!),
        const SizedBox(height: 8),

        // ── Slot 3: Rotary / Tremolo ──
        if (rotary != null && onRotaryChanged != null)
          _buildRotarySection(rotary!, onRotaryChanged!),
        const SizedBox(height: 8),
        if (tremolo != null && onTremoloChanged != null)
          _buildTremoloSection(tremolo!, onTremoloChanged!),
      ],
    );
  }

  // ── Slot Section Builders ──

  Widget _buildEqSection(EqConfig eq, Function(EqConfig) onChange) {
    return _FxSection(
      title: 'SLOT 1: EQ',
      enabled: eq.enabled,
      onToggle: (v) => onChange(eq.copyWith(enabled: v)),
      accentColor: SynthTheme.cyan,
      children: [
        SynthKnob(label: 'LO', value: eq.lowGain, min: -12, max: 12, size: 40,
          formatValue: (v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}dB',
          onChanged: (v) => onChange(eq.copyWith(lowGain: v)),
          activeColor: SynthTheme.cyan),
        SynthKnob(label: 'MID', value: eq.midGain, min: -12, max: 12, size: 40,
          formatValue: (v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}dB',
          onChanged: (v) => onChange(eq.copyWith(midGain: v)),
          activeColor: SynthTheme.cyan),
        SynthKnob(label: 'HI', value: eq.highGain, min: -12, max: 12, size: 40,
          formatValue: (v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}dB',
          onChanged: (v) => onChange(eq.copyWith(highGain: v)),
          activeColor: SynthTheme.cyan),
        SynthKnob(label: 'MID.F', value: eq.midFreq, min: 200, max: 5000, size: 40,
          formatValue: (v) => '${v.round()}Hz',
          onChanged: (v) => onChange(eq.copyWith(midFreq: v)),
          activeColor: SynthTheme.cyan),
        SynthKnob(label: 'MID.Q', value: eq.midQ, min: 0.1, max: 10, size: 40,
          formatValue: (v) => v.toStringAsFixed(1),
          onChanged: (v) => onChange(eq.copyWith(midQ: v)),
          activeColor: SynthTheme.cyan),
      ],
    );
  }

  Widget _buildLimiterSection(LimiterConfig limiter, Function(LimiterConfig) onChange) {
    return _FxSection(
      title: 'SLOT 2: LIMITER',
      enabled: limiter.enabled,
      onToggle: (v) => onChange(limiter.copyWith(enabled: v)),
      accentColor: Colors.amberAccent,
      children: [
        SynthKnob(label: 'THRESH', value: limiter.threshold, min: -60, max: 0, size: 40,
          formatValue: (v) => '${v.round()}dB',
          onChanged: (v) => onChange(limiter.copyWith(threshold: v)),
          activeColor: Colors.amberAccent),
        SynthKnob(label: 'ATK', value: limiter.attack, min: 0.01, max: 10, size: 40,
          formatValue: (v) => '${v.toStringAsFixed(2)}ms',
          onChanged: (v) => onChange(limiter.copyWith(attack: v)),
          activeColor: Colors.amberAccent),
        SynthKnob(label: 'REL', value: limiter.release, min: 10, max: 500, size: 40,
          formatValue: (v) => '${v.round()}ms',
          onChanged: (v) => onChange(limiter.copyWith(release: v)),
          activeColor: Colors.amberAccent),
        SynthKnob(label: 'MKG', value: limiter.makeupGain, min: 0, max: 24, size: 40,
          formatValue: (v) => '${v.round()}dB',
          onChanged: (v) => onChange(limiter.copyWith(makeupGain: v)),
          activeColor: Colors.amberAccent),
        SynthKnob(label: 'LKHD', value: limiter.lookahead, min: 0, max: 5, size: 40,
          formatValue: (v) => '${v.toStringAsFixed(1)}ms',
          onChanged: (v) => onChange(limiter.copyWith(lookahead: v)),
          activeColor: Colors.amberAccent),
      ],
    );
  }

  Widget _buildRotarySection(RotaryConfig rotary, Function(RotaryConfig) onChange) {
    return _FxSection(
      title: 'SLOT 3: ROTARY',
      enabled: rotary.enabled,
      onToggle: (v) => onChange(rotary.copyWith(enabled: v)),
      accentColor: SynthTheme.orange,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              child: DropdownButton<int>(
                value: rotary.mode,
                dropdownColor: SynthTheme.surface,
                underline: Container(),
                isDense: true,
                isExpanded: true,
                style: TextStyle(color: SynthTheme.orange, fontSize: 9, fontWeight: FontWeight.bold),
                onChanged: (v) {
                  if (v != null) onChange(rotary.copyWith(mode: v));
                },
                items: const [
                  DropdownMenuItem(value: 0, child: Text('SLOW')),
                  DropdownMenuItem(value: 1, child: Text('FAST')),
                  DropdownMenuItem(value: 2, child: Text('BRAKE')),
                ],
              ),
            ),
            const Text('MODE', style: TextStyle(color: Colors.white24, fontSize: 7)),
          ],
        ),
        SynthKnob(label: 'RATE', value: rotary.rate, min: 0.1, max: 20, size: 40,
          formatValue: (v) => '${v.toStringAsFixed(1)}Hz',
          onChanged: (v) => onChange(rotary.copyWith(rate: v)),
          activeColor: SynthTheme.orange),
        SynthKnob(label: 'DEPTH', value: rotary.depth, min: 0, max: 1, size: 40,
          onChanged: (v) => onChange(rotary.copyWith(depth: v)),
          activeColor: SynthTheme.orange),
        SynthKnob(label: 'DRIVE', value: rotary.drive, min: 0, max: 1, size: 40,
          onChanged: (v) => onChange(rotary.copyWith(drive: v)),
          activeColor: SynthTheme.orange),
        SynthKnob(label: 'MIX', value: rotary.mix, min: 0, max: 1, size: 40,
          onChanged: (v) => onChange(rotary.copyWith(mix: v)),
          activeColor: SynthTheme.orange),
      ],
    );
  }

  Widget _buildTremoloSection(TremoloConfig tremolo, Function(TremoloConfig) onChange) {
    return _FxSection(
      title: 'SLOT 3b: TREM',
      enabled: tremolo.enabled,
      onToggle: (v) => onChange(tremolo.copyWith(enabled: v)),
      accentColor: SynthTheme.purple,
      children: [
        SynthKnob(label: 'RATE', value: tremolo.rate, min: 0.1, max: 20, size: 40,
          formatValue: (v) => '${v.toStringAsFixed(1)}Hz',
          onChanged: (v) => onChange(tremolo.copyWith(rate: v)),
          activeColor: SynthTheme.purple),
        SynthKnob(label: 'DEPTH', value: tremolo.depth, min: 0, max: 1, size: 40,
          onChanged: (v) => onChange(tremolo.copyWith(depth: v)),
          activeColor: SynthTheme.purple),
        SynthKnob(label: 'SHAPE', value: tremolo.shape, min: 0, max: 1, size: 40,
          formatValue: (v) => v < 0.33 ? 'SIN' : (v < 0.66 ? 'TRI' : 'SAW'),
          onChanged: (v) => onChange(tremolo.copyWith(shape: v)),
          activeColor: SynthTheme.purple),
        SynthKnob(label: 'MIX', value: tremolo.mix, min: 0, max: 1, size: 40,
          onChanged: (v) => onChange(tremolo.copyWith(mix: v)),
          activeColor: SynthTheme.purple),
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
  final bool isLocked;

  const _FxSection({
    required this.title,
    required this.enabled,
    required this.onToggle,
    required this.accentColor,
    required this.children,
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
              if (isLocked) ...[
                const SizedBox(width: 6),
                Icon(Icons.lock, color: SynthTheme.magenta, size: 12),
              ],
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
