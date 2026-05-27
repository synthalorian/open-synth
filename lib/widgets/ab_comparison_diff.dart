import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/synth_preset.dart';
import '../providers/ab_comparison_provider.dart';
import '../theme/synth_theme.dart';

/// Shows a visual diff of parameters that changed between A/B snapshots.
class ABComparisonDiff extends ConsumerWidget {
  const ABComparisonDiff({super.key});

  /// Format a timestamp as HH:MM.
  static String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Compute which top-level preset fields differ between two snapshots.
  static List<_DiffEntry> _computeDiff(SynthPreset a, SynthPreset b) {
    final entries = <_DiffEntry>[];

    void add(String label, String valA, String valB, [Color? accent]) {
      if (valA != valB) {
        entries.add(_DiffEntry(label: label, valueA: valA, valueB: valB, accentColor: accent));
      }
    }

    // Oscillators
    add('OSC1 Wave', a.osc1.waveform.displayName, b.osc1.waveform.displayName);
    add('OSC1 Octave', a.osc1.octave.toString(), b.osc1.octave.toString());
    add('OSC1 Detune', a.osc1.detune.toStringAsFixed(1), b.osc1.detune.toStringAsFixed(1));
    add('OSC1 Volume', '${(a.osc1.volume * 100).round()}%', '${(b.osc1.volume * 100).round()}%');
    add('OSC1 Enabled', a.osc1.enabled ? 'ON' : 'OFF', b.osc1.enabled ? 'ON' : 'OFF');

    add('OSC2 Wave', a.osc2.waveform.displayName, b.osc2.waveform.displayName);
    add('OSC2 Octave', a.osc2.octave.toString(), b.osc2.octave.toString());
    add('OSC2 Detune', a.osc2.detune.toStringAsFixed(1), b.osc2.detune.toStringAsFixed(1));
    add('OSC2 Volume', '${(a.osc2.volume * 100).round()}%', '${(b.osc2.volume * 100).round()}%');
    add('OSC2 Enabled', a.osc2.enabled ? 'ON' : 'OFF', b.osc2.enabled ? 'ON' : 'OFF');

    // Filter
    add('Filter Type', a.filter.type.displayName, b.filter.type.displayName, SynthTheme.orange);
    add('Cutoff', '${a.filter.cutoff.toStringAsFixed(0)} Hz', '${b.filter.cutoff.toStringAsFixed(0)} Hz', SynthTheme.orange);
    add('Resonance', '${(a.filter.resonance * 100).round()}%', '${(b.filter.resonance * 100).round()}%', SynthTheme.orange);
    add('Flt Env Amt', '${(a.filter.envelopeAmount * 100).round()}%', '${(b.filter.envelopeAmount * 100).round()}%', SynthTheme.orange);

    // Envelopes
    void addEnv(String prefix, String field, String va, String vb) {
      add('$prefix $field', va, vb, SynthTheme.magenta);
    }

    addEnv('Amp', 'Attack', '${a.ampEnvelope.attack.toStringAsFixed(0)}ms', '${b.ampEnvelope.attack.toStringAsFixed(0)}ms');
    addEnv('Amp', 'Decay', '${a.ampEnvelope.decay.toStringAsFixed(0)}ms', '${b.ampEnvelope.decay.toStringAsFixed(0)}ms');
    addEnv('Amp', 'Sustain', '${(a.ampEnvelope.sustain * 100).round()}%', '${(b.ampEnvelope.sustain * 100).round()}%');
    addEnv('Amp', 'Release', '${a.ampEnvelope.release.toStringAsFixed(0)}ms', '${b.ampEnvelope.release.toStringAsFixed(0)}ms');

    addEnv('Filter', 'Attack', '${a.filterEnvelope.attack.toStringAsFixed(0)}ms', '${b.filterEnvelope.attack.toStringAsFixed(0)}ms');
    addEnv('Filter', 'Decay', '${a.filterEnvelope.decay.toStringAsFixed(0)}ms', '${b.filterEnvelope.decay.toStringAsFixed(0)}ms');
    addEnv('Filter', 'Sustain', '${(a.filterEnvelope.sustain * 100).round()}%', '${(b.filterEnvelope.sustain * 100).round()}%');
    addEnv('Filter', 'Release', '${a.filterEnvelope.release.toStringAsFixed(0)}ms', '${b.filterEnvelope.release.toStringAsFixed(0)}ms');

    // LFOs
    add('LFO1 Wave', a.lfo1.waveform.displayName, b.lfo1.waveform.displayName, SynthTheme.cyan);
    add('LFO1 Rate', '${a.lfo1.rate.toStringAsFixed(2)} Hz', '${b.lfo1.rate.toStringAsFixed(2)} Hz', SynthTheme.cyan);
    add('LFO1 Depth', '${(a.lfo1.depth * 100).round()}%', '${(b.lfo1.depth * 100).round()}%', SynthTheme.cyan);

    add('LFO2 Wave', a.lfo2.waveform.displayName, b.lfo2.waveform.displayName, SynthTheme.purple);
    add('LFO2 Rate', '${a.lfo2.rate.toStringAsFixed(2)} Hz', '${b.lfo2.rate.toStringAsFixed(2)} Hz', SynthTheme.purple);
    add('LFO2 Depth', '${(a.lfo2.depth * 100).round()}%', '${(b.lfo2.depth * 100).round()}%', SynthTheme.purple);

    // FX
    add('Chorus Enabled', a.chorus.enabled ? 'ON' : 'OFF', b.chorus.enabled ? 'ON' : 'OFF');
    add('Delay Enabled', a.delay.enabled ? 'ON' : 'OFF', b.delay.enabled ? 'ON' : 'OFF');
    add('Reverb Enabled', a.reverb.enabled ? 'ON' : 'OFF', b.reverb.enabled ? 'ON' : 'OFF');
    add('Phaser Enabled', a.phaser.enabled ? 'ON' : 'OFF', b.phaser.enabled ? 'ON' : 'OFF');
    add('Flanger Enabled', a.flanger.enabled ? 'ON' : 'OFF', b.flanger.enabled ? 'ON' : 'OFF');
    add('Compressor Enabled', a.compressor.enabled ? 'ON' : 'OFF', b.compressor.enabled ? 'ON' : 'OFF');
    add('Drive Enabled', a.drive.enabled ? 'ON' : 'OFF', b.drive.enabled ? 'ON' : 'OFF');

    // Master
    add('Master Volume', '${(a.masterVolume * 100).round()}%', '${(b.masterVolume * 100).round()}%', SynthTheme.orange);

    return entries;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abState = ref.watch(abComparisonProvider);
    final snapshotA = abState.snapshotA;
    final snapshotB = abState.snapshotB;

    if (snapshotA == null || snapshotB == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: SynthTheme.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows, size: 48, color: SynthTheme.purple.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'Capture both Bank A and Bank B\nto see a parameter diff.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SynthTheme.textSecondary.withValues(alpha: 0.6),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final diff = _computeDiff(snapshotA.preset, snapshotB.preset);

    return Container(
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: SynthTheme.magenta.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SynthTheme.cyan,
                    boxShadow: [BoxShadow(color: SynthTheme.cyan.withValues(alpha: 0.5), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'A/B PARAMETER DIFF',
                  style: TextStyle(
                    color: SynthTheme.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: SynthTheme.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${diff.length} diff${diff.length == 1 ? "" : "s"}',
                    style: TextStyle(color: SynthTheme.cyan, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                Consumer(builder: (context, ref, _) {
                  ref.watch(abComparisonProvider);
                  return GestureDetector(
                    onTap: () => ref.read(abComparisonProvider.notifier).clear(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: SynthTheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.close, color: SynthTheme.textSecondary, size: 16),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Bank labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: SynthTheme.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'BANK A  ${_fmtTime(snapshotA.createdAt)}',
                      style: TextStyle(color: SynthTheme.cyan, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: SynthTheme.magenta.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'BANK B  ${_fmtTime(snapshotB.createdAt)}',
                      style: TextStyle(color: SynthTheme.magenta, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Diff list
          if (diff.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No differences found — banks are identical.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            )
          else
            SizedBox(
              height: 320,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: diff.length,
                separatorBuilder: (_, _) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final entry = diff[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: entry.accentColor?.withValues(alpha: 0.05) ?? SynthTheme.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: entry.accentColor?.withValues(alpha: 0.15) ?? SynthTheme.purple.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Label
                        SizedBox(
                          width: 100,
                          child: Text(
                            entry.label,
                            style: TextStyle(
                              color: entry.accentColor ?? Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Value A
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SynthTheme.cyan.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              entry.valueA,
                              style: TextStyle(color: SynthTheme.cyan, fontSize: 9, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.arrow_forward, size: 12, color: SynthTheme.textSecondary.withValues(alpha: 0.4)),
                        ),

                        // Value B
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SynthTheme.magenta.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              entry.valueB,
                              style: TextStyle(color: SynthTheme.magenta, fontSize: 9, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DiffEntry {
  final String label;
  final String valueA;
  final String valueB;
  final Color? accentColor;

  const _DiffEntry({
    required this.label,
    required this.valueA,
    required this.valueB,
    this.accentColor,
  });
}
