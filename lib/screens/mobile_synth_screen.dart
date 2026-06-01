import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fx_config.dart';
import '../models/synth_preset.dart';
import '../providers/arpeggiator_provider.dart';
import '../providers/clock_provider.dart';
import '../providers/midi_recorder_provider.dart';
import '../providers/morph_provider.dart';
import '../providers/randomize_lock_provider.dart';
import '../providers/synth_providers.dart';
import '../providers/keyboard_split_provider.dart';
import '../providers/navigation_provider.dart';
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
import '../widgets/drum_panel.dart';

/// Mobile-optimized synth screen — full-width keyboard at bottom,
/// compact options bar at top, scrollable panels in the middle.
///
/// Both landscape and portrait use the same Column-based structure:
///   1. Compact top bar (preset, octave, volume, panic)
///   2. Expanded scrollable collapsible panels
///   3. Full-width keyboard spanning the bottom
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
    ref.watch(synthAudioStreamProvider);
    ref.watch(synthPairAudioStreamProvider);
    ref.watch(zoneBPresetSyncProvider);
    ref.watch(zoneBMixSyncProvider);

    return CrtOverlay(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _buildLayout(context, ref, effectivePreset, notifier, locks),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Unified layout: top bar → panels → keyboard
  // ─────────────────────────────────────────
  Widget _buildLayout(
    BuildContext context,
    WidgetRef ref,
    SynthPreset effectivePreset,
    CurrentPresetNotifier notifier,
    Set<LockableParam> locks,
  ) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    // Aggressive keyboard height — keys should DOMINATE the bottom of the screen.
    // On tall phones (20:9 ratio) at 412dp wide, 250dp gives ~2.5 octaves of playable keys.
    final keyboardHeight = isLandscape ? 200.0 : 250.0;

    return RetroGridBackground(
      child: ComputerKeyboardListener(
        active: ref.watch(mainShellIndexProvider) == 1,
        child: Column(
          children: [
            // ── Top bar ──
            _buildTopBar(context, ref, effectivePreset, notifier),

            // ── Oscilloscope + Spectrum row (compact) ──
            SizedBox(
              height: isLandscape ? 40 : 44,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(6, 2, 3, 2),
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
                      margin: const EdgeInsets.fromLTRB(3, 2, 6, 2),
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

            // ── Scrollable collapsible panels ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                children: _buildCollapsiblePanels(
                  ref,
                  effectivePreset,
                  notifier,
                  locks,
                  isCompact: isLandscape,
                ),
              ),
            ),

            // ── Full-width keyboard at bottom ──
            SizedBox(
              height: keyboardHeight,
              width: double.infinity,
              child: const KeyboardWidget(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Compact top options bar
  // ─────────────────────────────────────────
  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    SynthPreset effectivePreset,
    CurrentPresetNotifier notifier,
  ) {
    final presetList = ref.watch(presetListProvider);
    final currentOctave = ref.watch(keyboardOctaveProvider);
    final masterVolume = effectivePreset.masterVolume;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: SynthTheme.card.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: SynthTheme.purple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Preset name (tap to cycle) ──
          GestureDetector(
            onTap: () {
              if (presetList.isEmpty) return;
              final idx = presetList.indexWhere((p) => p.id == effectivePreset.id);
              final next = (idx + 1) % presetList.length;
              notifier.load(presetList[next]);
            },
            onLongPress: () {
              // Cycle backwards on long press
              if (presetList.isEmpty) return;
              final idx = presetList.indexWhere((p) => p.id == effectivePreset.id);
              final prev = (idx - 1 + presetList.length) % presetList.length;
              notifier.load(presetList[prev]);
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 120),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.music_note, color: SynthTheme.magenta, size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      effectivePreset.name,
                      style: TextStyle(
                        color: SynthTheme.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.swap_horiz, color: SynthTheme.purple, size: 12),
                ],
              ),
            ),
          ),

          // ── Separator ──
          Container(
            width: 1,
            height: 24,
            color: SynthTheme.purple.withValues(alpha: 0.25),
          ),

          // ── Octave controls ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TopBarButton(
                  icon: Icons.remove,
                  color: SynthTheme.cyan,
                  onTap: () {
                    final octave = ref.read(keyboardOctaveProvider);
                    ref.read(keyboardOctaveProvider.notifier).state =
                        (octave - 1).clamp(0, 8);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'OCT',
                        style: TextStyle(
                          color: SynthTheme.purple.withValues(alpha: 0.6),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '$currentOctave',
                        style: TextStyle(
                          color: SynthTheme.cyan,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _TopBarButton(
                  icon: Icons.add,
                  color: SynthTheme.cyan,
                  onTap: () {
                    final octave = ref.read(keyboardOctaveProvider);
                    ref.read(keyboardOctaveProvider.notifier).state =
                        (octave + 1).clamp(0, 8);
                  },
                ),
              ],
            ),
          ),

          // ── Separator ──
          Container(
            width: 1,
            height: 24,
            color: SynthTheme.purple.withValues(alpha: 0.25),
          ),

          // ── Master volume (compact slider) ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(Icons.volume_up, color: SynthTheme.orange, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: SynthTheme.orange,
                        inactiveTrackColor: SynthTheme.orange.withValues(alpha: 0.2),
                        thumbColor: SynthTheme.orange,
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        value: masterVolume,
                        min: 0,
                        max: 1,
                        onChanged: (v) {
                          notifier.update((p) => p.copyWith(masterVolume: v));
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${(masterVolume * 100).round()}',
                      style: TextStyle(
                        color: SynthTheme.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Separator ──
          Container(
            width: 1,
            height: 24,
            color: SynthTheme.purple.withValues(alpha: 0.25),
          ),

          // ── Panic button ──
          _TopBarButton(
            icon: Icons.warning_amber_rounded,
            label: 'PANIC',
            color: SynthTheme.magenta,
            onTap: () {
              ref.read(noteRouterProvider).allNotesOff();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PANIC: All notes killed'),
                  duration: Duration(milliseconds: 800),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
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
      CollapsibleSection(
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
      CollapsibleSection(
        title: 'SEQUENCER',
        accentColor: SynthTheme.orange,
        child: SequencerPanel(),
      ),

      // 8. Mod Matrix + Macros
      CollapsibleSection(
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
      CollapsibleSection(
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
      CollapsibleSection(
        title: 'PRESET MORPH',
        accentColor: SynthTheme.magenta,
        child: MorphPanel(),
      ),

      // 11. Drum Kit
      const CollapsibleSection(
        title: 'DRUM KIT',
        accentColor: Color(0xFFFF3355),
        child: DrumPanel(),
      ),

      // Bottom padding
      const SizedBox(height: 16),
    ];
  }
}

// ─────────────────────────────────────────
// Compact button for the top bar
// ─────────────────────────────────────────
class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;

  const _TopBarButton({
    required this.icon,
    this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            if (label != null)
              Text(
                label!,
                style: TextStyle(
                  color: color,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
          ],
        ),
      ),
    );
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
