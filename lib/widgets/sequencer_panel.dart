import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/sequencer_config.dart';
import '../providers/sequencer_provider.dart';
import '../providers/randomize_lock_provider.dart';
import '../theme/synth_theme.dart';
import '../utils/midi_file_reader.dart';

class SequencerPanel extends ConsumerWidget {
  const SequencerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pattern = ref.watch(sequencerPatternProvider);
    final isPlaying = ref.watch(sequencerPlayingProvider);
    final isRecording = ref.watch(sequencerRecordingProvider);
    final currentStep = ref.watch(sequencerCurrentStepProvider);
    final patterns = ref.watch(sequencerPatternsProvider);
    final isLocked = ref.watch(randomizeLockProvider).contains(LockableParam.sequencer);

    // Keep engine alive
    ref.watch(sequencerEngineProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPlaying
              ? SynthTheme.cyan.withValues(alpha: 0.4)
              : SynthTheme.purple.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPlaying ? SynthTheme.cyan : SynthTheme.purple.withValues(alpha: 0.3),
                  boxShadow: isPlaying
                      ? [BoxShadow(color: SynthTheme.cyan.withValues(alpha: 0.6), blurRadius: 8)]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'STEP SEQUENCER',
                style: TextStyle(
                  color: isPlaying ? SynthTheme.cyan : SynthTheme.textSecondary,
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
              // BPM display
              _BpmControl(bpm: pattern.bpm),
              const SizedBox(width: 8),
              // Transport controls
              _TransportBtn(
                icon: isPlaying ? Icons.stop : Icons.play_arrow,
                color: isPlaying ? Colors.redAccent : SynthTheme.cyan,
                onTap: () {
                  ref.read(sequencerPlayingProvider.notifier).state = !isPlaying;
                  if (!isPlaying) {
                    ref.read(sequencerCurrentStepProvider.notifier).state = 0;
                  }
                },
              ),
              const SizedBox(width: 6),
              _TransportBtn(
                icon: Icons.fiber_manual_record,
                color: isRecording ? Colors.red : SynthTheme.textSecondary,
                onTap: () {
                  ref.read(sequencerRecordingProvider.notifier).state = !isRecording;
                },
              ),
              const SizedBox(width: 6),
              _TransportBtn(
                icon: Icons.file_upload_outlined,
                color: SynthTheme.cyan,
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['mid', 'midi'],
                  );
                  if (result != null && result.files.single.path != null) {
                    final path = result.files.single.path!;
                    try {
                      final pattern = MidiFileReader.toSequencerPattern(path);
                      ref.read(sequencerPatternProvider.notifier).loadPattern(pattern);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Imported "${result.files.single.name}"'),
                            backgroundColor: SynthTheme.card,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Import failed: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pattern selector
          _PatternSelector(
            currentPattern: pattern,
            savedPatterns: patterns,
          ),
          const SizedBox(height: 12),

          // Step grid — one row per track
          ...List.generate(pattern.tracks.length, (trackIndex) {
            final track = pattern.tracks[trackIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          track.name,
                          style: TextStyle(
                            color: SynthTheme.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: _StepRow(
                          trackIndex: trackIndex,
                          steps: track.steps,
                          currentStep: currentStep,
                          isPlaying: isPlaying,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          // Track controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ScaleQuantizerButton(),
              const SizedBox(width: 8),
              _SmallBtn(
                label: 'Clear',
                onTap: () => ref.read(sequencerPatternProvider.notifier).clearTrack(0),
              ),
              const SizedBox(width: 8),
              _SmallBtn(
                label: '+ Track',
                onTap: () => ref.read(sequencerPatternProvider.notifier).addTrack(),
              ),
              if (pattern.tracks.length > 1) ...[
                const SizedBox(width: 8),
                _SmallBtn(
                  label: '- Track',
                  onTap: () => ref.read(sequencerPatternProvider.notifier).removeTrack(pattern.tracks.length - 1),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StepRow extends ConsumerWidget {
  final int trackIndex;
  final List<SequencerStep> steps;
  final int currentStep;
  final bool isPlaying;

  const _StepRow({
    required this.trackIndex,
    required this.steps,
    required this.currentStep,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: steps.length,
        separatorBuilder: (_, _) => const SizedBox(width: 3),
        itemBuilder: (context, stepIndex) {
          final step = steps[stepIndex];
          final isCurrent = stepIndex == currentStep && isPlaying;
          final isBeat = stepIndex % 4 == 0;

          return GestureDetector(
            onTap: () {
              ref.read(sequencerPatternProvider.notifier).toggleStep(trackIndex, stepIndex);
            },
            onLongPress: () => _showNotePicker(context, ref, stepIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 28,
              decoration: BoxDecoration(
                color: step.enabled
                    ? (isCurrent
                        ? SynthTheme.cyan.withValues(alpha: 0.9)
                        : SynthTheme.cyan.withValues(alpha: 0.4))
                    : (isCurrent
                        ? SynthTheme.cyan.withValues(alpha: 0.15)
                        : (isBeat
                            ? SynthTheme.surface.withValues(alpha: 0.8)
                            : SynthTheme.surface)),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isCurrent
                      ? Colors.white.withValues(alpha: 0.6)
                      : isBeat
                          ? SynthTheme.purple.withValues(alpha: 0.3)
                          : SynthTheme.purple.withValues(alpha: 0.1),
                  width: isCurrent ? 1.5 : 1.0,
                ),
                boxShadow: isCurrent
                    ? [BoxShadow(color: SynthTheme.cyan.withValues(alpha: 0.4), blurRadius: 6)]
                    : null,
              ),
              alignment: Alignment.center,
              child: step.enabled && step.note >= 0
                  ? Text(
                      _noteNameShort(step.note),
                      style: TextStyle(
                        color: isCurrent ? Colors.white : SynthTheme.cyan.withValues(alpha: 0.8),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  String _noteNameShort(int midiNote) {
    final names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return names[midiNote % 12];
  }

  void _showNotePicker(BuildContext context, WidgetRef ref, int stepIndex) {
    final currentStep = ref.read(sequencerPatternProvider).tracks[trackIndex].steps[stepIndex];
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
                Text(
                  'Step ${stepIndex + 1} Note',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: 128,
                    itemBuilder: (context, i) {
                      final names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
                      final name = names[i % 12];
                      final octave = (i ~/ 12) - 1;
                      final isSelected = currentStep.note == i;
                      return GestureDetector(
                        onTap: () {
                          ref.read(sequencerPatternProvider.notifier).setStepNote(trackIndex, stepIndex, i);
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? SynthTheme.cyan.withValues(alpha: 0.5)
                                : SynthTheme.surface,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: isSelected
                                  ? SynthTheme.cyan
                                  : SynthTheme.purple.withValues(alpha: 0.2),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$name$octave',
                            style: TextStyle(
                              color: isSelected ? Colors.white : SynthTheme.textSecondary,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                    foregroundColor: Colors.redAccent,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  onPressed: () {
                    ref.read(sequencerPatternProvider.notifier).setStep(
                      trackIndex,
                      stepIndex,
                      currentStep.copyWith(enabled: false),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Clear Step'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BpmControl extends ConsumerWidget {
  final double bpm;
  const _BpmControl({required this.bpm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: SynthTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: SynthTheme.cyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => ref.read(sequencerPatternProvider.notifier).setBpm(bpm - 1),
            child: Icon(Icons.remove, color: SynthTheme.cyan, size: 14),
          ),
          const SizedBox(width: 6),
          Text(
            '${bpm.round()}',
            style: GoogleFonts.orbitron(
              color: SynthTheme.cyan,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => ref.read(sequencerPatternProvider.notifier).setBpm(bpm + 1),
            child: Icon(Icons.add, color: SynthTheme.cyan, size: 14),
          ),
        ],
      ),
    );
  }
}

class _TransportBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TransportBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _PatternSelector extends ConsumerWidget {
  final SequencerPattern currentPattern;
  final List<SequencerPattern> savedPatterns;

  const _PatternSelector({
    required this.currentPattern,
    required this.savedPatterns,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: SynthTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.2)),
            ),
            child: Text(
              currentPattern.name,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 6),
        _SmallBtn(
          label: 'Save',
          onTap: () {
            ref.read(sequencerPatternsProvider.notifier).updatePattern(currentPattern);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pattern saved')),
            );
          },
        ),
        const SizedBox(width: 6),
        _SmallBtn(
          label: 'New',
          onTap: () {
            ref.read(sequencerPatternProvider.notifier).loadPattern(
              SequencerPattern.empty(),
            );
          },
        ),
        if (savedPatterns.isNotEmpty) ...[
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            tooltip: 'Load pattern',
            color: SynthTheme.card,
            icon: Icon(Icons.folder_open, color: SynthTheme.cyan, size: 16),
            itemBuilder: (context) => savedPatterns.map((p) {
              return PopupMenuItem(
                value: p.id,
                child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
              );
            }).toList(),
            onSelected: (id) {
              final pattern = savedPatterns.firstWhere((p) => p.id == id);
              ref.read(sequencerPatternProvider.notifier).loadPattern(pattern);
            },
          ),
        ],
      ],
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SmallBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: SynthTheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: SynthTheme.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Button that toggles scale quantize on/off and lets the user pick a scale.
class _ScaleQuantizerButton extends ConsumerWidget {
  const _ScaleQuantizerButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = ref.watch(sequencerPatternProvider.select((p) => p.scaleConfig));
    final isEnabled = scaleConfig.enabled;

    return GestureDetector(
      onTap: () => _showScalePicker(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isEnabled
              ? SynthTheme.cyan.withValues(alpha: 0.2)
              : SynthTheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isEnabled
                ? SynthTheme.cyan
                : SynthTheme.purple.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_note,
              size: 14,
              color: isEnabled ? SynthTheme.cyan : SynthTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              isEnabled ? scaleConfig.scale.displayName : 'SCALE',
              style: TextStyle(
                color: isEnabled ? SynthTheme.cyan : SynthTheme.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScalePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(sequencerPatternProvider).scaleConfig;
    showModalBottomSheet(
      context: context,
      backgroundColor: SynthTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.music_note, color: SynthTheme.cyan, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'SCALE QUANTIZER',
                      style: TextStyle(
                        color: SynthTheme.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: current.enabled,
                      onChanged: (v) {
                        ref.read(sequencerPatternProvider.notifier).updatePattern(
                          (p) => p.copyWith(
                            scaleConfig: current.copyWith(enabled: v),
                          ),
                        );
                      },
                      activeThumbColor: SynthTheme.cyan,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'ROOT NOTE',
                  style: TextStyle(
                    color: SynthTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 12,
                    separatorBuilder: (_, _) => const SizedBox(width: 4),
                    itemBuilder: (_, i) {
                      final names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
                      final isSelected = current.rootNote == i;
                      return GestureDetector(
                        onTap: () {
                          ref.read(sequencerPatternProvider.notifier).updatePattern(
                            (p) => p.copyWith(
                              scaleConfig: current.copyWith(rootNote: i, enabled: true),
                            ),
                          );
                        },
                        child: Container(
                          width: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? SynthTheme.cyan.withValues(alpha: 0.3)
                                : SynthTheme.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? SynthTheme.cyan
                                  : SynthTheme.purple.withValues(alpha: 0.2),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            names[i],
                            style: TextStyle(
                              color: isSelected ? SynthTheme.cyan : SynthTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'SCALE',
                  style: TextStyle(
                    color: SynthTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 200,
                  child: ListView(
                    children: MusicalScale.values.map((scale) {
                      final isSelected = current.scale == scale;
                      return GestureDetector(
                        onTap: () {
                          ref.read(sequencerPatternProvider.notifier).updatePattern(
                            (p) => p.copyWith(
                              scaleConfig: current.copyWith(scale: scale, enabled: true),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? SynthTheme.cyan.withValues(alpha: 0.15)
                                : SynthTheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? SynthTheme.cyan
                                  : SynthTheme.purple.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined,
                                size: 14,
                                color: isSelected ? SynthTheme.cyan : SynthTheme.textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                scale.displayName,
                                style: TextStyle(
                                  color: isSelected ? SynthTheme.cyan : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: SynthTheme.cyan.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: TextStyle(color: SynthTheme.cyan, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
