import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/macro_provider.dart';
import '../providers/midi_provider.dart';
import '../providers/mod_matrix_provider.dart';
import '../theme/synth_theme.dart';

/// Dedicated MIDI learn / CC mapping screen.
///
/// Shows all current MIDI CC assignments (macros + mod matrix) and
/// lets the user enter learn mode for any of them or manually assign
/// a CC number.
class MidiLearnScreen extends ConsumerWidget {
  const MidiLearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(selectedMidiDeviceProvider);
    final isConnected = ref.watch(midiConnectionStatusProvider);
    final macroBank = ref.watch(macroBankProvider);
    final macroLearnIndex = ref.watch(macroLearnModeProvider);
    final modMatrix = ref.watch(modMatrixProvider);
    final modLearnSlot = ref.watch(modMatrixLearnModeProvider);
    final ccAssignments = ref.watch(ccAssignmentsProvider);
    final eventLog = ref.watch(midiEventLogProvider);

    // Keep MIDI listener alive
    ref.watch(midiListenerProvider);

    return Scaffold(
      backgroundColor: SynthTheme.bg,
      appBar: AppBar(
        title: Text(
          'MIDI LEARN',
          style: GoogleFonts.orbitron(
            color: SynthTheme.magenta,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          // Connection status badge
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isConnected
                    ? SynthTheme.cyan.withValues(alpha: 0.15)
                    : Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isConnected ? SynthTheme.cyan : Colors.redAccent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? SynthTheme.cyan : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    device?.name ?? 'NO DEVICE',
                    style: TextStyle(
                      color: isConnected ? SynthTheme.cyan : Colors.redAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ── Macro CC Assignments ──
          _SectionHeader(
            title: 'MACRO CC ASSIGNMENTS',
            color: SynthTheme.magenta,
            action: GestureDetector(
              onTap: () => ref.read(macroLearnModeProvider.notifier).state = -1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SynthTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'Clear Learn Mode',
                  style: TextStyle(
                    color: SynthTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(4, (i) {
            final macro = macroBank.getMacro(i);
            final isLearning = macroLearnIndex == i;
            return _CcMappingTile(
              label: 'Macro ${i + 1}: ${macro.name}',
              ccNumber: macro.ccNumber,
              isLearning: isLearning,
              accentColor: SynthTheme.magenta,
              onLearn: () {
                if (isLearning) {
                  ref.read(macroLearnModeProvider.notifier).state = -1;
                } else {
                  ref.read(macroLearnModeProvider.notifier).state = i;
                }
              },
              onClear: () {
                ref.read(macroBankProvider.notifier).setMacroCc(i, -1);
              },
              onAssign: (cc) {
                ref.read(macroBankProvider.notifier).setMacroCc(i, cc);
              },
            );
          }),
          const SizedBox(height: 24),

          // ── Mod Matrix CC Assignments ──
          _SectionHeader(
            title: 'MOD MATRIX CC ASSIGNMENTS',
            color: SynthTheme.cyan,
            action: GestureDetector(
              onTap: () => ref.read(modMatrixLearnModeProvider.notifier).state = -1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SynthTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'Clear Learn Mode',
                  style: TextStyle(
                    color: SynthTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...modMatrix.slots.asMap().entries.map((entry) {
            final i = entry.key;
            final slot = entry.value;
            if (!slot.enabled) return const SizedBox.shrink();
            final isLearning = modLearnSlot == i;

            // Find CC number assigned to this slot's source
            int? assignedCc;
            for (final entry in ccAssignments.entries) {
              if (entry.value == slot.source) {
                assignedCc = entry.key;
                break;
              }
            }

            return _CcMappingTile(
              label: 'Slot ${i + 1}: ${slot.source.displayName} → ${slot.destination.displayName}',
              ccNumber: assignedCc ?? -1,
              isLearning: isLearning,
              accentColor: SynthTheme.cyan,
              onLearn: () {
                if (isLearning) {
                  ref.read(modMatrixLearnModeProvider.notifier).state = -1;
                } else {
                  ref.read(modMatrixLearnModeProvider.notifier).state = i;
                }
              },
              onClear: () {
                if (assignedCc != null) {
                  ref.read(ccAssignmentsProvider.notifier).remove(assignedCc);
                }
              },
              onAssign: (cc) {
                ref.read(ccAssignmentsProvider.notifier).assign(cc, slot.source);
              },
            );
          }),
          const SizedBox(height: 24),

          // ── All Learned CCMappings Summary ──
          _SectionHeader(
            title: 'ACTIVE CC MAPPINGS',
            color: SynthTheme.orange,
          ),
          const SizedBox(height: 8),
          if (ccAssignments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.music_off, size: 36, color: SynthTheme.purple.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    Text(
                      'No CC mappings yet.\nMove a hardware knob while in Learn Mode to assign it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SynthTheme.textSecondary.withValues(alpha: 0.6),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...ccAssignments.entries.map((entry) {
              final source = entry.value;
              final labels = {
                1: 'Mod Wheel',
                2: 'Breath',
                7: 'Volume',
                10: 'Pan',
                11: 'Expression',
                64: 'Sustain',
                71: 'Resonance',
                74: 'Cutoff',
              };
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: SynthTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: SynthTheme.orange.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: SynthTheme.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'CC${entry.key}',
                        style: TextStyle(
                          color: SynthTheme.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            labels[entry.key] ?? '',
                            style: TextStyle(
                              color: SynthTheme.textSecondary.withValues(alpha: 0.5),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(ccAssignmentsProvider.notifier).remove(entry.key),
                      child: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.redAccent.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),

          // ── Event Monitor ──
          _SectionHeader(
            title: 'MIDI EVENT MONITOR',
            color: SynthTheme.purple,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0118),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.15)),
            ),
            child: eventLog.isEmpty
                ? Text(
                    'Waiting for MIDI events...\nMove a knob or press a key on your MIDI controller.',
                    style: TextStyle(
                      color: SynthTheme.textSecondary.withValues(alpha: 0.4),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: eventLog.take(15).map((msg) {
                      final isOut = msg.startsWith('OUT');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOut ? SynthTheme.orange : SynthTheme.cyan,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                msg,
                                style: TextStyle(
                                  color: isOut
                                      ? SynthTheme.orange.withValues(alpha: 0.7)
                                      : SynthTheme.cyan.withValues(alpha: 0.7),
                                  fontSize: 9,
                                  fontFamily: 'monospace',
                                  fontFamilyFallback: const ['monospace'],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 12),

          // Help text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SynthTheme.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOW TO LEARN',
                  style: TextStyle(
                    color: SynthTheme.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                _HelpStep(number: 1, text: 'Tap the "Learn" button on a Macro or Mod Matrix slot'),
                _HelpStep(number: 2, text: 'Move a knob or slider on your MIDI controller'),
                _HelpStep(number: 3, text: 'The CC is automatically assigned!'),
                _HelpStep(number: 4, text: 'Tap the "Learn" button again to exit learn mode'),
                const SizedBox(height: 6),
                Text(
                  'Manually tap a CC number badge to assign a specific CC.',
                  style: TextStyle(
                    color: SynthTheme.textSecondary.withValues(alpha: 0.4),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final Widget? action;

  const _SectionHeader({
    required this.title,
    required this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        ?action,
      ],
    );
  }
}

class _HelpStep extends StatelessWidget {
  final int number;
  final String text;

  const _HelpStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: SynthTheme.purple.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: TextStyle(
                color: SynthTheme.purple,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: SynthTheme.textSecondary.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tile showing a single CC mapping with learn/clear/assign actions.
class _CcMappingTile extends ConsumerWidget {
  final String label;
  final int ccNumber;
  final bool isLearning;
  final Color accentColor;
  final VoidCallback onLearn;
  final VoidCallback onClear;
  final ValueChanged<int> onAssign;

  const _CcMappingTile({
    required this.label,
    required this.ccNumber,
    required this.isLearning,
    required this.accentColor,
    required this.onLearn,
    required this.onClear,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAssigned = ccNumber >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isLearning ? accentColor.withValues(alpha: 0.08) : SynthTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLearning
              ? accentColor.withValues(alpha: 0.6)
              : SynthTheme.purple.withValues(alpha: 0.15),
          width: isLearning ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Learn indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLearning ? accentColor : SynthTheme.textSecondary.withValues(alpha: 0.3),
              boxShadow: isLearning
                  ? [BoxShadow(color: accentColor.withValues(alpha: 0.6), blurRadius: 8)]
                  : null,
            ),
          ),
          const SizedBox(width: 10),

          // Label
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // CC badge (tappable for manual assign)
          GestureDetector(
            onTap: () => _showCcPicker(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAssigned
                    ? accentColor.withValues(alpha: 0.15)
                    : SynthTheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isAssigned
                      ? accentColor.withValues(alpha: 0.4)
                      : SynthTheme.purple.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                isAssigned ? 'CC$ccNumber' : '---',
                style: TextStyle(
                  color: isAssigned ? accentColor : SynthTheme.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Learn button
          GestureDetector(
            onTap: onLearn,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLearning
                    ? accentColor.withValues(alpha: 0.25)
                    : SynthTheme.surface,
                border: Border.all(
                  color: isLearning ? accentColor : SynthTheme.purple.withValues(alpha: 0.25),
                  width: isLearning ? 1.5 : 1.0,
                ),
              ),
              child: Icon(
                isLearning ? Icons.sensors : Icons.touch_app,
                size: 14,
                color: isLearning ? accentColor : SynthTheme.textSecondary,
              ),
            ),
          ),

          // Clear button
          if (isAssigned) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onClear,
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.redAccent.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCcPicker(BuildContext context, WidgetRef ref) {
    final labels = {
      1: 'Mod Wheel',
      2: 'Breath',
      7: 'Volume',
      10: 'Pan',
      11: 'Expression',
      64: 'Sustain',
      71: 'Resonance',
      74: 'Cutoff',
    };

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
                  'Assign CC Number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: 128,
                    itemBuilder: (context, cc) {
                      return GestureDetector(
                        onTap: () {
                          onAssign(cc);
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: ccNumber == cc
                                ? accentColor.withValues(alpha: 0.4)
                                : SynthTheme.surface,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: ccNumber == cc
                                  ? accentColor
                                  : SynthTheme.purple.withValues(alpha: 0.2),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$cc',
                                style: TextStyle(
                                  color: ccNumber == cc ? Colors.white : SynthTheme.textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                labels[cc] ?? '',
                                style: TextStyle(
                                  color: (ccNumber == cc ? Colors.white : SynthTheme.textSecondary)
                                      .withValues(alpha: 0.5),
                                  fontSize: 7,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
