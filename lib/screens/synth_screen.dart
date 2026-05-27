import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/fx_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ffi/audio_platform.dart';
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
import '../theme/synth_theme.dart';
import '../widgets/history_timeline.dart';
import '../widgets/arpeggiator_panel.dart';
import '../widgets/clock_panel.dart';
import '../widgets/computer_keyboard_listener.dart';
import '../widgets/crt_overlay.dart';
import '../widgets/envelope_display.dart';
import '../widgets/filter_panel.dart';
import '../widgets/fx_panel.dart';
import '../widgets/keyboard_widget.dart';
import '../providers/keyboard_split_provider.dart';
import '../widgets/lfo_panel.dart';
import '../widgets/oscillator_panel.dart';
import '../widgets/midi_panel.dart';
import '../widgets/morph_panel.dart';
import '../widgets/preset_browser.dart';
import '../widgets/oscilloscope.dart';
import '../widgets/retro_grid_background.dart';
import '../widgets/spectrum_analyzer.dart';
import '../widgets/synth_knob.dart';
import '../widgets/sequencer_panel.dart';
import '../widgets/mod_matrix_panel.dart';
import '../widgets/macro_panel.dart';
import '../widgets/animated_section.dart';
import '../providers/favorites_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/recent_presets_provider.dart';
import 'preset_editor_screen.dart';
import 'settings_screen.dart';
import 'midi_learn_screen.dart';
import 'mobile_synth_screen.dart';
import '../widgets/keyboard_shortcuts_overlay.dart';
import '../widgets/ab_comparison_diff.dart';
import '../widgets/onboarding_overlay.dart';
import '../widgets/quick_preset_context_menu.dart';

/// Tracks whether onboarding has been shown once per screen instance.
final _onboardingShownProvider = StateProvider<bool>((ref) => false);

/// Button that shows the A/B parameter diff overlay.
class _DiffViewButton extends ConsumerWidget {
  const _DiffViewButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abState = ref.watch(abComparisonProvider);
    final hasBoth = abState.snapshotA != null && abState.snapshotB != null;

    return IconButton(
      icon: Icon(
        Icons.compare_arrows,
        color: hasBoth ? SynthTheme.magenta : SynthTheme.textSecondary.withValues(alpha: 0.3),
        size: 20,
      ),
      tooltip: 'A/B Parameter Diff',
      onPressed: hasBoth
          ? () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  minChildSize: 0.3,
                  maxChildSize: 0.85,
                  expand: false,
                  builder: (context, scrollController) => const ABComparisonDiff(),
                ),
              );
            }
          : null,
    );
  }
}

class _AbComparisonButton extends ConsumerWidget {
  const _AbComparisonButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abState = ref.watch(abComparisonProvider);
    final isA = abState.isBankA;
    final hasSnapshot = abState.activeSnapshot != null;

    return GestureDetector(
      onLongPress: () {
        ref.read(undoRedoProvider.notifier).save();
        final preset = ref.read(currentPresetProvider);
        final modSlots = ref.read(modMatrixProvider).slots;
        ref.read(abComparisonProvider.notifier).captureCurrent(preset, modSlots);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Captured to Bank ${isA ? 'A' : 'B'}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onTap: () {
        ref.read(undoRedoProvider.notifier).save();
        ref.read(abComparisonProvider.notifier).toggleBank();
        final updated = ref.read(abComparisonProvider);
        final snapshot = updated.activeSnapshot;
        if (snapshot != null) {
          ref.read(currentPresetProvider.notifier).load(snapshot.preset);
          ref.read(modMatrixProvider.notifier).load(ModMatrix(slots: snapshot.modSlots));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to Bank ${updated.isBankA ? 'A' : 'B'}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: hasSnapshot
              ? (isA ? SynthTheme.cyan.withValues(alpha: 0.25) : SynthTheme.magenta.withValues(alpha: 0.25))
              : SynthTheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: hasSnapshot
                ? (isA ? SynthTheme.cyan : SynthTheme.magenta)
                : SynthTheme.purple.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          hasSnapshot ? (isA ? 'A' : 'B') : 'A/B',
          style: TextStyle(
            color: hasSnapshot
                ? (isA ? SynthTheme.cyan : SynthTheme.magenta)
                : SynthTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class SynthScreen extends ConsumerWidget {
  const SynthScreen({super.key});

  void _randomizePreset(BuildContext context, WidgetRef ref) {
    ref.read(undoRedoProvider.notifier).save();
    final notifier = ref.read(currentPresetProvider.notifier);
    final locks = ref.read(randomizeLockProvider);
    final rng = Random();
    double rnd(double min, double max) => min + rng.nextDouble() * (max - min);

    notifier.update((p) => p.copyWith(
      name: 'Randomized',
      osc1: locks.contains(LockableParam.osc1)
          ? p.osc1
          : p.osc1.copyWith(
              waveform: Waveform.values[rng.nextInt(Waveform.values.length)],
              octave: rng.nextInt(5) - 2,
              detune: rnd(-50, 50),
              volume: rnd(0.3, 1.0),
              enabled: true,
              unisonVoiceCount: [1, 2, 4, 8][rng.nextInt(4)],
              unisonDetuneSpread: rnd(2, 40),
              unisonStereoSpread: rnd(0.1, 0.9),
              unisonMix: rnd(0.3, 1.0),
            ),
      osc2: locks.contains(LockableParam.osc2)
          ? p.osc2
          : p.osc2.copyWith(
              waveform: Waveform.values[rng.nextInt(Waveform.values.length)],
              octave: rng.nextInt(5) - 2,
              detune: rnd(-50, 50),
              volume: rnd(0.0, 0.8),
              enabled: rng.nextBool(),
              unisonVoiceCount: [1, 2, 4, 8][rng.nextInt(4)],
              unisonDetuneSpread: rnd(2, 40),
              unisonStereoSpread: rnd(0.1, 0.9),
              unisonMix: rnd(0.3, 1.0),
            ),
      filter: locks.contains(LockableParam.filter)
          ? p.filter
          : p.filter.copyWith(
              type: FilterType.values[rng.nextInt(FilterType.values.length)],
              cutoff: rnd(200, 12000),
              resonance: rnd(0, 0.8),
              envelopeAmount: rnd(-0.8, 0.8),
            ),
      ampEnvelope: locks.contains(LockableParam.ampEnvelope)
          ? p.ampEnvelope
          : Envelope(
              attack: rnd(2, 800),
              decay: rnd(20, 800),
              sustain: rnd(0.1, 1.0),
              release: rnd(20, 2000),
            ),
      filterEnvelope: locks.contains(LockableParam.filterEnvelope)
          ? p.filterEnvelope
          : Envelope(
              attack: rnd(2, 1000),
              decay: rnd(20, 1000),
              sustain: rnd(0.0, 1.0),
              release: rnd(20, 2000),
            ),
      lfo1: locks.contains(LockableParam.lfo1)
          ? p.lfo1
          : p.lfo1.copyWith(
              waveform: Waveform.values[rng.nextInt(Waveform.values.length)],
              rate: rnd(0.1, 10),
              depth: rnd(0, 0.8),
            ),
      lfo2: locks.contains(LockableParam.lfo2)
          ? p.lfo2
          : p.lfo2.copyWith(
              waveform: Waveform.values[rng.nextInt(Waveform.values.length)],
              rate: rnd(0.1, 10),
              depth: rnd(0, 0.8),
            ),
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preset randomized — tweak to taste'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _generativeRandomize(BuildContext context, WidgetRef ref) {
    ref.read(undoRedoProvider.notifier).save();
    final rng = Random();
    final locks = ref.read(randomizeLockProvider);
    double rnd(double min, double max) => min + rng.nextDouble() * (max - min);

    // 1. Randomize preset (respecting locks)
    ref.read(currentPresetProvider.notifier).update((p) => p.copyWith(
      name: 'Generative',
      osc1: locks.contains(LockableParam.osc1)
          ? p.osc1
          : p.osc1.copyWith(
              waveform: Waveform.values[rng.nextInt(Waveform.values.length)],
              octave: rng.nextInt(4) - 1,
              detune: rnd(-40, 40),
              volume: rnd(0.4, 1.0),
              enabled: true,
              unisonVoiceCount: [1, 2, 4, 8][rng.nextInt(4)],
              unisonDetuneSpread: rnd(2, 35),
              unisonStereoSpread: rnd(0.1, 0.9),
              unisonMix: rnd(0.3, 1.0),
            ),
      osc2: locks.contains(LockableParam.osc2)
          ? p.osc2
          : p.osc2.copyWith(
              waveform: Waveform.values[rng.nextInt(Waveform.values.length)],
              octave: rng.nextInt(4) - 1,
              detune: rnd(-40, 40),
              volume: rnd(0.2, 0.8),
              enabled: rng.nextBool(),
              unisonVoiceCount: [1, 2, 4, 8][rng.nextInt(4)],
              unisonDetuneSpread: rnd(2, 35),
              unisonStereoSpread: rnd(0.1, 0.9),
              unisonMix: rnd(0.3, 1.0),
            ),
      filter: locks.contains(LockableParam.filter)
          ? p.filter
          : p.filter.copyWith(
              type: FilterType.values[rng.nextInt(FilterType.values.length)],
              cutoff: rnd(300, 10000),
              resonance: rnd(0.1, 0.7),
              envelopeAmount: rnd(-0.6, 0.6),
            ),
      ampEnvelope: locks.contains(LockableParam.ampEnvelope)
          ? p.ampEnvelope
          : Envelope(
              attack: rnd(5, 600),
              decay: rnd(30, 700),
              sustain: rnd(0.2, 0.9),
              release: rnd(50, 1500),
            ),
      filterEnvelope: locks.contains(LockableParam.filterEnvelope)
          ? p.filterEnvelope
          : Envelope(
              attack: rnd(5, 800),
              decay: rnd(30, 900),
              sustain: rnd(0.1, 0.8),
              release: rnd(50, 1800),
            ),
      lfo1: locks.contains(LockableParam.lfo1)
          ? p.lfo1
          : p.lfo1.copyWith(
              waveform: Waveform.values[rng.nextInt(Waveform.values.length)],
              rate: rnd(0.2, 8),
              depth: rnd(0.1, 0.7),
              target: LfoTarget.values[rng.nextInt(LfoTarget.values.length)],
            ),
      lfo2: locks.contains(LockableParam.lfo2)
          ? p.lfo2
          : p.lfo2.copyWith(
              waveform: Waveform.values[rng.nextInt(Waveform.values.length)],
              rate: rnd(0.2, 8),
              depth: rnd(0.1, 0.7),
              target: LfoTarget.values[rng.nextInt(LfoTarget.values.length)],
            ),
    ));

    // 2. Randomize mod matrix (respecting lock)
    if (!locks.contains(LockableParam.modMatrix)) {
      final sources = ModSource.values;
      final destinations = ModDestination.values;
      final modNotifier = ref.read(modMatrixProvider.notifier);
      for (int i = 0; i < 8; i++) {
        if (rng.nextDouble() < 0.35) {
          modNotifier.updateSlot(i, (s) => ModMatrixSlot(
            source: sources[rng.nextInt(sources.length)],
            destination: destinations[rng.nextInt(destinations.length)],
            amount: rnd(-0.8, 0.8),
            enabled: true,
          ));
        } else {
          modNotifier.clearSlot(i);
        }
      }
    }

    // 3. Generate a random 16-step pattern on track 0 (respecting lock)
    if (!locks.contains(LockableParam.sequencer)) {
      final seqNotifier = ref.read(sequencerPatternProvider.notifier);
      final steps = List.generate(16, (i) {
        final enabled = rng.nextDouble() < 0.4;
        final note = enabled ? 48 + rng.nextInt(24) : -1;
        return SequencerStep(
          enabled: enabled,
          note: note,
          velocity: enabled ? rnd(0.5, 1.0) : 0.0,
          gate: enabled ? rnd(0.3, 0.9) : 1.0,
        );
      });
      seqNotifier.updatePattern((p) => p.copyWith(
        tracks: [
          SequencerTrack(
            name: 'Gen Bass',
            midiChannel: 0,
            steps: steps,
          ),
        ],
        bpm: rnd(90, 140),
      ));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generative patch + pattern created'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLockDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SynthTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SynthTheme.purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LOCK PARAMETERS',
                      style: TextStyle(
                        color: SynthTheme.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => ref.read(randomizeLockProvider.notifier).resetAll(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: SynthTheme.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            color: SynthTheme.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LockableParam.values.map((param) {
                    final label = switch (param) {
                      LockableParam.osc1 => 'OSC 1',
                      LockableParam.osc2 => 'OSC 2',
                      LockableParam.filter => 'Filter',
                      LockableParam.ampEnvelope => 'Amp Env',
                      LockableParam.filterEnvelope => 'Filter Env',
                      LockableParam.lfo1 => 'LFO 1',
                      LockableParam.lfo2 => 'LFO 2',
                      LockableParam.chorus => 'Chorus',
                      LockableParam.delay => 'Delay',
                      LockableParam.reverb => 'Reverb',
                      LockableParam.phaser => 'Phaser',
                      LockableParam.flanger => 'Flanger',
                      LockableParam.compressor => 'Compressor',
                      LockableParam.drive => 'Drive',
                      LockableParam.masterVolume => 'Master',
                      LockableParam.modMatrix => 'Mod Matrix',
                      LockableParam.sequencer => 'Sequencer',
                      LockableParam.unison => 'Unison',
                    };
                    return Consumer(
                      builder: (context, ref, child) {
                        final isLocked = ref.watch(randomizeLockProvider).contains(param);
                        return GestureDetector(
                          onTap: () => ref.read(randomizeLockProvider.notifier).toggle(param),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isLocked
                                  ? SynthTheme.magenta.withValues(alpha: 0.25)
                                  : SynthTheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isLocked
                                    ? SynthTheme.magenta
                                    : SynthTheme.purple.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLocked ? Icons.lock : Icons.lock_open,
                                  color: isLocked ? SynthTheme.magenta : SynthTheme.textSecondary,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: isLocked ? SynthTheme.magenta : Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Locked parameters are skipped during randomization.',
                  style: TextStyle(
                    color: SynthTheme.textSecondary.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  void _initPatch(BuildContext context, WidgetRef ref) {
    ref.read(undoRedoProvider.notifier).save();
    ref.read(currentPresetProvider.notifier).load(
      SynthPreset(name: 'Init Patch', category: PresetCategory.custom),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loaded init patch'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddToSetlist(BuildContext context, WidgetRef ref) {
    showAddToSetlistForPreset(context, ref, ref.read(currentPresetProvider));
  }



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mobile gets its own split-view layout — desktop stays here.
    if (isMobile) return const MobileSynthScreen();

    final preset = ref.watch(currentPresetProvider);
    final morphed = ref.watch(morphedPresetProvider);
    final morphConfig = ref.watch(morphConfigProvider);
    final effectivePreset = (morphConfig.isPlaying || morphConfig.position > 0.0) ? morphed : preset;
    final notifier = ref.read(currentPresetProvider.notifier);
    final locks = ref.watch(randomizeLockProvider);

    // Keep the native engine in sync with the effective preset (morphed or current).
    ref.watch(livePresetSyncProvider);

    // Keep arpeggiator native engine in sync while on this screen.
    ref.watch(arpeggiatorNativeBridgeProvider);

    // Keep MIDI clock engine alive.
    ref.watch(midiClockEngineProvider);

    // Keep zone B engine + preset sync alive (for keyboard split).
    ref.watch(synthPairProvider);
    ref.watch(zoneBPresetSyncProvider);

    // Show onboarding if not yet completed — one-shot via Future.microtask.
    final onboardingDone = ref.watch(onboardingCompletedProvider);
    if (!onboardingDone && !ref.read(_onboardingShownProvider)) {
      ref.read(_onboardingShownProvider.notifier).state = true;
      Future.microtask(() {
        if (context.mounted) {
          showGeneralDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.transparent,
            pageBuilder: (ctx, anim1, anim2) => const OnboardingOverlay(),
          );
        }
      });
    }

    // Listen for onboarding reset (e.g. from settings).
    ref.listen<bool>(onboardingCompletedProvider, (prev, next) {
      if (prev == true && next == false && context.mounted) {
        ref.read(_onboardingShownProvider.notifier).state = false;
      }
    });

    // Auto-clear quick-strip search when leaving the Synth tab.
    ref.listen<int>(mainShellIndexProvider, (prev, next) {
      if (prev == 1 && next != 1) {
        ref.read(_quickStripSearchProvider.notifier).state = '';
        ref.read(_quickStripCategoryFilterProvider.notifier).state = null;
      }
    });

    return CrtOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            effectivePreset.name.toUpperCase(),
            style: GoogleFonts.orbitron(
              color: SynthTheme.magenta,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              ref.read(mainShellIndexProvider.notifier).state = 0;
            },
          ),
          actions: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final undoRedo = ref.watch(undoRedoProvider);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.undo,
                              color: undoRedo.canUndo ? SynthTheme.cyan : SynthTheme.textSecondary.withValues(alpha: 0.3),
                              size: 20,
                            ),
                            tooltip: 'Undo',
                            onPressed: undoRedo.canUndo
                                ? () => ref.read(undoRedoProvider.notifier).undo()
                                : null,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.redo,
                              color: undoRedo.canRedo ? SynthTheme.cyan : SynthTheme.textSecondary.withValues(alpha: 0.3),
                              size: 20,
                            ),
                            tooltip: 'Redo',
                            onPressed: undoRedo.canRedo
                                ? () => ref.read(undoRedoProvider.notifier).redo()
                                : null,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.history,
                              color: undoRedo.history.isNotEmpty ? SynthTheme.cyan : SynthTheme.textSecondary.withValues(alpha: 0.3),
                              size: 20,
                            ),
                            tooltip: 'History Timeline',
                            onPressed: undoRedo.history.isNotEmpty
                                ? () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => const HistoryTimeline(),
                                    );
                                  }
                                : null,
                          ),
                        ],
                      );
                    },
                  ),
                  GestureDetector(
                    onLongPress: () => _showLockDialog(context, ref),
                    child: IconButton(
                      icon: Icon(Icons.shuffle, color: SynthTheme.purple, size: 20),
                      tooltip: 'Randomize Preset (long-press for locks)',
                      onPressed: () => _randomizePreset(context, ref),
                    ),
                  ),
                  GestureDetector(
                    onLongPress: () => _showLockDialog(context, ref),
                    child: IconButton(
                      icon: Icon(Icons.auto_fix_high, color: SynthTheme.cyan, size: 20),
                      tooltip: 'Generative Randomize (long-press for locks)',
                      onPressed: () => _generativeRandomize(context, ref),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: SynthTheme.cyan, size: 20),
                    tooltip: 'Init Patch',
                    onPressed: () => _initPatch(context, ref),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: SynthTheme.cyan, size: 20),
                    tooltip: 'Edit Preset Info',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PresetEditorScreen()),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.save_outlined, color: SynthTheme.orange, size: 20),
                    tooltip: 'Save Preset',
                    onPressed: () {
                      ref.read(presetListProvider.notifier).updatePreset(preset);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Preset "${preset.name}" saved to the grid'),
                          backgroundColor: SynthTheme.card,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.grid_view, color: SynthTheme.cyan, size: 20),
                    tooltip: 'Patch Browser',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => DraggableScrollableSheet(
                          initialChildSize: 0.7,
                          minChildSize: 0.4,
                          maxChildSize: 0.9,
                          expand: false,
                          builder: (context, scrollController) {
                            return PresetBrowser(scrollController: scrollController);
                          },
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.piano, color: SynthTheme.cyan, size: 20),
                    tooltip: 'MIDI Learn',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MidiLearnScreen()),
                      );
                    },
                  ),
                  _DiffViewButton(),
                  IconButton(
                    icon: Icon(Icons.keyboard, color: SynthTheme.cyan, size: 20),
                    tooltip: 'Keyboard Shortcuts',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const KeyboardShortcutsOverlay(),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: SynthTheme.textSecondary, size: 20),
                    tooltip: 'Settings',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.fullscreen, color: SynthTheme.magenta, size: 20),
                    tooltip: 'Performance Tab',
                    onPressed: () {
                      ref.read(mainShellIndexProvider.notifier).state = 4;
                    },
                  ),
                  _AbComparisonButton(),
                  IconButton(
                    icon: Icon(Icons.queue_music, color: SynthTheme.cyan, size: 20),
                    tooltip: 'Add to Setlist',
                    onPressed: () => _showAddToSetlist(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        body: RetroGridBackground(
          child: ComputerKeyboardListener(
            active: ref.watch(mainShellIndexProvider) == 1,
            child: Column(
              children: [
                // ── Oscilloscope ──
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0118),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SynthTheme.cyan.withValues(alpha: 0.2),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 70,
                    child:                    Oscilloscope(
                      osc1: effectivePreset.osc1,
                      osc2: effectivePreset.osc2,
                      masterVolume: effectivePreset.masterVolume,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // ── Quick Preset Strip ──
                _QuickPresetStrip(),
                const SizedBox(height: 6),
                // ── Spectrum Analyzer ──
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0118),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SynthTheme.magenta.withValues(alpha: 0.2),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 70,
                    child:                    SpectrumAnalyzer(
                      osc1: effectivePreset.osc1,
                      osc2: effectivePreset.osc2,
                      masterVolume: effectivePreset.masterVolume,
                    ),
                  ),
                ),

                // Scrollable synth controls
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // ── Row 1: Oscillators ──
                        AnimatedSection(
                          index: 1,
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
                                    recordAutomationCC(ref, 105, ((osc.detune + 50) / 100).clamp(0.0, 1.0));
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OscillatorPanel(
                                  title: 'OSC 2',
                                  oscillator: effectivePreset.osc2,
                                  isLocked: locks.contains(LockableParam.osc2),
                                  onChanged: (osc) {
                                    notifier.update((p) => p.copyWith(osc2: osc));
                                    recordAutomationCC(ref, 106, ((osc.detune + 50) / 100).clamp(0.0, 1.0));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Row 2: Filter + Amp Envelope ──
                        AnimatedSection(
                          index: 2,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: FilterPanel(
                                  filter: effectivePreset.filter,
                                  isLocked: locks.contains(LockableParam.filter),
                                  onChanged: (f) {
                                    notifier.update((p) => p.copyWith(filter: f));
                                    recordAutomationCC(ref, 100, ((f.cutoff - 20) / 19980).clamp(0.0, 1.0));
                                    recordAutomationCC(ref, 101, f.resonance.clamp(0.0, 1.0));
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: EnvelopeDisplay(
                                  title: 'AMP ENV',
                                  envelope: effectivePreset.ampEnvelope,
                                  accentColor: SynthTheme.magenta,
                                  isLocked: locks.contains(LockableParam.ampEnvelope),
                                  onChanged: (e) {
                                    notifier.update((p) => p.copyWith(ampEnvelope: e));
                                    recordAutomationCC(ref, 107, (e.attack / 1000).clamp(0.0, 1.0));
                                    recordAutomationCC(ref, 108, (e.decay / 1000).clamp(0.0, 1.0));
                                    recordAutomationCC(ref, 109, e.sustain.clamp(0.0, 1.0));
                                    recordAutomationCC(ref, 110, (e.release / 2000).clamp(0.0, 1.0));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Row 3: Filter Envelope + LFO 1 ──
                        AnimatedSection(
                          index: 3,
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: LfoPanel(
                                  title: 'LFO 1',
                                  lfo: effectivePreset.lfo1,
                                  accentColor: SynthTheme.cyan,
                                  isLocked: locks.contains(LockableParam.lfo1),
                                  onChanged: (l) {
                                    notifier.update((p) => p.copyWith(lfo1: l));
                                    recordAutomationCC(ref, 103, (l.rate / 20).clamp(0.0, 1.0));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Row 4: LFO 2 + Master Section ──
                        AnimatedSection(
                          index: 4,
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
                                    recordAutomationCC(ref, 104, (l.rate / 20).clamp(0.0, 1.0));
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: SynthTheme.card,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: SynthTheme.orange.withValues(alpha: 0.3),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        SynthTheme.card,
                                        SynthTheme.card.withValues(alpha: 0.8),
                                      ],
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
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          if (locks.contains(LockableParam.masterVolume)) ...[
                                            const SizedBox(width: 6),
                                            Icon(Icons.lock, color: SynthTheme.magenta, size: 12),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SynthKnob(
                                        label: 'VOLUME',
                                        value: effectivePreset.masterVolume,
                                        min: 0,
                                        max: 1,
                                        size: 80,
                                        formatValue: (v) => '${(v * 100).round()}',
                                        onChanged: (v) {
                                          notifier.update((p) => p.copyWith(masterVolume: v));
                                          recordAutomationCC(ref, 102, v.clamp(0.0, 1.0));
                                        },
                                        activeColor: SynthTheme.orange,
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.withValues(alpha: 0.2),
                                          foregroundColor: Colors.redAccent,
                                          side: const BorderSide(color: Colors.redAccent),
                                          minimumSize: const Size(double.infinity, 30),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                        onPressed: () {
                                          ref.read(synthEngineProvider)?.reset();
                                          ref.read(playbackStateProvider.notifier).allNotesOff();
                                          ref.read(arpNotesProvider.notifier).state = {};
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('PANIC: All notes killed')),
                                          );
                                        },
                                        child: const Text('PANIC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Arpeggiator ──
                        const ArpeggiatorPanel(),
                        const SizedBox(height: 12),

                        // ── Effects Panel (Legacy + Multi-Slot) ──
                        FxPanel(
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
                          // ── Multi-Slot FX ──
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
                        const SizedBox(height: 12),

                        // ── Sequencer ──
                        const SequencerPanel(),
                        const SizedBox(height: 12),

                        // ── Modulation Matrix ──
                        const ModMatrixPanel(),
                        const SizedBox(height: 12),

                        // ── Macro Controls ──
                        const MacroPanel(),
                        const SizedBox(height: 12),

                        // ── Preset Morph ──
                        const MorphPanel(),
                        const SizedBox(height: 12),

                        // ── MIDI Clock / Sync ──
                        const ClockPanel(),
                        const SizedBox(height: 12),

                        // ── MIDI Input ──
                        const MidiPanel(),
                        const SizedBox(height: 16),

                        // DSP status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: SynthTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: SynthTheme.purple.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: SynthTheme.cyan,
                                  boxShadow: [
                                    BoxShadow(
                                      color: SynthTheme.cyan.withValues(alpha: 0.7),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'GRID CONNECTION: OPTIMAL  •  48kHz STEREO  •  1984 VIBES',
                                style: GoogleFonts.orbitron(
                                  color: SynthTheme.cyan,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── Fixed keyboard at bottom ──
                const KeyboardWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Local provider for the quick-strip search query.
final _quickStripSearchProvider = StateProvider<String>((ref) => '');

/// Local provider for the quick-strip category filter.
final _quickStripCategoryFilterProvider = StateProvider<PresetCategory?>((ref) => null);

/// Horizontal scrollable strip of quick-access presets shown just below
/// the oscilloscope / spectrum analyser on the Synth tab.
class _QuickPresetStrip extends ConsumerStatefulWidget {
  const _QuickPresetStrip();

  @override
  ConsumerState<_QuickPresetStrip> createState() => _QuickPresetStripState();
}

class _QuickPresetStripState extends ConsumerState<_QuickPresetStrip> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  final _activeTileKey = GlobalKey();
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<SynthPreset> _buildQuickList(
    List<SynthPreset> allPresets,
    Set<String> favorites,
    List<String> orderedFavorites,
    List<String> recentIds,
    String query,
    PresetCategory? categoryFilter,
  ) {
    final seen = <String>{};
    final result = <SynthPreset>[];

    SynthPreset? findPreset(String id) {
      for (final p in allPresets) {
        if (p.id == id) return p;
      }
      return null;
    }

    // 1. Favorites (in user-defined order)
    for (final id in orderedFavorites) {
      if (!favorites.contains(id)) continue;
      final preset = findPreset(id);
      if (preset != null && seen.add(preset.id)) {
        result.add(preset);
      }
    }

    // 2. Recently-used (most recent first, excluding already-seen)
    for (final id in recentIds.reversed) {
      final preset = findPreset(id);
      if (preset != null && seen.add(preset.id)) {
        result.add(preset);
      }
    }

    // 3. Fill remainder with any presets
    for (final p in allPresets) {
      if (seen.add(p.id)) {
        result.add(p);
      }
    }

    var list = result;

    // 4. Apply category filter
    if (categoryFilter != null) {
      list = list.where((p) => p.category == categoryFilter).toList();
    }

    // 5. Apply search filter
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.category.displayName.toLowerCase().contains(q) ||
            p.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    return list.take(20).toList();
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(presetListProvider);
    final current = ref.watch(currentPresetProvider);
    final favorites = ref.watch(favoritesProvider);
    final favoritesNotifier = ref.watch(favoritesProvider.notifier);
    final orderedFavorites = favoritesNotifier.orderedFavorites;
    final recentIds = ref.watch(recentPresetsProvider);
    final query = ref.watch(_quickStripSearchProvider);

    // Sync controller when provider is cleared externally (e.g. tab switch).
    ref.listen<String>(_quickStripSearchProvider, (prev, next) {
      if (next.isEmpty && _searchController.text.isNotEmpty) {
        _searchController.clear();
      }
    });

    // Auto-scroll to active preset when it changes externally.
    ref.listen<SynthPreset>(currentPresetProvider, (prev, next) {
      if (prev?.id != next.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_activeTileKey.currentContext != null) {
            Scrollable.ensureVisible(
              _activeTileKey.currentContext!,
              alignment: 0.5,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });

    final selectedCategory = ref.watch(_quickStripCategoryFilterProvider);

    final quickPresets = _buildQuickList(
      presets,
      favorites,
      orderedFavorites,
      recentIds,
      query,
      selectedCategory,
    );

    final categories = presets.map((p) => p.category).toSet().toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (categories.isNotEmpty)
            Container(
              height: 22,
              margin: const EdgeInsets.only(bottom: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, idx) {
                  final cat = categories[idx];
                  final isSelected = cat == selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      if (isSelected) {
                        ref.read(_quickStripCategoryFilterProvider.notifier).state = null;
                      } else {
                        ref.read(_quickStripCategoryFilterProvider.notifier).state = cat;
                      }
                    },
                    onLongPress: () {
                      ref.read(_quickStripCategoryFilterProvider.notifier).state = null;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? SynthTheme.cyan.withValues(alpha: 0.25)
                            : SynthTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? SynthTheme.cyan
                              : SynthTheme.purple.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        cat.displayName,
                        style: TextStyle(
                          color: isSelected ? SynthTheme.cyan : Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),            SizedBox(
            height: 52,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: quickPresets.isEmpty ? 4 : quickPresets.length + 3,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
          // ── Paste button ──
          if (index == 0) {
            return GestureDetector(
              onTap: () async {
                HapticFeedback.lightImpact();
                await pastePresetFromClipboard(context, ref);
              },
              child: Container(
                width: 44,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: SynthTheme.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: SynthTheme.purple.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.content_paste,
                      color: SynthTheme.purple,
                      size: 16,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PASTE',
                      style: TextStyle(
                        color: SynthTheme.purple,
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

          // ── Dice button ──
          if (index == 1) {
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (quickPresets.isEmpty) return;
                final rng = Random();
                final randomPreset = quickPresets[rng.nextInt(quickPresets.length)];
                ref.read(currentPresetProvider.notifier).load(randomPreset);
                ref.read(recentPresetsProvider.notifier).track(randomPreset.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Surprise! Loaded "${randomPreset.name}"'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: SynthTheme.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: SynthTheme.cyan.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.casino,
                      color: SynthTheme.cyan,
                      size: 18,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RANDOM',
                      style: TextStyle(
                        color: SynthTheme.cyan,
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

          // ── Search field ──
          if (index == 2) {
            final hasRecents = recentIds.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              width: _searchFocused ? 172 : 100,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SynthTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _searchFocused
                      ? SynthTheme.magenta.withValues(alpha: 0.5)
                      : SynthTheme.purple.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: SynthTheme.textSecondary.withValues(alpha: 0.5),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(
                          color: SynthTheme.textSecondary.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onChanged: (v) {
                        ref.read(_quickStripSearchProvider.notifier).state = v;
                      },
                    ),
                  ),
                  if (query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        ref.read(_quickStripSearchProvider.notifier).state = '';
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.close,
                          color: SynthTheme.textSecondary.withValues(alpha: 0.5),
                          size: 14,
                        ),
                      ),
                    )
                  else if (hasRecents)
                    GestureDetector(
                      onTap: () {
                        ref.read(recentPresetsProvider.notifier).clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recent history cleared'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.delete_outline,
                          color: SynthTheme.textSecondary.withValues(alpha: 0.35),
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          // ── Empty state ──
          if (index == 3 && quickPresets.isEmpty) {
            return Container(
              width: 160,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SynthTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: SynthTheme.purple.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list_off,
                    color: SynthTheme.textSecondary.withValues(alpha: 0.4),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No presets',
                          style: TextStyle(
                            color: SynthTheme.textSecondary.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (query.isNotEmpty || selectedCategory != null)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              ref.read(_quickStripSearchProvider.notifier).state = '';
                              ref.read(_quickStripCategoryFilterProvider.notifier).state = null;
                            },
                            child: Text(
                              'Clear filters',
                              style: TextStyle(
                                color: SynthTheme.cyan,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // ── Preset tile ──
          final p = quickPresets[index - 3];
          final isActive = p.id == current.id;
          final isFav = favorites.contains(p.id);
          final favIdx = orderedFavorites.indexOf(p.id);
          final inRecents = recentIds.contains(p.id);
          final tile = GestureDetector(
            key: isActive ? _activeTileKey : null,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(currentPresetProvider.notifier).load(p);
              ref.read(recentPresetsProvider.notifier).track(p.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Loaded "${p.name}"'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            onDoubleTap: () {
              HapticFeedback.lightImpact();
              ref.read(favoritesProvider.notifier).toggle(p.id);
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              showQuickPresetContextMenu(context, ref, p);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isFav ? 132 : 110,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? SynthTheme.magenta.withValues(alpha: 0.2)
                    : isFav
                        ? SynthTheme.orange.withValues(alpha: 0.1)
                        : SynthTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? SynthTheme.magenta.withValues(alpha: 0.6)
                      : isFav
                          ? SynthTheme.orange.withValues(alpha: 0.4)
                          : SynthTheme.purple.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            color: isActive ? SynthTheme.magenta : Colors.white.withValues(alpha: 0.9),
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.category.displayName.toUpperCase(),
                          style: TextStyle(
                            color: SynthTheme.textSecondary.withValues(alpha: 0.6),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (p.tags.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: SynthTheme.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              p.tags.first.toUpperCase(),
                              style: TextStyle(
                                color: SynthTheme.purple.withValues(alpha: 0.9),
                                fontSize: 6,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        // Pitch-offset indicator
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${p.osc1.octave >= 0 ? '+' : ''}${p.osc1.octave} • ${p.osc1.detune >= 0 ? '+' : ''}${p.osc1.detune.round()}¢',
                            style: TextStyle(
                              color: SynthTheme.textSecondary.withValues(alpha: 0.5),
                              fontSize: 7,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Waveform cycle button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      final nextIndex = (p.osc1.waveform.index + 1) % Waveform.values.length;
                      final nextWave = Waveform.values[nextIndex];
                      final updated = p.copyWith(osc1: p.osc1.copyWith(waveform: nextWave));
                      ref.read(presetListProvider.notifier).updatePreset(updated);
                      if (current.id == p.id) {
                        ref.read(currentPresetProvider.notifier).update((preset) => preset.copyWith(osc1: updated.osc1));
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${p.name} → ${nextWave.displayName}'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6, right: 2),
                      child: Icon(
                        p.osc1.waveform.icon,
                        color: isActive
                            ? SynthTheme.magenta.withValues(alpha: 0.8)
                            : SynthTheme.cyan.withValues(alpha: 0.6),
                        size: 14,
                      ),
                    ),
                  ),
                  if (isFav) ...[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (favIdx > 0) {
                          ref.read(favoritesProvider.notifier).reorder(favIdx, favIdx - 1);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.chevron_left,
                          color: favIdx > 0
                              ? SynthTheme.textSecondary.withValues(alpha: 0.5)
                              : SynthTheme.textSecondary.withValues(alpha: 0.15),
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(favoritesProvider.notifier).toggle(p.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isFav ? Icons.star : Icons.star_border,
                        color: isFav ? SynthTheme.orange : SynthTheme.textSecondary.withValues(alpha: 0.4),
                        size: 14,
                      ),
                    ),
                  ),
                  if (isFav) ...[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (favIdx >= 0 && favIdx < orderedFavorites.length - 1) {
                          HapticFeedback.lightImpact();
                          ref.read(favoritesProvider.notifier).reorder(favIdx, favIdx + 2);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.chevron_right,
                          color: (favIdx >= 0 && favIdx < orderedFavorites.length - 1)
                              ? SynthTheme.textSecondary.withValues(alpha: 0.5)
                              : SynthTheme.textSecondary.withValues(alpha: 0.15),
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );

          if (inRecents && !isFav) {
            return Dismissible(
              key: ValueKey(p.id),
              direction: DismissDirection.up,
              onDismissed: (_) {
                ref.read(recentPresetsProvider.notifier).untrack(p.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${p.name}" from recents'),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () {
                        ref.read(recentPresetsProvider.notifier).track(p.id);
                      },
                    ),
                  ),
                );
              },
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.delete, color: Colors.red, size: 16),
                ),
              ),
              child: tile,
            );
          }
          return tile;
        },
              ),
            ),
          ],
        ),
      );
    }
  }
