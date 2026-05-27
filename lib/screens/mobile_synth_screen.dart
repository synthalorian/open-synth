import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fx_config.dart';
import '../models/envelope.dart';
import '../models/mod_matrix.dart';
import '../models/mod_target.dart';
import '../models/preset_category.dart';
import '../models/sequencer_config.dart';
import '../models/synth_preset.dart';
import '../models/waveform.dart';
import '../providers/ab_comparison_provider.dart';
import '../providers/arpeggiator_provider.dart';
import '../providers/clock_provider.dart';
import '../providers/midi_recorder_provider.dart';
import '../providers/mod_matrix_provider.dart';
import '../providers/morph_provider.dart';
import '../providers/randomize_lock_provider.dart';
import '../providers/sequencer_provider.dart';
import '../providers/synth_providers.dart';
import '../providers/undo_redo_provider.dart';
import '../providers/keyboard_split_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/recent_presets_provider.dart';
import '../theme/synth_theme.dart';
import '../widgets/arpeggiator_panel.dart';
import '../widgets/clock_panel.dart';
import '../widgets/collapsible_section.dart';
import '../widgets/computer_keyboard_listener.dart';
import '../widgets/crt_overlay.dart';
import '../widgets/envelope_display.dart';
import '../widgets/filter_panel.dart';
import '../widgets/fx_panel.dart';
import '../widgets/keyboard_widget.dart';
import '../widgets/lfo_panel.dart';
import '../widgets/oscillator_panel.dart';
import '../widgets/midi_panel.dart';
import '../widgets/morph_panel.dart';
import '../widgets/oscilloscope.dart';
import '../widgets/retro_grid_background.dart';
import '../widgets/spectrum_analyzer.dart';
import '../widgets/synth_knob.dart';
import '../widgets/sequencer_panel.dart';
import '../widgets/mod_matrix_panel.dart';
import '../widgets/macro_panel.dart';
import '../widgets/animated_section.dart';

/// Mobile-optimized synth screen with split layout.
///
/// Landscape: left panel (~60%) with scrollable collapsible controls +
/// right panel (~40%) with a fixed keyboard.
///
/// Portrait: stacked layout with compact oscilloscope, scrollable panels,
/// and a fixed keyboard at the bottom.
class MobileSynthScreen extends ConsumerWidget {
  const MobileSynthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(currentPresetProvider);
    final morphed = ref.watch(morphedPresetProvider);
    final morphConfig = ref.watch(morphConfigProvider);
    final effectivePreset = (morphConfig.isPlaying || morphConfig.position > 0.0) ? morphed : preset;
    final notifier = ref.read(currentPresetProvider.notifier);
    final locks = ref.watch(randomizeLockProvider);

    // Keep the native engine in sync with the effective preset.
    ref.watch(livePresetSyncProvider);
    ref.watch(arpeggiatorNativeBridgeProvider);
    ref.watch(midiClockEngineProvider);
    ref.watch(synthPairProvider);
    ref.watch(zoneBPresetSyncProvider);

    final orientation = MediaQuery.of(context).orientation;

    return CrtOverlay(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: orientation == Orientation.landscape
            ? _buildLandscape(context, ref, effectivePreset, notifier, locks)
            : _buildPortrait(context, ref, effectivePreset, notifier, locks),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // LANDSCAPE: split view — left controls + right keyboard
  // ─────────────────────────────────────────────────────
  Widget _buildLandscape(
    BuildContext context,
    WidgetRef ref,
    SynthPreset effectivePreset,
    CurrentPresetNotifier notifier,
    Set<LockableParam> locks,
  ) {
    return RetroGridBackground(
      child: ComputerKeyboardListener(
        active: ref.watch(mainShellIndexProvider) == 1,
        child: Row(
          children: [
            // ── Left panel: ~60% ──
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  // Compact oscilloscope + spectrum row
                  SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(6, 4, 3, 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0118),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: SynthTheme.cyan.withValues(alpha: 0.15),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Oscilloscope(
                              osc1: effectivePreset.osc1,
                              osc2: effectivePreset.osc2,
                              masterVolume: effectivePreset.masterVolume,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(3, 4, 6, 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0118),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: SynthTheme.magenta.withValues(alpha: 0.15),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SpectrumAnalyzer(
                              osc1: effectivePreset.osc1,
                              osc2: effectivePreset.osc2,
                              masterVolume: effectivePreset.masterVolume,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable collapsible panels
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      children: _buildCollapsiblePanels(
                        ref,
                        effectivePreset,
                        notifier,
                        locks,
                        isCompact: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ──
            Container(
              width: 1,
              color: SynthTheme.purple.withValues(alpha: 0.2),
            ),

            // ── Right panel: ~40% — fixed keyboard ──
            Expanded(
              flex: 4,
              child: const KeyboardWidget(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // PORTRAIT: stacked — controls on top, keyboard bottom
  // ─────────────────────────────────────────────────
  Widget _buildPortrait(
    BuildContext context,
    WidgetRef ref,
    SynthPreset effectivePreset,
    CurrentPresetNotifier notifier,
    Set<LockableParam> locks,
  ) {
    return RetroGridBackground(
      child: ComputerKeyboardListener(
        active: ref.watch(mainShellIndexProvider) == 1,
        child: Column(
          children: [
            // Compact oscilloscope bar
            SizedBox(
              height: 40,
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 4, 8, 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0118),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: SynthTheme.cyan.withValues(alpha: 0.15),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Oscilloscope(
                  osc1: effectivePreset.osc1,
                  osc2: effectivePreset.osc2,
                  masterVolume: effectivePreset.masterVolume,
                ),
              ),
            ),
            // Scrollable panels
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                children: _buildCollapsiblePanels(
                  ref,
                  effectivePreset,
                  notifier,
                  locks,
                  isCompact: false,
                ),
              ),
            ),
            // Fixed keyboard at bottom
            const KeyboardWidget(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Collapsible panels shared between layouts
  // ─────────────────────────────────────────
  List<Widget> _buildCollapsiblePanels(
    WidgetRef ref,
    SynthPreset effectivePreset,
    CurrentPresetNotifier notifier,
    Set<LockableParam> locks, {
    required bool isCompact,
  }) {
    void recordCC(int cc, double val) {
      recordAutomationCC(ref, cc, val);
    }

    return [
      // 1. Oscillators (OSC 1 + OSC 2 side by side)
      CollapsibleSection(
        title: 'OSCILLATORS',
        accentColor: SynthTheme.magenta,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: OscillatorPanel(
                title: 'OSC 1',
                oscillator: effectivePreset.osc1,
                isLocked: locks.contains(LockableParam.osc1),
                onChanged: (osc) {
                  notifier.update((p) => p.copyWith(osc1: osc));
                  recordCC(105, ((osc.detune + 50) / 100).clamp(0.0, 1.0));
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OscillatorPanel(
                title: 'OSC 2',
                oscillator: effectivePreset.osc2,
                isLocked: locks.contains(LockableParam.osc2),
                onChanged: (osc) {
                  notifier.update((p) => p.copyWith(osc2: osc));
                  recordCC(106, ((osc.detune + 50) / 100).clamp(0.0, 1.0));
                },
              ),
            ),
          ],
        ),
      ),

      // 2. Filter + Amp Envelope (side by side)
      CollapsibleSection(
        title: 'FILTER + AMP',
        accentColor: SynthTheme.cyan,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FilterPanel(
                filter: effectivePreset.filter,
                isLocked: locks.contains(LockableParam.filter),
                onChanged: (f) {
                  notifier.update((p) => p.copyWith(filter: f));
                  recordCC(100, ((f.cutoff - 20) / 19980).clamp(0.0, 1.0));
                  recordCC(101, f.resonance.clamp(0.0, 1.0));
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: EnvelopeDisplay(
                title: 'AMP ENV',
                envelope: effectivePreset.ampEnvelope,
                accentColor: SynthTheme.magenta,
                isLocked: locks.contains(LockableParam.ampEnvelope),
                onChanged: (e) {
                  notifier.update((p) => p.copyWith(ampEnvelope: e));
                  recordCC(107, (e.attack / 1000).clamp(0.0, 1.0));
                  recordCC(108, (e.decay / 1000).clamp(0.0, 1.0));
                  recordCC(109, e.sustain.clamp(0.0, 1.0));
                  recordCC(110, (e.release / 2000).clamp(0.0, 1.0));
                },
              ),
            ),
          ],
        ),
      ),

      // 3. Filter Env + LFO 1 (side by side)
      CollapsibleSection(
        title: 'FILTER ENV + LFO 1',
        accentColor: SynthTheme.orange,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: EnvelopeDisplay(
                title: 'FILTER ENV',
                envelope: effectivePreset.filterEnvelope,
                accentColor: SynthTheme.orange,
                isLocked: locks.contains(LockableParam.filterEnvelope),
                onChanged: (e) =>
                    notifier.update((p) => p.copyWith(filterEnvelope: e)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: LfoPanel(
                title: 'LFO 1',
                lfo: effectivePreset.lfo1,
                accentColor: SynthTheme.cyan,
                isLocked: locks.contains(LockableParam.lfo1),
                onChanged: (l) {
                  notifier.update((p) => p.copyWith(lfo1: l));
                  recordCC(103, (l.rate / 20).clamp(0.0, 1.0));
                },
              ),
            ),
          ],
        ),
      ),

      // 4. LFO 2 + Master (side by side)
      CollapsibleSection(
        title: 'LFO 2 + MASTER',
        accentColor: SynthTheme.purple,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LfoPanel(
                title: 'LFO 2',
                lfo: effectivePreset.lfo2,
                accentColor: SynthTheme.purple,
                isLocked: locks.contains(LockableParam.lfo2),
                onChanged: (l) {
                  notifier.update((p) => p.copyWith(lfo2: l));
                  recordCC(104, (l.rate / 20).clamp(0.0, 1.0));
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MobileMasterSection(
                effectivePreset: effectivePreset,
                notifier: notifier,
                isLocked: locks.contains(LockableParam.masterVolume),
              ),
            ),
          ],
        ),
      ),

      // 5. Arpeggiator (full width)
      const CollapsibleSection(
        title: 'ARPEGGIATOR',
        accentColor: SynthTheme.magenta,
        child: ArpeggiatorPanel(),
      ),

      // 6. Effects (full width)
      CollapsibleSection(
        title: 'EFFECTS',
        accentColor: SynthTheme.cyan,
        child: FxPanel(
          chorus: effectivePreset.chorus,
          delay: effectivePreset.delay,
          reverb: effectivePreset.reverb,
          phaser: effectivePreset.phaser,
          flanger: effectivePreset.flanger,
          compressor: effectivePreset.compressor,
          drive: effectivePreset.drive,
          chorusLocked: locks.contains(LockableParam.chorus),
          delayLocked: locks.contains(LockableParam.delay),
          reverbLocked: locks.contains(LockableParam.reverb),
          phaserLocked: locks.contains(LockableParam.phaser),
          flangerLocked: locks.contains(LockableParam.flanger),
          compressorLocked: locks.contains(LockableParam.compressor),
          driveLocked: locks.contains(LockableParam.drive),
          onChorusChanged: (c) =>
              notifier.update((p) => p.copyWith(chorus: c)),
          onDelayChanged: (d) =>
              notifier.update((p) => p.copyWith(delay: d)),
          onReverbChanged: (r) =>
              notifier.update((p) => p.copyWith(reverb: r)),
          onPhaserChanged: (ph) =>
              notifier.update((p) => p.copyWith(phaser: ph)),
          onFlangerChanged: (f) =>
              notifier.update((p) => p.copyWith(flanger: f)),
          onCompressorChanged: (c) =>
              notifier.update((p) => p.copyWith(compressor: c)),
          onDriveChanged: (d) =>
              notifier.update((p) => p.copyWith(drive: d)),
          slotConfigs: effectivePreset.fxSlots,
          onSlotChanged: (slotIndex, slot) =>
              notifier.update((p) {
                final slots = List<FxSlotConfig>.from(p.fxSlots);
                while (slots.length <= slotIndex) {
                  slots.add(const FxSlotConfig());
                }
                slots[slotIndex] = slot;
                return p.copyWith(fxSlots: slots);
              }),
          eq: effectivePreset.eq,
          onEqChanged: (e) =>
              notifier.update((p) => p.copyWith(eq: e)),
          limiter: effectivePreset.limiter,
          onLimiterChanged: (l) =>
              notifier.update((p) => p.copyWith(limiter: l)),
          rotary: effectivePreset.rotary,
          onRotaryChanged: (r) =>
              notifier.update((p) => p.copyWith(rotary: r)),
          tremolo: effectivePreset.tremolo,
          onTremoloChanged: (t) =>
              notifier.update((p) => p.copyWith(tremolo: t)),
        ),
      ),

      // 7. Sequencer (full width)
      const CollapsibleSection(
        title: 'SEQUENCER',
        accentColor: SynthTheme.orange,
        child: SequencerPanel(),
      ),

      // 8. Mod Matrix + Macros
      const CollapsibleSection(
        title: 'MOD MATRIX + MACROS',
        accentColor: SynthTheme.purple,
        child: Column(
          children: [
            ModMatrixPanel(),
            SizedBox(height: 8),
            MacroPanel(),
          ],
        ),
      ),

      // 9. Clock + MIDI
      const CollapsibleSection(
        title: 'CLOCK + MIDI',
        accentColor: SynthTheme.cyan,
        child: Column(
          children: [
            ClockPanel(),
            SizedBox(height: 8),
            MidiPanel(),
          ],
        ),
      ),

      // 10. Morph
      const CollapsibleSection(
        title: 'PRESET MORPH',
        accentColor: SynthTheme.magenta,
        child: MorphPanel(),
      ),

      // Bottom padding
      const SizedBox(height: 16),
    ];
  }
}

/// Compact master section for mobile — volume knob + panic button.
class _MobileMasterSection extends StatelessWidget {
  final SynthPreset effectivePreset;
  final CurrentPresetNotifier notifier;
  final bool isLocked;

  const _MobileMasterSection({
    required this.effectivePreset,
    required this.notifier,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SynthTheme.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MASTER',
                style: TextStyle(
                  color: SynthTheme.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (isLocked) ...[
                const SizedBox(width: 4),
                Icon(Icons.lock, color: SynthTheme.magenta, size: 10),
              ],
            ],
          ),
          const SizedBox(height: 6),
          SynthKnob(
            label: 'VOL',
            value: effectivePreset.masterVolume,
            min: 0,
            max: 1,
            size: 60,
            formatValue: (v) => '${(v * 100).round()}',
            onChanged: (v) {
              notifier.update((p) => p.copyWith(masterVolume: v));
            },
            activeColor: SynthTheme.orange,
          ),
        ],
      ),
    );
  }
}
